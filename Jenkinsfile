pipeline {
    agent any  // runs on Jenkins master

    environment {
        // AWS ECR config — set these as Jenkins credentials/env vars
        AWS_REGION      = 'ap-south-1'
        AWS_ACCOUNT_ID  = '123456789012'
        ECR_REPO        = 'my-java-app'
        IMAGE_TAG       = "${BUILD_NUMBER}"   // unique tag per build
        ECR_URI         = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}"

        // SSH credentials stored in Jenkins credentials store
        STAGE_SERVER    = 'ubuntu@1.2.3.4'   // staging server IP
        PROD_SERVER     = 'ubuntu@5.6.7.8'   // prod server IP
    }

    stages {

        // ── STAGE 1: Pull code from GitHub ──────────────────────────
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/yourorg/my-java-app.git'
            }
        }

        // ── STAGE 2: Maven Build (runs on Jenkins master) ────────────
        stage('Maven Build') {
            steps {
                sh 'mvn clean package -DskipTests'
                // Output: target/my-java-app.jar
            }
        }

        // ── STAGE 3: Run Tests ───────────────────────────────────────
        stage('Test') {
            steps {
                sh 'mvn test'
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                }
            }
        }

        // ── STAGE 4: Docker Build (on Jenkins master) ────────────────
        stage('Docker Build') {
            steps {
                sh """
                    docker build -t ${ECR_REPO}:${IMAGE_TAG} .
                    docker tag ${ECR_REPO}:${IMAGE_TAG} ${ECR_URI}:${IMAGE_TAG}
                    docker tag ${ECR_REPO}:${IMAGE_TAG} ${ECR_URI}:latest
                """
            }
        }

        // ── STAGE 5: Push to AWS ECR ─────────────────────────────────
        stage('Push to ECR') {
            steps {
                sh """
                    aws ecr get-login-password --region ${AWS_REGION} | \
                    docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                    
                    docker push ${ECR_URI}:${IMAGE_TAG}
                    docker push ${ECR_URI}:latest
                """
            }
        }

        // ── STAGE 6: Deploy to STAGING ───────────────────────────────
        // Jenkins SSHes into staging server, pulls image, runs container
        stage('Deploy to Staging') {
            steps {
                sshagent(['staging-server-ssh-key']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ${STAGE_SERVER} '
                            aws ecr get-login-password --region ${AWS_REGION} | \
                            docker login --username AWS --password-stdin ${ECR_URI}
                            
                            docker pull ${ECR_URI}:${IMAGE_TAG}
                            
                            docker stop my-java-app || true
                            docker rm   my-java-app || true
                            
                            docker run -d \
                                --name my-java-app \
                                -p 8080:8080 \
                                --restart always \
                                ${ECR_URI}:${IMAGE_TAG}
                        '
                    """
                }
            }
        }

        // ── STAGE 7: Deploy to PROD ──────────────────────────────────
        // Manual approval gate before prod deploy
        stage('Approve Prod Deploy') {
            steps {
                input message: 'Deploy to Production?', ok: 'Deploy'
            }
        }

        stage('Deploy to Prod') {
            steps {
                sshagent(['prod-server-ssh-key']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ${PROD_SERVER} '
                            aws ecr get-login-password --region ${AWS_REGION} | \
                            docker login --username AWS --password-stdin ${ECR_URI}
                            
                            docker pull ${ECR_URI}:${IMAGE_TAG}
                            
                            docker stop my-java-app || true
                            docker rm   my-java-app || true
                            
                            docker run -d \
                                --name my-java-app \
                                -p 8080:8080 \
                                --restart always \
                                ${ECR_URI}:${IMAGE_TAG}
                        '
                    """
                }
            }
        }
    }

    post {
        success { echo "Pipeline completed successfully!" }
        failure { echo "Pipeline failed — check the logs." }
    }
}
