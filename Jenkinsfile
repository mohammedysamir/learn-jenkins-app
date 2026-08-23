pipeline {
    agent any
    environment {
        NODE_IMAGE        = 'node:18-alpine'
        AWS_CLI_IMAGE     = 'amazon/aws-cli:2.36.19'
        REACT_APP_VERSION = "1.0.${BUILD_ID}"
    }
    stages {
        stage('Build App') {
            agent {
                docker {
                    image "$NODE_IMAGE"
                    reuseNode true
                }
            }
            steps {
                sh '''
                    echo "Building project..."
                    npm ci --no-audit --no-fund
                    npm run build
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
                    echo "1. Installing extraction dependencies..."
                    yum install -y tar gzip > /dev/null

                    echo "2. Installing Docker client..."
                    curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-24.0.7.tgz | tar -xz -C /tmp
                    mv /tmp/docker/docker /usr/local/bin/docker
                    rm -rf /tmp/docker

                    echo "3. Verifying Docker installation..."
                    docker --version

                    echo "4. Building Docker image..."
                    docker build -t my-jenkins-app:${REACT_APP_VERSION} .
                '''
            }
        }
    }
}
