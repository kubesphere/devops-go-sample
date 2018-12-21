pipeline {
  agent {
    node {
      label 'go'
    }
  }
  parameters{
     string(name:'TAG_NAME',defaultValue: '',description:'')
  }
  environment {
    DOCKER_REPO_CREDENTIAL_ID = 'docker-repo-id'
    GIT_CREDENTIAL_ID = 'git-id'
    KUBECONFIG_CREDENTIAL_ID = 'demo-kubeconfig'
    DOCKER_REPO_NAMESPACE = 'kubesphere'
    GIT_ACCOUNT = 'kubesphere'
    APP_NAME = 'devops-go-sample'
    DOCKER_REPO_ADDRESS = 'harbor.devops.kubesphere.local:30280'
    GIT_ADDRESS = 'gitlab.devops.kubesphere.local:30080'
  }
  stages {
    stage('checkout scm') {
      steps {
        checkout(scm)
      }
    }
    stage('unit test') {
      steps {
        container('go') {
          sh 'CGO_ENABLED=0 go test ./...'
        }

      }
    }
    stage('build & push snapshot') {
      steps {
        container('go') {
          sh 'docker build -t $DOCKER_REPO_ADDRESS/$DOCKER_REPO_NAMESPACE/$APP_NAME:SNAPSHOT-$BRANCH_NAME-$BUILD_NUMBER .'
          withCredentials([usernamePassword(passwordVariable : 'DOCKER_PASSWORD' ,usernameVariable : 'DOCKER_USERNAME' ,credentialsId : "$DOCKER_REPO_CREDENTIAL_ID" ,)]) {
            sh 'echo "$DOCKER_PASSWORD" | docker login  $DOCKER_REPO_ADDRESS -u "$DOCKER_USERNAME" --password-stdin'
            sh 'docker push  $DOCKER_REPO_ADDRESS/$DOCKER_REPO_NAMESPACE/$APP_NAME:SNAPSHOT-$BRANCH_NAME-$BUILD_NUMBER '
          }
        }

      }
    }
    stage('push latest'){
       when{
         branch 'master'
       }
       steps{
         container('go'){
           sh 'docker tag  $DOCKER_REPO_ADDRESS/$DOCKER_REPO_NAMESPACE/$APP_NAME:SNAPSHOT-$BRANCH_NAME-$BUILD_NUMBER $DOCKER_REPO_ADDRESS/$DOCKER_REPO_NAMESPACE/$APP_NAME:latest '
           sh 'docker push  $DOCKER_REPO_ADDRESS/$DOCKER_REPO_NAMESPACE/$APP_NAME:latest '
         }
       }
    }
    stage('deploy to dev') {
      when{
        branch 'master'
      }
      steps {
        input(id: 'deploy-to-dev', message: 'deploy to dev?')
        kubernetesDeploy(configs: 'deploy/git/dev/**', enableConfigSubstitution: true, kubeconfigId: "$KUBECONFIG_CREDENTIAL_ID")
      }
    }
    stage('push with tag'){
      when{
        expression{
          return params.TAG_NAME =~ /v.*/
        }
      }
      steps {
         container('go'){
         input(id: 'release-image-with-tag', message: 'release image with tag?')
           withCredentials([usernamePassword(credentialsId: "$GIT_CREDENTIAL_ID", passwordVariable: 'GIT_PASSWORD', usernameVariable: 'GIT_USERNAME')]) {
             sh 'git config --global user.email "kubesphere@yunify.com" '
             sh 'git config --global user.name "kubesphere" '
             sh "git tag -a ${params.TAG_NAME} -m \"${params.TAG_NAME}\" "
             sh 'git push http://$GIT_USERNAME:$GIT_PASSWORD@$GIT_ADDRESS/$GIT_ACCOUNT/$APP_NAME.git --tags'
           }
         sh "docker tag  $DOCKER_REPO_ADDRESS/$DOCKER_REPO_NAMESPACE/$APP_NAME:SNAPSHOT-$BRANCH_NAME-$BUILD_NUMBER $DOCKER_REPO_ADDRESS/$DOCKER_REPO_NAMESPACE/$APP_NAME:${params.TAG_NAME}"
         sh "docker push  $DOCKER_REPO_ADDRESS/$DOCKER_REPO_NAMESPACE/$APP_NAME:${params.TAG_NAME}"
         }
      }
    }
    stage('deploy to production') {
      when{
        expression{
          return params.TAG_NAME =~ /v.*/
        }
      }
      steps {
        input(id: 'deploy-to-production', message: 'deploy to production?')
        kubernetesDeploy(configs: 'deploy/git/prod/**', enableConfigSubstitution: true, kubeconfigId: "$KUBECONFIG_CREDENTIAL_ID")
      }
    }
  }

}
