# Overview

This demo illustrates how to use a managed identity assigned to a user with customer-managed keys. The resource group's life cycle will determine the identity life cycle. This can be expanded with other resources using CMK reducing the need to assign access policy’s for the system assigned identities

## How to Deploy

```azurecli
az login --tenant <TENANTID>
az account set --subscription <SUBSCRIPTIONNAME> 

terraform init
terraform apply --var-file='./example.tfvars'
```

## Resource Cleanup 

```azurecli
terraform destroy
```