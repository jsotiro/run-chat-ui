
#!/bin/bash

# Check if two arguments are passed
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <PATH_TO_PRIVATE_KEY> <AWS_REGION>"
    exit 1
fi

PRIVATE_KEY_PATH=$1
REGION=$2
KEY_NAME=$(basename "$PRIVATE_KEY_PATH" | sed 's/\..*//') # Extract the file name without extension as the key name

# Generate the public key from the private key
ssh-keygen -y -f $PRIVATE_KEY_PATH > "${PRIVATE_KEY_PATH}.pub"

if [ $? -ne 0 ]; then
    echo "Failed to generate public key from private key."
    exit 2
fi

PUBLIC_KEY=$(cat "${PRIVATE_KEY_PATH}.pub")

# Upload the public key to AWS EC2
aws ec2 import-key-pair --key-name "$KEY_NAME" --public-key-material fileb://"${PRIVATE_KEY_PATH}.pub" --region $REGION

if [ $? -eq 0 ]; then
    echo "Key pair '$KEY_NAME' successfully uploaded to AWS EC2 in region $REGION."
else
    echo "Failed to upload key pair to AWS EC2."
    exit 3
fi