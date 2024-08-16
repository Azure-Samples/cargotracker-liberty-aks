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

@description('Secret name of certificate data.')
param certificateDataName string = 'myIdentityKeyStoreData'

@secure()
@description('Certificate data to store in the secret')
param certificateDataValue string = newGuid()

@description('Secret name of certificate password.')
param certificatePswSecretName string = 'myIdentityKeyStorePsw'

@secure()
@description('Certificate password to store in the secret')
param certificatePasswordValue string = newGuid()

@description('Property to specify whether Azure Resource Manager is permitted to retrieve secrets from the key vault.')
param enabledForTemplateDeployment bool = true

@description('Name of the vault')
param keyVaultName string = 'kv-${uniqueString('utcValue')}'

param location string

@description('Price tier for Key Vault.')
param sku string = 'Standard'

param utcValue string = utcNow()

resource keyvault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    accessPolicies: []
    enabledForTemplateDeployment: enabledForTemplateDeployment
    sku: {
      name: sku
      family: 'A'
    }
    tenantId: subscription().tenantId
  }
  tags:{
    'managed-by-azure-liberty-aks': utcValue
  }
}

resource secretForCertificate 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: format('{0}/{1}', keyVaultName, certificateDataName)
  properties: {
    value: certificateDataValue
  }
  dependsOn: [
    keyvault
  ]
}

resource secretForCertPassword 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: format('{0}/{1}', keyVaultName, certificatePswSecretName)
  properties: {
    value: certificatePasswordValue
  }
  dependsOn: [
    keyvault
  ]
}

output keyVaultName string = keyVaultName
output sslCertDataSecretName string = certificateDataName
output sslCertPwdSecretName string = certificatePswSecretName
