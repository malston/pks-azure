#!/bin/bash

set -e
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

if [ -z "$ENVIRONMENT_NAME" ]; then
    echo "Must provide environment name ENVIRONMENT_NAME as environment variable"
    echo "Set this to the same value of environment_name var in terraform.tfvars"
    exit 1
fi

mkdir -p "${__DIR}/../pcf/state/$ENVIRONMENT_NAME"

export state_file=${__DIR}/../pcf/state/"$ENVIRONMENT_NAME"/terraform.tfstate

terraform_dir="${__DIR}/../pcf/terraform"

pushd "${terraform_dir}" > /dev/null
  terraform init
  terraform plan -var-file=."./vars/${ENVIRONMENT_NAME}/terraform.tfvars" \
    -out="../state/${ENVIRONMENT_NAME}/terraform.tfplan"
  terraform apply \
    -state="${state_file}"
popd > /dev/null

terraform output -state="${state_file}"
