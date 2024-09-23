using './get-secrets.bicep'

param name = readEnvironmentVariable('ENV_NAME')
param location = readEnvironmentVariable('LOCATION', 'westus2')
param pgAdmin = readEnvironmentVariable('PG_ADMIN_USER', 'pgadmin')
param pgPassword = readEnvironmentVariable('PG_ADMIN_PASSWORD', 'P@ssw0rd1423$')

