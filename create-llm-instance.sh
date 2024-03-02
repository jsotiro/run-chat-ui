#!/bin/bash

# Script to create a CloudFormation stack for an EC2 instance with KMS key and optional HF_TOKEN

# Set default region from AWS config, default to eu-west-2 if not configured
REGION=$(aws configure get region)
REGION=${REGION:-eu-west-2}

# Check if minimum two arguments are passed
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <SSH_KEY_NAME> <KMS_KEY_ALIAS> [HF_TOKEN]"
    exit 1
fi

# Parameters
KEY_NAME=$1
KMS_KEY_ALIAS=$2
STACK_NAME="LLMStack"
TEMPLATE_PATH="assets/llm-stack.yml" 

# HF_TOKEN handling
HF_TOKEN_VALUE=${3:-$HF_TOKEN}

# Check if KMS key alias exists
echo "checking if KMS key with alias $KMS_KEY_ALIAS exists..."
ALIAS_EXISTS=$(aws kms list-aliases --region $REGION --query 'Aliases[?AliasName==`alias/'$KMS_KEY_ALIAS'`].AliasName' --output text)
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)

# If KMS key alias does not exist, create a new KMS key and alias
if [ -z "$ALIAS_EXISTS" ]; then
    echo "KMS key alias '$KMS_KEY_ALIAS' not found. Creating KMS key and alias..."
    KEY_ID=$(aws kms create-key --region $REGION --description "Key for $KMS_KEY_ALIAS" --query 'KeyMetadata.KeyId' --output text)
    aws kms create-alias --region $REGION --alias-name alias/$KMS_KEY_ALIAS --target-key-id $KEY_ID
    # use  a template  policyto  enables IAM access 
    # replace account id in the template and store it in a a variable
    policy=$(sed -e "s#\{{AWS_ACCOUNT_ID}}#$AWS_ACCOUNT_ID#g" assets/key_policy_template.json)
    echo $policy
    # Attach the policy to the KMS key to grant full permissions to the root user using the variable
    aws kms put-key-policy --region $REGION --key-id $KEY_ID --policy-name default --policy "$policy"
fi

# Create/update the HF_TOKEN parameter in SSM Parameter Store
aws ssm put-parameter --name "/secure-ai/HF_TOKEN" --overwrite --value "$HF_TOKEN_VALUE" --type SecureString --key-id alias/$KMS_KEY_ALIAS --description "HF TOKEN for LLM container"

# Dynamically find the AMI ID
AMI_ID=$(aws ec2 describe-images --region "$REGION"  --owners amazon --filters "Name=name,Values=Deep Learning AMI GPU PyTorch 2.0.1 (Ubuntu 20.04) 20231003" "Name=state,Values=available" --query 'Images | sort_by(@,&CreationDate) | [-1].ImageId' --output text)

# Create CloudFormation stack
echo "Creating CloudFormation stack in region $REGION with SSH key $KEY_NAME, KMS key alias $KMS_KEY_ALIAS..."
aws cloudformation create-stack --stack-name $STACK_NAME --template-body file://$TEMPLATE_PATH --parameters ParameterKey=KeyName,ParameterValue=$KEY_NAME ParameterKey=KmsKeyAlias,ParameterValue=$KMS_KEY_ALIAS ParameterKey=AmiId,ParameterValue=$AMI_ID --capabilities CAPABILITY_NAMED_IAM --region $REGION

# Wait for the stack to be created and output the final status
echo "Waiting for stack to be created..."
aws cloudformation wait stack-create-complete --stack-name $STACK_NAME --region $REGION

if [ $? -eq 0 ]; then
    echo "Stack creation completed successfully."
else
    echo "Stack creation failed."
fi

# Describe the stack to get details
echo "Retrieving details of the created stack..."
STACK_DESCRIPTION=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION)

# Extract Public  DNS Name
PUBLIC_DNS=$(echo $STACK_DESCRIPTION | jq -r '.Stacks[0].Outputs[] | select(.OutputKey == "PublicDNS") | .OutputValue')

if [ -n "$PUBLIC_DNS" ]; then
    echo "Stack created." 
    echo "You can now SSH into the LLM instance with:"
    echo "ssh -i ${KEY_NAME} ubuntu@${PUBLIC_DNS}"
    echo "You can access the Chat UI and the LLM app on ports 8081 and 8000 using SSH tunneling with:"
    echo "ssh -i ${KEY_NAME} -L 8081:localhost:80 -L 8000:localhost:8000 ubuntu@${PUBLIC_DNS}"
else
    echo "Public IP or DNS name not found."
fi
