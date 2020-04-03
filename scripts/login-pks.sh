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
pks_api_dns_name="$(terraform output -state="${state_dir}/terraform.tfstate" pks_api_dns)"

# shellcheck source=/dev/null
[[ -f "${__DIR}/target-bosh.sh" ]] &&  \
  source "${__DIR}/target-bosh.sh" ||  \
  (echo "${__DIR}/target-bosh.sh not found" && exit 1)

admin_password=$(om -k credentials \
    -p pivotal-container-service \
    -c '.properties.uaa_admin_password' \
    -f secret)

printf "\n\nAdmin password: %s\n\n" "${admin_password}"

pks login -a \
    "https://${pks_api_dns_name}" \
    --skip-ssl-validation \
    -u admin \
    -p "${admin_password}"
