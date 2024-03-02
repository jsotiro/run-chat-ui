#!/bin/bash
# Enable Docker BuildKit
export DOCKER_BUILDKIT=1

# Initialize default values
LLM_ENDPOINT="http://llm_model:8000/v1"
LLM_MODEL="mistralai/Mistral-7B-Instruct-v0.2"
LLM_API="openai"

# Parse named command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --llm-endpoint) LLM_ENDPOINT="$2"; shift ;;
        --llm-model) LLM_MODEL="$2"; shift ;;
        --llm-api) LLM_API="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Define the path to the chat-ui directory
chat_ui_dir="chat-ui"

# Check if the chat-ui directory exists
if [ -d "$chat_ui_dir" ]; then
    # Directory exists, so cd into it and git pull to update
    echo "Directory $chat_ui_dir exists. Updating the repository..."
    cd "$chat_ui_dir" && git pull
else
    # Directory does not exist, so clone the repository
    echo "Directory $chat_ui_dir does not exist. Cloning the repository..."
    git clone https://github.com/huggingface/chat-ui.git "$chat_ui_dir"
    cd "$chat_ui_dir"
fi

# Determine if USE_LOCAL_LLM should be true based on LLM_ENDPOINT
USE_LOCAL_LLM="false"
if [ "$LLM_ENDPOINT" = "http://llm_model:8000/v1" ]; then
    USE_LOCAL_LLM="true"
fi

# Generate .env.local based on a template in one step
pwd
sed -e "s|{{LLM_ENDPOINT}}|$LLM_ENDPOINT|g" -e "s|{{LLM_MODEL}}|$LLM_MODEL|g" -e "s|{{LLM_API}}|$LLM_API|g" ../assets/env.template > .env
echo ".env has been generated with the LLM endpoint set to $LLM_ENDPOINT, LLM model set to $LLM_MODEL, and LLM API set to $LLM_API"
docker build -t chat-ui .

# Set variables
REGION=$(aws configure get region)
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
REPO_NAME="chat-ui-repo"
IMAGE_TAG="latest"


# Step 1: Retrieve an authentication token and authenticate your Docker client to your registry.
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Step 2: Tag your image to match your repository name, and optionally, a specific version tag.
docker tag chat-ui-repo:$IMAGE_TAG $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:latest

# Step 3: Push the image to AWS ECR
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:latest

aws ssm put-parameter --name "/secure-ai/LLM_MODEL" --overwrite --value "$LLM_MODEL" --type String --description "LLM Model used for the SecureAI stack"
aws ssm put-parameter --name "/secure-ai/LLM_ENDPOINT" --overwrite --value "$LLM_ENDPOINT" --type String --description "LLM Endpoint for connecting to an LLM API"

#cache the mongo image

#cache the mistral image
