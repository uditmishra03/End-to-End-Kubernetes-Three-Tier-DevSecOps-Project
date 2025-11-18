pipeline {
    agent any 
    tools {
        jdk 'jdk'
        nodejs 'nodejs'
    }
    environment  {
        SCANNER_HOME=tool 'sonar-scanner'
        AWS_ACCOUNT_ID = credentials('ACCOUNT_ID')
        AWS_ECR_REPO_NAME = credentials('ECR_REPO01')
        AWS_DEFAULT_REGION = 'us-east-1'
        REPOSITORY_URI = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/"
    }
    stages {
        stage('Cleaning Workspace') {
            steps {
                cleanWs()
            }
        }
        stage('Checkout from Git') {
            steps {
                git credentialsId: 'GITHUB', url: 'https://github.com/uditmishra03/End-to-End-Kubernetes-Three-Tier-DevSecOps-Project.git'
            }
        }
        stage('Sonarqube Analysis & Quality Check') {
            steps {
                dir('Application-Code/frontend') {
                    withSonarQubeEnv('sonar-server') {
                        sh ''' $SCANNER_HOME/bin/sonar-scanner \
                        -Dsonar.projectName=three-tier-frontend \
                        -Dsonar.projectKey=three-tier-frontend '''
                    }
                }
                script {
                    timeout(time: 5, unit: 'MINUTES') {
                        waitForQualityGate abortPipeline: false, credentialsId: 'sonar-token'
                    }
                }
            }
        }
        // stage('OWASP Dependency-Check Scan') {
        //     steps {
        //         dir('Application-Code/frontend') {
        //             dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'DP-Check'
        //             dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
        //         }
        //     }
        // }
        stage('Trivy File Scan') {
            steps {
                script {
                    catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                        dir('Application-Code/frontend') {
                            sh 'trivy fs . > trivyfs.txt'
                        }
                    }
                }
            }
        }
        stage("Docker Image Build & Push with Buildx") {
            steps {
                script {
                    dir('Application-Code/frontend') {
                        sh 'aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${REPOSITORY_URI}'
                        sh '''
                            # Create builder if it doesn't exist
                            if ! docker buildx inspect mybuilder > /dev/null 2>&1; then
                                docker buildx create --name mybuilder --use --bootstrap
                            else
                                docker buildx use mybuilder
                            fi
                        '''
                        sh 'docker buildx build --platform linux/amd64 -t ${REPOSITORY_URI}${AWS_ECR_REPO_NAME}:${BUILD_NUMBER} --push .'
                    }
                }
            }
        }
        stage("TRIVY Image Scan") {
            steps {
                script {
                    catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                        sh 'trivy image ${REPOSITORY_URI}${AWS_ECR_REPO_NAME}:${BUILD_NUMBER} > trivyimage.txt'
                    }
                }
            }
        }
    }
    post {
        success {
            echo "Pipeline completed successfully!"
            echo "Frontend image pushed to ECR: ${REPOSITORY_URI}${AWS_ECR_REPO_NAME}:${BUILD_NUMBER}"
            echo "ArgoCD Image Updater will automatically detect and deploy the new image"
        }
    }
}