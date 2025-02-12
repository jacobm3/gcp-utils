# update with your org
ORG=organizations/123456/locations/global

# make plan
terraform plan -out .tf.plan

# convert plan to json
terraform show -json .tf.plan > .tf.plan.json

# generate validation report from json plan
gcloud scc iac-validation-reports create --format json $ORG \
  --tf-plan-file=.tf.plan.json > report.json

# single line with changes to make
jq -r '[.response.iacValidationReport.violations[].nextSteps] | join(";")' report.json 
