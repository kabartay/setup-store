# MLflow on GCP - Quick Start Guide

This is a 5-minute guide to get MLflow running on GCP.

## Prerequisites Checklist

- [ ] GCP account with billing enabled
- [ ] gcloud CLI installed (`gcloud --version`)
- [ ] Docker installed (`docker --version`)
- [ ] gcloud authenticated (`gcloud auth login`)

## Quick Setup (3 Steps)

### Step 1: Create Environment File

```bash
# Copy template
cp .env.template .env

# Generate strong passwords
openssl rand -base64 32  # Use for ROOT_PASSWORD
openssl rand -base64 32  # Use for USER_PASSWORD

# Edit .env file with your passwords
nano .env  # or use your preferred editor
```

### Step 2: Configure Project

```bash
# Set your GCP project ID
export PROJECT_ID="your-project-id"

# Configure gcloud
gcloud config set project $PROJECT_ID

# Update setup_mlflow_gcp.sh with your project ID (line 58)
# Change: export PROJECT_ID="mlflow-bek"
# To:     export PROJECT_ID="your-project-id"

# Update deploy_mlflow.sh with your project ID (line 34)
# (Same change as above)
```

### Step 3: Deploy

```bash
# Create infrastructure (takes ~10 minutes)
bash setup_mlflow_gcp.sh

# Deploy MLflow server (takes ~5 minutes)
bash deploy_mlflow.sh

# Your MLflow URL will be displayed at the end!
```

## Using MLflow

### From Python

```python
import mlflow

# Set your MLflow server URL
mlflow.set_tracking_uri("https://mlflow-tracking-XXX.run.app")

# Create an experiment
mlflow.set_experiment("my-evaluation")

# Start tracking
with mlflow.start_run():
    mlflow.log_param("learning_rate", 0.01)
    mlflow.log_metric("accuracy", 0.95)
    mlflow.log_artifact("report.html")
```

### From Command Line

```bash
# Set tracking URI
export MLFLOW_TRACKING_URI="https://mlflow-tracking-XXX.run.app"

# List experiments
mlflow experiments list

# Search runs
mlflow runs list --experiment-id 0
```

## Optional: Service Account for Artifact Access

If you need programmatic access without gcloud CLI:

```bash
bash create_mlflow_access.sh

# This creates mlflow-client-key.json
# Use it by setting:
export GOOGLE_APPLICATION_CREDENTIALS="mlflow-client-key.json"
```

## Cost Estimate

- Cloud SQL (db-f1-micro): ~$15/month
- Cloud Storage (< 100GB): ~$3/month
- Cloud Run (idle): $0/month
- **Total: ~$18/month**

## Common Issues

### Issue: "Project not found"
```bash
# Solution: Verify project ID and permissions
gcloud projects list
gcloud config set project YOUR_PROJECT_ID
```

### Issue: "API not enabled"
```bash
# Solution: Enable required APIs
gcloud services enable sqladmin.googleapis.com
gcloud services enable run.googleapis.com
```

### Issue: Docker build fails
```bash
# Solution: Use --platform flag for M1/M2 Macs
docker build --platform linux/amd64 -t mlflow-server .
```

### Issue: Cannot upload artifacts
```bash
# Solution: Authenticate with Google Cloud
gcloud auth application-default login
```

## Cleanup

To remove everything:

```bash
# Delete Cloud Run service
gcloud run services delete mlflow-tracking-XXX --region=europe-west9

# Delete Cloud SQL
gcloud sql instances delete mlflow-db

# Delete GCS bucket
gsutil -m rm -r gs://YOUR_PROJECT-mlflow-artifacts/
```

## Next Steps

1. Read the full [README.md](README.md) for detailed information
2. Configure your evaluation scripts to use MLflow
3. Set up monitoring and alerts in GCP Console
4. Schedule regular backups
5. Consider setting up private access for production

## Support

- Full documentation: [README.md](README.md)
- MLflow docs: https://mlflow.org/docs/latest/
- GCP Cloud Run: https://cloud.google.com/run/docs
