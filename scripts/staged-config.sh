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

usage() {
cat <<EOF

USAGE: $0 product-name [<options>]

You can use the following options:

--include-credentials, -c   include credentials. note: requires product to have been deployed
--include-placeholders, -r  replace obscured credentials with interpolatable placeholders
EOF
}

PRODUCT_NAME="${1}"

if [ -z "${PRODUCT_NAME}" ]; then
	echo "PRODUCT_NAME unset!"
	usage
	exit 1
fi

# shellcheck source=/dev/null
[[ -f "${__DIR}/set-om-creds.sh" ]] &&  \
  source "${__DIR}/set-om-creds.sh" ||  \
  (echo "set-om-creds.sh not found" && exit 1)

# Initialize parameters specified from command line
while [[ $# -gt 1 ]]
do
key="$1"
case ${key} in
    -r|--include-placeholders)
    INCLUDE_PLACEHOLDERS="$1"
    ;;
    -c|--include-credentials)
    INCLUDE_CREDENTIALS="$1"
    ;;
    --help)
    usage
    exit 0
    ;;
    *)
    echo "Invalid option: [$1]"
    usage
    exit 1
    ;;
esac
shift
done

om --skip-ssl-validation staged-config \
    --product-name "${PRODUCT_NAME}" \
    "${INCLUDE_PLACEHOLDERS}" \
    "${INCLUDE_CREDENTIALS}"
