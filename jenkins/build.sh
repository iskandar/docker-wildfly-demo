#!/bin/bash

set -x
set -e -o pipefail

# Mess around with local maven install vars
export M2_HOME=/usr/local/maven
export M2=$M2_HOME/bin
PATH=$M2:$PATH

for Q in $QUICKSTARTS; do
	pushd quickstart/$Q
	mvn test package
    cp -av target/*.war ${WORKSPACE}/deployments/
	popd
done

DOCKER_HUB_NAMESPACE=iskandar
ECR_NAMESPACE=487172405423.dkr.ecr.eu-west-1.amazonaws.com
IMAGE_NAME=docker-wildfly-demo
ECS_TASK_FAMILY=wildfly-demo

TAG=${VERSION}.${BUILD_NUMBER}

# Build a container image
docker build \
	--label GIT_COMMIT=${GIT_COMMIT} \
	--label VERSION=${VERSION} \
	--label QUICKSTARTS="${QUICKSTARTS}" \
	-t ${IMAGE_NAME}:${TAG} .

# Add tags
docker tag ${IMAGE_NAME}:${TAG} ${DOCKER_HUB_NAMESPACE}/${IMAGE_NAME}:${TAG}
docker tag ${IMAGE_NAME}:${TAG} ${ECR_NAMESPACE}/${IMAGE_NAME}:${TAG}

# Log in and push to Docker Hub
docker login -u=${DOCKER_USERNAME} -p=${DOCKER_PASSWORD}
docker push ${DOCKER_HUB_NAMESPACE}/${IMAGE_NAME}:${TAG}

# Log in and push to AWS ECR
$(aws ecr get-login --region eu-west-1)
docker push ${ECR_NAMESPACE}/${IMAGE_NAME}:${TAG}

# Store our build.properties
cat > build.properties <<EOF
IMAGE_NAME=${IMAGE_NAME}
TAG=${TAG}
UPSTREAM_BUILD_NUMBER=${BUILD_NUMBER}
GIT_COMMIT=${GIT_COMMIT}
QUICKSTARTS=${QUICKSTARTS}
VERSION=${VERSION}
DOCKER_HUB_NAMESPACE=${DOCKER_HUB_NAMESPACE}
ECR_NAMESPACE=${ECR_NAMESPACE}
ECS_TASK_FAMILY=${ECS_TASK_FAMILY}
EOF


