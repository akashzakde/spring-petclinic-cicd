def COLOR_MAP = [
    'SUCCESS': 'good',
    'FAILURE': 'danger',
]
pipeline {
    agent any
    tools{
        maven "MVN"
        jdk "JDK11"
    }

    stages {
        stage('Fetch Code') {
            steps {
                git branch: 'main', credentialsId: 'github', url: 'git@github.com:akashzakde/spring-petclinic-cicd.git'
            }
        }

        stage('Build Code'){
            steps{
                sh 'mvn -s settings.xml clean -DskipTests package'
            }
        }
        stage('Test Code'){
            steps{
                sh 'mvn -s settings.xml test'
            }
        }
	stage('Upload Artifact'){
            steps{
                sh 'mvn -s settings.xml -Dmaven.test.skip=true -Dmaven.compile.skip=true deploy'
            }
        }
        stage('Build image'){
            steps{
                script{
                    sh 'docker build -t akashz/spring-petclinic:latest .'
                }
            }
        }
        stage('Push image'){
            steps{
               withCredentials([usernamePassword(credentialsId: 'dockerHub', passwordVariable: 'dockerHubPassword', usernameVariable: 'dockerHubUser')]) {
        	sh "docker login -u ${env.dockerHubUser} -p ${env.dockerHubPassword}"
            sh 'docker push akashz/spring-petclinic:latest'
            }
          }
        }

    }
       post{
          always {
              echo 'Slack Notifications'
              slackSend channel: '#jenkinscicd',
                  color: COLOR_MAP[currentBuild.currentResult],
                  message: "*${currentBuild.currentResult}:* Job ${env.JOB_NAME} build ${env.BUILD_NUMBER} \n More info at: ${env.BUILD_URL}"
             }
          }

}
