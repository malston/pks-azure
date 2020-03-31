# Deploy Pivotal Container Service (PKS) onto Azure

This repo contains scripts and terraform configurations to deploy a control
plane, opsmanager and PKS to Azure Cloud.

## Setup Variables

```sh
cat > .envrc <<EOF
export AZURE_CLIENT_ID=<application client id>
export AZURE_CLIENT_SECRET=<application client secret>
export AZURE_REGION=<azure region>
export AZURE_TENANT_ID=<azure tenant it>
export AZURE_SUBSCRIPTION_ID=<azure subscription id>
export ENVIRONMENT_NAME=pcf
EOF
```

Run the following source command to set the environment variables into your shell or install [direnv](https://direnv.net/) to do this automatically.

```sh
source .envrc
```

## DNS

- Create a [DNS zone](https://docs.microsoft.com/en-us/azure/dns/dns-delegate-domain-azure-dns#create-a-dns-zone) in Azure Portal

- Perform a DNS query to make sure the correct nameservers are resolved

  ```sh
  nslookup -type=SOA foo.example.com
  ```

## Terraform PKS

- Run `./scripts/install-cli-tools.sh` to install required CLI tools
- Follow [these instructions](https://docs.pivotal.io/platform/ops-manager/2-8/azure/prepare-azure-terraform.html#install) to create and configure the Service Principal account that is needed to run the terraform templates. To save time, you can run `./scripts/create-service-account.sh`
- Copy `./pks/vars/$ENVIRONMENT_NAME/terraform.tfvars.example` to `./pks/vars/$ENVIRONMENT_NAME/terraform.tfvars` and modify with your configuration choices and credentials.
- Run `./scripts/terraform-pks-apply.sh` - this will create the
  infrastructure required in Azure for a pks.

## Platform Automation

- Coming soon ...