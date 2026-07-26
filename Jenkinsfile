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
                        }
                    }
                    steps {
                        sh '''
                            echo "E2E Stage"

                            # 1. Start serve listening on 0.0.0.0:3000 in background
                            npx serve -s build -l tcp://0.0.0.0:3000 &

                            # 2. Give npx enough time to download & launch serve (15s)
                            sleep 15

                            # 3. Run Playwright tests
                            npx playwright test --reporter=html
                        '''
                    }
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
        stage('Archive Artifacts') {
            steps {
                archiveArtifacts artifacts: 'build/**'
            }
        }
    }
    stage('Deploying') {
        steps {
            echo 'Deploying the project...'
            sh '''
                npm install netlify-cli@20.1.1
                node_modules/.bin/netlify --version
                #netlify deploy --dir=build --prod --auth=$NETLIFY_AUTH_TOKEN --site=$NETLIFY_SITE_ID
                echo "Deployment completed."
            '''
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
