targetScope = 'subscription'


/*
aks cluster
*/

@minLength(5)
@maxLength(64)
@description('Name which is used to create the resource group and to generate a short unique hash for each resource')
param name string

@minLength(1)
@description('Primary location for all resources')
param location string = deployment().location

@description('Object ID of the Entra ID group containing aks admins')
param aksAdminGroupObjectId string = ''


resource rgAks 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: '${abbrs.resourcesResourceGroups}aks-${name}'
  location: location
  tags: tags
}


// variables
var abbrs = loadJsonContent('abbreviations.json')
var tags = { 'env-name': name }
var resourceToken = toLower(uniqueString(subscription().id, name, location))
var suffix = '${name}-${resourceToken}'

var aksClusterName = '${abbrs.containerServiceManagedClusters}${suffix}'
var acrName = take('${abbrs.containerRegistryRegistries}${toLower(replace(suffix, '-', ''))}${resourceToken}', 50)


module registry 'br/public:avm/res/container-registry/registry:0.5.1' = {
  scope: rgAks
  name: 'registryDeployment'
  params: {
    // Required parameters
    name: acrName
    // Non-required parameters
    acrSku: 'Standard'
    location: location
    acrAdminUserEnabled: true
  }
}

module aks 'br/public:avm/res/container-service/managed-cluster:0.3.0' = {
  scope: rgAks
  name: 'aks-cluster-${resourceToken}'
  params: {
    name: aksClusterName
    enableRBAC: true
    aadProfileManaged: true
    aadProfileEnableAzureRBAC: false
    disableLocalAccounts: false
    aadProfileAdminGroupObjectIDs: [
      aksAdminGroupObjectId
    ]
    primaryAgentPoolProfile: [
      {
        count: 1
        mode: 'System'
        name: 'systempool'
        vmSize: 'Standard_DS2_v2'
      }
    ]
    managedIdentities: {
      systemAssigned: true
    }
    publicNetworkAccess: 'Enabled'
  }
}

// Outputs
output aksId string = aks.outputs.resourceId
output acrId string = registry.outputs.resourceId
