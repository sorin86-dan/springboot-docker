#!/bin/bash

AWS_KEY=$1
AWS_ACCESS_KEY=$2
AWS_SECRET_KEY=$3
AWS_SECURITY_GROUP=$4

chmod 400 $AWS_KEY
aws configure set aws_access_key_id $AWS_ACCESS_KEY && \
     aws configure set aws_secret_access_key $AWS_SECRET_KEY && \
     aws configure set default.region us-east-1

# Login to ECR
aws ecr get-login-password --region us-east-1 | sudo docker login --username AWS --password-stdin 571845120151.dkr.ecr.us-east-1.amazonaws.com/


# Create ECR repository
aws ecr create-repository \
    --repository-name springboot-docker \
    --region us-east-1

# Create Docker image and push it to ECR repository
sudo mvn spring-boot:build-image -DskipTests
sudo docker tag springboot-docker:latest 571845120151.dkr.ecr.us-east-1.amazonaws.com/springboot-docker:latest
sudo docker push 571845120151.dkr.ecr.us-east-1.amazonaws.com/springboot-docker:latest

# Create EC2 instance
aws ec2 run-instances --image-id ami-09d95fab7fff3776c \
      --instance-type t2.micro \
      --security-group-ids $AWS_SECURITY_GROUP \
      --key-name $AWS_KEY \
      --tag-specifications "ResourceType=instance,Tags=[{Key=SERVER,Value=springboot_docker_${BUILD_NUMBER}}]"
EC2_IP=$(aws ec2 describe-instances --filters "Name=tag:SERVER,Values=springboot_docker_${BUILD_NUMBER}" | grep PublicIpAddress | awk '{print $2}' | cut -d '"' -f 2)
EC2_ID=$(aws ec2 describe-instances --filters "Name=tag:SERVER,Values=springboot_docker_${BUILD_NUMBER}" | grep InstanceId | awk '{print $2}' | cut -d '"' -f 2)
aws ec2 wait instance-status-ok --instance-ids $EC2_ID

# Install prerequisites
ssh -o StrictHostKeyChecking=no -i $AWS_KEY ec2-user@$EC2_IP sudo yum update -y
ssh -i $AWS_KEY ec2-user@$EC2_IP sudo yum install docker -y
ssh -i $AWS_KEY ec2-user@$EC2_IP sudo service docker start
ssh -i $AWS_KEY ec2-user@$EC2_IP sudo usermod -a -G docker ec2-user

# Deploy application on EC2 instance
ssh -i $AWS_KEY ec2-user@$EC2_IP aws configure set aws_access_key_id $AWS_ACCESS_KEY
ssh -i $AWS_KEY ec2-user@$EC2_IP aws configure set aws_secret_access_key $AWS_SECRET_KEY
ssh -i $AWS_KEY ec2-user@$EC2_IP aws configure set default.region us-east-1
ssh -i $AWS_KEY ec2-user@$EC2_IP "aws ecr get-login-password --region us-east-1 | sudo docker login --username AWS --password-stdin 571845120151.dkr.ecr.us-east-1.amazonaws.com/ && sudo docker pull 571845120151.dkr.ecr.us-east-1.amazonaws.com/springboot-docker:latest"
ssh -i $AWS_KEY ec2-user@$EC2_IP sudo docker run -d -p 8081:8081 571845120151.dkr.ecr.us-east-1.amazonaws.com/springboot-docker

# Run tests
sudo mvn clean test -Dec2-ip=$EC2_IP

# Delete ECR repository
aws ecr delete-repository \
      --repository-name springboot-docker \
      --force

# Delete EC2 instance
aws ec2 terminate-instances --instance-ids $EC2_ID