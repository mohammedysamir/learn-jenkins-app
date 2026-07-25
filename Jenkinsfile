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
        stage('Tests') {
            parallel {
                stage('Unit Tests') {
                    agent {
                        docker {
                            image "$NODE_IMAGE"
                            reuseNode true
                        }
                    }
                    steps {
                        sh '''
                            echo "Unit Tests Stage"
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
                            npx playwright test --reporter=html
                        '''
                    }
                }
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
                echo 'Test Reports'
                junit 'jest-results/junit.xml'
                publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, icon: '', keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Playwright HTML Report', reportTitles: '', useWrapperFileDirectly: true])
            }
    }
}
