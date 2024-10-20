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
                sh 'terraform plan -out=tfplan'
            }
        }
        
       /* stage('Approval') {
            steps {
                input message: 'Apply the terraform plan?'
            }
        }
        
        stage('Terraform Apply') {
            steps {
                sh 'terraform apply -auto-approve tfplan'
            }
        }
        */
    }
    
    post {
        always {
            cleanWs()
        }
    }
}
