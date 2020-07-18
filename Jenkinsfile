//install withAWS from "Pipeline: AWS Steps" plugin
def ec2Ip
def ec2Id

pipeline {

    agent any

    stages {
        stage('Retrieve code') {
            steps {
                // Get some code from a GitHub repository
                git 'https://github.com/sorin86-dan/springboot-docker'
            }
        }

        stage('Create AWS EC2 instance') {
            steps{
                withAWS(credentials: '7be35d01-571f-4218-bb7a-635f2f041eaf', region: 'us-east-1') {
                    sh 'aws ec2 run-instances --image-id ami-09d95fab7fff3776c \
                          --instance-type t2.micro \
                          --security-group-ids $AWS_SECURITY_GROUP \
                          --key-name AwsKey \
                          --tag-specifications "ResourceType=instance,Tags=[{Key=SERVER,Value=springboot_docker_${BUILD_NUMBER}}]"'

                    script {
                        def jsonEc2InstanceString = sh (script: 'aws ec2 describe-instances --filters "Name=tag:SERVER,Values=springboot_docker_${BUILD_NUMBER}"', returnStdout: true)
                        def jsonEc2IpInstance = readJSON text: jsonEc2InstanceString

                        ec2Ip = jsonEc2IpInstance['Reservations'][0]['Instances'][0]['PublicIpAddress']
                        ec2Id = jsonEc2IpInstance['Reservations'][0]['Instances'][0]['InstanceId']
                    }
                    sh "aws ec2 wait instance-status-ok --instance-ids ${ec2Id}"
                }
            }
        }

        stage('Install prerequisites on AWS EC2 instance') {
            steps{
                sh "chmod 400 AwsKey"
                withAWS(credentials: '7be35d01-571f-4218-bb7a-635f2f041eaf', region: 'us-east-1') {
                    sh "ssh -o StrictHostKeyChecking=no -i AwsKey ec2-user@${ec2Ip} sudo yum update -y"
                    sh "ssh -i AwsKey ec2-user@${ec2Ip} sudo yum install docker -y"
                    sh "ssh -i AwsKey ec2-user@${ec2Ip} sudo service docker start"
                    sh "sh -i AwsKey ec2-user@${ec2Ip} sudo usermod -a -G docker ec2-user"
                    sh "ssh -i AwsKey ec2-user@${ec2Ip} sudo yum install git -y"
                    sh "ssh -i AwsKey ec2-user@${ec2Ip} sudo yum install maven -y"
                    sh "ssh -i AwsKey ec2-user@${ec2Ip} git clone https://github.com/sorin86-dan/springboot-docker.git"
                }
            }
        }

        stage('Build everything and run tests') {
            steps{
                withAWS(credentials: '7be35d01-571f-4218-bb7a-635f2f041eaf', region: 'us-east-1') {
                    sh "ssh -i AwsKey ec2-user@${ec2Ip} 'cd springboot-docker ; mvn clean install -DskipTests'"
                    sh "ssh -i AwsKey ec2-user@${ec2Ip} 'cd springboot-docker ; mvn spring-boot:build-image -DskipTests'"
                    sh "ssh -i AwsKey ec2-user@${ec2Ip} docker run -d -p 8081:8080 springboot-docker"
                    sh "ssh -i AwsKey ec2-user@${ec2Ip} \"cd springboot-docker ; mvn clean test -Dec2-ip=${ec2Ip}\""
                }
            }
        }

        stage('Terminate AWS EC2 instance') {
            steps{
                withAWS(credentials: '7be35d01-571f-4218-bb7a-635f2f041eaf', region: 'us-east-1') {
                    sh "aws ec2 terminate-instances --instance-ids ${ec2Id}"
                }
            }
        }
    }
}
