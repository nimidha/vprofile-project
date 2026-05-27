pipeline {
    agent any

    environment {
        SONAR_SERVER_NAME = 'sonar-server'
        // Points to our local registry over the shared Docker bridge network
        REGISTRY_URL      = '127.0.0.1:5001'
        IMAGE_NAME        = 'vprofile-app'
        BUILD_TAG         = "${BUILD_NUMBER}"
    }

    stages {
        stage('Fetch Code') {
            steps {
                echo 'Pulling fresh code from GitHub Repository...'
                checkout scm
            }
        }

        stage('Trivy File System Scan') {
            steps {
                echo 'Auditing repository source files for vulnerabilities...'
                // Using a dockerized runner for Trivy so it works anywhere
                sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest fs --exit-code 0 --severity HIGH,CRITICAL ."
            }
        }

        stage('SonarQube Static Scan') {
            steps {
                echo 'Initializing SonarQube Code Security Scan...'
                withEnv(["PATH+MAVEN=${tool 'maven3'}/bin"]) {
                    withSonarQubeEnv("${SONAR_SERVER_NAME}") {
                        sh '''
                            mvn clean compile sonar:sonar \
                            -Dsonar.host.url=http://devsecops-sonarqube:9000 \
                            -Dsonar.projectKey=vprofile-project \
                            -Dsonar.projectName=vprofile-project \
                            -Dsonar.java.binaries=target/classes \
                            -Dsonar.login=$SONAR_AUTH_TOKEN
                        '''
                    }
                }
            }
        }

        stage('Quality Gate Checklist') {
            steps {
                echo 'Checking SonarQube Quality Gate Status...'
                timeout(time: 5, unit: 'MINUTES') {
                    script {
                        def qg = waitForQualityGate()
                        if (qg.status != 'OK') {
                            error "Pipeline stopped! Code failed security compliance quality gates: ${qg.status}"
                        }
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Compiling Application into production-ready Docker container image...'
                sh "docker build -t ${REGISTRY_URL}/${IMAGE_NAME}:${BUILD_TAG} ."
                sh "docker tag ${REGISTRY_URL}/${IMAGE_NAME}:${BUILD_TAG} ${REGISTRY_URL}/${IMAGE_NAME}:latest"
            }
        }

        stage('Trivy Image Scan') {
            steps {
                echo 'Auditing final container image OS layers for CVE vulnerabilities...'
                sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image --exit-code 0 --severity CRITICAL ${REGISTRY_URL}/${IMAGE_NAME}:${BUILD_TAG}"
            }
        }

        stage('Push to Registry') {
            steps {
                echo 'Shipping verified secure image to local registry warehouse...'
                sh "docker push ${REGISTRY_URL}/${IMAGE_NAME}:${BUILD_TAG}"
                sh "docker push ${REGISTRY_URL}/${IMAGE_NAME}:latest"
            }
        }
    }
}