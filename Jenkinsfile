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
        stage('Fetch code from github') {
            steps {
                git branch: 'main', credentialsId: 'github', url: ' git@github.com:akashzakde/simple-java-app.git'
            }
        }

        stage('Static Code Analysis'){
            steps{
                withSonarQubeEnv(credentialsId: 'sonar-login',installationName: 'sonar-server') {
               sh 'mvn sonar:sonar'
             }
          }
        }

        stage('Quality Gate') {
            steps {
                    timeout(time: 1, unit: 'HOURS'){
                    waitForQualityGate abortPipeline: true
                    }
                }

        post {
        success {
            echo 'Static code analysis and quality gate passed.'
        }
        failure {
            echo 'Static code analysis or quality gate failed. Please investigate and take appropriate action.'
           }
         }
       }
        stage('Build Code'){
            steps{
                sh 'mvn -s settings.xml clean -DskipTests package'
            }
        }
        stage('Test Code'){
            steps{
                sh 'mvn  -s settings.xml test'
            }
        }
        stage('Upload Artifact On Nexus Repo'){
            steps{
                sh 'mvn -s settings.xml deploy'
            }
        }
         stage('Build docker image'){
            steps{
                script{
                    sh 'docker build -t akashz/springbootapp:latest .'
                }
            }
        }
        stage('Push image to Hub'){
            steps{
               withCredentials([usernamePassword(credentialsId: 'dockerHub', passwordVariable: 'dockerHubPassword', usernameVariable: 'dockerHubUser')]) {
        	sh "docker login -u ${env.dockerHubUser} -p ${env.dockerHubPassword}"
            sh 'docker push akashz/springbootapp:latest'
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
