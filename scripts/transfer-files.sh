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

state_file=${__DIR}/../pcf/state/"$ENVIRONMENT_NAME"/terraform.tfstate
opsman_dns=$(terraform output -state="${state_file}" ops_manager_dns)
private_key="$HOME"/.ssh/om_pks_azure_ssh_key

if [[ ! -f ${private_key} ]]; then
	terraform output -state="${state_file}" ops_manager_ssh_private_key > "${private_key}"
	chmod 600 "${private_key}"
	 echo "opsman ssh private key written to '${private_key}'"
fi

scp -i "${private_key}" "$HOME/.ssh/id_rsa" \
	ubuntu@"${opsman_dns}":/home/ubuntu/.ssh

scp -i "${private_key}" -r "${__DIR}/../pcf/state" \
	ubuntu@"${opsman_dns}":/home/ubuntu/workspace/pks-azure/pcf/

scp -i "${private_key}" -r "${__DIR}/../pcf/vars" \
	ubuntu@"${opsman_dns}":/home/ubuntu/workspace/pks-azure/pcf/

scp -i "${private_key}" ".envrc" \
	ubuntu@"${opsman_dns}":/home/ubuntu/workspace/pks-azure/.envrc
