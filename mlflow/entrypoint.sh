#!/bin/bash

# ============================================================================
# MLflow Server Entrypoint Script
# ============================================================================
# This script validates environment variables and starts the MLflow server
# with the appropriate backend and artifact storage configuration.
#
# Required Environment Variables:
# - DB_URI: PostgreSQL connection string for metadata storage
# - ARTIFACT_ROOT: GCS bucket path for artifact storage
#
# These variables are set by Cloud Run during deployment.
# ============================================================================

set -e  # Exit on any error

# ============================================================================
# Validate Required Environment Variables
# ============================================================================

if [ -z "$DB_URI" ]; then
    echo "Error: DB_URI environment variable not set"
    echo "   This should contain the PostgreSQL connection string"
    exit 1
fi

if [ -z "$ARTIFACT_ROOT" ]; then
    echo "Error: ARTIFACT_ROOT environment variable not set"
    echo "   This should contain the GCS bucket path (gs://bucket-name)"
    exit 1
fi

# ============================================================================
# Log Configuration (hide sensitive information)
# ============================================================================

echo "============================================================================"
echo "Starting MLflow Server"
echo "============================================================================"
echo ""
echo "Backend Store:  ${DB_URI%%:*}://****"  # Show only the protocol, hide password
echo "Artifact Store: $ARTIFACT_ROOT"
echo ""
echo "Server Configuration:"
echo "  - Host: 0.0.0.0 (all interfaces)"
echo "  - Port: 8080"
echo "  - Artifact serving: enabled"
echo ""
echo "============================================================================"

# ============================================================================
# Start MLflow Server
# ============================================================================

# Start MLflow tracking server with:
# - Listen on all interfaces (0.0.0.0) on port 8080
# - Use PostgreSQL for experiment metadata storage
# - Use GCS bucket for artifact storage
# - Enable built-in artifact serving (proxy artifacts through MLflow server)

exec mlflow server \
  --host 0.0.0.0 \
  --port 8080 \
  --backend-store-uri "$DB_URI" \
  --default-artifact-root "$ARTIFACT_ROOT" \
  --serve-artifacts
