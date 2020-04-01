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

export STATE_FILE=${__DIR}/../pcf/state/"$ENVIRONMENT_NAME"/terraform.tfstate

VARS_subscription_id="$(terraform output -state="${STATE_FILE}" subscription_id)"
export VARS_subscription_id
VARS_resource_group_name="$(terraform output -state="${STATE_FILE}" pcf_resource_group_name)"
export VARS_resource_group_name

om interpolate --config "${__DIR}/../templates/pks_master_role.json" --vars-env VARS > "/tmp/pks_master_role.yaml" && \
	yaml2json "/tmp/pks_master_role.yaml" | jq . > "/tmp/pks_master_role.json"
om interpolate --config "${__DIR}/../templates/pks_worker_role.json" --vars-env VARS > "/tmp/pks_worker_role.yaml" && \
	yaml2json "/tmp/pks_worker_role.yaml"  | jq . > "/tmp/pks_worker_role.json"

az role definition create --role-definition "/tmp/pks_master_role.json"
az identity create -g "${VARS_resource_group_name}" -n "pks-master"

az role definition create --role-definition "/tmp/pks_worker_role.json"
az identity create -g "${VARS_resource_group_name}" -n "pks-worker"

# eventual consistency... retry until it works
until az role assignment create --assignee "pks-master" \
  --role "PKS master" --scope /subscriptions/"$VARS_subscription_id" > /dev/null 2>&1;
do
	echo 'Retrying role assignment...'
	sleep 1
done

echo "Verifying role assignment to pks-master..."
az role assignment list --assignee "pks-master"

# eventual consistency... retry until it works
until az role assignment create --assignee "pks-worker" \
  --role "PKS worker" --scope /subscriptions/"$VARS_subscription_id" > /dev/null 2>&1;
do
	echo 'Retrying role assignment...'
	sleep 1
done

echo "Verifying role assignment to pks-worker..."
az role assignment list --assignee "pks-worker"

echo
echo "Done!"
echo
