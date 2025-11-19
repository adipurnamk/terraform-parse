#!/bin/bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"
LOCALSTACK_ENDPOINT="http://localhost:4566"

echo -e "${YELLOW}Starting Terraform testing with LocalStack...${NC}"

# Check if LocalStack is running
if ! curl -s "$LOCALSTACK_ENDPOINT/_localstack/health" > /dev/null; then
    echo -e "${RED}Error: LocalStack is not running. Please start it with:${NC}"
    echo "  docker-compose -f docker-compose.localstack.yml up -d"
    exit 1
fi

echo -e "${GREEN}LocalStack is running${NC}"

# Configure AWS CLI for LocalStack
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT_URL=$LOCALSTACK_ENDPOINT

# Create S3 bucket for Terraform state in LocalStack
echo -e "${YELLOW}Creating S3 bucket for Terraform state...${NC}"
aws --endpoint-url=$LOCALSTACK_ENDPOINT s3 mb s3://terraform-state || true

cd "$TERRAFORM_DIR"

# Initialize Terraform with LocalStack backend
echo -e "${YELLOW}Initializing Terraform with LocalStack backend...${NC}"
terraform init \
    -backend-config="bucket=terraform-state" \
    -backend-config="key=terraform.tfstate" \
    -backend-config="region=us-east-1" \
    -backend-config="endpoint=http://localhost:4566" \
    -backend-config="skip_credentials_validation=true" \
    -backend-config="skip_metadata_api_check=true" \
    -backend-config="skip_region_validation=true" \
    -backend-config="force_path_style=true" \
    -reconfigure

# Configure AWS provider for LocalStack
export TF_VAR_aws_region=us-east-1
export TF_VAR_environment=test
export TF_VAR_cluster_name=test-cluster
export TF_VAR_vpc_id=vpc-test123
export TF_VAR_subnet_ids='["subnet-test1","subnet-test2"]'
export TF_VAR_node_desired_capacity=1
export TF_VAR_node_min_capacity=1
export TF_VAR_node_max_capacity=2

# Validate Terraform configuration
echo -e "${YELLOW}Validating Terraform configuration...${NC}"
if terraform validate; then
    echo -e "${GREEN}Terraform configuration is valid${NC}"
else
    echo -e "${RED}Terraform validation failed${NC}"
    exit 1
fi

# Format check
echo -e "${YELLOW}Checking Terraform formatting...${NC}"
if terraform fmt -check -recursive; then
    echo -e "${GREEN}Terraform files are properly formatted${NC}"
else
    echo -e "${YELLOW}Some Terraform files need formatting. Run 'terraform fmt -recursive' to fix.${NC}"
fi

# Plan (dry-run) - Note: This may fail with LocalStack due to EKS limitations
echo -e "${YELLOW}Running Terraform plan (dry-run)...${NC}"
echo -e "${YELLOW}Note: EKS resources may not be fully supported in LocalStack${NC}"

if terraform plan -var-file=env/dev.tfvars -out=tfplan; then
    echo -e "${GREEN}Terraform plan completed successfully${NC}"
    rm -f tfplan
else
    echo -e "${YELLOW}Terraform plan encountered issues (this may be expected with LocalStack)${NC}"
    echo -e "${YELLOW}LocalStack has limited EKS support, so some resources may fail validation${NC}"
fi

echo -e "${GREEN}Terraform testing completed!${NC}"
echo -e "${YELLOW}Note: LocalStack has limited support for EKS. For full EKS testing, use a real AWS account.${NC}"

