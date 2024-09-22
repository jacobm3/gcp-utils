#!/bin/bash
#
# Checks that no org service policies prohibit the services SCCE requires.
#
# Intended to run from your cloud shell. Will require alternate authn to run 
# from somewhere else.
#

# Define colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check if an API is enabled
check_api_enabled() {
  local api=$1
  gcloud services list --enabled --format="value(config.name)" | grep -q "$api"
}

# Check if orgpolicy.googleapis.com API is enabled
if ! check_api_enabled "orgpolicy.googleapis.com"; then
  echo -e "${RED}FAIL${NC}: Org Policy API (orgpolicy.googleapis.com) is not enabled."
  echo "This script requires the Org Policy API to be enabled before it can check if a Service Usage Org Policy is in place prohibiting services needed by SCCE."
  echo "To enable the Org Policy API, run the following command:"
  echo
  echo -e "${NC}gcloud services enable orgpolicy.googleapis.com${NC}"
  echo
  exit 1
fi

echo "Org Policy API (orgpolicy.googleapis.com) is enabled."

# Get the organization ID by listing all organizations
ORG_ID=$(gcloud organizations list --format="value(ID)" | head -n 1)

if [[ -z "$ORG_ID" ]]; then
  echo "Unable to determine organization ID. Make sure you're associated with an organization."
  exit 1
fi

echo "Organization ID: $ORG_ID"

# Check if Service Usage Organization Policy is enabled for the org
policy_check=$(gcloud org-policies describe "serviceuser.services" --organization="$ORG_ID" --format="json" 2>/dev/null)

# Handle the case where no org policy exists or an error occurs
if [[ $? -ne 0 || -z "$policy_check" ]]; then
  echo -e "Org policies are not enabled, meaning services aren't restricted. ${GREEN}PASS${NC}"
  exit 0
fi

# Parse the policy to see if any restrictions apply
services_restricted=$(echo "$policy_check" | jq -r '.listPolicy.allowedValues[]' 2>/dev/null)

if [[ -z "$services_restricted" ]]; then
  echo -e "${RED}FAIL${NC}: Org policies are enabled, but no explicit services are listed."
  exit 1
else
  echo "Restricted services found: $services_restricted"
  required_services=("chronicle.googleapis.com" "securitycentermanagement.googleapis.com" "securitycenter.googleapis.com")

  all_pass=1
  for service in "${required_services[@]}"; do
    if [[ "$services_restricted" == *"$service"* ]]; then
      #echo -e "${GREEN}PASS${NC}: $service is allowed."
      echo -e "$service: is allowed. ${GREEN}PASS${NC}"
    else
      #echo -e "${RED}FAIL${NC}: $service is restricted."
      echo -e "$service: is not allowed. ${RED}FAIL${NC}"
      all_pass=0
    fi
  done

  if [[ "$all_pass" -eq 1 ]]; then
    exit 0
  else
    exit 1
  fi
fi

