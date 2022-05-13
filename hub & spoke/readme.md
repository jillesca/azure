# CLI Hub & Spoke Topology

- [CLI Hub & Spoke Topology](#cli-hub--spoke-topology)
- [Create a Resource Group](#create-a-resource-group)
- [Create VNets](#create-vnets)
  - [hub](#hub)
  - [Spoke1](#spoke1)
  - [Spoke2](#spoke2)
- [Create the Virtual Network Gateway](#create-the-virtual-network-gateway)
- [Create the Hub Virtual Machine](#create-the-hub-virtual-machine)
- [Create a route between the two spokes](#create-a-route-between-the-two-spokes)
  - [Spoke1](#spoke1-1)
  - [Spoke2](#spoke2-1)
- [Create Virtual Machines](#create-virtual-machines)
  - [Spoke1](#spoke1-2)
  - [Spoke2](#spoke2-2)
- [Configure VNet peering between Hub and Spokes](#configure-vnet-peering-between-hub-and-spokes)
  - [Spoke1](#spoke1-3)
  - [Spoke2](#spoke2-3)
- [Verification](#verification)

This is an exercise to create a hub and spoke topology in Azure using 3 VM, 3 VNETs and 1 network gateway.

If you haven't start by login to your azure account, this will open a window on your web browser where you can login.

```bash
az login
```

# Create a Resource Group

Create a [resource group](<https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-cli>)

```bash
az group create --name techTalk --location northeurope
```

Verify the Resource Group is there.

```bash
az group list -o table
```

# Create VNets

Then we can [create a vnet](<https://docs.microsoft.com/en-us/azure/virtual-network/quick-create-cli>)

## hub

```bash
az network vnet create \
  --name hub-vnet \
  --resource-group techTalk \
  --subnet-name hub-subnet \
  --address-prefixes 10.0.0.0/16 \
  --subnet-prefixes 10.0.1.0/24
```

## Spoke1

```bash
az network vnet create \
  --name spoke1-vnet \
  --resource-group techTalk \
  --subnet-name spoke1-subnet \
  --address-prefixes 10.1.0.0/16 \
  --subnet-prefixes 10.1.1.0/24 
```

## Spoke2

```bash
az network vnet create \
  --name spoke2-vnet \
  --resource-group techTalk \
  --subnet-name spoke2-subnet \
  --address-prefixes 10.2.0.0/16 \
  --subnet-prefixes 10.2.1.0/24 
```

Review the vnet is created

```bash
az network vnet list -o table
```

# Create the Virtual Network Gateway

Next we create the virtual network gateway that will help us route packets between our spokes and remotes VMs through the hub vnet

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

Finally create the virtual network gateway, this can take a while, aprox 20-40min

```bash
az network vnet-gateway create \
  --name vnet-Gateway \
  --location northeurope \
  --public-ip-address gateway-ip-address \
  --resource-group techTalk \
  --vnet hub-vnet \
  --gateway-type Vpn \
  --sku Standard \
  --vpn-type RouteBased \
  --no-wait
```

# Create the Hub Virtual Machine

Create hub VM and add it to the hub vnet

If you want to see the output from the command that creates the VM remove the `--no-wait` argument.

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
  --os-disk-delete-option Delete \
  --no-wait
```

# Create a route between the two spokes

To be able to ping both spokes through the hub vnet we need to add a route on them to tell them to use the virtual network gateway as next hop.

## Spoke1

First create a route table

```bash
az network route-table create \
  --resource-group techTalk \
  --name spoke1RouteTable 
 ```

 Then create the route entry

 ```bash
 az network route-table route create \
  --name spoke1ToSpoke2 \
  --resource-group techTalk \
  --route-table-name spoke1RouteTable \
  --address-prefix 10.2.1.0/24  \
  --next-hop-type VirtualNetworkGateway 
  ```

Finally associate the entry to a subnet

```bash
az network vnet subnet update \
  --vnet-name spoke1-vnet \
  --name spoke1-subnet \
  --resource-group techTalk \
  --route-table spoke1RouteTable
```

## Spoke2

```bash
az network route-table create \
  --resource-group techTalk \
  --name spoke2RouteTable 
 ```

 ```bash
 az network route-table route create \
  --name spoke2ToSpoke1 \
  --resource-group techTalk \
  --route-table-name spoke2RouteTable \
  --address-prefix 10.1.1.0/24  \
  --next-hop-type VirtualNetworkGateway 
  ```

```bash
az network vnet subnet update \
  --vnet-name spoke2-vnet \
  --name spoke2-subnet \
  --resource-group techTalk \
  --route-table spoke2RouteTable
```

# Create Virtual Machines

## Spoke1

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
  --os-disk-delete-option Delete \
  --no-wait
```

## Spoke2

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
  --os-disk-delete-option Delete \
  --no-wait
```

# Configure VNet peering between Hub and Spokes

## Spoke1

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

## Spoke2

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

# Verification

let's verify the IPs of the VMs we created:

```bash
az vm list-ip-addresses -o table -n hub
az vm list-ip-addresses -o table -n spoke1 
az vm list-ip-addresses -o table -n spoke2

```
