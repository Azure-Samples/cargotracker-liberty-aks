#!/bin/bash

# Build and push docker image to ACR
echo "Get image name and version......"

run_maven_command() {
    mvn -q -Dexec.executable=echo -Dexec.args="$1" --non-recursive exec:exec 2>/dev/null | sed -e 's/\x1b\[[0-9;]*m//g' | tr -d '\r\n'
}

IMAGE_NAME=$(run_maven_command '${project.artifactId}')
IMAGE_VERSION=$(run_maven_command '${project.version}')

echo "Build image and upload"

mvn clean package -DskipTests
cd target
echo "docker build"
docker build -t ${IMAGE_NAME}:${IMAGE_VERSION} --pull --file=Dockerfile .
docker tag ${IMAGE_NAME}:${IMAGE_VERSION} ${ACRServer}/${IMAGE_NAME}:${IMAGE_VERSION}
docker login -u ${ACRUserName} -p ${ACRPassword} ${ACRServer}

echo "Docker push to ACR Server ${ACRServer} with image name ${IMAGE_NAME} and version ${IMAGE_VERSION}"

docker push ${ACRServer}/${IMAGE_NAME}:${IMAGE_VERSION}
