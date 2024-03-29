#!/bin/bash

AWS_KEY=$1
AWS_ACCESS_KEY=$2
AWS_SECRET_KEY=$3
AWS_SECURITY_GROUP=$4

chmod 400 $AWS_KEY
aws configure set aws_access_key_id $AWS_ACCESS_KEY && \
     aws configure set aws_secret_access_key $AWS_SECRET_KEY && \
     aws configure set default.region us-east-1

#Create EC2 instance
aws ec2 run-instances --image-id ami-09d95fab7fff3776c \
      --instance-type t2.micro \
      --security-group-ids $AWS_SECURITY_GROUP \
      --key-name $AWS_KEY \
      --tag-specifications "ResourceType=instance,Tags=[{Key=SERVER,Value=springboot_docker_${BUILD_NUMBER}}]"

EC2_IP=$(aws ec2 describe-instances --filters "Name=tag:SERVER,Values=springboot_docker_${BUILD_NUMBER}" | grep PublicIpAddress | awk '{print $2}' | cut -d '"' -f 2)
EC2_ID=$(aws ec2 describe-instances --filters "Name=tag:SERVER,Values=springboot_docker_${BUILD_NUMBER}" | grep InstanceId | awk '{print $2}' | cut -d '"' -f 2)

aws ec2 wait instance-status-ok --instance-ids $EC2_ID

#Install prerequisites
ssh -o StrictHostKeyChecking=no -i $AWS_KEY ec2-user@$EC2_IP sudo yum update -y
ssh -i $AWS_KEY ec2-user@$EC2_IP sudo yum install docker -y
ssh -i $AWS_KEY ec2-user@$EC2_IP sudo service docker start
ssh -i $AWS_KEY ec2-user@$EC2_IP sudo usermod -a -G docker ec2-user
ssh -i $AWS_KEY ec2-user@$EC2_IP sudo yum install git -y
ssh -i $AWS_KEY ec2-user@$EC2_IP sudo yum install maven -y
ssh -i $AWS_KEY ec2-user@$EC2_IP git clone https://github.com/sorin86-dan/springboot-docker.git

#Build everything and run tests
ssh -i $AWS_KEY ec2-user@$EC2_IP "cd springboot-docker ; mvn clean install -DskipTests"
ssh -i $AWS_KEY ec2-user@$EC2_IP "cd springboot-docker ; sudo mvn spring-boot:build-image -DskipTests"
ssh -i $AWS_KEY ec2-user@$EC2_IP docker run -d -p 8081:8081 springboot-docker
ssh -i $AWS_KEY ec2-user@$EC2_IP "cd springboot-docker ; mvn clean test -Dec2-ip=localhost"
scp -i $AWS_KEY ec2-user@$EC2_IP:/home/ec2-user/springboot-docker/target/surefire-reports/testng-results.xml .

#Delete EC2 instance
aws ec2 terminate-instances --instance-ids $EC2_ID
