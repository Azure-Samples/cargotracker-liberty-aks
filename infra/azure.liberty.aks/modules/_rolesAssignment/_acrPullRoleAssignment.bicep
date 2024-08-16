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

param aksClusterName string = ''
param aksClusterRGName string = ''
param acrName string = ''
param acrRGName string = ''

var const_APIVersion = '2020-12-01'
// https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
var const_roleDefinitionIdOfAcrPull = '7f951dda-4ed3-4680-a7ca-43fe172d538d'

resource aksCluster 'Microsoft.ContainerService/managedClusters@2023-08-01' existing = {
  name: aksClusterName
  scope: resourceGroup(aksClusterRGName)
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
  scope: resourceGroup(acrRGName)
}

// https://github.com/Azure/azure-quickstart-templates/issues/4205
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('${aksCluster.id}${acr.id}ForKubeletIdentity')
  properties: {
    description: 'Assign Resource Group Contributor role to User Assigned Managed Identity '
    principalId: reference(aksCluster.id, const_APIVersion , 'Full').properties.identityProfile.kubeletidentity.objectId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', const_roleDefinitionIdOfAcrPull)
  }
  dependsOn: [
    aksCluster
    acr
  ]
}

output aksClusterId string = aksCluster.id
output acrId string = acr.id
