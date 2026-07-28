pipeline {
    agent any
    environment {
        NODE_IMAGE = 'node:18-alpine'
        PLAYWRIGHT_IMAGE = 'mcr.microsoft.com/playwright:v1.39.0-jammy'
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
                    npm ci --no-audit --no-fund
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
                            // Ensure port 3000 is open/mapped if needed inside the container
                            args '-p 3000:3000'
                        }
                    }
                    steps {
                        echo 'Running Playwright E2E Tests...'
                        sh '''
                            # Verify the build directory exists in this container
                            ls -la build

                            # Playwright automatically starts 'npx serve -s build -l 3000',
                            # waits for http://127.0.0.1:3000 to be ready, and runs tests.
                            npx playwright test
                        '''
                    }
                }
            }
            post {
                always {
                    echo 'Test Reports'
                    junit 'jest-results/junit.xml'
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: false,
                        icon: '',
                        keepAll: false,
                        reportDir: 'playwright-report',
                        reportFiles: 'index.html',
                        reportName: 'Playwright HTML Report',
                        reportTitles: '',
                        useWrapperFileDirectly: true
                    ])
                }
            }
        }
        stage('Lint') {
            agent {
                docker {
                    image "$NODE_IMAGE"
                    reuseNode true
                }
            }
            steps {
                sh '''
                    echo "Lint Stage"
                    npm run lint
                '''
            }
        }
        stage('Deploying to Staging') {
            agent {
                docker {
                    image "$NODE_IMAGE"
                    reuseNode true
                }
            }
            environment {
                VERCEL_PROJECT_ID = 'prj_qdyHetTH5yH6VNQaZ0AahR67OCqk'
                VERCEL_TOKEN = credentials('vercel-auth-token')
                VERCEL_ORG_ID = credentials('vercel-team-id')
            }
            steps {
                echo 'Deploying the project to Staging...'
                sh '''
                    npm install vercel@latest
                    npx vercel --version
                    npx vercel deploy --token=$VERCEL_TOKEN --yes
                    echo "Deployment to staging is completed."
                '''
            }
        }
        stage('Deploying') {
            agent {
                docker {
                    image "$NODE_IMAGE"
                    reuseNode true
                }
            }
            environment {
                VERCEL_PROJECT_ID = credentials('vercel-simple-app-project-id')
                VERCEL_TOKEN = credentials('vercel-auth-token')
                VERCEL_ORG_ID = credentials('vercel-team-id')
            }
            steps {
                echo 'Deploying the project...'
                sh '''
                    npm install vercel@latest
                    npx vercel --version
                    npx vercel deploy  --prod --token=$VERCEL_TOKEN --yes
                    echo "Deployment completed."
                '''
            }
        }
        stage('Production Post-Deployment Tests') {
            agent {
                docker {
                    image "$NODE_IMAGE"
                    image "$PLAYWRIGHT_IMAGE"
                    reuseNode true
                }
            }
            environment {
                CI_ENVIRONMENT_URL = 'https://simple-web-app-nu.vercel.app'
            }
            steps {
                echo 'Running Production Post-Deployment Tests...'

                sh '''
                    echo "Running tests against the deployed application..."
                    npx playwright test --config=playwright.config.js
                '''
            }
            post {
                always {
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: false,
                        icon: '',
                        keepAll: false,
                        reportDir: 'playwright-e2e-report',
                        reportFiles: 'index.html',
                        reportName: 'Playwright Production HTML Report',
                        reportTitles: '',
                        useWrapperFileDirectly: true
                    ])
                }
            }
        }
        stage('Archive Artifacts') {
            steps {
                archiveArtifacts artifacts: 'build/**'
            }
        }
    }
}
