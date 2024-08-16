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

param name_deploymentScriptContributorRoleAssignmentName string = guid('${resourceGroup().id}Deployment Script')

// https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
var const_roleDefinitionIdOfContributor = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
var name_deploymentScriptUserDefinedManagedIdentity = 'ol-aks-deployment-script-user-defined-managed-itentity-${substring(uniqueString(name_deploymentScriptContributorRoleAssignmentName),0,5)}'


// UAMI for deployment script
resource uamiForDeploymentScript 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: name_deploymentScriptUserDefinedManagedIdentity
  location: location
}

// Assign Contributor role in subscription scope, we need the permission to get/update resource cross resource groups.
module deploymentScriptUAMICotibutorRoleAssignment '_rolesAssignment/_roleAssignmentinSubscription.bicep' = {
  name: name_deploymentScriptContributorRoleAssignmentName
  scope: subscription()
  params: {
    roleDefinitionId: const_roleDefinitionIdOfContributor
    principalId: reference(resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', name_deploymentScriptUserDefinedManagedIdentity)).principalId
  }
}

output uamiIdForDeploymentScript string = uamiForDeploymentScript.id
