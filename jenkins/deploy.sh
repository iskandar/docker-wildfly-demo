#!/bin/bash

set -x
set -e -o pipefail

# Exercise for the reader:
# Inject environment-specific vars to 'environment' values in task definition
# Use 'jq' or JMESpath or similar

# Create a barebones JSON Task definition
cat > task.json <<EOF
{
  "family": "${ECS_TASK_FAMILY}",
  "containerDefinitions": [
    {
      "environment": [],
      "name": "wildfly",
      "mountPoints": [],
      "image": "${ECR_NAMESPACE}/${IMAGE_NAME}:${TAG}",
      "cpu": 0,
      "portMappings": [
        {
          "protocol": "tcp",
          "containerPort": 8080
        }
      ],
      "memory": 1024,
      "essential": true,
      "volumesFrom": []
    }
  ]
}
EOF


# Register the task
aws ecs register-task-definition \
	--cli-input-json file://./task.json | tee definition.json

# Update the service
# To be more robust, we could parse the 'version' property from the definition.json result.
aws ecs update-service \
	--cluster ${ECS_CLUSTER} \
	--service ${ECS_SERVICE_NAME} \
    --task-definition ${ECS_TASK_FAMILY}

# Wait for a result
aws ecs wait services-stable \
	--cluster ${ECS_CLUSTER} \
	--services ${ECS_SERVICE_NAME} \
