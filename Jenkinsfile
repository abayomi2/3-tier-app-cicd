pipeline {
    agent any

    environment {
        DOCKER_SERVER = '18.235.207.184'
        DOCKER_USER = 'ubuntu'
        DOCKER_HUB_REPO = 'akinaregbesola/class_images'
        DOCKER_HUB_CREDENTIALS = 'dockerhub_credentials_id'
        IMAGE_TAG = 'latest'
        SSH_CREDENTIALS_ID = 'SSH_CREDENTIALS_ID'
        REPO_URL = 'https://github.com/theitern/3-tier-application.git'
    }

    tools {
        jdk 'myjava'
        maven 'mymaven'
    }

    stages {
        stage('Clone Repository') {
            steps {
                echo 'Cloning repository..'
                withCredentials([usernamePassword(credentialsId: 'github_credentials_id', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    script {
                        sh "rm -rf \"${env.WORKSPACE}/3-tier-application\""
                        git credentialsId: 'github_credentials_id', url: env.REPO_URL, branch: 'main'
                    }
                }
            }
        }

        stage('Verify Repository') {
            steps {
                script {
                    echo "Workspace path: ${env.WORKSPACE}"
                    sh "ls -la \"${env.WORKSPACE}/3-tier-application\""
                }
            }
        }

        stage('Compile') {
            steps {
                echo 'Compiling..'
                dir('3-tier-application') {
                    sh 'mvn compile'
                }
            }
        }

        stage('Package') {
            steps {
                echo 'Packaging..'
                dir('3-tier-application') {
                    sh 'mvn package'
                }
            }
        }

        stage('Clear Docker Server') {
            steps {
                echo 'Clearing Docker Server..'
                script {
                    sshagent(credentials: [env.SSH_CREDENTIALS_ID]) {
                        def containerIds = sh(
                            script: "ssh -o StrictHostKeyChecking=no ${env.DOCKER_USER}@${env.DOCKER_SERVER} 'docker ps -aq'",
                            returnStdout: true
                        ).trim()
                        
                        if (containerIds) {
                            sh "ssh -o StrictHostKeyChecking=no ${env.DOCKER_USER}@${env.DOCKER_SERVER} 'docker rm -f ${containerIds}'"
                        } else {
                            echo "No containers to remove."
                        }
                        
                        sh "ssh -o StrictHostKeyChecking=no ${env.DOCKER_USER}@${env.DOCKER_SERVER} 'yes | docker system prune --all'"
                    }
                }
            }
        }

        stage('Copy JAR to Docker Server') {
            steps {
                echo 'Copying JAR to Docker Server..'
                sshagent(credentials: [env.SSH_CREDENTIALS_ID]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ${env.DOCKER_USER}@${env.DOCKER_SERVER} 'rm -f /home/ubuntu/app.jar'
                        scp -o StrictHostKeyChecking=no "${env.WORKSPACE}/3-tier-application/target/*.jar" ${env.DOCKER_USER}@${env.DOCKER_SERVER}:/home/ubuntu/app.jar
                    """
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker Image..'
                sshagent(credentials: [env.SSH_CREDENTIALS_ID]) {
                    sh """
                        scp -o StrictHostKeyChecking=no -r "${env.WORKSPACE}/3-tier-application/*" ${env.DOCKER_USER}@${env.DOCKER_SERVER}:/home/ubuntu
                        ssh -o StrictHostKeyChecking=no ${env.DOCKER_USER}@${env.DOCKER_SERVER} 'ls -la && docker build -t ${env.DOCKER_HUB_REPO}:${env.IMAGE_TAG} .'
                    """
                }
            }
        }
        
        stage('Push Docker Image') {
            steps {
                echo 'Pushing Docker Image..'
                sshagent(credentials: [env.SSH_CREDENTIALS_ID]) {
                    withCredentials([usernamePassword(credentialsId: env.DOCKER_HUB_CREDENTIALS, usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                        sh """
                            ssh -o StrictHostKeyChecking=no ${env.DOCKER_USER}@${env.DOCKER_SERVER} 'echo ${DOCKER_PASSWORD} | docker login -u $DOCKER_USERNAME --password-stdin'
                            ssh -o StrictHostKeyChecking=no ${env.DOCKER_USER}@${env.DOCKER_SERVER} 'docker push ${env.DOCKER_HUB_REPO}:${env.IMAGE_TAG}'
                        """
                    }
                }
            }
        }

        stage('Run Docker Image') {
            steps {
                echo 'Running Docker Image..'
                sshagent(credentials: [env.SSH_CREDENTIALS_ID]) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ${env.DOCKER_USER}@${env.DOCKER_SERVER} 'sudo docker run -d --name our_app_container -p 8080:8080 ${env.DOCKER_HUB_REPO}:${env.IMAGE_TAG}'
                    """
                }
            }
        } 
    }

    post {
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
