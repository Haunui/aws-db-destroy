pipeline {
  agent any
  stages {
    stage('Destroy Instance') {
      steps {
        script {
          sshagent (credentials: ['bkp_ssh_credentials']) {
            sh "bash destroy.sh"
          }
        }
      }
    }
  }
  environment {
    AWS_ACCESS_KEY_ID = credentials('aws_access_key_id')
    AWS_SECRET_ACCESS_KEY = credentials('aws_secret_access_key')
    AWS_REGION = 'eu-west-3'
  }
}
