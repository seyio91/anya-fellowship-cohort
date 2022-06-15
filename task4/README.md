# Polkadot Nodes provisioning

This repository Provisions Polkadot Bootnodes, rpc nodes and Collator nodes


### Create Amazon Machine Image

```
cd packer
packer build ami.json
```

### Create Terraform Infrastructure Plan

```
cd terraform
terraform plan
```

### Provision Polkadot Nodes

```
cd terraform
terraform apply
```

## Destroy Nodes

```
cd terraform
terraform destroy
```