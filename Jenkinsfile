pipeline {
    agent { label 'master'}
    
  environment {
    IMAGE_REPO = "budarkevichigor/wordpress"
    IMAGE_TAG = cat /tmp/packageTeg | cut -c 13-18
    // Instead of DOCKERHUB_USER, use your Dockerhub name
  }
  stages {
    stage('Cloning Git') {
      environment {
        DOCKERHUB_CREDS = credentials('dockerhub')
      }
      steps {
        dir('wordpress') 
        {
          git url: 'https://github.com/igortank/study-project.git', branch: 'master'
        }
      }
    }
    stage('Building and push image') {
      steps{
        script {
          dockerImage = docker.build IMAGE_REPO + ":" + IMAGE_TAG , ".wordpress/docker/"
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
      }
      steps {
        script {
          sh """
            echo $IMAGE_TAG
            ls -lth
            yq eval '.spec.source.helm.parameters[0].value = env(IMAGE_TAG)' -i wordpress/init-app/wordpress-argo.yaml
            cat wordpress/init-app/wordpress-argo.yaml
          """
        }
        withCredentials([usernamePassword(credentialsId: 'github', usernameVariable: 'USER', passwordVariable: 'PASS')]) 
        {
          script {
            env.encodedPass=URLEncoder.encode(PASS, "UTF-8")
            {
              sh """
                cd wordpress
                git config --global user.email ${env.GIT_REPO_EMAIL}
                git add --all
                git commit -m "Change file wordpress-argo.yaml tag ${env(IMAGE_TAG)}"
                git push https://${USER}:${encodedPass}@github.com/igortank/study-project.git
                sleep 5s
              """
            }
          }
        }
      }
    }
  }
}