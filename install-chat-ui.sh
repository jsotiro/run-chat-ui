#!/bin/bash

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
  git clone https://github.com/huggingface/chat-ui.git
  cd "$chat_ui_dir"
fi

# Check if as command-line argument is provided for MISTRAL_ENDPOINT
if [ -n "$1" ]; then
  MISTRAL_ENDPOINT="$1"
else
  # Use the MISTRAL_ENDPOINT environment variable if set, otherwise default
  MISTRAL_ENDPOINT=${MISTRAL_ENDPOINT:-"http://mistral_llm:8000/v1"}
fi

# Determine if USE_LOCAL_MISTRAL should be true based on MISTRAL_ENDPOINT
if [ "$MISTRAL_ENDPOINT" = "http://mistral_llm:8000/v1" ]; then
  USE_LOCAL_MISTRAL="true"
else
  USE_LOCAL_MISTRAL="false"
fi

# Generate .env.local based on a template
pwd

sed "s|{{MISTRAL_ENDPOINT}}|$MISTRAL_ENDPOINT|g" ../env.local.template > .env.local
echo ".env.local has been generated with the Mistral endpoint set to $MISTRAL_ENDPOINT"
docker build -t chat-ui .
