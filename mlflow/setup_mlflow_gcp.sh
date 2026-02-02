#!/bin/bash

# ============================================================================
# MLflow GCP Infrastructure Setup Script
# ============================================================================
# This script provisions the necessary GCP infrastructure for MLflow:
# - Cloud SQL PostgreSQL instance for experiment metadata
# - GCS bucket for artifact storage with lifecycle policy
# - IAM permissions and service configuration
#
# Prerequisites:
# - gcloud CLI installed and authenticated
# - GCP project with billing enabled
# - Owner or Editor role on the project
# - .env file with ROOT_PASSWORD and USER_PASSWORD
#
# Usage:
#   bash setup_mlflow_gcp.sh
#
# Estimated time: 5-10 minutes (mostly Cloud SQL creation)
# ============================================================================

set -e  # Exit on any error

# ============================================================================
# Load and Validate Environment Variables
# ============================================================================

if [ -f .env ]; then
  echo "Loading passwords from .env file..."
  export $(cat .env | grep -v '^#' | grep -v '^[[:space:]]*$' | xargs)
else
  echo "Error: .env file not found!"
  echo "   Create .env file with ROOT_PASSWORD and USER_PASSWORD"
  exit 1
fi

# Validate required password variables
if [ -z "$ROOT_PASSWORD" ] || [ -z "$USER_PASSWORD" ]; then
  echo "Error: ROOT_PASSWORD and/or USER_PASSWORD not set in .env"
  exit 1
fi

echo "Passwords loaded successfully"
echo ""

set -x  # Echo commands for transparency

# ============================================================================
# Configuration Variables
# ============================================================================

# Project and region settings
export PROJECT_ID="mlflow-bek"
export REGION="europe-west9"  # Paris region
export SERVICE_NAME="mlflow-tracking-dmc"

# Cloud SQL configuration
INSTANCE_NAME="mlflow-db"
INSTANCE_TIER="db-f1-micro"         # Smallest instance tier (~$15/month)
DATABASE_VERSION="POSTGRES_15"      # PostgreSQL 15
DATABASE_NAME="mlflow"              # Database name for MLflow metadata
DB_USER="mlflow-bek"                # Database user for MLflow

# Storage configuration
STORAGE_TYPE="SSD"                  # SSD for better performance
STORAGE_SIZE="10GB"                 # Initial storage size
STORAGE_AUTO_RESIZE=true            # Auto-resize when space runs low

# GCS Bucket configuration
BUCKET_NAME="${PROJECT_ID}-mlflow-artifacts"
BUCKET_LOCATION="EU"                # European multi-region
STORAGE_CLASS="STANDARD"            # Standard storage class
LIFECYCLE_DAYS=90                   # Auto-delete artifacts after 90 days

# ============================================================================
# Project Setup
# ============================================================================

# Set active GCP project
gcloud config set project $PROJECT_ID

# Enable required GCP APIs
echo "Enabling required APIs..."
gcloud services enable sqladmin.googleapis.com
gcloud services enable secretmanager.googleapis.com

# ============================================================================
# Cloud SQL Instance Creation
# ============================================================================

echo "Creating Cloud SQL instance: $INSTANCE_NAME"
echo "   This takes approximately 5-10 minutes..."
echo "   Region: $REGION"
echo "   Tier: $INSTANCE_TIER"
echo "   Storage: $STORAGE_SIZE (auto-resize enabled)"
echo ""

# Create PostgreSQL instance with automated backups and maintenance
gcloud sql instances create $INSTANCE_NAME \
  --database-version=$DATABASE_VERSION \
  --tier=$INSTANCE_TIER \
  --region=$REGION \
  --storage-type=$STORAGE_TYPE \
  --storage-size=$STORAGE_SIZE \
  --storage-auto-increase \
  --root-password="$ROOT_PASSWORD" \
  --backup-start-time=03:00 \
  --maintenance-window-day=SUN \
  --maintenance-window-hour=04

echo "Cloud SQL instance created successfully"
echo ""

# ============================================================================
# Database Setup
# ============================================================================

echo "Creating database: $DATABASE_NAME"
gcloud sql databases create $DATABASE_NAME \
  --instance=$INSTANCE_NAME

echo "Database created successfully"
echo ""

# ============================================================================
# User Setup
# ============================================================================

echo "Creating database user: $DB_USER"
gcloud sql users create $DB_USER \
  --instance=$INSTANCE_NAME \
  --password="$USER_PASSWORD"

echo "Database user created successfully"
echo ""

# ============================================================================
# GCS Bucket Setup
# ============================================================================

echo ""
echo "Creating GCS bucket for MLflow artifacts: $BUCKET_NAME"
echo "   Location: $BUCKET_LOCATION"
echo "   Storage Class: $STORAGE_CLASS"
echo "   Lifecycle: Delete after $LIFECYCLE_DAYS days"
echo ""

# Create GCS bucket
gsutil mb -p $PROJECT_ID -c $STORAGE_CLASS -l $BUCKET_LOCATION gs://$BUCKET_NAME/

# Enable versioning to keep history of artifacts
gsutil versioning set on gs://$BUCKET_NAME/

# Configure lifecycle policy for automatic deletion of old artifacts
cat > /tmp/lifecycle.json <<EOF
{
  "lifecycle": {
    "rule": [
      {
        "action": {"type": "Delete"},
        "condition": {"age": $LIFECYCLE_DAYS}
      }
    ]
  }
}
EOF

gsutil lifecycle set /tmp/lifecycle.json gs://$BUCKET_NAME/
rm /tmp/lifecycle.json

# Enable uniform bucket-level access for simplified IAM management
gsutil uniformbucketlevelaccess set on gs://$BUCKET_NAME/

echo "GCS bucket created successfully"
echo ""

# ============================================================================
# Summary and Connection Details
# ============================================================================

# Retrieve Cloud SQL connection name
CONNECTION_NAME=$(gcloud sql instances describe $INSTANCE_NAME \
  --format='value(connectionName)')

echo ""
echo "============================================================================"
echo "MLflow Infrastructure Setup Complete!"
echo "============================================================================"
echo ""
echo "Connection Details:"
echo ""
echo "   Instance Name:    $INSTANCE_NAME"
echo "   Database:         $DATABASE_NAME"
echo "   User:             $DB_USER"
echo "   Connection Name:  $CONNECTION_NAME"
echo ""
echo "Storage Details:"
echo ""
echo "   Bucket:           gs://$BUCKET_NAME"
echo "   Location:         $BUCKET_LOCATION"
echo "   Lifecycle Policy: Delete after $LIFECYCLE_DAYS days"
echo ""
echo "Next Steps:"
echo ""
echo "   1. Run deploy_mlflow.sh to deploy the MLflow server"
echo "   2. Access MLflow UI at the URL provided by deploy script"
echo "   3. (Optional) Run create_mlflow_access.sh to create service account keys"
echo ""
echo "============================================================================"
