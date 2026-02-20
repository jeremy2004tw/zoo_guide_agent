#! /usr/bin/bash

# Lab: Build and deploy an ADK agent on Cloud Run
# https://codelabs.developers.google.com/codelabs/production-ready-ai-with-gc/5-deploying-agents/deploy-an-adk-agent-to-cloud-run#0

# Lab: How to deploy a secure MCP server on Cloud Run
# https://codelabs.developers.google.com/codelabs/cloud-run/use-mcp-server-on-cloud-run-with-an-adk-agent

# gcloud auth login

# gcloud projects create mcp-server
gcloud config set project mcp-server

gcloud config set run/region us-central1

# list all your project ids
# gcloud projects list | awk '/PROJECT_ID/{print $2}'

gcloud services enable \
    run.googleapis.com \
    artifactregistry.googleapis.com \
    cloudbuild.googleapis.com \
    aiplatform.googleapis.com \
    compute.googleapis.com 

# uv venv
# uv init
source .venv/Scripts/activate
uv add "google-adk==1.25.0"
uv pip install -r requirements.txt
deactivate

export PROJECT_ID=$(gcloud config get-value project)
echo "$PROJECT_ID"

export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
echo "$PROJECT_NUMBER"

export SA_NAME=lab2-cr-service
export SERVICE_ACCOUNT="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
gcloud iam service-accounts create ${SA_NAME} \
    --display-name="Service Account for lab 2 "

cat <<EOF > .env
PROJECT_ID=$PROJECT_ID
PROJECT_NUMBER=$PROJECT_NUMBER
SA_NAME=$SA_NAME
SERVICE_ACCOUNT=${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com
MODEL="gemini-2.5-flash"
EOF

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/run.invoker"

echo -e "\nMCP_SERVER_URL=https://zoo-mcp-server-${PROJECT_NUMBER}.us-central1.run.app/mcp" >> .env

source .env

# Grant the "Vertex AI User" role to your service account
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT" \
  --role="roles/aiplatform.user"

# Run the deployment command
uvx --from google-adk==1.25.1 \
adk deploy cloud_run \
  --project=$PROJECT_ID \
  --region=us-central1 \
  --service_name=zoo-tour-guide \
  --with_ui \
  . \
  -- \
  --labels=dev-tutorial=codelab-adk \
  --service-account=$SERVICE_ACCOUNT

# adk web

# gcloud run services delete zoo-tour-guide --region=us-central1 --quiet
# gcloud artifacts repositories delete cloud-run-source-deploy --location=us-central1 --quiet
