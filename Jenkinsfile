pipeline {
    agent any
    
    tools {
        terraform 'terraform'
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/damiandibie/myassessment.git'
            }
        }
        
        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }
        
        stage('Terraform Plan') {
            steps {
                sh 'terraform plan -lock=false'
            }
        }
        
        stage('Approval') {
            steps {
                input message: 'Apply the terraform plan?'
            }
        }
        
        stage('Terraform Apply') {
            steps {
                sh 'terraform apply -auto-approve -lock=false'
            }
        }
        
    }
    
    post {
        always {
            cleanWs()
        }
    }
}
