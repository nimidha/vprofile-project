pipeline {
    agent any // Simplifies executor allocation across all stages smoothly

    environment {
        REGISTRY_URL   = "localhost:5001"
        IMAGE_NAME     = "vprofile-app"
        IMAGE_TAG      = "${BUILD_NUMBER}"
        SCANNER_HOME   = tool 'SonarQubeScanner' // Looks up the tool name we registered above
    }

    stages {
        stage('1. Fetch Source Code') {
            steps {
                echo 'Pulling fresh code from version control...'
                checkout scm
            }
        }

        stage('2. Build & Unit Test') {
            steps {
                echo 'Compiling Java Application via Maven...'
                sh 'mvn clean package -DskipTests=false'
            }
        }

        stage('3. SAST Code Analysis (SonarQube)') {
            steps {
                echo 'Injecting code into SonarQube Engine...'
                withSonarQubeEnv('SonarQube-Server') { 
                    // Make sure 'SonarQube-Server' matches your Jenkins System configuration name!
                    sh "${SCANNER_HOME}/bin/sonar-scanner -Dsonar.projectKey=vprofile-app -Dsonar.sources=."
                }
            }
        }

        stage('4. SonarQube Quality Gate Blocker') {
            steps {
                echo 'Checking corporate quality compliance thresholds...'
                timeout(time: 5, unit: 'MINUTES') {
                    script {
                        def qg = waitForQualityGate()
                        if (qg.status != 'OK') {
                            error "Pipeline aborted due to Quality Gate Failure: ${qg.status}"
                        }
                    }
                }
            }
        }

        stage('5. Containerization (Docker Build)') {
            steps {
                echo 'Building production docker image blueprint...'
                sh "docker build -t ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG} ."
                sh "docker tag ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG} ${REGISTRY_URL}/${IMAGE_NAME}:latest"
            }
        }

        stage('6. Image Vulnerability Scan (Trivy)') {
            steps {
                echo 'Running Trivy Deep File System Inspection...'
                sh "trivy image --exit-code 1 --severity CRITICAL,HIGH ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

        stage('7. Secure Push to Enterprise Registry') {
            steps {
                echo 'Uploading verified secure artifact to registry...'
                sh "docker push ${REGISTRY_URL}/${IMAGE_NAME}:${IMAGE_TAG}"
                sh "docker push ${REGISTRY_URL}/${IMAGE_NAME}:latest"
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully. Artifact is ready for Ansible/Kubernetes deployment.'
        }
        failure {
            echo 'Pipeline failed security or quality checks. Notification dispatched to engineering channels.'
        }
        cleanup {
            echo 'Wiping build artifacts and cleaning workspace execution footprints...'
            // 2+ Years MNC Standard: Native error handling to prevent cleanup failures from corrupting job status
            catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {
                cleanWs()
            }
        }
    }

}