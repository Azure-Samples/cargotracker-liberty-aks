acrName=acrb4ae10
acrUserName=acrb4ae10
acrPassword=33grUwljfzDYiA/0EkbEnyGdcsU0rhmD
acrLoginServer=acrb4ae10.azurecr.io
appNamespaceName=default
appDeploymentTemplateYamlEncoded=IyAgICAgIENvcHlyaWdodCAoYykgTWljcm9zb2Z0IENvcnBvcmF0aW9uLgojIAojICBMaWNlbnNlZCB1bmRlciB0aGUgQXBhY2hlIExpY2Vuc2UsIFZlcnNpb24gMi4wICh0aGUgIkxpY2Vuc2UiKTsKIyAgeW91IG1heSBub3QgdXNlIHRoaXMgZmlsZSBleGNlcHQgaW4gY29tcGxpYW5jZSB3aXRoIHRoZSBMaWNlbnNlLgojICBZb3UgbWF5IG9idGFpbiBhIGNvcHkgb2YgdGhlIExpY2Vuc2UgYXQKIyAKIyAgICAgICAgICAgaHR0cDovL3d3dy5hcGFjaGUub3JnL2xpY2Vuc2VzL0xJQ0VOU0UtMi4wCiMgCiMgIFVubGVzcyByZXF1aXJlZCBieSBhcHBsaWNhYmxlIGxhdyBvciBhZ3JlZWQgdG8gaW4gd3JpdGluZywgc29mdHdhcmUKIyAgZGlzdHJpYnV0ZWQgdW5kZXIgdGhlIExpY2Vuc2UgaXMgZGlzdHJpYnV0ZWQgb24gYW4gIkFTIElTIiBCQVNJUywKIyAgV0lUSE9VVCBXQVJSQU5USUVTIE9SIENPTkRJVElPTlMgT0YgQU5ZIEtJTkQsIGVpdGhlciBleHByZXNzIG9yIGltcGxpZWQuCiMgIFNlZSB0aGUgTGljZW5zZSBmb3IgdGhlIHNwZWNpZmljIGxhbmd1YWdlIGdvdmVybmluZyBwZXJtaXNzaW9ucyBhbmQKIyAgbGltaXRhdGlvbnMgdW5kZXIgdGhlIExpY2Vuc2UuCgphcGlWZXJzaW9uOiBhcHBzLm9wZW5saWJlcnR5LmlvL3YxYmV0YTIKa2luZDogT3BlbkxpYmVydHlBcHBsaWNhdGlvbgptZXRhZGF0YToKICBuYW1lOiAke0FwcGxpY2F0aW9uX05hbWV9CiAgbmFtZXNwYWNlOiBkZWZhdWx0CnNwZWM6CiAgcmVwbGljYXM6IDIKICBhcHBsaWNhdGlvbkltYWdlOiBhY3JiNGFlMTAuYXp1cmVjci5pby8ke0FwcGxpY2F0aW9uX0ltYWdlfQogIHB1bGxQb2xpY3k6IEFsd2F5cwogIHNlcnZpY2U6CiAgICB0eXBlOiBMb2FkQmFsYW5jZXIKICAgIHBvcnQ6IDkwODAK



```
#      Copyright (c) Microsoft Corporation.
# 
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
# 
#           http://www.apache.org/licenses/LICENSE-2.0
# 
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

apiVersion: apps.openliberty.io/v1beta2
kind: OpenLibertyApplication
metadata:
  name: ${Application_Name}
  namespace: default
spec:
  replicas: 2
  applicationImage: acrb4ae10.azurecr.io/${Application_Image}
  pullPolicy: Always
  service:
    type: LoadBalancer
    port: 9080
```

# Database

resource group ejb010212d
server name ejb010212d
admin user name ejb010212d
password Secret123!

```bash
DB_NAME=ejb010212d LOGIN_SERVER=acrb4ae10.azurecr.io REGISTRY_NAME=acrb4ae10 USER_NAME=acrb4ae10 PASSWORD='33grUwljfzDYiA/0EkbEnyGdcsU0rhmD' DB_SERVER_NAME=ejb010212d.postgres.database.azure.com DB_PORT_NUMBER=5432 DB_TYPE=postgres DB_USER=ejb010212d@ejb010212d DB_PASSWORD='Secret123!' NAMESPACE=default mvn clean package -PopenLibertyOnAks

mvn -PopenLibertyOnAks liberty:devc -Ddb.server.name=${DB_SERVER_NAME} -Ddb.port.number=${DB_PORT_NUMBER} -Ddb.name=${DB_NAME} -Ddb.user=${DB_USER} -Ddb.password=${DB_PASSWORD} -Ddockerfile=target/Dockerfile-local
```



```bash
export REGISTRY_NAME=acrb4ae10
export LOGIN_SERVER=${REGISTRY_NAME}.azurecr.io
export USER_NAME=${REGISTRY_NAME}
export PASSWORD=33grUwljfzDYiA/0EkbEnyGdcsU0rhmD
export DB_SERVER_NAME=ejb010212d.postgres.database.azure.com
export DB_PORT_NUMBER=5432
export DB_NAME=postgres
export DB_USER=ejb010212d@ejb010212d
export DB_PASSWORD='Secret123!'
export NAMESPACE=default
export APPLICATIONINSIGHTS_CONNECTION_STRING='InstrumentationKey=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx;IngestionEndpoint=https://eastus-6.in.applicationinsights.azure.com/;LiveEndpoint=https://eastus.livediagnostics.monitor.azure.com/'

echo REGISTRY_NAME=${REGISTRY_NAME}
echo LOGIN_SERVER=${LOGIN_SERVER}
echo USER_NAME=${USER_NAME}
echo PASSWORD=${PASSWORD}
echo DB_SERVER_NAME=${DB_SERVER_NAME}
echo DB_PORT_NUMBER=${DB_PORT_NUMBER}
echo DB_NAME=${DB_NAME}
echo DB_USER=${DB_USER}
echo DB_PASSWORD=${DB_PASSWORD}
echo NAMESPACE=${NAMESPACE}

```
