#!/bin/bash

if [ -z "$GOOGLE_ORG_ID" ]; then 
  echo "GOOGLE_ORG_ID is missing"
  exit 1
fi

for PROJECT_ID in $(gcloud alpha projects list --organization=$GOOGLE_ORG_ID --format="value(projectId)"); do
  # Check if the Cloud Storage API is enabled
  echo "DEBUG: $PROJECT_ID"
  gcloud services list --project="$PROJECT_ID" --enabled | grep storage.googleapis.com >/dev/null
  if [ $? -eq 0 ]; then
    # List all the buckets in the project and format the output as CSV
    echo "DEBUG2: $PROJECT_ID"
    gsutil ls -p "$PROJECT_ID" | awk -v proj="$PROJECT_ID" '{print "STORAGE_BUCKET_INFO:", proj "," $0}'
  else
    echo "DEBUG3: $PROJECT_ID"
    echo "NO_STORAGE_API: $PROJECT_ID doesn't have storage.googleapis.com API enabled"
  fi
done
