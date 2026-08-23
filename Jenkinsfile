pipeline {
    agent any
    environment {
        NODE_IMAGE = 'node:18-alpine'
        PLAYWRIGHT_IMAGE = 'mcr.microsoft.com/playwright:v1.39.0-jammy'
        AWS_CLI_IMAGE = 'amazon/aws-cli:2.36.19'
        REACT_APP_VERSION = "1.0.${BUILD_ID}"
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
        stage('Build Docker Image') {
            agent {
                docker {
                    image "$AWS_CLI_IMAGE"
                    reuseNode true
                    args "-u root --entrypoint='' -v /var/run/docker.sock:/var/run/docker.sock"
                }
            }
            steps {
                sh '''
                    echo "Installing Docker binary..."
                    if ! command -v docker &> /dev/null; then
                        curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-24.0.7.tgz | tar -xz -C /tmp
                        mv /tmp/docker/docker /usr/local/bin/
                        rm -rf /tmp/docker
                    fi

                    echo "Verifying Docker installation..."
                    docker --version

                    echo "Building Docker image..."
                    docker build -t my-jenkins-app:${REACT_APP_VERSION} .
                '''
            }
        }
    }
}