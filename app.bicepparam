using './app.bicep'

param name = readEnvironmentVariable('ENV_NAME')
param location = readEnvironmentVariable('LOCATION', 'westus2')
param queueStorageQueues = json(readEnvironmentVariable('QUEUE_STORAGE_QUEUES', '["samplequeue"]'))
param blobStorageContainers = json(readEnvironmentVariable('BLOB_STORAGE_CONTAINER', '["samplecontainer"]'))
param serviceBusQueues = json(readEnvironmentVariable('SERVICE_BUS_QUEUES', '["samplequeue"]'))
param serviceBusTopics = json(readEnvironmentVariable('SERVICE_BUS_TOPICS', '["sampletopic"]'))

param databaseNames = json(readEnvironmentVariable('DATABASES', '["sampledb"]'))
param pgAdmin = readEnvironmentVariable('PG_ADMIN_USER', 'pgadmin')
param pgPassword = readEnvironmentVariable('PG_ADMIN_PASSWORD', 'P@ssw0rd1423$')
param postgresqlSku = {
  skuName: 'Standard_D2ds_v4'
  tier: 'GeneralPurpose'
}
param kvAdminGroupObjectId = readEnvironmentVariable('KV_ADMIN_GROUP_OBJECT_ID')

