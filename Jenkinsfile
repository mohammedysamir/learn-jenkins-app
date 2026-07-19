pipeline {
    agent any
    environment {
        NODE_IMAGE = 'node:18-alpine'
        PLAYWRIGHT_IMAGE = 'mcr.microsoft.com/playwright:v1.61.0-noble'
    }
    stages {
        stage('Build') {
            agent {
                docker {
                    image "$NODE_IMAGE"
                    reuseNode true
                }
            }
            steps {
                sh '''
                    echo "Building the project..."
                    node --version
                    npm --version
                    npm ci
                    npm run build
                    ls -la
                '''
            }
        }
        stage('Test') {
            agent {
                docker {
                    image "$NODE_IMAGE"
                    reuseNode true
                }
            }
            steps {
                sh '''
                    echo "Test Stage"
                    npm test
                    test -f build/index.html | echo exit code: $?
                '''
            }
        }
        stage('E2E') {
            agent {
                docker {
                    image "$PLAYWRIGHT_IMAGE"
                    reuseNode true
                }
            }
            steps {
                sh '''
                    echo "E2E Stage"
                    npm install -g serve
                    node_modules/serve -s build &
                    sleep 10
                    npx playwright test
                '''
            }
        }
        stage('Archive Artifacts') {
            steps {
                archiveArtifacts artifacts: 'build/**'
            }
        }
    }
    post {
            always {
                echo 'Junit Test Report'
                junit 'jest-results/junit.xml'
            }
    }
}
