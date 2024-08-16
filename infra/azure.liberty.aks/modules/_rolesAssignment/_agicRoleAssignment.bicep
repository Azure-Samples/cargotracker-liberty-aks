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

var const_APIVersion = '2020-12-01'
var name_appGwContributorRoleAssignmentName = guid('${resourceGroup().id}ForApplicationGateway')
// https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
var const_roleDefinitionIdOfContributor = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

resource aksCluster 'Microsoft.ContainerService/managedClusters@2023-08-01' existing = {
  name: aksClusterName
  scope: resourceGroup(aksClusterRGName)
}

resource agicUamiRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: name_appGwContributorRoleAssignmentName
  properties: {
    description: 'Assign Resource Group Contributor role to User Assigned Managed Identity '
    principalId: reference(aksCluster.id, const_APIVersion , 'Full').properties.addonProfiles.ingressApplicationGateway.identity.objectId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', const_roleDefinitionIdOfContributor)
  }
  dependsOn: [
    aksCluster
  ]
}
