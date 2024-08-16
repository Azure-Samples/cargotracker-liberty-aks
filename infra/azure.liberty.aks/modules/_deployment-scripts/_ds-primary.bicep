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
param arguments string = ''
param acrRGName string = ''
param deployWLO bool = false
param edition string = 'IBM WebSphere Application Server'
param productEntitlementSource string = 'Standalone'
param metric string = 'Processor Value Unit (PVU)'
param deployApplication bool = false
param enableAppGWIngress bool = false
param appFrontendTlsSecretName string =''
param enableCookieBasedAffinity bool = false
param appgwUsePrivateIP bool = false
param autoScaling bool = false
param cpuUtilizationPercentage int = 80
param minReplicas int = 1
param maxReplicas int = 100
param requestCPUMillicore int = 300

param utcValue string = utcNow()

var const_scriptLocation = uri(_artifactsLocation, 'scripts/')

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: name
  location: location
  kind: 'AzureCLI'
  identity: identity
  properties: {
    azCliVersion: '2.15.0'
    environmentVariables: [
      {
        name: 'ACR_RG_NAME'
        value: string(acrRGName)
      }
      {
        name: 'ENABLE_APP_GW_INGRESS'
        value: string(enableAppGWIngress)
      }
      {
        name: 'APP_FRONTEND_TLS_SECRET_NAME'
        value: string(appFrontendTlsSecretName)
      }
      {
        name: 'ENABLE_COOKIE_BASED_AFFINITY'
        value: string(enableCookieBasedAffinity)
      }
      {
        name: 'APP_GW_USE_PRIVATE_IP'
        value: string(appgwUsePrivateIP)
      }
      {
        name: 'DEPLOY_WLO'
        value: string(deployWLO)
      }
      {
        name: 'WLA_EDITION'
        value: string(edition)
      }
      {
        name: 'WLA_PRODUCT_ENTITLEMENT_SOURCE'
        value: string(productEntitlementSource)
      }
      {
        name: 'WLA_METRIC'
        value: string(metric)
      }
      {
        name: 'AUTO_SCALING'
        value: string(autoScaling)
      }
      {
        name: 'CPU_UTILIZATION_PERCENTAGE'
        value: string(cpuUtilizationPercentage)
      }
      {
        name: 'MIN_REPLICAS'
        value: string(minReplicas)
      }
      {
        name: 'MAX_REPLICAS'
        value: string(maxReplicas)
      }
      {
        name: 'REQUEST_CPU_MILLICORE'
        value: string(requestCPUMillicore)
      }
    ]
    arguments: arguments
    primaryScriptUri: uri(const_scriptLocation, 'install.sh${_artifactsLocationSasToken}')
    supportingScriptUris: [
      uri(const_scriptLocation, 'open-liberty-application.yaml.template${_artifactsLocationSasToken}')
      uri(const_scriptLocation, 'open-liberty-application-agic.yaml.template${_artifactsLocationSasToken}')
      uri(const_scriptLocation, 'websphere-liberty-application.yaml.template${_artifactsLocationSasToken}')
      uri(const_scriptLocation, 'websphere-liberty-application-agic.yaml.template${_artifactsLocationSasToken}')
      uri(const_scriptLocation, 'open-liberty-application-autoscaling.yaml.template${_artifactsLocationSasToken}')
      uri(const_scriptLocation, 'open-liberty-application-agic-autoscaling.yaml.template${_artifactsLocationSasToken}')
      uri(const_scriptLocation, 'websphere-liberty-application-autoscaling.yaml.template${_artifactsLocationSasToken}')
      uri(const_scriptLocation, 'websphere-liberty-application-agic-autoscaling.yaml.template${_artifactsLocationSasToken}')
    ]
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
    forceUpdateTag: utcValue
  }
}

output appEndpoint string = (deployApplication && !enableAppGWIngress) ? deploymentScript.properties.outputs.appEndpoint : ''
output appDeploymentYaml string = deploymentScript.properties.outputs.appDeploymentYaml
