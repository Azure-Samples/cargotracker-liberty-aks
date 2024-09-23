#!/bin/bash

# Build and push docker image to ACR
echo "Get image name and version......"

run_maven_command() {
    mvn -q -Dexec.executable=echo -Dexec.args="$1" --non-recursive exec:exec 2>/dev/null | sed -e 's/\x1b\[[0-9;]*m//g' | tr -d '\r\n'
}

IMAGE_NAME=$(run_maven_command '${project.artifactId}')
IMAGE_VERSION=$(run_maven_command '${project.version}')

echo "Docker build and push to ACR Server ${ACR_SERVER} with image name ${IMAGE_NAME} and version ${IMAGE_VERSION}"

mvn clean package -DskipTests
cd target

docker login -u ${ACR_PASSWORD} -p ${ACR_PASSWORD} ${ACR_SERVER}

export DOCKER_BUILDKIT=1
docker buildx create --use
docker buildx build --platform linux/amd64 -t ${ACR_SERVER}/${IMAGE_NAME}:${IMAGE_VERSION} --pull --file=Dockerfile . --load
docker push ${ACR_SERVER}/${IMAGE_NAME}:${IMAGE_VERSION}
