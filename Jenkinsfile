#!/usr/bin/env groovy

pipeline {
    agent any
    tools {
        maven 'maven'
        terraform 'tf'
    }
    environment {
        IMAGE_NAME = "eagle79/java-app:java-maven-${BUILD_NUMBER}"
    }
    stages {
/*     
        stage('test') {
            steps {
                script {
                    echo "test the application"
                    sh 'mvn test'
                }
            }
        }
        stage('build jar') {
            steps {
                script {
                    echo "building the application jar"
                    sh 'mvn package'
                }
            }
        } */

        stage('build image') {
            steps {
                script {
                    echo "building the docker image"
                     withCredentials([usernamePassword(credentialsId: 'docker-hub', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                        sh 'docker build -t ${IMAGE_NAME} .'
                        sh "echo $PASS | docker login -u $USER --password-stdin"
                        sh 'docker push ${IMAGE_NAME}'
                    }
                }
            }
        }
        stage('provision server') {
           steps {
                script {
                    dir('terraform') {
                        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',credentialsId: "AWS-ID",accessKeyVariable: 'AWS_ACCESS_KEY_ID',secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
                            sh "terraform init"
                            sh "terraform apply --auto-approve"
                            EC2_PUBLIC_IP = sh(script: "terraform output ec2_public_ip",returnStdout: true).trim()
                        }
                    }
                }
            }
        }
        stage('deploy') {
            steps {
                script {
                   echo "waiting for EC2 server to initialize" 
                   sleep(time: 90, unit: "SECONDS") 
                   echo 'deploying docker image to EC2...'
                   echo "${EC2_PUBLIC_IP}"
                   def shellCmd = "bash ./server-cmds.sh ${IMAGE_NAME}"
                   sh "cat ./server-cmds.sh"
                   withCredentials([usernamePassword(credentialsId: 'docker-hub', passwordVariable: 'PASS', usernameVariable: 'USER')]) {
                        sshagent(['ssh-my-key']) {
                            sh "scp -o StrictHostKeyChecking=no server-cmds.sh ec2-user@${EC2_PUBLIC_IP}:/home/ec2-user" 
                            sh "scp -o StrictHostKeyChecking=no docker-compose.yaml ec2-user@${EC2_PUBLIC_IP}:/home/ec2-user"
                            sh "ssh -o StrictHostKeyChecking=no ec2-user@${EC2_PUBLIC_IP} ${shellCmd}"
                            sh "ssh -o StrictHostKeyChecking=no ec2-user@${EC2_PUBLIC_IP} echo $PASS | docker login -u $USER --password-stdin && docker-compose -f docker-compose.yaml up --detach"
                        }
                   }
                }
            }
        }
    }
}
