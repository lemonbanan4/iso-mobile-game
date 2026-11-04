#!/usr/bin/env bash
# ==============================================================================
# Google Cloud Run Deployment Script
# Deploys the stateless FastAPI backend container to Google Cloud Run
# ==============================================================================
set -euo pipefail

# Configuration Defaults (override via environment variables)
PROJECT_ID="${GCP_PROJECT_ID:-$(gcloud config get-value project 2>/dev/null || echo '')}"
REGION="${GCP_REGION:-us-central1}"
SERVICE_NAME="${SERVICE_NAME:-iso-strategy-backend}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
REPOSITORY_NAME="${ARTIFACT_REPO:-game-services}"

if [[ -z "${PROJECT_ID}" ]]; then
  echo "❌ Error: GCP_PROJECT_ID is not set and no active gcloud project found."
  echo "Please run: gcloud config set project YOUR_PROJECT_ID or export GCP_PROJECT_ID=..."
  exit 1
fi

IMAGE_URI="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY_NAME}/${SERVICE_NAME}:${IMAGE_TAG}"

echo "======================================================================"
echo "🚀 DEPLOYING ISO-STRATEGY BACKEND TO GOOGLE CLOUD RUN"
echo "Project:      ${PROJECT_ID}"
echo "Region:       ${REGION}"
echo "Service:      ${SERVICE_NAME}"
echo "Image URI:    ${IMAGE_URI}"
echo "======================================================================"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# 1. Verify OpenAPI Contract Consistency before deployment
echo "Step 1: Validating API contract compliance..."
"${ROOT_DIR}/backend/.venv/bin/python" "${ROOT_DIR}/contracts/verify_contracts.py"

# 2. Build Container Image via Google Cloud Build
echo ""
echo "Step 2: Submitting container build to Cloud Build..."
gcloud builds submit "${ROOT_DIR}/backend" \
  --tag "${IMAGE_URI}" \
  --project "${PROJECT_ID}"

# 3. Deploy to Cloud Run with Stateless Optimizations
echo ""
echo "Step 3: Deploying container to Cloud Run..."
gcloud run deploy "${SERVICE_NAME}" \
  --image "${IMAGE_URI}" \
  --platform managed \
  --region "${REGION}" \
  --project "${PROJECT_ID}" \
  --allow-unauthenticated \
  --port 8080 \
  --cpu 1 \
  --memory 512Mi \
  --concurrency 80 \
  --min-instances 0 \
  --max-instances 10 \
  --timeout 60s \
  --set-env-vars "DEBUG=False,PROJECT_NAME=IsoStrategy 4X Backend"

echo ""
echo "======================================================================"
echo "✅ DEPLOYMENT COMPLETE!"
SERVICE_URL=$(gcloud run services describe "${SERVICE_NAME}" --platform managed --region "${REGION}" --project "${PROJECT_ID}" --format 'value(status.url)')
echo "Service URL: ${SERVICE_URL}"
echo "API Docs:    ${SERVICE_URL}/docs"
echo "Health:      ${SERVICE_URL}/health"
echo "======================================================================"
