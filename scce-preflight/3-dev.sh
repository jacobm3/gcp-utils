#!/bin/bash
#
# Checks that logging is enabled for the various service logs SCCE ingests.
#
# WARNING:  this is an initial alpha version. It's incomplete and has bugs.
#
# Intended to run from your cloud shell. Will require alternate authn to run 
# from somewhere else.
#
# https://github.com/jacobm3/gcp-utils/tree/main/scce-preflight
#

# Set colors for output
green='\033[0;32m'
red='\033[0;31m'
yellow='\033[0;33m'
no_color='\033[0m'

check_log_sink() {
  local project_id=$1
  local sink_name=$2
  local filter_expression=$3
  local writer_identity=$4

  if gcloud logging sinks list --quiet --project="$project_id" '--filter=destination:"cloud-logging://gcplogs.googleapis.com/projects/*/locations/*/buckets/*" AND writerIdentity:"'"$writer_identity"'"' '--format=value(name)' | grep -q .; then
    echo "DNS log sink exists in project $project_id"
  else
    echo "DNS log sink does NOT exist in project $project_id"
  fi
}

# Function to check if a log sink exists for a specific service
check_log_sink() {
  service=$1
  filter=$2
  sink_name=$3

  if gcloud logging sinks list --quiet --filter="$filter" --format="value(name)" | grep -q "$sink_name"; then
    echo -e "${green}PASS${no_color}"
  else
    echo -e "${red}FAIL${no_color}"
    return 1 # Indicate failure
  fi
}


# Get the organization ID
if [[ -n "$1" ]]; then
  ORG_ID="$1"
elif [[ -n "$ORG_ID" ]]; then
  # ORG_ID is already defined in the environment
  :
else
  echo "Error: Please provide the organization ID as the first argument or set the ORG_ID environment variable."
  echo "Usage: $0 <ORG_ID>"
  exit 1
fi

# ensure we have an active authenticated session first
echo "Checking gcloud auth session:"
if ! gcloud auth list 2>/dev/null; then
    echo "Error: Please log in to your Google Cloud account using 'gcloud auth login'"
    exit 1
fi
echo


# Get a list of project IDs in the organization
PROJECT_IDS=$(gcloud projects list --filter="parent.id:$ORG_ID" --format="value(projectId)")

# Iterate through each project
for PROJECT_ID in $PROJECT_IDS; do
  echo
  echo "Checking logs for project: $PROJECT_ID"




  #if gcloud services describe logging.googleapis.com --project=$PROJECT_ID > /dev/null 2>&1; then
  if gcloud services list --project=${PROJECT_ID} --filter="name:logging.googleapis.com AND state:ENABLED" | grep -q "logging.googleapis.com"; then
    echo -e "Cloud Logging API is enabled: ${green}PASS${no_color}"

    # Check if DNS API is enabled and logging is enabled
    echo -n "Checking DNS API: "
    if gcloud services list --enabled | grep -q "dns.googleapis.com"; then
      echo -e "${green}PASS${no_color} (API Enabled)"
      echo -n "Checking DNS Logging: "
      check_log_sink "dns" 'destination:"cloud-logging://gcplogs.googleapis.com/projects/*/locations/*/buckets/*" AND writerIdentity:"serviceAccount:service-975996031170@gcp-sa-dns.iam.gserviceaccount.com"' "_Default" || dns_failed=true
    else
      echo -e "${yellow}WARNING: DNS API is not enabled. Please enable it for DNS logging.${no_color}"
      dns_failed=true
    fi
    
    # Check if Cloud Audit Logs API is enabled
    echo -n "Checking Cloud Audit Logs API: "
    if gcloud services list --enabled | grep -q "logging.googleapis.com"; then
      echo -e "${green}PASS${no_color} (Always Enabled)" # Audit logs are always enabled if the API is enabled
    else
      echo -e "${yellow}WARNING: Cloud Audit Logs API is not enabled. Please enable it for audit logging.${no_color}"
      audit_failed=true
    fi
    
    # Check if Cloud NAT API is enabled and logging is enabled
    echo -n "Checking Cloud NAT API: "
    if gcloud services list --enabled | grep -q "compute.googleapis.com"; then
      echo -e "${green}PASS${no_color} (API Enabled)"
      echo -n "Checking NAT Logging: "
      check_log_sink "nat" 'destination:"cloud-logging://gcplogs.googleapis.com/projects/*/locations/*/buckets/*" AND writerIdentity:"serviceAccount:service-646636466451@gcp-sa-compute.iam.gserviceaccount.com"' "_Default" || nat_failed=true
    else
      echo -e "${yellow}WARNING: Cloud NAT API is not enabled. Please enable it for NAT logging.${no_color}"
      nat_failed=true
    fi
    
    # Check if any checks failed
    if [ -n "$dns_failed" ] || [ -n "$audit_failed" ] || [ -n "$nat_failed" ]; then
      echo -e "${red}Overall Result: FAIL${no_color}"
      exit 1
    else
      echo -e "${green}Overall Result: PASS${no_color}"
    fi


  else
    echo -e "Cloud Logging API is not enabled, which is required for other service logs: ${red}FAIL${no_color}"
    echo "Not checking specific service logs in this project."
    echo "Enable cloud logging in this project first: "
    echo "   gcloud services enable logging.googleapis.com --project=${PROJECT_ID}"
  fi


done
