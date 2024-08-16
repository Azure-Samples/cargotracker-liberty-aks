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

@secure()
@description('Certificate data to store in the secret')
param certificateDataValue string = newGuid()

@secure()
@description('Certificate password to store in the secret')
param certificatePasswordValue string = newGuid()

@description('Property to specify whether Azure Resource Manager is permitted to retrieve secrets from the key vault.')
param enabledForTemplateDeployment bool = true

param identity object = {}
param location string
param permission object = {
  certificates: [
    'get'
    'list'
    'update'
    'create'
  ]
}

@description('Price tier for Key Vault.')
param sku string = 'Standard'

@description('Subject name to create a certificate.')
param subjectName string = ''

@description('If false, will create a certificate.')
param useExistingAppGatewaySSLCertificate bool = false

@description('Current deployment time. Used as a tag in deployment script.')
param keyVaultName string = 'GEN_UNIQUE'

var name_sslCertSecretName = 'myAppGatewaySSLCert'
var name_sslCertPasswordSecretName = 'myAppGatewaySSLCertPassword'

module keyVaultwithSelfSignedAppGatewaySSLCert '_keyvault/_keyvaultWithNewCert.bicep' = if (!useExistingAppGatewaySSLCertificate) {
  name: 'kv-appgw-selfsigned-certificate-deployment'
  params: {
    identity: identity
    keyVaultName: keyVaultName
    location: location
    permission: permission
    subjectName: subjectName
    sku: sku
  }
}

module keyVaultwithExistingAppGatewaySSLCert '_keyvault/_keyvaultWithExistingCert.bicep' = if (useExistingAppGatewaySSLCertificate) {
  name: 'kv-appgw-existing-certificate-deployment'
  params: {
    certificateDataName: name_sslCertSecretName
    certificateDataValue: certificateDataValue
    certificatePswSecretName: name_sslCertPasswordSecretName
    certificatePasswordValue: certificatePasswordValue
    enabledForTemplateDeployment: enabledForTemplateDeployment
    keyVaultName: keyVaultName
    location: location
    sku: sku
  }
}

output keyVaultName string = (useExistingAppGatewaySSLCertificate ? keyVaultwithExistingAppGatewaySSLCert.outputs.keyVaultName : keyVaultwithSelfSignedAppGatewaySSLCert.outputs.keyVaultName)
output sslCertDataSecretName string = (useExistingAppGatewaySSLCertificate ? keyVaultwithExistingAppGatewaySSLCert.outputs.sslCertDataSecretName : keyVaultwithSelfSignedAppGatewaySSLCert.outputs.secretName)
output sslCertPwdSecretName string = (useExistingAppGatewaySSLCertificate ? keyVaultwithExistingAppGatewaySSLCert.outputs.sslCertPwdSecretName: keyVaultwithSelfSignedAppGatewaySSLCert.outputs.secretName)
output sslBackendCertDataSecretName string = ''

