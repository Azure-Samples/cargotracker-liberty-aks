targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('The base URL for artifacts')
param _artifactsLocation string = 'https://raw.githubusercontent.com/WASdev/azure.liberty.aks/048e776e9efe2ffed8368812e198c1007ba94b2c/src/main/'

@description('Whether to create a new AKS cluster')
param createCluster bool = true

@description('The VM size for AKS nodes')
param vmSize string = 'Standard_DS2_v2'

@description('The minimum node count for AKS cluster')
param minCount int = 1

@description('The maximum node count for AKS cluster')
param maxCount int = 5

@description('Whether to create Azure Container Registry')
param createACR bool = true

@description('Whether to deploy the application')
param deployApplication bool = false

@description('Whether to enable Application Gateway Ingress')
param enableAppGWIngress bool = true

@description('The certificate option for Application Gateway')
param appGatewayCertificateOption string = 'generateCert'

@description('Whether to enable cookie-based affinity')
param enableCookieBasedAffinity bool = true

@description('Server administrator login name')
@secure()
param administratorLogin string = 'azureroot'

@description('Server administrator password')
@secure()
param administratorLoginPassword string

// Tags that should be applied to all resources.
//
// Note that 'azd-service-name' tags should be applied separately to service host resources.
// Example usage:
//   tags: union(tags, { 'azd-service-name': <service name in azure.yaml> })
var tags = {
  'azd-env-name': environmentName
}

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var suffix = take(resourceToken, 6)

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-${environmentName}-${take(resourceToken, 6)}'
  location: location
  tags: tags
}

module openLibertyOnAks './azure.liberty.aks/mainTemplate.bicep' = {
  name: 'openliberty-on-aks'
  params: {
        _artifactsLocation: _artifactsLocation
        location: location
        createCluster: createCluster
        vmSize: vmSize
        minCount: minCount
        maxCount: maxCount
        createACR: createACR
        deployApplication: deployApplication
        enableAppGWIngress: enableAppGWIngress
        appGatewayCertificateOption: appGatewayCertificateOption
        enableCookieBasedAffinity: enableCookieBasedAffinity
  }
   scope: rg
}

module monitoring './shared/monitoring.bicep' = {
 name: 'monitoring'
 params: {
   location: location
   tags: tags
   logAnalyticsName: '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
   applicationInsightsName: '${abbrs.insightsComponents}${resourceToken}'
 }
 scope: rg
}

output ACRPassword string = openLibertyOnAks.outputs.acrPassword
output ACRServer string = openLibertyOnAks.outputs.acrServerName
output ACRUserName string = openLibertyOnAks.outputs.acrUsername
output AZURE_AKS_CLUSTER_NAME string = openLibertyOnAks.outputs.clusterName
output AZURE_REGISTRY_NAME string = openLibertyOnAks.outputs.acrServerName
output AZURE_RESOURCE_GROUP string = rg.name
output DB_NAME string = 'liberty-db-${suffix}'
output DB_RESOURCE_NAME string = 'liberty-server-${suffix}'
output DB_USER_NAME string = administratorLogin
output DB_USER_PASSWORD string = administratorLoginPassword
output LOCATION string = location
output RESOURCE_GROUP_NAME string = rg.name
output WORKSPACE_ID string = monitoring.outputs.logAnalyticsWorkspaceId
output APP_INSIGHTS_CONNECTION_STRING string = monitoring.outputs.appInsightsConnectionString
