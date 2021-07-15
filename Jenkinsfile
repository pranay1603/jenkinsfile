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
        stage('archive artifact') {
            steps {
               archiveArtifacts artifacts: 'target/*.jar', followSymlinks: false
               stash includes: '*', name: 'my jarfile'
            }
        }
        stage('creating graph') {
            steps {
                junit 'target/surefire-reports/*.xml'
            }
        }
        stage('build image') {
            agent {label 'ec2a'}
            steps {
              unstash 'my jarfile'
              sh "docker build -t pranay1603/japp:v2 ."

            }
        }
        stage('push into dockerhub') {
            agent {label 'ec2a'}
                enviroment {
                    SERVICE_CREDS= credentials('dockerhub')
                }
                steps {
                    sh "docker push -u ${SERVICE_CREDS_USER} -p ${SERVICE_CREDS_PSW}"
                }
        }        
    }
}