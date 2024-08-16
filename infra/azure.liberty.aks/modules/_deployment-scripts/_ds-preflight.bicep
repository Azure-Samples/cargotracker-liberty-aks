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
param name string = ''
param identity object = {}
param createCluster bool = true
param aksClusterName string = ''
param aksClusterRGName string = ''
param enableAppGWIngress bool = false
param vnetForApplicationGateway object = {}
param appGatewayCertificateOption string = ''
param keyVaultName string = ''
param keyVaultResourceGroup string = ''
param keyVaultSSLCertDataSecretName string = ''
param keyVaultSSLCertPasswordSecretName string = ''
@secure()
param appGatewaySSLCertData string = ''
@secure()
param appGatewaySSLCertPassword string = ''
param vmSize string
param deployApplication bool
param sourceImagePath string

param utcValue string = utcNow()

var const_scriptLocation = uri(_artifactsLocation, 'scripts/')

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: name
  location: location
  kind: 'AzureCLI'
  identity: identity
  properties: {
    azCliVersion: '2.53.0'
    environmentVariables: [
      {
        name: 'CREATE_CLUSTER'
        value: string(createCluster)
      }
      {
        name: 'AKS_CLUSTER_NAME'
        value: aksClusterName
      }
      {
        name: 'AKS_CLUSTER_RG_NAME'
        value: aksClusterRGName
      }      
      {
        name: 'ENABLE_APPLICATION_GATEWAY_INGRESS_CONTROLLER'
        value: string(enableAppGWIngress)
      }
      {
        name: 'VNET_FOR_APPLICATIONGATEWAY'
        value: string(vnetForApplicationGateway)
      }
      {
        name: 'APPLICATION_GATEWAY_CERTIFICATE_OPTION'
        value: appGatewayCertificateOption
      }
      {
        name: 'APPLICATION_GATEWAY_SSL_KEYVAULT_NAME'
        value: keyVaultName
      }
      {
        name: 'APPLICATION_GATEWAY_SSL_KEYVAULT_RESOURCEGROUP'
        value: keyVaultResourceGroup
      }
      {
        name: 'APPLICATION_GATEWAY_SSL_KEYVAULT_FRONTEND_CERT_DATA_SECRET_NAME'
        value: keyVaultSSLCertDataSecretName
      }
      {
        name: 'APPLICATION_GATEWAY_SSL_KEYVAULT_FRONTEND_CERT_PASSWORD_SECRET_NAME'
        value: keyVaultSSLCertPasswordSecretName
      }
      {
        name: 'APPLICATION_GATEWAY_SSL_FRONTEND_CERT_DATA'
        secureValue: appGatewaySSLCertData
      }
      {
        name: 'APPLICATION_GATEWAY_SSL_FRONTEND_CERT_PASSWORD'
        secureValue: appGatewaySSLCertPassword
      }
      {
        name: 'LOCATION'
        value: location
      }
      {
        name: 'VM_SIZE'
        value: vmSize
      }
      {
        name: 'DEPLOY_APPLICATION'
        value: string(deployApplication)
      }
      {
        name: 'SOURCE_IMAGE_PATH'
        value: sourceImagePath
      }
    ]
    primaryScriptUri: uri(const_scriptLocation, 'preflight.sh${_artifactsLocationSasToken}')
    supportingScriptUris: [
      uri(const_scriptLocation, 'utility.sh${_artifactsLocationSasToken}')
    ]

    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
    forceUpdateTag: utcValue
  }
}

output aksAgentAvailabilityZones array = json(deploymentScript.properties.outputs.agentAvailabilityZones)
