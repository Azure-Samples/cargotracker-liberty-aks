#!/bin/bash

az extension add --upgrade -n application-insights
source .scripts/setup-env-variables-template.sh

mkdir tmp-build
DIR=$(pwd)/tmp-build
echo "Current directory: $DIR"

cd ${DIR}
git clone https://github.com/WASdev/azure.liberty.aks ${DIR}/azure.liberty.aks

cd ${DIR}/azure.liberty.aks
git checkout ${LIBERTY_AKS_REPO_REF}
export VERSION=$(grep -A4 "<parent>" pom.xml | grep "<version>" | awk -F'[<>]' '{print $3}')

cd ${DIR}
curl -L -o ${DIR}/azure-javaee-iaas-parent-${VERSION}.pom  \
     https://github.com/azure-javaee/azure-javaee-iaas/releases/download/azure-javaee-iaas-parent-${VERSION}/azure-javaee-iaas-parent-${VERSION}.pom


mvn install:install-file -Dfile=${DIR}/azure-javaee-iaas-parent-${VERSION}.pom \
                         -DgroupId=com.microsoft.azure.iaas \
                         -DartifactId=azure-javaee-iaas-parent \
                         -Dversion=${VERSION} \
                         -Dpackaging=pom

cd ${DIR}/azure.liberty.aks
mvn clean package -DskipTests

mkdir -p ${DIR}/../infra/azure.liberty.aks
cp -r ${DIR}/azure.liberty.aks/target/bicep/* ${DIR}/../infra/azure.liberty.aks

# shell sleep 5 seconds
sleep 5

rm -rf ${DIR}
