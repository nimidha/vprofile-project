pipeline {
    agent any

    environment {
        // Match the name you gave in Manage Jenkins -> System
        SONAR_SERVER_NAME = 'sonar-server' 
    }

    stages {
        // Stage 1: Pulling latest code from your Forked Github
        stage('Fetch Code') {
            steps {
                echo 'Pulling fresh code from GitHub Repository...'
                checkout scm
            }
        }

        // Stage 2: Running Static Application Security Testing (SAST)
        stage('SonarQube Static Scan') {
            steps {
                echo 'Initializing SonarQube Code Security Scan...'
                withSonarQubeEnv("${SONAR_SERVER_NAME}") {
                    // This runs the Maven sonar plugin built into the project pom.xml
                    sh 'mvn clean sonar:sonar'
                }
            }
        }

        // Stage 3: Enforcing Security Compliance Gates
        stage('Quality Gate Checklist') {
            steps {
                echo 'Checking SonarQube Quality Gate Status...'
                timeout(time: 5, unit: 'MINUTES') {
                    // Jenkins waits for SonarQube's Webhook to reply back with Pass/Fail
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