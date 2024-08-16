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

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param _artifactsLocation string = deployment().properties.templateLink.uri

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated. Use the defaultValue if the staging location is not secured.')
@secure()
param _artifactsLocationSasToken string = ''

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Flag indicating whether to create a new cluster or not')
param createCluster bool = true

@description('The VM size of the cluster')
param vmSize string = 'Standard_DS2_v2'

@description('The minimum node count of the cluster')
param minCount int = 1

@description('The maximum node count of the cluster')
param maxCount int = 5

@description('Name for the existing cluster')
param clusterName string = ''

@description('Name for the resource group of the existing cluster')
param clusterRGName string = ''

@description('Flag indicating whether to create a new ACR or not')
param createACR bool = true

@description('Name for the existing ACR')
param acrName string = ''

@description('Name for the resource group of the existing ACR')
param acrRGName string = ''

@description('true to set up Application Gateway ingress.')
param enableAppGWIngress bool = false

@description('VNET for Application Gateway.')
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
@description('To mitigate ARM-TTK error: Control Named vnetForApplicationGateway must output the newOrExisting property when hideExisting is false')
param newOrExistingVnetForApplicationGateway string = 'new'
@description('To mitigate ARM-TTK error: Control Named vnetForApplicationGateway must output the resourceGroup property when hideExisting is false')
param vnetRGNameForApplicationGateway string = 'vnet-contoso-rg-name'
@description('If true, configure Azure Application Gateway frontend IP with private IP.')
param appgwUsePrivateIP bool = false

@description('DNS prefix for ApplicationGateway')
param dnsNameforApplicationGateway string = 'olgw'

@allowed([
  'haveCert'
  'haveKeyVault'
  'generateCert'
])
@description('Three scenarios we support for deploying app gateway')
param appGatewayCertificateOption string = 'haveCert'

@description('Public IP Name for the Application Gateway')
param appGatewayPublicIPAddressName string = 'gwip'

@secure()
@description('The one-line, base64 string of the SSL certificate data.')
param appGatewaySSLCertData string = newGuid()

@secure()
@description('The value of the password for the SSL Certificate')
param appGatewaySSLCertPassword string = newGuid()

@description('Resource group name in current subscription containing the KeyVault')
param keyVaultResourceGroup string = 'kv-contoso-rg'

@description('Existing Key Vault Name')
param keyVaultName string = 'kv-contoso'

@description('Price tier for Key Vault.')
param keyVaultSku string = 'Standard'

@description('The name of the secret in the specified KeyVault whose value is the SSL Certificate Data for Appliation Gateway frontend TLS/SSL.')
param keyVaultSSLCertDataSecretName string = 'kv-ssl-data'

@description('The name of the secret in the specified KeyVault whose value is the password for the SSL Certificate of Appliation Gateway frontend TLS/SSL')
param keyVaultSSLCertPasswordSecretName string = 'kv-ssl-psw'

@description('true to enable cookie based affinity.')
param enableCookieBasedAffinity bool = false

@description('Flag indicating whether to deploy WebSphere Liberty Operator.')
param deployWLO bool = false

@allowed([
  'IBM WebSphere Application Server'
  'IBM WebSphere Application Server Liberty Core'
  'IBM WebSphere Application Server Network Deployment'
])
@description('Product edition')
param edition string = 'IBM WebSphere Application Server'

@allowed([
  'Standalone'
  'IBM WebSphere Hybrid Edition'
  'IBM Cloud Pak for Applications'
  'IBM WebSphere Application Server Family Edition'
])
@description('Entitlement source for the product')
param productEntitlementSource string = 'Standalone'

@description('Flag indicating whether to deploy an application')
param deployApplication bool = false

@description('The image path of the application')
param appImagePath string = ''

@description('The number of application replicas to deploy')
param appReplicas int = 2

@description('Flag indicating whether to enable autoscaling for app deployment')
param autoScaling bool = false

@description('The target average CPU utilization percentage for autoscaling')
param cpuUtilizationPercentage int = 80

@description('The minimum application replicas for autoscaling')
param minReplicas int = 1

@description('The maximum application replicas for autoscaling')
param maxReplicas int = 100

@description('The minimum required CPU core (millicore) over all the replicas for autoscaling')
param requestCPUMillicore int = 300

// TODo Updated
// param guidValue string = take(uniqueString(subscription().id, environmentName, location), 6)
param guidValue string = newGuid()

var const_acrRGName = (createACR ? resourceGroup().name : acrRGName)
var const_appGatewaySSLCertOptionHaveCert = 'haveCert'
var const_appGatewaySSLCertOptionHaveKeyVault = 'haveKeyVault'
var const_appFrontendTlsSecretName = format('secret{0}', guidValue)
var const_appImage = format('{0}:{1}', const_appImageName, const_appImageTag)
var const_appImageName = format('image{0}', guidValue)
var const_appImagePath = (empty(appImagePath) ? 'NA' : ((const_appImagePathLen == 1) ? format('docker.io/library/{0}', appImagePath) : ((const_appImagePathLen == 2) ? format('docker.io/{0}', appImagePath) : appImagePath)))
var const_appImagePathLen = length(split(appImagePath, '/'))
var const_appImageTag = '1.0.0'
var const_appName = format('app{0}', guidValue)
var const_appProjName = 'default'
var const_arguments = format('{0} {1} {2} {3} {4} {5} {6} {7} {8}', const_clusterRGName, name_clusterName, name_acrName, deployApplication, const_appImagePath, const_appName, const_appProjName, const_appImage, appReplicas)
var const_azureSubjectName = format('{0}.{1}.{2}', name_dnsNameforApplicationGateway, location, 'cloudapp.azure.com')
var const_clusterRGName = (createCluster ? resourceGroup().name : clusterRGName)
var const_cmdToGetAcrLoginServer = format('az acr show -n {0} --query loginServer -o tsv', name_acrName)
var const_metric = productEntitlementSource == 'Standalone' || productEntitlementSource == 'IBM WebSphere Application Server Family Edition' ? 'Processor Value Unit (PVU)' : 'Virtual Processor Core (VPC)'
var const_newVnet = (vnetForApplicationGateway.newOrExisting == 'new') ? true : false
var name_acrName = createACR ? format('acr{0}', guidValue) : acrName
var name_appGatewayPublicIPAddressName = format('{0}{1}', appGatewayPublicIPAddressName, guidValue)
var name_clusterName = createCluster ? format('cluster{0}', guidValue) : clusterName
var name_dnsNameforApplicationGateway = format('{0}{1}', dnsNameforApplicationGateway, guidValue)
var name_keyVaultName = format('keyvault{0}', guidValue)
var name_prefilghtDsName = format('preflightds{0}', guidValue)
var name_primaryDsName = format('primaryds{0}', guidValue)
var name_subnet = vnetForApplicationGateway.subnets.gatewaySubnet.name
var name_vnet = vnetForApplicationGateway.name
var ref_subId = const_newVnet ? resourceId('Microsoft.Network/virtualNetworks/subnets', name_vnet, name_subnet) : existingSubnet.id

var obj_uamiForDeploymentScript = {
  type: 'UserAssigned'
  userAssignedIdentities: {
    '${uamiDeployment.outputs.uamiIdForDeploymentScript}': {}
  }
}

// Workaround arm-ttk test "Parameter Types Should Be Consistent"
var _appgwUsePrivateIP = appgwUsePrivateIP
var _appGatewaySubnetStartAddress = vnetForApplicationGateway.subnets.gatewaySubnet.startAddress
var _enableAppGWIngress = enableAppGWIngress
var _useExistingAppGatewaySSLCertificate = appGatewayCertificateOption == const_appGatewaySSLCertOptionHaveCert

module partnerCenterPid './modules/_pids/_empty.bicep' = {
  name: 'pid-68a0b448-a573-4012-ab25-d5dc9842063e-partnercenter'
  params: {}
}

module uamiDeployment 'modules/_uamiAndRoles.bicep' = {
  name: 'uami-deployment'
  params: {
    location: location
  }
}

module aksStartPid './modules/_pids/_empty.bicep' = {
  name: '628cae16-c133-5a2e-ae93-2b44748012fe'
  params: {}
}

module preflightDsDeployment 'modules/_deployment-scripts/_ds-preflight.bicep' = {
  name: name_prefilghtDsName
  params: {
    name: name_prefilghtDsName
    location: location
    _artifactsLocation: _artifactsLocation
    _artifactsLocationSasToken: _artifactsLocationSasToken
    identity: obj_uamiForDeploymentScript
    createCluster: createCluster
    aksClusterName: name_clusterName
    aksClusterRGName: const_clusterRGName
    enableAppGWIngress: enableAppGWIngress
    vnetForApplicationGateway: vnetForApplicationGateway
    appGatewayCertificateOption: appGatewayCertificateOption
    keyVaultName: keyVaultName
    keyVaultResourceGroup: keyVaultResourceGroup
    keyVaultSSLCertDataSecretName: keyVaultSSLCertDataSecretName
    keyVaultSSLCertPasswordSecretName: keyVaultSSLCertPasswordSecretName
    appGatewaySSLCertData: appGatewaySSLCertData
    appGatewaySSLCertPassword: appGatewaySSLCertPassword
    vmSize: vmSize
    deployApplication: deployApplication
    sourceImagePath: const_appImagePath
  }
  dependsOn: [
    uamiDeployment
  ]
}

resource acrDeployment 'Microsoft.ContainerRegistry/registries@2023-07-01' = if (createACR) {
  name: name_acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
  dependsOn: [
    preflightDsDeployment
  ]
}

// Get existing VNET
resource existingVnet 'Microsoft.Network/virtualNetworks@2023-11-01' existing = if (enableAppGWIngress && !const_newVnet) {
  name: name_vnet
  scope: resourceGroup(vnetForApplicationGateway.resourceGroup)
}

// Get existing subnet
resource existingSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' existing = if (enableAppGWIngress && !const_newVnet) {
  name: name_subnet
  parent: existingVnet
}

// To void space overlap with AKS Vnet, must deploy the Applciation Gateway VNet before AKS deployment
module vnetForAppgatewayDeployment 'modules/_azure-resoruces/_vnetAppGateway.bicep' = if (enableAppGWIngress) {
  name: 'vnet-application-gateway'
  params: {
    location: location
    nameSuffix: guidValue
    newOrExistingVnetForApplicationGateway: newOrExistingVnetForApplicationGateway
    vnetForApplicationGateway: vnetForApplicationGateway
    vnetRGNameForApplicationGateway: vnetRGNameForApplicationGateway
  }
  dependsOn: [
    preflightDsDeployment
  ]
}

resource clusterDeployment 'Microsoft.ContainerService/managedClusters@2023-08-01' = if (createCluster) {
  name: name_clusterName
  location: location
  properties: {
    enableRBAC: true
    dnsPrefix: format('{0}-dns', name_clusterName)
    agentPoolProfiles: [
      {
        name: 'agentpool'
        osDiskSizeGB: 0
        enableAutoScaling: true
        minCount: minCount
        maxCount: maxCount
        count: minCount
        vmSize: vmSize
        osType: 'Linux'
        type: 'VirtualMachineScaleSets'
        mode: 'System'
        availabilityZones: preflightDsDeployment.outputs.aksAgentAvailabilityZones
      }
    ]
    networkProfile: {
      loadBalancerSku: 'standard'
      networkPlugin: 'kubenet'
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
  dependsOn: [
    acrDeployment
    vnetForAppgatewayDeployment
  ]
}

module acrPullRoleAssignment 'modules/_rolesAssignment/_acrPullRoleAssignment.bicep' = {
  name: 'assign-acrpull-role-to-kubelet-identity'
  scope: resourceGroup(const_acrRGName)
  params: {
    aksClusterName: name_clusterName
    aksClusterRGName: const_clusterRGName
    acrName: name_acrName
    acrRGName: const_acrRGName
  }
  dependsOn: [
    clusterDeployment
  ]
}

module appgwStartPid './modules/_pids/_empty.bicep' = if (enableAppGWIngress) {
  name: '43c417c4-4f5a-555e-a9ba-b2d01d88de1f'
  params: {}
  dependsOn: [
    acrPullRoleAssignment
  ]
}

module appgwSecretDeployment 'modules/_azure-resoruces/_keyvaultForGateway.bicep' = if (enableAppGWIngress && (appGatewayCertificateOption != const_appGatewaySSLCertOptionHaveKeyVault)) {
  name: 'appgateway-certificates-secrets-deployment'
  params: {
    certificateDataValue: appGatewaySSLCertData
    certificatePasswordValue: appGatewaySSLCertPassword
    identity: obj_uamiForDeploymentScript
    location: location
    sku: keyVaultSku
    subjectName: format('CN={0}', const_azureSubjectName)
    useExistingAppGatewaySSLCertificate: _useExistingAppGatewaySSLCertificate
    keyVaultName: name_keyVaultName
  }
  dependsOn: [
    appgwStartPid
  ]
}

// get key vault object in a resource group
resource existingKeyvault 'Microsoft.KeyVault/vaults@2023-07-01' existing = if (enableAppGWIngress) {
  name: (!enableAppGWIngress || appGatewayCertificateOption == const_appGatewaySSLCertOptionHaveKeyVault) ? keyVaultName : appgwSecretDeployment.outputs.keyVaultName
  scope: resourceGroup(appGatewayCertificateOption == const_appGatewaySSLCertOptionHaveKeyVault ? keyVaultResourceGroup : resourceGroup().name)
}

module queryPrivateIPFromSubnet 'modules/_deployment-scripts/_ds_query_available_private_ip_from_subnet.bicep' = if (enableAppGWIngress && appgwUsePrivateIP) {
  name: 'query-available-private-ip-for-app-gateway'
  params: {
    _artifactsLocation: _artifactsLocation
    _artifactsLocationSasToken: _artifactsLocationSasToken
    identity: obj_uamiForDeploymentScript
    location: location
    subnetId: ref_subId

    knownIP: _appGatewaySubnetStartAddress
  }
  dependsOn: [
    vnetForAppgatewayDeployment
  ]
}

module appgwDeployment 'modules/_azure-resoruces/_appgateway.bicep' = if (enableAppGWIngress) {
  name: 'app-gateway-deployment'
  params: {
    dnsNameforApplicationGateway: name_dnsNameforApplicationGateway
    gatewayPublicIPAddressName: name_appGatewayPublicIPAddressName
    nameSuffix: guidValue
    location: location
    gatewaySubnetId: ref_subId
    staticPrivateFrontentIP: _appgwUsePrivateIP ? queryPrivateIPFromSubnet.outputs.privateIP : ''
    usePrivateIP: appgwUsePrivateIP
  }
  dependsOn: [
    appgwStartPid
    queryPrivateIPFromSubnet
  ]
}

module enableAgic 'modules/_deployment-scripts/_ds_enable_agic.bicep' = if (enableAppGWIngress) {
  name: 'enable-agic'
  params: {
    _artifactsLocation: _artifactsLocation
    _artifactsLocationSasToken: _artifactsLocationSasToken
    location: location

    identity: obj_uamiForDeploymentScript

    aksClusterName: name_clusterName
    aksClusterRGName: const_clusterRGName
    appgwName: _enableAppGWIngress ? appgwDeployment.outputs.appGatewayName : ''
  }
  dependsOn: [
    appgwDeployment
  ]
}

module agicRoleAssignment 'modules/_rolesAssignment/_agicRoleAssignment.bicep' = if (enableAppGWIngress) {
  name: 'allow-agic-access-current-resource-group'
  params: {
    aksClusterName: name_clusterName
    aksClusterRGName: const_clusterRGName
  }
  dependsOn: [
    enableAgic
  ]
}

module networkingDeployment 'modules/_deployment-scripts/_ds-networking.bicep' = if (enableAppGWIngress) {
  name: 'networking-deployment'
  params: {
    _artifactsLocation: _artifactsLocation
    _artifactsLocationSasToken: _artifactsLocationSasToken
    location: location

    identity: obj_uamiForDeploymentScript

    appgwCertificateOption: appGatewayCertificateOption
    appgwFrontendSSLCertData: existingKeyvault.getSecret((!enableAppGWIngress || appGatewayCertificateOption == const_appGatewaySSLCertOptionHaveKeyVault) ? keyVaultSSLCertDataSecretName : appgwSecretDeployment.outputs.sslCertDataSecretName)
    appgwFrontendSSLCertPsw: existingKeyvault.getSecret((!enableAppGWIngress || appGatewayCertificateOption == const_appGatewaySSLCertOptionHaveKeyVault) ? keyVaultSSLCertPasswordSecretName : appgwSecretDeployment.outputs.sslCertPwdSecretName)

    appgwName: _enableAppGWIngress ? appgwDeployment.outputs.appGatewayName : ''

    aksClusterRGName: const_clusterRGName
    aksClusterName: name_clusterName
    appFrontendTlsSecretName: const_appFrontendTlsSecretName
    appProjName: const_appProjName
  }
  dependsOn: [
    appgwSecretDeployment
    agicRoleAssignment
  ]
}

module appgwEndPid './modules/_pids/_empty.bicep' = if (enableAppGWIngress) {
  name: 'dfa75d32-05de-5635-9833-b004cabcd378'
  params: {}
  dependsOn: [
    networkingDeployment
  ]
}

module primaryDsDeployment 'modules/_deployment-scripts/_ds-primary.bicep' = {
  name: name_primaryDsName
  params: {
    name: name_primaryDsName
    location: location
    _artifactsLocation: _artifactsLocation
    _artifactsLocationSasToken: _artifactsLocationSasToken
    identity: obj_uamiForDeploymentScript
    arguments: const_arguments
    acrRGName: const_acrRGName
    deployWLO: deployWLO
    edition: edition
    productEntitlementSource: productEntitlementSource
    metric: const_metric
    deployApplication: deployApplication
    enableAppGWIngress: enableAppGWIngress
    appFrontendTlsSecretName: const_appFrontendTlsSecretName
    enableCookieBasedAffinity: enableCookieBasedAffinity
    appgwUsePrivateIP: appgwUsePrivateIP
    autoScaling: autoScaling
    cpuUtilizationPercentage: cpuUtilizationPercentage
    minReplicas: minReplicas
    maxReplicas: maxReplicas
    requestCPUMillicore: requestCPUMillicore
  }
  dependsOn: [
    acrPullRoleAssignment
    appgwEndPid
  ]
}

module aksEndPid './modules/_pids/_empty.bicep' = {
  name: '59f5f6da-0a6d-587d-b23c-177108cd8bbf'
  params: {}
  dependsOn: [
    primaryDsDeployment
  ]
}

module autoscalingPid './modules/_pids/_empty.bicep' = if (deployApplication && autoScaling) {
  name: '7a4e4f27-dcea-5207-86ed-e7c7de1ccd34'
  params: {}
  dependsOn: [
    aksEndPid
  ]
}

output appHttpEndpoint string = deployApplication ? (enableAppGWIngress ? appgwDeployment.outputs.appGatewayURL : primaryDsDeployment.outputs.appEndpoint ) : ''
output appHttpsEndpoint string = deployApplication && enableAppGWIngress ? appgwDeployment.outputs.appGatewaySecuredURL : ''
output clusterName string = name_clusterName
output clusterRGName string = const_clusterRGName
output acrName string = name_acrName
output cmdToGetAcrLoginServer string = const_cmdToGetAcrLoginServer
output appNamespaceName string = const_appProjName
output appName string = deployApplication ? const_appName : ''
output appImage string = deployApplication ? const_appImage : ''
output cmdToConnectToCluster string = format('az aks get-credentials -g {0} -n {1} --admin', const_clusterRGName, name_clusterName)
output cmdToGetAppInstance string = deployApplication ? format('kubectl get openlibertyapplication {0}', const_appName) : ''
output cmdToGetAppDeployment string = deployApplication ? format('kubectl get deployment {0}', const_appName) : ''
output cmdToGetAppPods string = deployApplication ? 'kubectl get pod' : ''
output cmdToGetAppService string = deployApplication ? format('kubectl get service {0}', const_appName) : ''
output cmdToLoginInRegistry string = format('az acr login -n {0}', name_acrName)
output cmdToPullImageFromRegistry string = deployApplication ? format('docker pull $({0})/{1}', const_cmdToGetAcrLoginServer, const_appImage) : ''
output cmdToTagImageWithRegistry string = format('docker tag <source-image-path> $({0})/<target-image-name:tag>', const_cmdToGetAcrLoginServer)
output cmdToPushImageToRegistry string = format('docker push $({0})/<target-image-name:tag>', const_cmdToGetAcrLoginServer)
output appDeploymentYaml string = deployApplication? format('echo "{0}" | base64 -d', primaryDsDeployment.outputs.appDeploymentYaml) : ''
output appDeploymentTemplateYaml string =  !deployApplication ? format('echo "{0}" | base64 -d', primaryDsDeployment.outputs.appDeploymentYaml) : ''
output cmdToUpdateOrCreateApplication string = 'kubectl apply -f <application-yaml-file-path>'
