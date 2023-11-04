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
    environment {
        AWS_DEFAULT_REGION = 'ap-south-1'
        AWS_ACCESS_KEY_ID = credentials('awscreds')
        AWS_SECRET_ACCESS_KEY = credentials('awscreds')
        ECR_REGISTRY = '680247317246.dkr.ecr.ap-south-1.amazonaws.com/spring-petclinic'
        ECS_CLUSTER = 'DevCluster'
        SERVICE_NAME = 'Pet-Clinic-Dev-SVC'
	IMAGE_TAG = 'v1'
                }
    stages{
        stage('Fetch Code') {
            steps {
                git branch: 'main', credentialsId: 'github', url: 'git@github.com:akashzakde/spring-petclinic-cicd.git'
            }
        }
	stage('Code Analysis'){
            steps{
                withSonarQubeEnv(credentialsId: 'sonar-login',installationName: 'sonar-server') {
               sh 'mvn sonar:sonar'
             }
          }
        }

        stage('QualityGate Test') {
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
                sh 'mvn -s settings.xml test'
            }
        }
	stage('Upload Artifact'){
            steps{
                sh 'mvn -s settings.xml -Dmaven.test.skip=true -Dmaven.compile.skip=true deploy'
            }
        }
	stage('Login to ECR') {
            steps {
                script {
                        sh "aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY"
                    }
                }
            }
        stage('Push Image') {
            steps {
                script {
                    sh "docker push $ECR_REGISTRY:$IMAGE_TAG"
                }
            }
        }

        stage('Update ECS Service') {
            steps {
                script {
                    sh "aws ecs update-service --cluster $ECS_CLUSTER --service $SERVICE_NAME --force-new-deployment"
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
