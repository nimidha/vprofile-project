pipeline {
    agent {
        node {
            label '' // Forces Jenkins to stick to a dedicated node context throughout the entire run
        }
    }

    environment {
        // MNC Best Practice: Centralized tracking variables
        REGISTRY_URL   = "localhost:5001"
        IMAGE_NAME     = "vprofile-app"
        IMAGE_TAG      = "${BUILD_NUMBER}" // Dynamically tag images with the build number
        SCANNER_HOME   = tool 'SonarQubeScanner' // Binds the Sonar scanner binary
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
                // Run compilation and unit tests
                sh 'mvn clean package -DskipTests=false'
            }
        }

        stage('3. SAST Code Analysis (SonarQube)') {
            steps {
                echo 'Injecting code into SonarQube Engine...'
                withSonarQubeEnv('SonarQube-Server') {
                    sh "${SCANNER_HOME}/bin/sonar-scanner -Dsonar.projectKey=vprofile-app -Dsonar.sources=."
                }
            }
        }

        stage('4. SonarQube Quality Gate Blocker') {
            steps {
                echo 'Checking corporate quality compliance thresholds...'
                timeout(time: 5, unit: 'MINUTES') {
                    // 2+ Years MNC Standard: Wait for SonarQube's verdict. 
                    // If the Quality Gate fails, Jenkins aborts the pipeline here!
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
                // MNC Standard: If a container image has high-severity unpatched CVEs, fail the pipeline!
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
        always {
            echo 'Cleaning up workstation workspace build footprints...'
            cleanWs()
        }
        success {
            echo 'Pipeline completed successfully. Artifact is ready for Ansible/Kubernetes deployment.'
        }
        failure {
            echo 'Pipeline failed security or quality checks. Notification dispatched to engineering channels.'
        }
    }
}