#!/usr/bin/env bash

set -euo pipefail

# --- CONFIGURATION ---
POD_NAME="${1:-}"
NAMESPACE="${2:-default}"
LOCALSTACK_URL="http://localhost:4566"

# Color definitions
GREEN="\033[0;32m"
CYAN="\033[0;36m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"

if [ -z "$POD_NAME" ]; then
    echo -e "${RED}Error: Pod name is required.${NC}"
    echo -e "Usage: $0 <pod-name> [namespace]"
    exit 1
fi

# Auto-detect LocalStack vs Real AWS
AWS_FLAGS=()
KUBECTL_FLAGS=()

if curl -s --connect-timeout 2 "${LOCALSTACK_URL}" > /dev/null 2>&1; then
    AWS_FLAGS+=("--endpoint-url=${LOCALSTACK_URL}")
    KUBECTL_FLAGS+=("--insecure-skip-tls-verify")
fi

echo -e "${CYAN}Tracing placement for Pod:${NC} ${GREEN}${POD_NAME}${NC} in namespace ${GREEN}${NAMESPACE}${NC}...\n"

# 1. Fetch Pod IP and Node Name from Kubernetes
POD_INFO=$(kubectl "${KUBECTL_FLAGS[@]}" get pod "${POD_NAME}" -n "${NAMESPACE}" \
  -o jsonpath='{.status.podIP} {.spec.nodeName}' 2>/dev/null || echo "")

if [ -z "$POD_INFO" ]; then
    echo -e "${RED}Could not find pod '${POD_NAME}' in namespace '${NAMESPACE}'.${NC}"
    exit 1
fi

POD_IP=$(echo "$POD_INFO" | awk '{print $1}')
NODE_NAME=$(echo "$POD_INFO" | awk '{print $2}')

# 2. Fetch Node Private IP
NODE_IP=$(kubectl "${KUBECTL_FLAGS[@]}" get node "${NODE_NAME}" \
  -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null || echo "Unknown")

# 3. Match Node Private IP to EC2 Instance & Subnet in AWS directly using text output
INSTANCE_ID=$(aws ec2 describe-instances "${AWS_FLAGS[@]}" \
  --filters "Name=private-ip-address,Values=${NODE_IP}" \
  --query "Reservations[0].Instances[0].InstanceId" \
  --output text 2>/dev/null || echo "N/A")

VPC_ID=$(aws ec2 describe-instances "${AWS_FLAGS[@]}" \
  --filters "Name=private-ip-address,Values=${NODE_IP}" \
  --query "Reservations[0].Instances[0].VpcId" \
  --output text 2>/dev/null || echo "N/A")

SUBNET_ID=$(aws ec2 describe-instances "${AWS_FLAGS[@]}" \
  --filters "Name=private-ip-address,Values=${NODE_IP}" \
  --query "Reservations[0].Instances[0].SubnetId" \
  --output text 2>/dev/null || echo "N/A")

# 4. Get Subnet CIDR Block
SUBNET_CIDR="N/A"
if [ "$SUBNET_ID" != "N/A" ] && [ "$SUBNET_ID" != "None" ] && [ -n "$SUBNET_ID" ]; then
    SUBNET_CIDR=$(aws ec2 describe-subnets "${AWS_FLAGS[@]}" \
      --subnet-ids "${SUBNET_ID}" \
      --query "Subnets[0].CidrBlock" \
      --output text 2>/dev/null || echo "N/A")
fi

# --- PRINT CLEAN REPORT ---
echo -e "${CYAN}======================================================================${NC}"
echo -e "                   POD PLACEMENT & TRACE REPORT                       "
echo -e "${CYAN}======================================================================${NC}"
printf "%-20s : %s\n" "Pod Name" "${POD_NAME}"
printf "%-20s : %s\n" "Namespace" "${NAMESPACE}"
printf "%-20s : %s\n" "Pod IP" "${POD_IP}"
printf "%-20s : %s\n" "Worker Node" "${NODE_NAME}"
printf "%-20s : %s\n" "Worker Node IP" "${NODE_IP}"
printf "%-20s : %s\n" "EC2 Instance ID" "${INSTANCE_ID}"
printf "%-20s : %s\n" "AWS VPC ID" "${VPC_ID}"
printf "%-20s : %s\n" "AWS Subnet ID" "${SUBNET_ID}"
printf "%-20s : %s\n" "Subnet CIDR Block" "${GREEN}${SUBNET_CIDR}${NC}"
echo -e "${CYAN}======================================================================${NC}\n"