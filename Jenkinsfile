pipeline {
    agent { label 'master'}
    
  environment {
    IMAGE_REPO = "budarkevichigor/wordpress"
    IMAGE_TAG = """${sh(
                returnStdout: true,
                script: 'cat /tmp/packageTeg | cut -c 13-18'
            ).trim()}"""
    // Instead of DOCKERHUB_USER, use your Dockerhub name
  }
  stages {
    stage('Building and push image') {
      environment {
        DOCKERHUB_CREDS = 'dockerhub'
      }
      steps{
        script {
          //sh '$IMAGE_TAG = cat /tmp/packageTeg | cut -c 13-18'
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
        GIT_REPO_BRANCH = "master"
        //GIT_CREDS = credentials('github')
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
}