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

param _artifactsLocation string = deployment().properties.templateLink.uri
@secure()
param _artifactsLocationSasToken string = ''
param location string

param identity object = {}

@allowed([
  'haveCert'
  'haveKeyVault'
  'generateCert'
])
@description('Three scenarios we support for deploying app gateway')
param appgwCertificateOption string = 'haveCert'
@secure()
param appgwFrontendSSLCertData string = newGuid()
@secure()
param appgwFrontendSSLCertPsw string = newGuid()

param appgwName string = 'appgw-contoso'

param aksClusterRGName string = 'aks-contoso-rg'
param aksClusterName string = 'aks-contoso'
param appFrontendTlsSecretName string = 'tls-secret'
param appProjName string = 'default'

param utcValue string = utcNow()

var const_scriptLocation = uri(_artifactsLocation, 'scripts/')

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'ds-networking-deployment'
  location: location
  kind: 'AzureCLI'
  identity: identity
  properties: {
    azCliVersion: '2.15.0'
    environmentVariables: [
      {
        name: 'AKS_CLUSTER_RG_NAME'
        value: aksClusterRGName
      }
      {
        name: 'AKS_CLUSTER_NAME'
        value: aksClusterName
      }
      {
        name: 'CURRENT_RG_NAME'
        value: resourceGroup().name
      }
      {
        name: 'APP_GW_NAME'
        value: appgwName
      }
      {
        name: 'APP_GW_FRONTEND_SSL_CERT_DATA'
        value: appgwFrontendSSLCertData
      }
      {
        name: 'APP_GW_FRONTEND_SSL_CERT_PSW'
        secureValue: appgwFrontendSSLCertPsw
      }
      {
        name: 'APP_GW_CERTIFICATE_OPTION'
        value: appgwCertificateOption
      }
      {
        name: 'APP_FRONTEND_TLS_SECRET_NAME'
        value: appFrontendTlsSecretName
      }
      {
        name: 'APP_PROJ_NAME'
        value: appProjName
      }
    ]
    primaryScriptUri: uri(const_scriptLocation, 'createAppGatewayIngress.sh${_artifactsLocationSasToken}')
    supportingScriptUris: [
      uri(const_scriptLocation, 'utility.sh${_artifactsLocationSasToken}')
    ]
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
    forceUpdateTag: utcValue
  }
}
