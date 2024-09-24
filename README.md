
### 1 - Setup environment
- clone repository: 
```bash
git clone https://github.com/demo-az/radius-poc-infra.git
```
- create .env file and adjust values
```bash
# .env file
# Environment settings
ENV_NAME="radius-dapr-poc-1"
LOCATION="westus2"

# AKS - Object id of the EntraId group that will be added as an admin to the AKS cluster
AKS_ADMIN_GROUP_OBJECT_ID="00000000-0000-0000-0000-000000000000"

# Blob Storage Containers
BLOB_STORAGE_CONTAINER_ARRAY=[\"container1\",\"container2\"]

# Queue Storage
QUEUE_STORAGE_QUEUES_ARRAY=[\"queue-a\",\"queue-b\"]

# Service bus
SERVICE_BUS_TOPICS=[\"topic-a\",\"topic-b\"]
SERVICE_BUS_QUEUES=[\"queue-a\",\"queue-b\"]

# Postgresql
DATABASES=[\"database-1\",\"database-2\"]
PG_ADMIN_USER="pgadmin"
PG_ADMIN_PASSWORD="xxxxxxxxx"
```	
```bash
# Load environment variables from .env file
export $(<.env grep -v "^#" | xargs)
```
### 2 - provision AKS and ACR
```bash
# Deploy AKS and ACR
export $(<.env grep -v "^#" | xargs)
az deployment sub create -l $LOCATION -f aks.bicep -p  aks.bicepparam -n radius-poc-aks-1
```
### 3 - provision App backend services
Includes the following services:
- Azure Blob Storage account + container(s)
- Azure Queue Storage account + queue(s)
- Azure Service Bus Namespace + queue(s) + topic(s)
- Azure PosgreSQL Flexible Server + database(s)


```bash
# Deploy Radius application backend services
az deployment sub create -l $LOCATION -f app.bicep -p  app.bicepparam -n radius-poc-app-1
```

### 4 - Export secrets and other variables to dotenv file and export all variables

```bash
# Export environment variables (secrets, connection strings, resources ids, etc.) to dotenv file
az deployment sub create -l $LOCATION -f get-secrets.bicep -p  get-secrets.bicepparam -n radius-poc-get-secrets-1 --query properties.outputs.my_secrets.value -o tsv > ${ENV_NAME:-default}.env
export $(<${ENV_NAME:-default}.env grep -v "^#" | xargs)
```


### 5 - configure ACR integration with AKS cluster
Prerequisites:
- kubectl
- kubelogin (to learn more, please go to: https://aka.ms/aks/kubelogin)

These executables can be installed with Azure CLI:
```bash
az aks install-cli
```


```bash

# attach ACR to AKS
# native integration using 'az aks update -n $AKS_CLUSTER_NAME -g $RG_AKS --attach-acr $ACR_NAME' is not possible due to missing RBAC permissions
# a service account with secret for ACR will be used instead

# get aks credentials 
az aks get-credentials -n $AKS_CLUSTER_NAME -g $RG_AKS

# check selected context
kubectl config get-contexts

# create a service account that will be used to pull images from ACR
kubectl create serviceaccount acr-service-account

# create secret for the service account
kubectl create secret docker-registry acr-secret --docker-server=$ACR_LOGIN_SERVER --docker-username=$ACR_USER --docker-password=$ACR_PASSWORD --docker-email=notused@ignorethis.com

# Bind the service account to the secret
kubectl patch serviceaccount acr-service-account -p '{"imagePullSecrets": [{"name": "acr-secret"}]}'


```


### 6 - Test integration
```bash

# import image from docker hub to ACR
az acr import --name $ACR_NAME --source docker.io/library/nginx:latest --image nginx:v1

# create deployment
envsubst < test-app.yaml  | kubectl apply -f -

# check deployment to confirm that pods are running
kubectl get all

# delete deployment
kubectl delete deployment.apps/nginx0-deployment
