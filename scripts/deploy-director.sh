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

if [[ -z "${OPSMAN_USER}" ]]; then
  echo "Enter a username for the opsman administrator account: "
  read -r OPSMAN_USER
  printf "\nexport OPSMAN_USER=%s" "${OPSMAN_USER}" >> "${__DIR}/../.envrc"
fi

if [[ -z "${OPSMAN_PASSWORD}" ]]; then
  echo "Enter a password for the opsman administrator account: "
  read -rs OPSMAN_PASSWORD
  printf "\nexport OPSMAN_PASSWORD=%s" "${OPSMAN_PASSWORD}" >> "${__DIR}/../.envrc"
fi

if [[ -z "${OPSMAN_DECRYPTION_PASSPHRASE}" ]]; then
  echo "Enter a decryption passphrase to unlock the opsman ui: "
  read -rs OPSMAN_DECRYPTION_PASSPHRASE
  printf "\nexport OPSMAN_DECRYPTION_PASSPHRASE=%s" "${OPSMAN_DECRYPTION_PASSPHRASE}" >> "${__DIR}/../.envrc"
fi

if [[ -z "${OPSMAN_SKIP_SSL_VALIDATION}" ]]; then
  echo "Disable ssl validation for Ops Manager [true/false]: "
  read -r OPSMAN_SKIP_SSL_VALIDATION
  printf "\nexport OPSMAN_SKIP_SSL_VALIDATION=%s" "${OPSMAN_SKIP_SSL_VALIDATION}" >> "${__DIR}/../.envrc"
fi

# shellcheck source=/dev/null
[[ -f "${__DIR}/../.envrc" ]] &&  \
  source "${__DIR}/../.envrc" ||  \
  (echo "${__DIR}/../.envrc not found" && exit 1)

export STATE_FILE=${__DIR}/../pcf/state/"$ENVIRONMENT_NAME"/terraform.tfstate

export director_iaas_configuration_environment_azurecloud="AzureCloud"
director_bosh_root_storage_account="$(terraform output -state="${STATE_FILE}" bosh_root_storage_account)"
export director_bosh_root_storage_account
director_client_id="$(terraform output -state="${STATE_FILE}" client_id)"
export director_client_id
director_client_secret="$(terraform output -state="${STATE_FILE}" client_secret)"
export director_client_secret
director_bosh_deployed_vms_security_group_name="$(terraform output -state="${STATE_FILE}" bosh_deployed_vms_security_group_name)"
export director_bosh_deployed_vms_security_group_name
director_resource_group_name="$(terraform output -state="${STATE_FILE}" pcf_resource_group_name)"
export director_resource_group_name
director_ops_manager_ssh_public_key="$(terraform output -state="${STATE_FILE}" ops_manager_ssh_public_key)"
export director_ops_manager_ssh_public_key
director_ops_manager_ssh_private_key="$(terraform output -state="${STATE_FILE}" ops_manager_ssh_private_key)"
export director_ops_manager_ssh_private_key
director_subscription_id="$(terraform output -state="${STATE_FILE}" subscription_id)"
export director_subscription_id
director_tenant_id="$(terraform output -state="${STATE_FILE}" tenant_id)"
export director_tenant_id
director_network_name="$(terraform output -state="${STATE_FILE}" network_name)"
export director_network_name
director_infrastructure_subnet_name="$(terraform output -state="${STATE_FILE}" infrastructure_subnet_name)"
export director_infrastructure_subnet_name
director_infrastructure_subnet_cidr="$(terraform output -state="${STATE_FILE}" infrastructure_subnet_cidr)"
export director_infrastructure_subnet_cidr
director_infrastructure_subnet_gateway="$(terraform output -state="${STATE_FILE}" infrastructure_subnet_gateway)"
export director_infrastructure_subnet_gateway
director_infrastructure_subnet_range="$(terraform output -state="${STATE_FILE}" infrastructure_subnet_range)"
export director_infrastructure_subnet_range
director_pks_subnet_name="$(terraform output -state="${STATE_FILE}" pks_subnet_name)"
export director_pks_subnet_name
director_pks_subnet_cidr="$(terraform output -state="${STATE_FILE}" pks_subnet_cidr)"
export director_pks_subnet_cidr
director_pks_subnet_gateway="$(terraform output -state="${STATE_FILE}" pks_subnet_gateway)"
export director_pks_subnet_gateway
director_pks_subnet_range="$(terraform output -state="${STATE_FILE}" pks_subnet_range)"
export director_pks_subnet_range
director_services_subnet_name="$(terraform output -state="${STATE_FILE}" services_subnet_name)"
export director_services_subnet_name
director_services_subnet_cidr="$(terraform output -state="${STATE_FILE}" services_subnet_cidr)"
export director_services_subnet_cidr
director_services_subnet_gateway="$(terraform output -state="${STATE_FILE}" services_subnet_gateway)"
export director_services_subnet_gateway
director_services_subnet_range="$(terraform output -state="${STATE_FILE}" services_subnet_range)"
export director_services_subnet_range
director_env_dns_zone_name_servers="$(terraform output -state="${STATE_FILE}" -json env_dns_zone_name_servers | jq -r .[] |tr '\n' ',' | sed -e 's/.,/, /g' -e 's/, $//')"
export director_env_dns_zone_name_servers
# director_pks_api_app_sec_group="$(terraform output -state="${STATE_FILE}" pks-api-app-sec-group)"
# export director_pks_api_app_sec_group
director_pks_master_app_sec_group="$(terraform output -state="${STATE_FILE}" pks-master-app-sec-group)"
export director_pks_master_app_sec_group

# shellcheck source=/dev/null
[[ -f "${__DIR}/set-om-creds.sh" ]] &&  \
  source "${__DIR}/set-om-creds.sh" ||  \
  (echo "set-om-creds.sh not found" && exit 1)

# Validate template
om interpolate --config "${__DIR}/../templates/director.yml" --vars-env=director

# Configure Ops Manager Authentication
om -t "$OM_TARGET" --skip-ssl-validation \
  configure-authentication \
    --decryption-passphrase "$OM_DECRYPTION_PASSPHRASE" \
    --username "$OM_USERNAME" \
    --password "$OM_PASSWORD"

# Configure Ops Manager Director
om -t "$OM_TARGET" --skip-ssl-validation \
  configure-director --config "${__DIR}/../templates/director.yml" --vars-env=director

# Deploy Ops Manager Director
om -t "$OM_TARGET" --skip-ssl-validation apply-changes
