#!/bin/bash

# List of repository names to delete
REPO_NAMES=('vLLM-repo' 'chat-ui-repo' 'mongo-repo')
REGION=$(aws configure get region)

# If AWS CLI does not return a region, default to us-west-2
if [ -z "$REGION" ]; then
    REGION="eu-west-2"
fi

for REPO_NAME in "${REPO_NAMES[@]}"; do
    # Check if the repository exists
    if aws ecr describe-repositories --repository-names "$REPO_NAME" --region "$REGION" >/dev/null 2>&1; then
        # Attempt to delete the repository (force deletion to remove all images)
        aws ecr delete-repository --repository-name "$REPO_NAME" --region "$REGION" --force >/dev/null
        if [ $? -eq 0 ]; then
            echo "Repository $REPO_NAME deleted successfully from region $REGION."
        else
            echo "Failed to delete the repository $REPO_NAME in region $REGION."
            exit 1
        fi
    else
        echo "Repository $REPO_NAME does not exist in region $REGION. Skipping."
    fi
done
