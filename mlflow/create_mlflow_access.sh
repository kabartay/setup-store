#!/bin/bash

# ============================================================================
# MLflow Client Access Setup Script
# ============================================================================
# This script creates a GCP service account for programmatic access to MLflow
# artifacts stored in GCS. The generated key file can be used for authentication
# without requiring gcloud CLI installation.
#
# Prerequisites:
# - Infrastructure already created via setup_mlflow_gcp.sh
# - gcloud CLI installed and authenticated
# - Appropriate IAM permissions to create service accounts
#
# Usage:
#   bash create_mlflow_access.sh
#
# Output:
#   mlflow-client-key.json - Service account key file for authentication
#
# The key file should be:
# - Kept secure and never committed to version control
# - Shared securely with team members who need MLflow access
# - Used by setting GOOGLE_APPLICATION_CREDENTIALS environment variable
# ============================================================================

set -e  # Exit on any error

# ============================================================================
# Configuration Variables
# ============================================================================

export PROJECT_ID="mlflow-bek"
BUCKET_NAME="${PROJECT_ID}-mlflow-artifacts"
SA_NAME="mlflow-client"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
KEY_FILE="mlflow-client-key.json"

# ============================================================================
# Service Account Creation
# ============================================================================

echo "Creating service account for MLflow client access..."
echo ""

# Create service account with descriptive name and description
gcloud iam service-accounts create $SA_NAME \
    --project=$PROJECT_ID \
    --display-name="MLflow Client Access" \
    --description="Service account for MLflow artifact access from evaluation scripts"

echo "Service account created: $SA_EMAIL"
echo ""

# ============================================================================
# Grant Storage Permissions
# ============================================================================

echo "Granting Storage Object Admin role to service account..."
echo "   This allows read/write access to MLflow artifacts in GCS"
echo ""

# Grant Storage Object Admin role on the MLflow artifacts bucket
# This allows the service account to read and write artifacts
gcloud storage buckets add-iam-policy-binding gs://$BUCKET_NAME \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/storage.objectAdmin"

echo "Permissions granted successfully"
echo ""

# ============================================================================
# Create Service Account Key
# ============================================================================

echo "Creating service account key file..."
echo ""

# Create and download JSON key file for authentication
gcloud iam service-accounts keys create $KEY_FILE \
    --iam-account=$SA_EMAIL \
    --project=$PROJECT_ID

# ============================================================================
# Usage Instructions
# ============================================================================

echo ""
echo "============================================================================"
echo "Service Account Created Successfully!"
echo "============================================================================"
echo ""
echo "Key file: $KEY_FILE"
echo ""
echo "This key file provides access to MLflow artifacts in GCS."
echo "Share it securely with team members who need MLflow access."
echo ""
echo "============================================================================"
echo "Setup Instructions"
echo "============================================================================"
echo ""
echo "1. Save the key file securely:"
echo "   - Do NOT commit to version control"
echo "   - Store in a secure location (e.g., ~/.config/gcloud/)"
echo ""
echo "2. Configure authentication (choose one method):"
echo ""
echo "   Method A - Environment Variable (Recommended):"
echo "   ------------------------------------------------"
echo "   Add to ~/.bashrc or ~/.zshrc:"
echo ""
echo "     export GOOGLE_APPLICATION_CREDENTIALS=\"\$HOME/.config/gcloud/mlflow-client-key.json\""
echo ""
echo "   Then restart terminal or run:"
echo "     source ~/.bashrc  # or source ~/.zshrc"
echo ""
echo "   Method B - Python Code:"
echo "   ------------------------------------------------"
echo "   In your Python script:"
echo ""
echo "     import os"
echo "     os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = '/path/to/mlflow-client-key.json'"
echo ""
echo "3. Use MLflow with GCS artifacts:"
echo ""
echo "   import mlflow"
echo "   mlflow.set_tracking_uri('https://your-mlflow-server.run.app')"
echo "   "
echo "   with mlflow.start_run():"
echo "       mlflow.log_artifact('report.html')  # Will upload to GCS"
echo ""
echo "============================================================================"
echo "Security Notes"
echo "============================================================================"
echo ""
echo "- This key provides full read/write access to MLflow artifacts"
echo "- Rotate keys regularly (recommended: every 90 days)"
echo "- If compromised, delete the key immediately:"
echo ""
echo "  gcloud iam service-accounts keys list --iam-account=$SA_EMAIL"
echo "  gcloud iam service-accounts keys delete KEY_ID --iam-account=$SA_EMAIL"
echo ""
echo "============================================================================"
