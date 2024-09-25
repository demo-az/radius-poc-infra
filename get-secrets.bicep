targetScope = 'subscription'

@description('Name which is used to create the resource group and to generate a short unique hash for each resource')
param name string

@minLength(1)
@description('Primary location for all resources')
param location string = deployment().location

@description('Postgresql local administrator')
param pgAdmin string

@secure()
@description('Postgresql local administrator password')
param pgPassword string


var abbrs = loadJsonContent('abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, name, location))
var suffix = '${name}-${resourceToken}'

var rgAppName = '${abbrs.resourcesResourceGroups}app-${name}'
var rgAksName = '${abbrs.resourcesResourceGroups}aks-${name}'
var blobStorageAccountName = take('${abbrs.storageStorageAccounts}blob${toLower(replace(suffix, '-', ''))}', 24)
var queueStorageAccountName = take('${abbrs.storageStorageAccounts}queue${toLower(replace(suffix, '-', ''))}', 24)
var serviceBusNamespace = '${abbrs.serviceBusNamespaces}${suffix}'
var postgresServerName = '${abbrs.dBforPostgreSQLServers}${suffix}'
var appConfigStoreName = '${abbrs.appConfigurationStores}${suffix}'


var aksClusterName = '${abbrs.containerServiceManagedClusters}${suffix}'
var acrName = take('${abbrs.containerRegistryRegistries}${toLower(replace(suffix, '-', ''))}${resourceToken}', 50)

resource rgApp 'Microsoft.Resources/resourceGroups@2024-07-01' existing = {
  name: rgAppName
}

resource rgAks 'Microsoft.Resources/resourceGroups@2024-07-01' existing = {
  name: rgAksName
}

resource aksCluster 'Microsoft.ContainerService/managedClusters@2024-07-01' existing = {
  scope: rgAks
  name: aksClusterName
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' existing = {
  scope: rgAks
  name: acrName
}

resource blobStorage 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  scope: rgApp
  name: blobStorageAccountName
}

resource queueStorage 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  scope: rgApp
  name: queueStorageAccountName
}

resource serviceBus 'Microsoft.ServiceBus/namespaces@2023-01-01-preview' existing = {
  scope: rgApp
  name: serviceBusNamespace
}

resource serviceBusAuthorizationRule 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2023-01-01-preview' existing = {
  parent: serviceBus
  name: 'RootManageSharedAccessKey'
}


resource pgServer 'Microsoft.DBforPostgreSQL/flexibleServers@2024-03-01-preview' existing = {
  scope: rgApp
  name: postgresServerName
}

resource appConfigStore 'Microsoft.AppConfiguration/configurationStores@2023-09-01-preview' existing = {
  scope: rgApp
  name: appConfigStoreName
}

var blobStorageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${blobStorage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${blobStorage.listKeys().keys[0].value}'
var queueStorageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${queueStorage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${queueStorage.listKeys().keys[0].value}'
var serviceBusConnectionString = serviceBusAuthorizationRule.listKeys().primaryConnectionString
var appConfigStoreConnectionString = appConfigStore.listKeys().value[0].connectionString


output my_secrets array = [
  '# Azure subscriptions and resource groups'
  'SUBSCRIPTION_ID=${subscription().id}'
  'RG_AKS=${rgAks.name}'
  'RG_APP=${rgApp.name}'
  'ACR_LOGIN_SERVER=${acr.properties.loginServer}'
  'ACR_USER=${acr.listCredentials().username}'
  'ACR_PASSWORD=${acr.listCredentials().passwords[0].value}'

  '# aks and acr'
  'AKS_CLUSTER_NAME="${aksCluster.name}"'
  'ACR_NAME="${acr.name}"'

  ''
  '# blob storage'
  'BLOB_STORAGE_ID="${blobStorage.id}"'
  'BLOB_STORAGE_NAME="${blobStorage.name}"'
  'BLOB_STORAGE_CONNECTION_STRING="${blobStorageConnectionString}"'
  ''
  '# queue storage'
  'QUEUE_STORAGE_ID="${queueStorage.id}"'
  'QUEUE_STORAGE_NAME="${queueStorage.name}"'
  'QUEUE_STORAGE_CONNECTION_STRING="${queueStorageConnectionString}"'
  ''
  '# Service Bus'
  'SERVICE_BUS_ID="${serviceBus.id}"'
  'SERVICE_BUS_CONNECTION_STRING=${serviceBusConnectionString}'
  ''
  '# Postgresql'
  'PG_SERVER_ID="${pgServer.id}"'
  'PG_ADMIN=${pgAdmin}'
  'PG_PASSWORD=${pgPassword}'
  ''
  '# appConfigStore'
  'APP_CONFIG_STORE_CONNECTION_STRING=${appConfigStoreConnectionString}'
]

// output AKS_CLUSTER_ID string = aksCluster.id
// output BLOB_STORAGE_ID string = blobStorage.id
// output BLOB_STORAGE_SUBSCRIPTION_KEY string = blobStorage.listKeys().keys[0].value
// output BLOB_STORAGE_CONNECTION_STRING string = 'DefaultEndpointsProtocol=https;AccountName=${blobStorage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${blobStorage.listKeys().keys[0].value}'
// output QUEUE_STORAGE_ID string = queueStorage.id
// output SERVICE_BUS_ID string = serviceBus.id
// output PG_SERVER_ID string = pgServer.id
