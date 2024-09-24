targetScope = 'subscription'


/*
based on this, I would think 
- Azure Queue Storage
- Azure Blog Storage
- Azure Service bus
- Postgres DB 
*/

@minLength(1)
@maxLength(64)
@description('Name which is used to create the resource group and to generate a short unique hash for each resource')
param name string

@minLength(1)
@description('Primary location for all resources')
param location string = deployment().location

@description('array containing the list of blob container')
param blobStorageContainers array 

@description('array containing the list of queue names')
param queueStorageQueues array

@description('array containing the list of servicebus topics')
param serviceBusTopics array

@description('array containing the list of servicebus queues')
param serviceBusQueues array

@description('array containing database names')
param databaseNames array

@description('Postgresql local administrator')
param pgAdmin string

@secure()
@description('Postgresql local administrator password')
param pgPassword string

@description('Posgresql SKU')
param postgresqlSku object

var rgAppName = '${abbrs.resourcesResourceGroups}app-${name}'

@description('Object ID of the Entra ID group that will be granted kv policy')
param kvAdminGroupObjectId string = ''

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgAppName
  location: location
  tags: tags
}


// variables
var abbrs = loadJsonContent('abbreviations.json')
var tags = { 'env-name': name }
var resourceToken = toLower(uniqueString(subscription().id, name, location))
var suffix = '${name}-${resourceToken}'

var blobStorageAccountName = take('${abbrs.storageStorageAccounts}blob${toLower(replace(suffix, '-', ''))}', 24)
var queueStorageAccountName = take('${abbrs.storageStorageAccounts}queue${toLower(replace(suffix, '-', ''))}', 24)
var serviceBusNamespace = '${abbrs.serviceBusNamespaces}${suffix}'
var postgresServerName = '${abbrs.dBforPostgreSQLServers}${suffix}'
var keyVaultName = take('${abbrs.keyVaultVaults}${suffix}', 24)

// storage account with blob storage services and containers provided in parameters
module blobStorage 'br/public:avm/res/storage/storage-account:0.13.2' = {
  scope: rg
  name: 'blob-storage-${resourceToken}'
  params: {
    name: blobStorageAccountName
    publicNetworkAccess: 'Enabled'
    allowBlobPublicAccess: true
    blobServices: {
      containers: [ for name in blobStorageContainers: {
          name: name
        }
      ]
    }
  }
}

// storage account with queue services and queues provided in parameters
module queueStorage 'br/public:avm/res/storage/storage-account:0.13.2' = {
  scope: rg
  name: 'queue-storage-${resourceToken}'
  params: {
    name: queueStorageAccountName
    publicNetworkAccess: 'Enabled'
    allowBlobPublicAccess: true
    queueServices: {
      queues: [for name in queueStorageQueues: {
          metadata: {}
          name: name
        }
      ]
    }
  }
}

// service bus
module serviceBus 'br/public:avm/res/service-bus/namespace:0.9.0' = {
  scope: rg
  name: 'service-bus-${resourceToken}'
  params: {
    name: serviceBusNamespace
    zoneRedundant: false
    disableLocalAuth: false
    skuObject: {
      name: 'Standard'
    }
    topics: [ for name in serviceBusTopics: {
      name: name
      authorizationRules: [
        {
          name: 'RootManageSharedAccessKey'
          rights: [
            'Listen'
            'Manage'
            'Send'
          ]
        }
      ]
    }
    ]
    queues: [ for name in serviceBusQueues: {
      name: name
    }]
  }
}

// postgresql db
module postgreSql 'br/public:avm/res/db-for-postgre-sql/flexible-server:0.3.0' = {
  scope: rg
  name: 'postgresql-flexible-server-${resourceToken}'
  params: {
    name: postgresServerName
    skuName: postgresqlSku.skuName
    tier: postgresqlSku.tier
    geoRedundantBackup: 'Disabled'
    highAvailability: 'Disabled'
    passwordAuth: 'Enabled'
    location: location
    firewallRules: [
      {
        name: 'AllowAll_2024-9-20_18-38-51'
        startIPAddress: '0.0.0.0'
        endIPAddress: '255.255.255.255'
      }
    ]
    storageSizeGB: 128
    databases: [for name in databaseNames: {
        name: name
      }
    ]
    administratorLogin: pgAdmin
    administratorLoginPassword: pgPassword
  }
}

module kv 'br/public:avm/res/key-vault/vault:0.9.0' = {
  scope: rg
  name: 'keyvault-${resourceToken}'
  params: {
    name: keyVaultName
    enableSoftDelete: false
    enableRbacAuthorization: false
    publicNetworkAccess: 'Enabled'
    
    accessPolicies: [
      {
        objectId: kvAdminGroupObjectId
        permissions: {
          secrets: [
            'all'
          ]
          keys: [
            'all'
          ]
          storage: [
            'all'
          ]
          certificates: [
            'all'
          ]
        }
      }
    ]
  }
}

// Outputs
output blobStorageAccountId string = blobStorage.outputs.resourceId
output queueStorageAccountId string = queueStorage.outputs.resourceId
output serviceBusNamespaceId string = serviceBus.outputs.resourceId
output kvId string = kv.outputs.resourceId
