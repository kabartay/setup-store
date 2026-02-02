# ============================================================================
# MLflow Server Docker Image
# ============================================================================
# This Dockerfile creates a production-ready MLflow tracking server for GCP.
# It includes PostgreSQL and GCS support for metadata and artifact storage.
#
# Base Image: python:3.11-slim
# - Small footprint (~150MB base)
# - Security-focused with minimal attack surface
# - Official Python image with long-term support
#
# Key Features:
# - Non-root user for security
# - MLflow 2.9.2 with tracking server
# - PostgreSQL backend support (psycopg2-binary)
# - GCS artifact storage support (google-cloud-storage)
#
# Usage:
#   docker build --platform linux/amd64 -t mlflow-server .
#   docker run -p 8080:8080 \
#     -e DB_URI="postgresql://..." \
#     -e ARTIFACT_ROOT="gs://..." \
#     mlflow-server
# ============================================================================

FROM python:3.11-slim

# Create non-root user for running the MLflow server
# This enhances security by limiting privileges
RUN useradd -m -u 1000 mlflow

# Install MLflow and dependencies
# - mlflow: Core MLflow package with tracking server
# - psycopg2-binary: PostgreSQL adapter for Python
# - google-cloud-storage: GCS client library for artifact storage
RUN pip install --no-cache-dir \
    mlflow==2.9.2 \
    psycopg2-binary \
    google-cloud-storage

# Expose port 8080 for the MLflow tracking server
EXPOSE 8080

# Set working directory
WORKDIR /app

# Copy and configure the entrypoint script
COPY entrypoint.sh /app/
RUN chmod +x /app/entrypoint.sh

# Run the server as non-root user
USER mlflow

# Start MLflow server via entrypoint script
# The script validates environment variables and starts the server
ENTRYPOINT ["/app/entrypoint.sh"]
