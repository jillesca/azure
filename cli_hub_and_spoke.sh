
# https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-cli

az group create --name techTalk --location northeurope

az group list -o table

# https://docs.microsoft.com/en-us/azure/virtual-network/quick-create-cli


az network vnet list -o table

# https://docs.microsoft.com/en-us/azure/vpn-gateway/create-routebased-vpn-gateway-cli

az network vnet create \
  --name hub-vnet \
  --resource-group techTalk \
  --subnet-name hub-subnet \
  --address-prefixes 10.0.0.0/16 \
  --subnet-prefixes 10.0.1.0/24
  
### gateway configuration
az network vnet subnet create \
  --vnet-name hub-vnet \
  --name GatewaySubnet \
  --resource-group techTalk \
  --address-prefix 10.0.255.0/27

az network public-ip create \
  --name gateway-ip-address \
  --resource-group techTalk \
  --allocation-method Dynamic \
  --sku Basic

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

# hub configuration 
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

# spoke1 configuration 
az network vnet create \
  --name spoke1-vnet \
  --resource-group techTalk \
  --subnet-name spoke1-subnet \
  --address-prefixes 10.1.0.0/16 \
  --subnet-prefixes 10.1.1.0/24 

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

az network vnet peering create \
    --resource-group techTalk \
    --name spoke1-Peering \
    --vnet-name hub-vnet \
    --remote-vnet spoke1-vnet \
    --allow-vnet-access \
    --allow-gateway-transit \
    --allow-forwarded-traffic

az network vnet peering create \
    --resource-group techTalk \
    --name spoke1-hub-Peering \
    --vnet-name spoke1-vnet \
    --remote-vnet hub-vnet \
    --allow-vnet-access \
    --use-remote-gateways

# spoke2 configuration
az network vnet create \
  --name spoke2-vnet \
  --resource-group techTalk \
  --subnet-name spoke2-subnet \
  --address-prefixes 10.2.0.0/16 \
  --subnet-prefixes 10.2.1.0/24 

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

az network vnet peering create \
    --resource-group techTalk \
    --name spoke2-Peering \
    --vnet-name hub-vnet \
    --remote-vnet spoke2-vnet \
    --allow-vnet-access \
    --allow-gateway-transit \
    --allow-forwarded-traffic

az network vnet peering create \
    --resource-group techTalk \
    --name spoke2-hub-Peering \
    --vnet-name spoke2-vnet \
    --remote-vnet hub-vnet \
    --allow-vnet-access \
    --use-remote-gateways

for vm in hub, spoke1, spoke2
do
    az vm list-ip-addresses -o table -n $vm
done