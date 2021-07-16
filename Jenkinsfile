pipeline {
    agent { label 'mydocker'}
    stages {
        stage('pull from git') {
            steps {
                 git 'https://github.com/pranay1603/jenkins-maven.git'
            } 
        }
        stage('test image nd creating package') {
            steps {
                sh 'mvn package'
            }
        }
        stage('archive artifact nd creating graph of reports') {
            steps {
               archiveArtifacts artifacts: 'target/*.jar', followSymlinks: false
               junit 'target/surefire-reports/*.xml'
               stash includes: '*', name: 'my jarfile'
               stash includes: 'target/*', name: 'target'
               sh 'pwd'
               sh 'ls -l'
            }
        }

        stage('build image') {
            agent {
                node {
                 label 'ec2a'
                 customWorkspace "/slave/workspace/"
            }
            }
            steps {
              unstash 'my jarfile'
              unstash "target"
              sh 'pwd'
              sh 'ls -l'
              sh "docker build -t pranay1603/japp:v2 ."

            }
        }
        stage('push into dockerhub') {
            agent {label 'ec2a'}
            environment {
                    SERVICE_CREDS= credentials('dockerhub')
            }
            steps {
                    sh "docker push -u ${SERVICE_CREDS_USR} -p ${SERVICE_CREDS_PSW}"
                }
        }        
    }
}
