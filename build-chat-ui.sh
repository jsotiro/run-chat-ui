#!/bin/bash
# Enable Docker BuildKit
export DOCKER_BUILDKIT=1


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

# Check if a command-line argument is provided for LLM_ENDPOINT
if [ -n "$1" ]; then
  LLM_ENDPOINT="$1"
else
  # Use the LLM_ENDPOINT environment variable if set, otherwise default
  LLM_ENDPOINT=${LLM_ENDPOINT:-"http://mistral_llm:8000/v1"}
fi

# Check if a command-line argument is provided for LLM_TYPE or use environment variable/default
if [ -n "$2" ]; then
  LLM_TYPE="$2"
else
  LLM_TYPE=${LLM_TYPE:-"openai"}
fi

# Determine if USE_LOCAL_LLM should be true based on LLM_ENDPOINT
if [ "$LLM_ENDPOINT" = "http://mistral_llm:8000/v1" ]; then
  USE_LOCAL_LLM="true"
else
  USE_LOCAL_LLM="false"
fi

# Generate .env.local based on a template in one step
pwd
sed -e "s|{{LLM_ENDPOINT}}|$LLM_ENDPOINT|g" -e "s|{{LLM_TYPE}}|$LLM_TYPE|g" ../assets/env.local.template > .env.local
echo ".env.local has been generated with the LLM endpoint set to $LLM_ENDPOINT and LLM type set to $LLM_TYPE"
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
aws ssm put-parameter --name "/secure-ai/LLM_ENDPOINT" --overwrite --value "$LLM_ENDPOINT" --type String --description "LLM Endpoint for connecting to an LLM API"

#cache the mongo image

#cache the mistral image
