# CLI Hub & Spoke Topology

- [CLI Hub & Spoke Topology](#cli-hub--spoke-topology)
  - [Create a Resource Group](#create-a-resource-group)
  - [Create Hub VNet](#create-hub-vnet)
  - [Create Gateway configuration](#create-gateway-configuration)
- [hub configuration](#hub-configuration)
- [spoke1 configuration](#spoke1-configuration)
- [spoke2 configuration](#spoke2-configuration)

This is an exercise to create a hub and spoke topology in Azure using 3 VM, 3 VNETs and 1 network gateway.

## Create a Resource Group

The first part is to create a [resource group](<https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-cli>)

```bash
az group create --name techTalk --location northeurope
```

Verify the resource group is there

```bash
az group list -o table
```

## Create Hub VNet

Then we can [create a vnet](<https://docs.microsoft.com/en-us/azure/virtual-network/quick-create-cli>)

```bash
az network vnet create \
  --name hub-vnet \
  --resource-group techTalk \
  --subnet-name hub-subnet \
  --address-prefixes 10.0.0.0/16 \
  --subnet-prefixes 10.0.1.0/24
```

Review the vnet is created

```bash
az network vnet list -o table
```

## Create Gateway configuration

Next we create the network gateway that will help us route packets between our spokes and remotes VMs through the hub vnet

First, add the `GatewaySubnet` to the hub VNet, this is a keyword the gateway is expecting. Is important to add it.

```bash
az network vnet subnet create \
  --vnet-name hub-vnet \
  --name GatewaySubnet \
  --resource-group techTalk \
  --address-prefix 10.0.255.0/27
```

Then request a public IP that will be used by the Gateway

```bash
az network public-ip create \
  --name gateway-ip-address \
  --resource-group techTalk \
  --allocation-method Dynamic \
  --sku Basic
```

Finally create the gateway, this can take a while, aprox 20-40min

```bash
az network vnet-gateway create \
  --name vnet-Gateway \
  --location northeurope \
  --public-ip-address gateway-ip-address \
  --resource-group techTalk \
  --vnet hub-vnet \
  --gateway-type Vpn \
  --sku Basic \
  --vpn-type RouteBased \
  --no-wait
```

# hub configuration

Create hub VM and add it to the hub vnet

```bash
az vm create \
  --resource-group techTalk \
  --name hub \
  --image debian \
  --generate-ssh-keys \
  --public-ip-sku Basic \
  --size Standard_B1ls \
  --vnet-name hub-vnet \
  --subnet hub-subnet \
  --nic-delete-option Delete \
  --data-disk-delete-option Delete \
  --os-disk-delete-option Delete
```

# spoke1 configuration

Create the spoke1 vnet

```bash
az network vnet create \
  --name spoke1-vnet \
  --resource-group techTalk \
  --subnet-name spoke1-subnet \
  --address-prefixes 10.1.0.0/16 \
  --subnet-prefixes 10.1.1.0/24 
```

Create the spoke1 vm

```bash
az vm create \
  --resource-group techTalk \
  --name spoke1 \
  --image debian \
  --generate-ssh-keys \
  --public-ip-sku Basic \
  --size Standard_B1ls \
  --vnet-name spoke1-vnet \
  --subnet spoke1-subnet \
  --nic-delete-option Delete \
  --data-disk-delete-option Delete \
  --os-disk-delete-option Delete
```

Create the [peering between VNets](https://docs.microsoft.com/en-us/cli/azure/network/vnet/peering?view=azure-cli-latest), in this case from the hub to the spoke1 vnet

```bash
az network vnet peering create \
    --resource-group techTalk \
    --name spoke1-Peering \
    --vnet-name hub-vnet \
    --remote-vnet spoke1-vnet \
    --allow-vnet-access \
    --allow-gateway-transit \
    --allow-forwarded-traffic
```

Create the peering from the spoke to the hub

```bash
az network vnet peering create \
    --resource-group techTalk \
    --name spoke1-hub-Peering \
    --vnet-name spoke1-vnet \
    --remote-vnet hub-vnet \
    --allow-vnet-access \
    --use-remote-gateways
```

# spoke2 configuration

```bash
az network vnet create \
  --name spoke2-vnet \
  --resource-group techTalk \
  --subnet-name spoke2-subnet \
  --address-prefixes 10.2.0.0/16 \
  --subnet-prefixes 10.2.1.0/24 
```

```bash
az vm create \
  --resource-group techTalk \
  --name spoke2 \
  --image debian \
  --generate-ssh-keys \
  --public-ip-sku Basic \
  --size Standard_B1ls \
  --vnet-name spoke2-vnet \
  --subnet spoke2-subnet \
  --nic-delete-option Delete \
  --data-disk-delete-option Delete \
  --os-disk-delete-option Delete
```

```bash
az network vnet peering create \
    --resource-group techTalk \
    --name spoke2-Peering \
    --vnet-name hub-vnet \
    --remote-vnet spoke2-vnet \
    --allow-vnet-access \
    --allow-gateway-transit \
    --allow-forwarded-traffic
```

```bash
az network vnet peering create \
    --resource-group techTalk \
    --name spoke2-hub-Peering \
    --vnet-name spoke2-vnet \
    --remote-vnet hub-vnet \
    --allow-vnet-access \
    --use-remote-gateways
```

let's verify the IPs of the VMs we created:

```bash
for vm in hub, spoke1, spoke2
do
    az vm list-ip-addresses -o table -n $vm
done

```
