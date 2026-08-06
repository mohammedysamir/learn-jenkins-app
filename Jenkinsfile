pipeline {
    agent any
    environment {
        NODE_IMAGE = 'node:18-alpine'
        PLAYWRIGHT_IMAGE = 'mcr.microsoft.com/playwright:v1.39.0-jammy'
        REACT_APP_VERSION = "1.0.${BUILD_ID}"
    }
    stages {
        stage('Docker') {
            agent any
            steps {
                sh 'docker build -t my-playwright-app .'
            }
        }
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
                            image 'my-playwright-app'
                            reuseNode true
                            // Ensure port 3000 is open/mapped if needed inside the container
                            args '-p 3000:3000'
                        }
                    }
                    steps {
                        echo 'Running Playwright E2E Tests...'
                        sh 'npx playwright test --reporter=html'
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
        stage('Deploy to Staging and run Post-Deployment Tests') {
            agent {
                docker {
                    image 'my-playwright-app'
                    reuseNode true
                }
            }
            environment {
                VERCEL_PROJECT_ID = 'prj_ZrUZ7N6nBOLNFV5CM4FXsIM7h9d5'
                VERCEL_TOKEN = credentials('vercel-auth-token')
                VERCEL_ORG_ID = credentials('vercel-team-id')
            }
            steps {
                echo 'Deploying the project to Staging...'
                sh '''
                    npx vercel --version
                    npx vercel pull --yes --environment=preview --token=$VERCEL_TOKEN
                    npx vercel build --token=$VERCEL_TOKEN
                    npx vercel deploy --prebuilt --token=$VERCEL_TOKEN > staging-url.txt

                    # Read the output URL into a shell variable
                    STAGING_URL=$(cat staging-url.txt | tail -n 1)
                    echo "Deployment to staging is completed: $STAGING_URL"

                    export CI_ENVIRONMENT_URL="$STAGING_URL"
                    echo "Running tests against the staging environment: $CI_ENVIRONMENT_URL"
                '''
            }
            post {
                always {
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: false,
                        icon: '',
                        keepAll: false,
                        reportDir: 'playwright-report',
                        reportFiles: 'index.html',
                        reportName: 'Playwright Staging HTML Report',
                        reportTitles: '',
                        useWrapperFileDirectly: true
                    ])
                }
            }
        }
        stage('Approving to Deploy to Production') {
            //manual approval to deploy to production with timeout 5 minutes to automatically cancel the deployment
            agent any
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    input message: 'Do you want to deploy to production?', ok: 'Deploy', submitter: 'admin'
                }
            }
        }
        stage('Deploy to Production and run Post-Deployment Tests') {
            agent {
                docker {
                    image 'my-playwright-app'
                    reuseNode true
                }
            }
            environment {
                VERCEL_PROJECT_ID = 'prj_UndDE6RRi5OrZARFCG0eZyyrB9ar'
                VERCEL_TOKEN = credentials('vercel-auth-token')
                VERCEL_ORG_ID = credentials('vercel-team-id')
                // Public production alias. The URL printed by `vercel deploy` is the
                // generated deployment URL, which sits behind Vercel Deployment
                // Protection and serves a login page to the tests.
                PRODUCTION_URL = 'https://simple-web-app-nu.vercel.app'
            }
            steps {
                echo 'Running Production Post-Deployment Tests...'
                echo 'Deploying the project...'
                sh '''
                    npx vercel --version
                    npx vercel pull --yes --environment=production --token=$VERCEL_TOKEN
                    npx vercel build --prod --token=$VERCEL_TOKEN
                    npx vercel deploy --prebuilt --prod --token=$VERCEL_TOKEN > production-url.txt
                    echo "Deployment completed: $(tail -n 1 production-url.txt)"

                    export CI_ENVIRONMENT_URL="$PRODUCTION_URL"
                    echo "Testing against the production alias: $CI_ENVIRONMENT_URL"
                    echo "Running tests against the deployed application..."
                    npx playwright test --reporter=html --config=playwright.config.js
                '''
            }
            post {
                always {
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: false,
                        icon: '',
                        keepAll: false,
                        reportDir: 'playwright-report',
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
