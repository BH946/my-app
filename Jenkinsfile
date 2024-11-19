pipeline {
    environment {
        PROJECT = "vital-wavelet-381119"
        APP_NAME = "docker-springboot"
        FULL_SVC_NAME = "secret-full-svc"
        CLUSTER = "lab-cluster"
        CLUSTER_ZONE = "asia-northeast3"
        IMAGE_TAG = "asia-northeast3-docker.pkg.dev/${PROJECT}/my-repository/${APP_NAME}:${env.BRANCH_NAME}.${env.BUILD_NUMBER}"
        JENKINS_CRED = "${PROJECT}"
    }

    agent {
        kubernetes {
            label 'my-app'
            defaultContainer 'jnlp'
            yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    component: ci
spec:
  serviceAccountName: cd-jenkins
  containers:
  - name: gcloud
    image: gcr.io/cloud-builders/gcloud
    command:
    - cat
    tty: true
  - name: kubectl
    image: gcr.io/cloud-builders/kubectl
    command:
    - cat
    tty: true
"""
        }
    }

    stages {
        stage('Build and Push Docker Image') {
            steps {
                container('gcloud') {
                    sh """
                        PYTHONUNBUFFERED=1 gcloud builds submit -t ${IMAGE_TAG} .
                    """
                }
            }
        }

        stage('Deploy Canary') {
            when { branch 'canary' }
            steps {
                container('kubectl') {
                    sh """
                        gcloud container clusters get-credentials ${CLUSTER} --zone ${CLUSTER_ZONE} --project ${PROJECT}
                        sed -i.bak 's#DOCKER_IMAGE_PLACEHOLDER#${IMAGE_TAG}#' ./k8s/canary/*.yaml
                        kubectl apply -f ./k8s/services
                        kubectl apply -f ./k8s/canary
                        echo http://`kubectl --namespace=production get service/${FULL_SVC_NAME} -o jsonpath='{.status.loadBalancer.ingress[0].ip}'` > ${FULL_SVC_NAME}
                    """
                }
            }
        }

        stage('Deploy Production') {
            when { branch 'main' }
            steps {
                container('kubectl') {
                    sh """
                        gcloud container clusters get-credentials ${CLUSTER} --zone ${CLUSTER_ZONE} --project ${PROJECT}
                        sed -i.bak 's#DOCKER_IMAGE_PLACEHOLDER#${IMAGE_TAG}#' ./k8s/production/*.yaml
                        kubectl apply -f ./k8s/services
                        kubectl apply -f ./k8s/production
                        echo http://`kubectl --namespace=production get service/${FULL_SVC_NAME} -o jsonpath='{.status.loadBalancer.ingress[0].ip}'` > ${FULL_SVC_NAME}
                    """
                }
            }
        }

        stage('Deploy Dev') {
            when {
                not { branch 'main' }
                not { branch 'canary' }
            }
            steps {
                container('kubectl') {
                    sh """
                        gcloud container clusters get-credentials ${CLUSTER} --zone ${CLUSTER_ZONE} --project ${PROJECT}
                        kubectl get ns ${env.BRANCH_NAME} || kubectl create ns ${env.BRANCH_NAME}
                        sed -i.bak 's#DOCKER_IMAGE_PLACEHOLDER#${IMAGE_TAG}#' ./k8s/dev/*.yaml
                        kubectl apply -f ./k8s/services -n ${env.BRANCH_NAME}
                        kubectl apply -f ./k8s/dev -n ${env.BRANCH_NAME}
                        echo 'To access your environment run `kubectl proxy`'
                        echo "Then access your service via http://localhost:8001/api/v1/proxy/namespaces/${env.BRANCH_NAME}/services/${FULL_SVC_NAME}:80/"
                    """
                }
            }
        }
    }

    post {
        success {
            echo '배포 성공!'
        }
        failure {
            echo '배포 실패!'
        }
    }
}
