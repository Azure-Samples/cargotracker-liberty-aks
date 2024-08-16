/*
     Copyright (c) Microsoft Corporation.
     Copyright (c) IBM Corporation.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

          http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
*/

param location string
param newOrExistingVnetForApplicationGateway string
param vnetForApplicationGateway object = {
  name: 'olaks-app-gateway-vnet'
  resourceGroup: resourceGroup().name
  addressPrefixes: [
    '172.16.0.0/24'
  ]
  addressPrefix: '172.16.0.0/24'
  newOrExisting: 'new'
  subnets: {
    gatewaySubnet: {
      name: 'olaks-gateway-subnet'
      addressPrefix: '172.16.0.0/24'
      startAddress: '172.16.0.4'
    }
  }
}
param vnetRGNameForApplicationGateway string
param nameSuffix string = ''
param guidValue string = take(replace(newGuid(), '-', ''), 6)

var const_nameSuffix = empty(nameSuffix) ? guidValue : nameSuffix
var const_subnetAddressPrefixes = vnetForApplicationGateway.subnets.gatewaySubnet.addressPrefix
var const_vnetAddressPrefixes = vnetForApplicationGateway.addressPrefixes
var const_newVnet = (vnetForApplicationGateway.newOrExisting == 'new') ? true : false
var name_nsg = format('olaks-nsg{0}', const_nameSuffix)
var name_subnet = vnetForApplicationGateway.subnets.gatewaySubnet.name
var name_vnet = vnetForApplicationGateway.name

// Create new network security group.
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = if (const_newVnet) {
  name: name_nsg
  location: location
  properties: {
    securityRules: [
      {
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '65200-65535'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 500
          direction: 'Inbound'
        }
        name: 'ALLOW_APPGW'
      }
      {
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 510
          direction: 'Inbound'
          destinationPortRanges: [
            '80'
            '443'
          ]
        }
        name: 'ALLOW_HTTP_ACCESS'
      }
    ]
  }
}

// Create new VNET and subnet.
resource newVnet 'Microsoft.Network/virtualNetworks@2023-11-01' = if (const_newVnet) {
  name: name_vnet
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: const_vnetAddressPrefixes
    }
    subnets: [
      {
        name: name_subnet
        properties: {
          addressPrefix: const_subnetAddressPrefixes
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

// To mitigate ARM-TTK error: Control Named vnetForApplicationGateway must output the resourceGroup property when hideExisting is false
output vnetResourceGroupName string = vnetRGNameForApplicationGateway
// To mitigate ARM-TTK error: Control Named vnetForApplicationGateway must output the newOrExisting property when hideExisting is false
output newOrExisting string = newOrExistingVnetForApplicationGateway
