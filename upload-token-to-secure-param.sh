aws ssm put-parameter --name "/secure-ai/hf-token" --overwrite --value "$(cat $1)" --type SecureString --key-id alias/SageMakerKey --description "HF_TOKEN used by vLLM to fetch LLMs"
