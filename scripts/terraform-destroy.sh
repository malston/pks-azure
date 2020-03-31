#!/bin/bash

set -e
# only exit with zero if all commands of the pipeline exit successfully
set -o pipefail

__DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "$ENVIRONMENT_NAME" ]; then
    echo "Must provide environment name ENVIRONMENT_NAME as environment variable"
    echo "Set this to the same value of environment_name var in terraform.tfvars"
    exit 1
fi

state_dir="${__DIR}/../pcf/state/$ENVIRONMENT_NAME"
vars_dir="${__DIR}/../pcf/vars/$ENVIRONMENT_NAME"

terraform_dir="${__DIR}/../pcf/terraform/pks"

pushd "${terraform_dir}" > /dev/null
  terraform destroy -var-file="${vars_dir}/terraform.tfvars" \
    -state="${state_dir}/terraform.tfstate"
popd > /dev/null
