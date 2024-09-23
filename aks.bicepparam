using './aks.bicep'

param name = readEnvironmentVariable('ENV_NAME')
param location = readEnvironmentVariable('LOCATION', 'westus2')
param aksAdminGroupObjectId = readEnvironmentVariable('AKS_ADMIN_GROUP_OBJECT_ID')


