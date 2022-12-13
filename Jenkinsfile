pipeline {
    agent any
environment {
        Cluster_Name = 'tbdcluster'
        K8s_Version = '1.25'
        Region = 'us-east-1'
        Availability_Zones = 'us-east-1b,us-east-1c'
        NodeGroup_Name = 'tbdng'
        Instance_Type = 't2.medium'
        Desired_Nodes = '1'
        Min_Nodes = '1'
        Max_Nodes = '3'
        Image_Name = 'nginx'

    }
    stages {
        stage('List EKS Cluster') {
            steps {
                   withAWS(credentials:'aws_credentials') {
                   sh '''
                        clusters="$(aws eks list-clusters --region us-east-1 --output text | awk '{print $2}')"
                        echo ${clusters} > myclusters.txt
                      '''
                    script {
                        myCls = readFile('myclusters.txt').trim()
                    }              
                    echo "${myCls} are EKS Clusters found on AWS"
                }
            }
        }
	    stage('EKS Cluster & Node Group Creation & Update Kubeconfig') {
            steps {
                   withAWS(credentials:'aws_credentials') {
                script {
                    if ("${Cluster_Name}" == "${myCls}") {
                        echo "${Cluster_Name} is already present on AWS, jumping to the next stage"
                    } else {
                        echo "${Cluster_Name} not found on AWS, creating ${Cluster_Name}..."
                        sh '''
                                    eksctl create cluster \
                                        --name ${Cluster_Name} \
                                        --version ${K8s_Version} \
                                        --region ${Region} \
                                        --zones "${Availability_Zones}" \
                                        --nodegroup-name ${NodeGroup_Name} \
                                        --node-type ${Instance_Type} \
                                        --nodes ${Desired_Nodes} \
                                        --nodes-min ${Min_Nodes} \
                                        --nodes-max ${Max_Nodes} \
                                        --managed \

                                    aws eks --region ${Region} update-kubeconfig --name ${Cluster_Name}
                                    kubectl get nodes
                                '''        
                        }
                    }
                }
            }
        }
        stage('Create Docker image & push to AWS ECR') {
            steps {
                  withAWS(credentials:'aws_credentials') {
                  sh './makedocker.sh'
                  }
            }
        }
        // stage('List Docker Images from AWS ECR') {
        //     steps {
        //           withAWS(credentials:'aws_credentials') {
        //           sh '''
        //                images="$(aws ecr list-images --repository-name petclinic --region us-east-1 --output=text | awk '{print $3}')"
        //                echo ${images} > myimages.txt
        //               '''
        //             script {
        //                 myImg = readFile('myimages.txt').trim()
        //             }              
        //             echo "${myImg} are ECR Images found on AWS"
        //           }
        //     }
        // }
        stage('Modify Deployment.yaml file ') {
            steps {
                  withCredentials([gitUsernamePassword(credentialsId: 'git_credentials')]) {
                  sh """#!/bin/bash
                           cat cicd/kubernetes/deployment.yaml | grep image
                           sed -i 's|image: .*|image: "${Image_Name}"|' cicd/kubernetes/deployment.yaml
                           cat cicd/kubernetes/deployment.yaml | grep image
                           git status
                           git branch
                           git checkout MigrationToCloud
                           git add .
                           git commit -m "latest deployment file"
                           git push origin HEAD:MigrationToCloud
                           git status
                     """
                  }
            }
        }
        stage('Deploy Application on EKS Cluster') {
            steps {
                  withAWS(credentials:'aws_credentials') {
                  sh '''
                            kubectl apply -f cicd/kubernetes/deployment.yaml
                     '''
                  }
            }
        }

        stage('Create K8s Service ') {
            steps {
                  withAWS(credentials:'aws_credentials') {
                  sh '''
                            kubectl apply -f cicd/kubernetes/service_external.yaml
                            sleep 100
                            kubectl get svc -o wide
                     '''
                  }
            }
        }
    }
}
    
