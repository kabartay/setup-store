# MLflow Server Deployment on GCP

This directory contains scripts and configuration for deploying a production MLflow tracking server on Google Cloud Platform.

## Overview

The MLflow server provides:
- **Centralized experiment tracking** across team members
- **Persistent storage** immune to local failures
- **Secure access control** via IAM
- **Cost-optimized infrastructure** (~$20/month)

## Architecture

```
┌─────────────────────────────────────────────────┐
│            Cloud Run (MLflow Server)            │
│            • Auto-scaling 0-10 instances        │
│            • Docker container                   │
│            • Public HTTPS endpoint              │
└───────────┬─────────────────┬───────────────────┘
            │                 │
            ▼                 ▼
┌─────────────────────┐  ┌──────────────────────┐
│   Cloud SQL         │  │  Cloud Storage (GCS) │
│   (PostgreSQL)      │  │                      │
│  • Experiment       │  │  • Artifacts (HTML,  │
│    metadata         │  │    JSON, models)     │
│  • Runs & params    │  │  • 90-day lifecycle  │
└─────────────────────┘  └──────────────────────┘
```

## Components

### 1. Cloud SQL PostgreSQL
- **Purpose**: Store experiment metadata (runs, parameters, metrics)
- **Instance**: `db-f1-micro` (smallest tier, suitable for small teams)
- **Cost**: ~$15/month
- **Connection**: Unix socket via Cloud SQL Proxy

### 2. Cloud Storage (GCS)
- **Purpose**: Store artifacts (reports, models, files)
- **Bucket**: Auto-created with lifecycle policy
- **Cost**: ~$3/month (< 100GB)
- **Lifecycle**: 90-day retention (configurable)

### 3. Cloud Run
- **Purpose**: Host MLflow server
- **Scaling**: 0-10 instances (auto-scale on demand)
- **Port**: 8080
- **Cost**: ~$0 when idle
- **Image**: Custom Docker container from Artifact Registry

## Deployment Files

### `Dockerfile`
Builds the MLflow server container with:
- Python 3.11 slim base image
- MLflow 2.9.2 with PostgreSQL and GCS support
- Non-root user for security
- Exposed port 8080

### `entrypoint.sh`
Server startup script with:
- Environment variable validation
- PostgreSQL backend store configuration
- GCS artifact root setup
- MLflow server launch with artifact serving

**Required Environment Variables (set by Cloud Run):**
- `DB_URI`: PostgreSQL connection string with Cloud SQL socket path
- `ARTIFACT_ROOT`: GCS bucket path for artifacts

### `setup_mlflow_gcp.sh`
Infrastructure provisioning script that:
- Creates Cloud SQL PostgreSQL instance
- Creates GCS bucket with lifecycle policy
- Sets up IAM permissions
- Configures networking and backup policies

### `deploy_mlflow.sh`
Server deployment script that:
- Builds Docker image for linux/amd64
- Pushes to Artifact Registry
- Deploys to Cloud Run
- Configures environment variables and Cloud SQL connection

### `create_mlflow_access.sh`
Service account creation script for:
- Creating dedicated service accounts for client access
- Granting storage permissions
- Generating authentication keys

## One-Time Setup

### Prerequisites

1. **GCP Project**: Active project with billing enabled
2. **gcloud CLI**: Installed and authenticated (`gcloud auth login`)
3. **Docker**: Installed for local image building
4. **Permissions**: Owner or Editor role on the project
5. **APIs**: Will be enabled automatically by scripts
   - Cloud SQL Admin API
   - Cloud Run API
   - Artifact Registry API
   - Cloud Storage API

### Deployment Steps

```bash
# 1. Navigate to mlflow directory
cd /path/to/mlflow

# 2. Create .env file with passwords
cat > .env << EOF
ROOT_PASSWORD=your_strong_root_password
USER_PASSWORD=your_strong_user_password
EOF

# 3. Set your GCP project
export PROJECT_ID="your-project-id"
gcloud config set project $PROJECT_ID

# 4. Run infrastructure setup (one-time, takes 5-10 minutes)
bash setup_mlflow_gcp.sh

# This will create:
# - Cloud SQL instance (mlflow-db)
# - PostgreSQL database (mlflow)
# - Database user (mlflow-bek)
# - GCS bucket (PROJECT_ID-mlflow-artifacts)
# - Lifecycle policy (90-day retention)

# 5. Deploy MLflow server
bash deploy_mlflow.sh

# This will:
# - Build Docker image
# - Push to Artifact Registry
# - Deploy to Cloud Run
# - Output MLflow URL

# 6. Test the deployment
curl https://mlflow-tracking-YOUR_SERVICE.a.run.app/health

# 7. (Optional) Create service account for programmatic access
bash create_mlflow_access.sh
# This generates mlflow-client-key.json for authentication
```

### Configuration for Evaluation Scripts

After deployment, configure your evaluation scripts to use the MLflow server:

```python
import mlflow

# Set tracking URI
mlflow.set_tracking_uri("https://mlflow-tracking-YOUR_SERVICE.a.run.app")

# Set experiment name
mlflow.set_experiment("my-evaluation")

# Use MLflow tracking in your code
with mlflow.start_run():
    mlflow.log_param("param1", value)
    mlflow.log_metric("metric1", score)
    mlflow.log_artifact("report.html")
```

Or via environment variable:
```bash
export MLFLOW_TRACKING_URI="https://mlflow-tracking-YOUR_SERVICE.a.run.app"
python your_evaluation_script.py
```

## Usage from Evaluation Scripts

Once deployed, evaluation scripts can use MLflow tracking:

```bash
# Set tracking URI via environment variable
export MLFLOW_TRACKING_URI="https://mlflow-tracking-YOUR_SERVICE.a.run.app"

# For artifact uploads, authenticate
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/mlflow-client-key.json"

# Run your evaluation script
python evaluation_script.py
```

The MLflow client will automatically:
- Connect to remote MLflow server
- Log metrics, parameters, and artifacts
- Upload reports and artifacts to GCS

## Maintenance

### View Logs
```bash
# Cloud Run logs
gcloud run services logs read mlflow-tracking-YOUR_SERVICE \
  --region=europe-west9 \
  --limit=50

# Cloud SQL logs
gcloud sql operations list --instance=mlflow-db --limit=10
```

### Update Server
```bash
# After modifying Dockerfile or entrypoint.sh, redeploy:
bash deploy_mlflow.sh
```

### Scale Limits
```bash
# Adjust max instances for higher load
gcloud run services update mlflow-tracking-YOUR_SERVICE \
  --max-instances=20 \
  --region=europe-west9
```

### Backup Database
```bash
# Create manual backup
gcloud sql backups create --instance=mlflow-db

# List existing backups
gcloud sql backups list --instance=mlflow-db

# Restore from backup
gcloud sql backups restore BACKUP_ID \
  --backup-instance=mlflow-db \
  --backup-id=BACKUP_ID
```

## Cost Optimization

### Current Costs (~$18/month)
- **Cloud SQL** (db-f1-micro): $15/month
- **Cloud Storage** (< 100GB): $3/month
- **Cloud Run** (idle): $0/month
- **Artifact Registry**: $0 (free tier)

### Cost Reduction Strategies

1. **Pause when not in use:**
   ```bash
   # Stop Cloud SQL instance (saves ~$15/month)
   gcloud sql instances patch mlflow-db --activation-policy=NEVER
   
   # Start when needed
   gcloud sql instances patch mlflow-db --activation-policy=ALWAYS
   ```

2. **Adjust lifecycle policy:**
   ```bash
   # Modify retention to 30 days instead of 90
   # Edit setup_mlflow_gcp.sh and change LIFECYCLE_DAYS=30
   # Then update the bucket lifecycle:
   gsutil lifecycle set lifecycle.json gs://YOUR_PROJECT-mlflow-artifacts/
   ```

3. **Delete old artifacts manually:**
   ```bash
   # List old runs
   gsutil ls -l gs://YOUR_PROJECT-mlflow-artifacts/artifacts/
   
   # Delete specific run artifacts
   gsutil -m rm -r gs://YOUR_PROJECT-mlflow-artifacts/artifacts/RUN_ID/
   ```

4. **Use smaller Cloud SQL instance:**
   - db-f1-micro is already the smallest tier
   - Consider shared-core instances for dev/test

## Troubleshooting

### Connection Issues

**Problem**: Cannot connect to MLflow server
```bash
# Check service status
gcloud run services describe mlflow-tracking-YOUR_SERVICE \
  --region=europe-west9

# Test health endpoint
curl https://mlflow-tracking-YOUR_SERVICE.a.run.app/health

# Check if URL is correct
gcloud run services list --region=europe-west9
```

**Problem**: "Permission denied" errors
```bash
# Verify IAM permissions
gcloud projects get-iam-policy $PROJECT_ID

# For private access, add Cloud Run Invoker role
gcloud run services add-iam-policy-binding mlflow-tracking-YOUR_SERVICE \
  --member="user:your-email@example.com" \
  --role="roles/run.invoker" \
  --region=europe-west9
```

### Database Issues

**Problem**: Cloud SQL connection timeout
```bash
# Check Cloud SQL status
gcloud sql instances describe mlflow-db

# Check if Cloud SQL instance is running
gcloud sql instances list

# Start instance if stopped
gcloud sql instances patch mlflow-db --activation-policy=ALWAYS
```

**Problem**: Database connection errors
```bash
# Connect to Cloud SQL via Cloud Shell
gcloud sql connect mlflow-db --user=mlflow-bek

# Check database exists
\l

# Check tables
\c mlflow
\dt

# Reset database if needed (WARNING: deletes all data)
DROP DATABASE mlflow;
CREATE DATABASE mlflow;
```

### Artifact Upload Issues

**Problem**: Cannot upload artifacts to GCS
```bash
# Check authentication
gcloud auth application-default print-access-token

# Re-authenticate
gcloud auth application-default login

# Test GCS access
gsutil ls gs://YOUR_PROJECT-mlflow-artifacts/

# Verify service account has permissions
gsutil iam get gs://YOUR_PROJECT-mlflow-artifacts/
```

**Problem**: Bucket permission denied
```bash
# Check bucket IAM policy
gsutil iam get gs://YOUR_PROJECT-mlflow-artifacts/

# Add storage admin role to user
gsutil iam ch user:your-email@example.com:roles/storage.admin \
  gs://YOUR_PROJECT-mlflow-artifacts/

# Or use service account key file
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/mlflow-client-key.json"
```

**Problem**: Large artifact upload fails
```bash
# Cloud Run has a 60-minute timeout by default
# For larger artifacts, increase timeout:
gcloud run services update mlflow-tracking-YOUR_SERVICE \
  --timeout=3600 \
  --region=europe-west9
```

## Security Considerations

### Access Control

**Current Setup**: Public endpoint (anyone can view experiments)

**For Private Access:**
```bash
# Make Cloud Run private (requires authentication)
gcloud run services update mlflow-tracking-YOUR_SERVICE \
  --no-allow-unauthenticated \
  --region=europe-west9

# Grant access to specific users
gcloud run services add-iam-policy-binding mlflow-tracking-YOUR_SERVICE \
  --member="user:teammate@example.com" \
  --role="roles/run.invoker" \
  --region=europe-west9

# Grant access to service accounts
gcloud run services add-iam-policy-binding mlflow-tracking-YOUR_SERVICE \
  --member="serviceAccount:SA_EMAIL@PROJECT.iam.gserviceaccount.com" \
  --role="roles/run.invoker" \
  --region=europe-west9
```

### Network Security

**Current Setup**: Public internet access

**For Enhanced Security (VPC Access):**

VPC (Virtual Private Cloud) allows you to restrict MLflow to your private network:

1. **Create VPC Connector:**
   ```bash
   gcloud compute networks vpc-access connectors create mlflow-connector \
     --network=default \
     --region=europe-west9 \
     --range=10.8.0.0/28
   ```

2. **Configure Cloud SQL with private IP:**
   ```bash
   gcloud sql instances patch mlflow-db \
     --network=default \
     --no-assign-ip
   ```

3. **Update Cloud Run to use VPC:**
   ```bash
   gcloud run services update mlflow-tracking-YOUR_SERVICE \
     --vpc-connector=mlflow-connector \
     --vpc-egress=private-ranges-only \
     --region=europe-west9
   ```

### Secrets Management

**Current Setup**: Environment variables in Cloud Run

**For Enhanced Security:**
1. **Use Secret Manager:**
   ```bash
   # Store password in Secret Manager
   echo -n "your-password" | gcloud secrets create db-password --data-file=-
   
   # Grant Cloud Run access
   gcloud secrets add-iam-policy-binding db-password \
     --member="serviceAccount:PROJECT_NUMBER-compute@developer.gserviceaccount.com" \
     --role="roles/secretmanager.secretAccessor"
   
   # Update Cloud Run to use secret
   gcloud run services update mlflow-tracking-YOUR_SERVICE \
     --update-secrets=DB_PASSWORD=db-password:latest \
     --region=europe-west9
   ```

2. **Rotate credentials regularly:**
   - Change database passwords quarterly
   - Regenerate service account keys annually

3. **Enable audit logging:**
   ```bash
   gcloud logging read "resource.type=cloud_run_revision" \
     --limit=50 \
     --format=json
   ```

## Cleanup

To completely remove the MLflow infrastructure:

```bash
# 1. Delete Cloud Run service
gcloud run services delete mlflow-tracking-YOUR_SERVICE \
  --region=europe-west9

# 2. Delete Cloud SQL instance (includes all databases)
gcloud sql instances delete mlflow-db

# 3. Delete GCS bucket (removes all artifacts)
gsutil -m rm -r gs://YOUR_PROJECT-mlflow-artifacts/

# 4. Delete Artifact Registry repository (optional)
gcloud artifacts repositories delete mlflow-repo \
  --location=europe-west9

# 5. Delete service accounts (optional)
gcloud iam service-accounts delete mlflow-client@PROJECT_ID.iam.gserviceaccount.com

# 6. Verify cleanup
gcloud run services list --region=europe-west9
gcloud sql instances list
gsutil ls
gcloud artifacts repositories list
```

## Best Practices

### For Production Use

1. **Enable automatic backups** (already configured in setup script)
   - Daily backups at 3:00 AM
   - Weekly maintenance window on Sunday at 4:00 AM

2. **Monitor costs regularly**
   ```bash
   # View billing for Cloud SQL
   gcloud billing accounts list
   ```

3. **Set up alerting**
   - Configure Cloud Monitoring alerts for high resource usage
   - Set budget alerts in GCP Billing

4. **Regular maintenance**
   - Review and clean old experiments monthly
   - Check logs for errors or warnings
   - Update MLflow version when needed

5. **Document your experiments**
   - Use clear experiment names
   - Add descriptive tags to runs
   - Log comprehensive parameters and metrics

### For Development/Testing

1. **Use separate instances**
   - Create separate Cloud SQL instance for dev
   - Use different GCS buckets for dev/prod

2. **Reduce costs during development**
   - Stop Cloud SQL when not in use
   - Use shorter lifecycle policies (7-14 days)

3. **Test deployments**
   - Always test updates in dev before prod
   - Keep Dockerfile and scripts in version control

## References

- [MLflow Documentation](https://mlflow.org/docs/latest/index.html)
- [MLflow Tracking Server](https://mlflow.org/docs/latest/tracking.html#mlflow-tracking-servers)
- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Cloud SQL for PostgreSQL](https://cloud.google.com/sql/docs/postgres)
- [Cloud Storage Documentation](https://cloud.google.com/storage/docs)
- [Artifact Registry](https://cloud.google.com/artifact-registry/docs)

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Cloud Run logs: `gcloud run services logs read mlflow-tracking-YOUR_SERVICE`
3. Check Cloud SQL status: `gcloud sql instances describe mlflow-db`
4. Verify GCS bucket access: `gsutil ls gs://YOUR_PROJECT-mlflow-artifacts/`
5. Review `deployment_logs.json` for deployment details (if created)

## Version History

- **v1.0**: Initial MLflow setup for GCP
  - MLflow 2.9.2
  - Cloud SQL PostgreSQL 15
  - Cloud Run with auto-scaling
  - GCS artifact storage with lifecycle policy
