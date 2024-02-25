aws ssm put-parameter --name "/secure-ai/hf-token" --overwrite --value "$(cat $1)" --type SecureString --key-id alias/SageMakerKey --description "Private Key for connecting to GitHub"
