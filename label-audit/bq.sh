#!/bin/bash

if [ -z "$GOOGLE_ORG_ID" ]; then echo "GOOGLE_ORG_ID is missing"; exit 1; fi

for PROJECT_ID in $(gcloud alpha projects list --organization=$GOOGLE_ORG_ID --format="value(projectId)");
do
  #echo "Project: $PROJECT_ID"
  gcloud services list --project="$PROJECT_ID" --enabled | grep bigquery.googleapis.com >/dev/null
  if [ $? -eq 0 ]; then
    bq ls --format=json --project_id="$PROJECT_ID" | jq -r '.[] | [.datasetReference.projectId, .datasetReference.datasetId, (.labels // {} | to_entries | map("\(.key)=\(.value)") | join(","))] | @csv'
  else
    echo "NO_BQ_API: $PROJECT_ID doesn't have bigquery.googleapis.com API enabled"
  fi

done
