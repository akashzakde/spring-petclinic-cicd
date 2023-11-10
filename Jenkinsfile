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
        DEV_ECS_CLUSTER = 'DevCluster'
        DEV_SERVICE_NAME = 'Pet-Clinic-Dev-SVC'
	PROD_ECS_CLUSTER = 'ProdCluster'
	PROD_SERVICE_NAME = 'Pet-Clinic-Prod-SVC'
	IMAGE_TAG = 'latest'
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
               sh '''mvn clean verify sonar:sonar \
  -Dsonar.projectKey='PetClinic-3' \
  -Dsonar.projectName='PetClinic-3' \
  -Dsonar.host.url=http://172.31.37.229:9000 \
  -Dsonar.token=sqp_a9a2a730f8e8a246f5b25eda32b5b3fb94b01ce3'''
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
	stage('Login to ECR') {
            steps {
                script {
                        sh "aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY"
                    }
                }
            }
        stage('Build Image') {
            steps {
                script {
                    sh '''
	   	docker build -t spring-petclinic .
		docker tag spring-petclinic:latest "$ECR_REGISTRY:$IMAGE_TAG"
		       '''	
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

        stage('Deploy To Stage Env') {
            steps {
                script {
                    sh "aws ecs update-service --cluster $DEV_ECS_CLUSTER --service $DEV_SERVICE_NAME --force-new-deployment"
                }
            }
        }
          stage('Manual Approval for Production Deployment') {
            when {
                expression {
                    currentBuild.resultIsBetterOrEqualTo('SUCCESS')
                }
            }
            steps {
                // Added manual approval for Prod Deployment
                timeout(activity: true, time: 1, unit: 'DAYS'){
                input 'Have you done sanity check for deployment to production?'
                }
            }
        }

	stage('Deploy to Prod') {
            steps {
                script {
                    sh "aws ecs update-service --cluster $PROD_ECS_CLUSTER --service $PROD_SERVICE_NAME --force-new-deployment"
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
