#!/bin/bash

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
sed "s|{{MISTRAL_ENDPOINT}}|$MISTRAL_ENDPOINT|g" env.local.template > ./chat-ui/env.local
echo ".env.local has been generated with the Mistral endpoint set to $MISTRAL_ENDPOINT"

# Start the application with docker-compose based on the Mistral endpoint
if [ "$USE_LOCAL_MISTRAL" = "true" ]; then
  echo "Starting with local Mistral LLM container..."
  docker-compose up -d
else
  echo "Starting with remote Mistral LLM..."
  docker-compose -f docker-compose.remote.yml up -d
fi
