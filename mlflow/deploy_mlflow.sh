#!/bin/bash

# ============================================================================
# MLflow Server Deployment Script
# ============================================================================
# This script builds and deploys the MLflow server to GCP Cloud Run.
# It connects to Cloud SQL for metadata and GCS for artifacts.
#
# Prerequisites:
# - Infrastructure already created via setup_mlflow_gcp.sh
# - gcloud CLI installed and authenticated
# - Docker installed for building images
# - .env file with USER_PASSWORD
#
# Usage:
#   bash deploy_mlflow.sh
#
# Estimated time: 5-10 minutes (image build and deployment)
# ============================================================================

set -e  # Exit on any error

# ============================================================================
# Load Environment Variables
# ============================================================================

# Load passwords from .env file in parent directory
if [ -f ../.env ]; then
  echo "Loading environment variables from parent directory..."
  export $(cat ../.env | grep -v '^#' | grep -v '^[[:space:]]*$' | xargs)
elif [ -f .env ]; then
  echo "Loading environment variables from current directory..."
  export $(cat .env | grep -v '^#' | grep -v '^[[:space:]]*$' | xargs)
else
  echo "Error: .env file not found!"
  echo "   Create .env file with USER_PASSWORD"
  exit 1
fi

set -x  # Echo commands for transparency

# ============================================================================
# Configuration Variables
# ============================================================================

# Project and service configuration
export PROJECT_ID="mlflow-bek"
export REGION="europe-west9"
export SERVICE_NAME="mlflow-tracking-dmc"
export IMAGE_NAME="mlflow-server"

# Cloud SQL configuration (must match setup_mlflow_gcp.sh)
INSTANCE_NAME="mlflow-db"
INSTANCE_TIER="db-f1-micro"
DATABASE_VERSION="POSTGRES_15"
DATABASE_NAME="mlflow"
DB_USER="mlflow-bek"

# ============================================================================
# Build Connection Strings
# ============================================================================

# Get Cloud SQL connection name
CONNECTION_NAME=$(gcloud sql instances describe $INSTANCE_NAME \
  --format='value(connectionName)')

# Construct PostgreSQL connection URI with Cloud SQL socket
# Format: postgresql+psycopg2://user:password@/database?host=/cloudsql/CONNECTION_NAME
DB_URI="postgresql+psycopg2://$DB_USER:${USER_PASSWORD}@/mlflow?host=/cloudsql/${CONNECTION_NAME}"

# Set GCS bucket as artifact root
ARTIFACT_ROOT="gs://${PROJECT_ID}-mlflow-artifacts"

# ============================================================================
# Enable Required APIs
# ============================================================================

echo "Enabling required GCP APIs..."
gcloud services enable artifactregistry.googleapis.com
gcloud services enable run.googleapis.com

# ============================================================================
# Artifact Registry Setup
# ============================================================================

# Create Artifact Registry repository for Docker images (if not exists)
echo "Creating Artifact Registry repository..."
gcloud artifacts repositories create mlflow-repo \
  --repository-format=docker \
  --location=$REGION \
  --description="MLflow Docker images" || true

# Configure Docker to authenticate with Artifact Registry
gcloud auth configure-docker $REGION-docker.pkg.dev

# ============================================================================
# Docker Image Build
# ============================================================================

echo "Building Docker image for linux/amd64 platform..."
docker build --platform linux/amd64 \
  -t $REGION-docker.pkg.dev/$PROJECT_ID/mlflow-repo/$IMAGE_NAME:latest .

# ============================================================================
# Push to Artifact Registry
# ============================================================================

echo "Pushing image to Artifact Registry..."
docker push $REGION-docker.pkg.dev/$PROJECT_ID/mlflow-repo/$IMAGE_NAME:latest

# ============================================================================
# Deploy to Cloud Run
# ============================================================================

echo "Deploying MLflow server to Cloud Run..."
gcloud run deploy $SERVICE_NAME \
  --image=$REGION-docker.pkg.dev/$PROJECT_ID/mlflow-repo/$IMAGE_NAME:latest \
  --region=$REGION \
  --platform=managed \
  --allow-unauthenticated \
  --set-env-vars="DB_URI=${DB_URI},ARTIFACT_ROOT=${ARTIFACT_ROOT}" \
  --add-cloudsql-instances=$CONNECTION_NAME \
  --memory=2Gi \
  --cpu=1 \
  --min-instances=0 \
  --max-instances=10 \
  --timeout=3600

# ============================================================================
# Get Service URL
# ============================================================================

SERVICE_URL=$(gcloud run services describe $SERVICE_NAME \
  --region=$REGION \
  --format='value(status.url)')

# ============================================================================
# Deployment Summary
# ============================================================================

echo ""
echo "============================================================================"
echo "MLflow Server Deployment Complete!"
echo "============================================================================"
echo ""
echo "   MLflow UI: $SERVICE_URL"
echo ""
echo "Configuration:"
echo ""
echo "   Backend Store:  Cloud SQL PostgreSQL ($CONNECTION_NAME)"
echo "   Artifact Store: GCS ($ARTIFACT_ROOT)"
echo "   Memory:         2Gi"
echo "   CPU:            1 vCPU"
echo "   Scaling:        0-10 instances (auto-scale)"
echo ""
echo "Next Steps:"
echo ""
echo "   1. Open MLflow UI: $SERVICE_URL"
echo "   2. Test health endpoint: curl $SERVICE_URL/health"
echo "   3. Configure your scripts with MLFLOW_TRACKING_URI"
echo "   4. (Optional) Run create_mlflow_access.sh for service account access"
echo ""
echo "Usage in Python:"
echo ""
echo "   import mlflow"
echo "   mlflow.set_tracking_uri('$SERVICE_URL')"
echo "   mlflow.set_experiment('my-evaluation')"
echo ""
echo "============================================================================"
