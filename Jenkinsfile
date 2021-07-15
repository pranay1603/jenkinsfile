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
            }
        }
        stage('creating graph') {
            steps {
                junit 'target/surefire-reports/*.xml'
            }
        }
    }
}
