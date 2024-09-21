#!/bin/bash

if [ -z "$GOOGLE_ORG_ID" ]; then echo "GOOGLE_ORG_ID is missing"; exit 1; fi

for PROJECT_ID in $(gcloud alpha projects list --organization=$GOOGLE_ORG_ID --format="value(projectId)");
do
  #echo "Project: $PROJECT_ID"
  gcloud services list --project="$PROJECT_ID" --enabled | grep compute.googleapis.com >/dev/null
  if [ $? -eq 0 ]; then
    gcloud compute instances list --project="$PROJECT_ID" --format="csv[no-heading](project,name,labels)" | awk -v proj="$PROJECT_ID" '{print "COMPUTE_INSTANCE_INFO:", proj $0}' 
  else
    echo "NO_COMPUTE_API: $PROJECT_ID doesn't have compute.googleapis.com API enabled"
  fi

done
