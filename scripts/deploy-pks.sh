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

# shellcheck source=/dev/null
[[ -f "${__DIR}/../.envrc" ]] &&  \
  source "${__DIR}/../.envrc" ||  \
  (echo "${__DIR}/../.envrc not found" && exit 1)

export STATE_FILE=${__DIR}/../pcf/state/"$ENVIRONMENT_NAME"/terraform.tfstate

export pks_iaas_configuration_environment_azurecloud="AzurePublicCloud"
pks_subscription_id="$(terraform output -state="${STATE_FILE}" subscription_id)"
export pks_subscription_id
pks_tenant_id="$(terraform output -state="${STATE_FILE}" tenant_id)"
export pks_tenant_id
pks_pks_api_dns="$(terraform output -state="${STATE_FILE}" pks_api_dns)"
export pks_pks_api_dns
pks_network_name="$(terraform output -state="${STATE_FILE}" network_name)"
export pks_network_name
pks_pcf_resource_group_name="$(terraform output -state="${STATE_FILE}" pcf_resource_group_name)"
export pks_pcf_resource_group_name
pks_bosh_deployed_vms_security_group_name="$(terraform output -state="${STATE_FILE}" bosh_deployed_vms_security_group_name)"
export pks_bosh_deployed_vms_security_group_name
if [[ -z "$AZURE_REGION" ]]; then
	echo "Enter azure location (region):"
	read -r AZURE_REGION
fi
pks_location="${AZURE_REGION}"
export pks_location

# shellcheck source=/dev/null
[[ -f "${__DIR}/set-om-creds.sh" ]] &&  \
  source "${__DIR}/set-om-creds.sh" ||  \
  (echo "set-om-creds.sh not found" && exit 1)

# Configure cert
pks_ca_cert=$(om -t "$OM_TARGET" --skip-ssl-validation certificate-authorities \
  --format json | jq -r '.[0] | select(.active==true) | .cert_pem' )
export pks_ca_cert

om -t "$OM_TARGET" --skip-ssl-validation generate-certificate \
  --domains "${pks_pks_api_dns}" > /tmp/om_generated_cert.json

pks_pcf_tls_cert=$(jq -r .certificate /tmp/om_generated_cert.json)
export pks_pcf_tls_cert
pks_pcf_tls_private_key=$(jq -r .key /tmp/om_generated_cert.json)
export pks_pcf_tls_private_key

short_version=$(om interpolate --config "${__DIR}/../versions.yml" --path /pks_version | cut -d - -f 1)

# Validate PKS template
om interpolate --config "${__DIR}/../templates/pks/${short_version}/pivotal-container-service.yml" --vars-env=pks

# Configure PKS
om -t "$OM_TARGET" --skip-ssl-validation \
  configure-product \
  --config "${__DIR}/../templates/pks/${short_version}/pivotal-container-service.yml" \
  --vars-env=pks

# Deploy PKS
om -t "$OM_TARGET" --skip-ssl-validation apply-changes
