pipeline {
    agent any
    environment {
        DOCKER_SERVER = '100.29.50.7'
        DOCKER_USER = 'ubuntu'
        DOCKER_HUB_REPO = 'abayomi2/cici_working'
        DOCKER_HUB_CREDENTIALS = 'dockerhub_credentials_id'
        IMAGE_TAG = 'latest'
        SSH_CREDENTIALS_ID = 'SSH_CREDENTIALS_ID'
        REPO_URL = '://github.com/abayomi2/3-tier-app-cicd.git'
    }
    tools {
        jdk 'myjava'
        maven 'mymaven'
    }
    stages {
        stage('Clone Repository') {
            steps {
                echo 'Cloning repository..'
                cleanWs()  // Clears workspace before cloning
                withCredentials([usernamePassword(credentialsId: 'github_credentials_id', 
                    usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    script {
                        git credentialsId: 'github_credentials_id', url: env.REPO_URL, branch: 'main'
                    }
                }
            }
        }
        
        stage('Compile') {
            steps {
                echo 'Compiling..'
                sh 'mvn compile'
            }
        }

        stage('Package') {
            steps {
                echo 'Packaging..'
                sh 'mvn package'
            }
        }

        stage('Clear Docker Server') {
            steps {
                echo 'Clearing Docker Server..'
                sshagent(credentials: ['SSH_CREDENTIALS_ID']) {
                    script {
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
                sshagent(credentials: ['SSH_CREDENTIALS_ID']) {
                    sh """
                    ssh -o StrictHosthttpsKeyChecking=no ${env.DOCKER_USER}@${env.DOCKER_SERVER} 'rm -f /home/ubuntu/app.jar'
                    scp -o StrictHostKeyChecking=no ${WORKSPACE}/target/*.jar ${env.DOCKER_USER}@${env.DOCKER_SERVER}:/home/ubuntu/app.jar
                    """
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker Image..'
                sshagent(credentials: ['SSH_CREDENTIALS_ID']) {
                    sh """
                    scp -o StrictHostKeyChecking=no -r ${WORKSPACE}/* ${env.DOCKER_USER}@${env.DOCKER_SERVER}:/home/ubuntu
                    ssh -o StrictHostKeyChecking=no ${env.DOCKER_USER}@${env.DOCKER_SERVER} 'cd /home/ubuntu && ls -la && docker build -t ${env.DOCKER_HUB_REPO}:${env.IMAGE_TAG} .'"
                    """
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                echo 'Pushing Docker Image..'
                sshagent(credentials: ['SSH_CREDENTIALS_ID']) {
                    withCredentials([usernamePassword(credentialsId: env.DOCKER_HUB_CREDENTIALS, 
                        usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                        sh """
                        ssh -o StrictHostKeyChecking=no ${env.DOCKER_USER}@${env.DOCKER_SERVER} 'echo ${env.DOCKER_PASSWORD} | docker login -u ${env.DOCKER_USERNAME} --password-stdin'
                        ssh -o StrictHostKeyChecking=no ${env.DOCKER_USER}@${env.DOCKER_SERVER} 'docker push ${env.DOCKER_HUB_REPO}:${env.IMAGE_TAG}'
                        """
                    }
                }
            }
        }

        stage('Run Docker Image') {
            steps {
                echo 'Running Docker Image..'
                sshagent(credentials: ['SSH_CREDENTIALS_ID']) {
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
