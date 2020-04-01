# Deploy Pivotal Container Service (PKS) onto Azure

This repo contains scripts and terraform configurations to deploy PCF Ops Manager, PKS and PAS to Azure Cloud.

## Setup Variables

```sh
cat > .envrc <<EOF
export ENVIRONMENT_NAME=pcf
export AZURE_CLIENT_ID=<application client id>
export AZURE_CLIENT_SECRET=<application client secret>
export AZURE_REGION=<azure region>
export AZURE_TENANT_ID=<azure tenant it>
export AZURE_SUBSCRIPTION_ID=<azure subscription id>
export OPSMAN_USERNAME=admin
export OPSMAN_PASSWORD=admin
export OPSMAN_DECRYPTION_PASSPHRASE=admin
export OPSMAN_SKIP_SSL_VALIDATION=false
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

## Installation

### Install Tools

- Run `./scripts/install-cli-tools.sh` to install required CLI tools

### Update Versions

- Update `./versions.yml` to use latest versions

### Create Azure Active Directory Service Account

- Follow [these instructions](https://docs.pivotal.io/platform/ops-manager/2-8/azure/prepare-azure-terraform.html#install) to create and configure the Service Principal account that is needed to run the terraform templates. To save time, you can run `./scripts/create-service-account.sh`

### Terraforming PCF on Azure

- Copy `./pcf/vars/$ENVIRONMENT_NAME/terraform.tfvars.example` to `./pcf/vars/$ENVIRONMENT_NAME/terraform.tfvars` and modify with your configuration choices and credentials.
- Run `./scripts/terraform-apply.sh` - this will create the infrastructure required in Azure for PCF.

### Configure Operations Manager and Deploy Director

- Configure opsman auth and the director tile

```sh
./scripts/deploy-director.sh
```

### Deploy Pivotal Container Service Product

- Download the product and stemcell from pivnet. Ensure environment variable `$PIVNET_TOKEN` is set.

```sh
./scripts/download-pks.sh
```

- Upload and Stage the product and upload/assign the stemcell.

```sh
./scripts/stage-pks.sh
```

- Apply pks configuration and deploy.

```sh
./scripts/deploy-pks.sh
```

### Access BOSH

```sh
source ./scripts/target-bosh.sh
```

## Platform Automation

- **Coming soon**
