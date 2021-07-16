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
        stage('creating custom workspace of target') {
            agent { label 'ec2a'}
            steps {
               sh 'mkdir target'
            }
        }
        stage('unstashing target folder in ec2a') {
            agent { label 'ec2a'
                customworkspace "/slave/workspace/target/"
            }
            steps {
                unstash "target"
            }

        }

        stage('build image') {
            agent {label 'ec2a'
                 customworkspace "/slave/workspace/"
            }
            steps {
              unstash 'my jarfile'
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
                    sh "docker push -u ${SERVICE_CREDS_USER} -p ${SERVICE_CREDS_PSW}"
                }
        }        
    }
}