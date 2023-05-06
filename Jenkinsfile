pipeline {
    agent { label 'master'}
    
    options {
        buildDiscarder(logRotator(numToKeepStr:'5'))
    }
    
    environment {
        IMAGE_REPO = "budarkevichigor/wordpress"
        IMAGE_TAG = """${sh(
            returnStdout: true,
            script: 'cat /tmp/packageTag | cut -c 11-16'
        ).trim()}"""
    }
    
    stages {
        stage('Clone repository'){
            steps {
                deleteDir()
                git url: 'https://github.com/igortank/study-project.git'
            }
        }
        
        stage('Lint dockerfile'){
            agent {
                docker {
                    image 'hadolint/hadolint:latest-debian'
                    label 'master'
                }
            }
            steps {
                sh 'hadolint ./docker/Dockerfile | tee -a hadolint_lint.txt'
            }
            post {
                always {
                    archiveArtifacts 'hadolint_lint.txt'
                }
            }
        }
        
        stage('Building and push image') {
            environment {
                DOCKERHUB_CREDS = 'dockerhub'
            }
            steps{
                script {
                    dockerImage = docker.build IMAGE_REPO + ":" + IMAGE_TAG , "--network host ./docker/"
                    docker.withRegistry( '', DOCKERHUB_CREDS ) {
                        dockerImage.push()
                    }
                }
            }
        }   
        
        stage('Deploy') {
            environment {
                GIT_REPO_EMAIL = 'budarkevichigor@mail.ru'
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'github', usernameVariable: 'USER', passwordVariable: 'PASS')]) 
                {
                    script {
                        env.encodedPass=URLEncoder.encode(PASS, "UTF-8")
                    }
                    sh """
                        echo $IMAGE_TAG
                        git checkout master
                        git config --global user.email ${env.GIT_REPO_EMAIL}
                        ls -lth
                        yq eval '.spec.source.helm.parameters[0].value = env(IMAGE_TAG)' -i init-app/wordpress-argo.yaml
                        cat init-app/wordpress-argo.yaml
                        git add init-app/wordpress-argo.yaml
                        git commit -m "Change file wordpress-argo.yaml tag ${IMAGE_TAG}"
                        git push https://${USER}:${encodedPass}@github.com/igortank/study-project.git master
                        sleep 5s
                    """
                }
            }
        }
    }
    
    post {
        success {
            slackSend (color: "good", message: "SUCCESSFUL: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
        }
        failure {
            slackSend (color: "danger", message: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
        }
    }
}