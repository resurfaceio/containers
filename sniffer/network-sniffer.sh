#!/bin/bash
set -e

GRAVITON2ID="i-0d9c8acf873549834"
X86REMOTEID="i-07c4ddf0a760c55cc"

check_status() {
  GRAVITON2STATUS=""
  X86REMOTESTATUS=""
  while [ "$GRAVITON2STATUS" != "$1" -o "$X86REMOTESTATUS" != "$1" ]; do
    GRAVITON2STATUS=$(aws ec2 describe-instances --instance-id=$GRAVITON2ID --query "Reservations[*].Instances[*].State.Name" --output text --profile $AWSPROFILE)
    echo "  Graviton2 instance ($GRAVITON2ID) status: $GRAVITON2STATUS"

    X86REMOTESTATUS=$(aws ec2 describe-instances --instance-id=$X86REMOTEID --query "Reservations[*].Instances[*].State.Name" --output text --profile $AWSPROFILE)
    echo "  X86-64 instance ($X86REMOTEID) status: $X86REMOTESTATUS"
  done
}

read -p "Enter your AWS profile [default]: " AWSPROFILE
AWSPROFILE=${AWSPROFILE:-default}

echo -e "\nSTEP 1/9: Start up EC2 instances with $AWSPROFILE profile (will check status until both are running. Ctrl+C if any machine does not reach running status)"
aws ec2 start-instances --instance-ids $GRAVITON2ID $X86REMOTEID --profile $AWSPROFILE
check_status "running"

echo -e "\nSTEP 2/9: Obtain domain names"
echo -n "  Obtaining DNS name for Graviton2 instance..."
GRAVITON2HOSTNAME=$(aws ec2 describe-instances --instance-id=$GRAVITON2ID --query "Reservations[*].Instances[*].PublicDnsName" --output text --profile $AWSPROFILE)
echo $GRAVITON2HOSTNAME
echo -n "  Obtaining DNS name for X86-64 instance..."
X86REMOTEHOSTNAME=$(aws ec2 describe-instances --instance-id=$X86REMOTEID --query "Reservations[*].Instances[*].PublicDnsName" --output text --profile $AWSPROFILE)
echo $X86REMOTEHOSTNAME

echo -e "\nSTEP 3/9: Add ~/.ssh/graviton2builderkey.pem private key"
ssh-add -k ~/.ssh/graviton2builderkey.pem

echo -e "\nSTEP 4/9: Add hostnames to ~/.ssh/known_hosts"
ssh-keyscan -H -t rsa $GRAVITON2HOSTNAME >> ~/.ssh/known_hosts
ssh-keyscan -H -t rsa $X86REMOTEHOSTNAME >> ~/.ssh/known_hosts

echo -e "\nSTEP 5/9: Verify connection"
docker -H ssh://ec2-user@$GRAVITON2HOSTNAME info
docker -H ssh://ec2-user@$X86REMOTEHOSTNAME info

echo -e "\nSTEP 6/9: Create docker buildx builder"
echo "Creating builder with one node"
docker buildx create --name multiremote --driver docker-container --platform linux/arm64 ssh://ec2-user@$GRAVITON2HOSTNAME

echo "Appending second node"
docker buildx create --name multiremote --append --driver docker-container --platform linux/amd64 ssh://ec2-user@$X86REMOTEHOSTNAME

echo -e "\nSTEP 7/9: Bootstrap buildx builder"
docker buildx inspect --bootstrap --builder multiremote

echo -e "\nSTEP 8/9: Build multi-platform image"
docker buildx build --builder multiremote --push -t resurfaceio/network-sniffer:$1 --build-arg GORVER=$2 --platform linux/amd64,linux/arm64  .

echo -e "\nSTEP 9/9: Remove builder and stop EC2 instances (will check status until both are stopped. Ctrl+C if any machine does not reach stopped status)"
docker buildx prune --builder multiremote -f && docker buildx rm multiremote
aws ec2 stop-instances --instance-ids $GRAVITON2ID $X86REMOTEID --profile $AWSPROFILE
check_status "stopped"
