pipeline {
    agent any

    environment {
        SONAR_SERVER_NAME = 'sonar-server'
    }

    stages {
        stage('Fetch Code') {
            steps {
                echo 'Pulling fresh code from GitHub Repository...'
                checkout scm
            }
        }

        stage('SonarQube Static Scan') {
            steps {
                echo 'Initializing SonarQube Code Security Scan...'
                
                withEnv(["PATH+MAVEN=${tool 'maven3'}/bin"]) {
                    withSonarQubeEnv("${SONAR_SERVER_NAME}") {
                        // Added explicit project definitions and token authentication strings
                        sh '''
                            mvn clean sonar:sonar \
                            -Dsonar.projectKey=vprofile-project \
                            -Dsonar.projectName=vprofile-project \
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
    }
}