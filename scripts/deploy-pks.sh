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

# shellcheck source=/dev/null
[[ -f "${__DIR}/set-om-creds.sh" ]] &&  \
  source "${__DIR}/set-om-creds.sh" ||  \
  (echo "set-om-creds.sh not found" && exit 1)

# Validate template
# om interpolate --config "${__DIR}/../templates/pivotal_container_service.yml" --vars-env=pks

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
