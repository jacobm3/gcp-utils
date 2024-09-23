#!/bin/bash
#
# Checks that the current user has the GCP IAM roles necessary to deploy SCCE.
#
# Intended to run from your cloud shell. Will require alternate authn to run
# from somewhere else.
#
# Please provide the organization ID as the first argument or set the ORG_ID 
# environment variable. You may need to run it a second time if you 
# get a gcloud login error the first time; not sure why.
#
# https://github.com/jacobm3/gcp-utils/tree/main/scce-preflight
#

# Define colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Define the required roles
required_roles=(
  "roles/resourcemanager.organizationAdmin"
  "roles/cloudasset.owner"
  "roles/securitycenter.admin"
  "roles/iam.securityAdmin"
  "roles/iam.serviceAccountCreator"
  "roles/chronicle.serviceAdmin"
  "roles/chroniclesoar.admin"
  "roles/chronicle.apiAdmin"
  "roles/securitycenter.viewer"
  "roles/chroniclesoar.viewer"
  "roles/chronicle.apiViewer"
)

# Flag to track if any check fails
any_fail=0

# Get the current active project
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

if [[ -z "$PROJECT_ID" ]]; then
  echo "No active project is set."
  exit 1
fi

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


# Get IAM policy for the organization
echo "Fetching IAM policy for organization..."
IAM_POLICY=$(gcloud organizations get-iam-policy "$ORG_ID" --format=json)

if [[ -z "$IAM_POLICY" ]]; then
  echo "Failed to retrieve IAM policy for the organization."
  exit 1
fi

# Get the email of the current user
CURRENT_USER=$(gcloud config get-value account 2>/dev/null)

echo "Checking roles for user: $CURRENT_USER"

# Check if the user has the required roles
for role in "${required_roles[@]}"; do
  # Check if the IAM policy contains the user with the specified role
  role_check=$(echo "$IAM_POLICY" | jq --arg role "$role" --arg user "user:$CURRENT_USER" '.bindings[] | select(.role == $role) | select(.members[] | contains($user))')

  if [[ -n "$role_check" ]]; then
    echo -e "$role: ${GREEN}PASS${NC}"
  else
    echo -e "$role: ${RED}FAIL${NC}"
    any_fail=1
  fi
done

# Exit with status 1 if any check failed
if [[ "$any_fail" -eq 1 ]]; then
  exit 1
else
  exit 0
fi
