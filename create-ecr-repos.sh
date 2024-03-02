#!/bin/bash

# List of repository names to create
REPO_NAMES=('vllm-repo' 'chat-ui-repo' 'mongo-repo')
REGION=$(aws configure get region)

# If AWS CLI does not return a region, default to us-west-2
if [ -z "$REGION" ]; then
    REGION="eu-west-2"
fi

for REPO_NAME in "${REPO_NAMES[@]}"; do
    # Check if the repository already exists
    if aws ecr describe-repositories --repository-names "$REPO_NAME" --region "$REGION" >/dev/null 2>&1; then
        echo "Repository $REPO_NAME already exists in region $REGION. Skipping."
    else
        # Create ECR repository
        aws ecr create-repository --repository-name "$REPO_NAME" --region "$REGION" >/dev/null
        if [ $? -eq 0 ]; then
            echo "Repository $REPO_NAME created successfully in region $REGION."
        else
            echo "Failed to create the repository $REPO_NAME in region $REGION."
            exit 1
        fi
    fi
done
