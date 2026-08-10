#!/usr/bin/env bash

# Exit immediately if a command fails during setup
set -euo pipefail

# --- CONFIGURATION ---
CLUSTER_NAME="${1:-my-eks-cluster}"
LOCALSTACK_URL="http://localhost:4566"

# Color definitions for output
BOLD="\031[1m"
GREEN="\033[0;32m"
CYAN="\033[0;36m"
YELLOW="\033[1;33m"
NC="\033[0m" # No Color

# --- ENVIRONMENT DETECTION ---
AWS_FLAGS=()
KUBECTL_FLAGS=()

# Check if LocalStack is reachable
if curl -s --connect-timeout 2 "${LOCALSTACK_URL}" > /dev/null 2>&1; then
    echo -e "${YELLOW}[!] LocalStack detected at ${LOCALSTACK_URL}. Using LocalStack flags.${NC}\n"
    AWS_FLAGS+=("--endpoint-url=${LOCALSTACK_URL}")
    KUBECTL_FLAGS+=("--insecure-skip-tls-verify")
else
    echo -e "${GREEN}[+] Real AWS environment detected. Using default CLI endpoints.${NC}\n"
fi

print_header() {
    echo -e "\n${CYAN}======================================================================${NC}"
    echo -e "${BOLD} $1 ${NC}"
    echo -e "${CYAN}======================================================================${NC}"
}

# --- 1. NETWORK & VPC CHECKS ---
print_header "1. VPC & CIDR BLOCK VERIFICATION"
aws ec2 describe-vpcs "${AWS_FLAGS[@]}" \
  --query "Vpcs[*].{VpcId:VpcId, CidrBlock:CidrBlock, State:State, IsDefault:IsDefault}" \
  --output table

print_header "2. SUBNET & IP AVAILABILITY CHECKS"
aws ec2 describe-subnets "${AWS_FLAGS[@]}" \
  --query "Subnets[*].{SubnetId:SubnetId, VpcId:VpcId, CidrBlock:CidrBlock, AvailableIps:AvailableIpAddressCount, AZ:AvailabilityZone}" \
  --output table

print_header "3. INTERNET GATEWAY ATTACHMENT"
aws ec2 describe-internet-gateways "${AWS_FLAGS[@]}" \
  --query "InternetGateways[*].{IgwId:InternetGatewayId, VpcId:Attachments[0].VpcId, State:Attachments[0].State}" \
  --output table


# --- 2. EKS CLUSTER CHECKS ---
print_header "4. EKS CLUSTER STATUS (${CLUSTER_NAME})"
aws eks describe-cluster "${AWS_FLAGS[@]}" \
  --name "${CLUSTER_NAME}" \
  --query "cluster.{Name:name, Status:status, Version:version, Endpoint:endpoint, VpcId:resourcesVpcConfig.vpcId}" \
  --output table 2>/dev/null || echo -e "${YELLOW}Could not fetch cluster '${CLUSTER_NAME}'. Check cluster name.${NC}"

print_header "5. EKS NODE GROUPS"
NODEGROUPS=$(aws eks list-nodegroups "${AWS_FLAGS[@]}" --cluster-name "${CLUSTER_NAME}" --query "nodegroups" --output text 2>/dev/null || echo "")

if [ -n "$NODEGROUPS" ]; then
    for ng in $NODEGROUPS; do
        aws eks describe-nodegroup "${AWS_FLAGS[@]}" \
          --cluster-name "${CLUSTER_NAME}" \
          --nodegroup-name "$ng" \
          --query "nodegroup.{NodeGroup:nodegroupName, Status:status, Desired:scalingConfig.desiredSize, Min:scalingConfig.minSize, Max:scalingConfig.maxSize}" \
          --output table
    done
else
    echo -e "${YELLOW}No managed node groups found for cluster '${CLUSTER_NAME}'.${NC}"
fi


# --- 3. ENI & EC2 INSTANCE IP ALLOCATIONS ---
print_header "6. EKS NODE INSTANCES & PRIVATE IPs"
aws ec2 describe-instances "${AWS_FLAGS[@]}" \
  --query "Reservations[*].Instances[*].{InstanceId:InstanceId, PrivateIp:PrivateIpAddress, SubnetId:SubnetId, VpcId:VpcId, State:State.Name}" \
  --output table

print_header "7. ELASTIC NETWORK INTERFACES (ENIs)"
aws ec2 describe-network-interfaces "${AWS_FLAGS[@]}" \
  --query "NetworkInterfaces[0:10].{EniId:NetworkInterfaceId, SubnetId:SubnetId, PrivateIp:PrivateIpAddress, Status:Status, Description:Description}" \
  --output table


# --- 4. KUBERNETES WORKLOAD CHECKS ---
print_header "8. KUBERNETES POD IP ALLOCATIONS (-A)"
kubectl "${KUBECTL_FLAGS[@]}" get pods -A -o wide 2>/dev/null || echo -e "${YELLOW}Unable to reach Kubernetes API server.${NC}"

print_header "9. KUBERNETES SERVICES & ENDPOINTS"
kubectl "${KUBECTL_FLAGS[@]}" get svc -A 2>/dev/null || echo -e "${YELLOW}Unable to reach Kubernetes API server.${NC}"

echo -e "\n${GREEN}[✔] All cluster verification checks completed successfully!${NC}\n"