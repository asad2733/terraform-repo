pipeline {
    agent any
environment {
        Cluster_Name = 'awsbgcluster'
        K8s_Version = '1.21'
        Region = 'ap-southeast-1'
        Availability_Zones = 'ap-southeast-1a,ap-southeast-1b'
        NodeGroup_Name = 'awsbgng'
        Instance_Type = 't2.small'
        Desired_Nodes = '1'
        Min_Nodes = '1'
        Max_Nodes = '2'
        Image_Name = 'kgvprasad/mypetclinicapp'
        // Cluster_Name = 'trialcluster'
        // K8s_Version = '1.21'
        // Region = 'us-east-2'
        // Availability_Zones = 'us-east-2a,us-east-2b'
        // NodeGroup_Name = 'trialng'
        // Instance_Type = 't2.small'
        // Desired_Nodes = '1'
        // Min_Nodes = '1'
        // Max_Nodes = '2'
        // Image_Name = 'nginx'
        // Branch_Name = 'MigrationToCloud'

    }
    stages {
        stage('To Create Connection Between AWS and GitHub') {
            input {
                message "Enter AWS CodeGuru Connection Name"
                ok "Proceed"
                parameters {
                    string(name: "Conn_Name", defaultValue: "CodeguruConnection")
                }
            }
            steps {
                  withAWS(credentials:'aws_credentials') {
                  sh '''
                    aws codestar-connections create-connection \
                        --provider-type GitHub \
                        --region ${Region} \
                        --connection-name ${Conn_Name}
                      '''
                }
            }
        }
        stage('Update the Pending Connection') {
            input {
                message "Go to AWS Console, Update the Pending Connection and Click on Proceed Below"
                ok "Proceed"
            }
            steps {
                echo "Connection Between AWS and GitHub Successful"
            }
        }
        stage('To Associate GitHub Repository with AWS CodeGuru Reviewer') {
            input {
                message "Enter GitHub Repository Details"
                ok "Proceed"
                parameters {
                    string(name: "Owner_Name", defaultValue: "asad2733")
                    string(name: "Repo_Name", defaultValue: "spring-petclinic-docker")
                    string(name: "Conn_Arn", defaultValue: "")
                }
            }
            steps {
                  withAWS(credentials:'aws_credentials') {
                  sh '''
                    aws codeguru-reviewer associate-repository \
                        --region ${Region} \
	                    --repository "GitHubEnterpriseServer={Owner=${Owner_Name}, Name=${Repo_Name}, ConnectionArn=${Conn_Arn} }"
                      '''
                }
            }
        }
        stage('To Run AWS CodeReview on the Associated Branch') {
            input {
                message "Enter AWS Code Review Details"
                ok "Proceed"
                parameters {
                    string(name: "CodeReview_Name", defaultValue: "petclinic-code-review")
                    string(name: "Repo_Asso_Arn", defaultValue: "")
                    string(name: "Branch_Name1", defaultValue: "MigrationToCloud")
                }
            }
            steps {
                   withAWS(credentials:'aws_credentials') {
                   sh '''
                    aws codeguru-reviewer create-code-review \
                        --name ${CodeReview_Name} \
                        --region ${Region} \
                        --repository-association-arn ${Repo_Asso_Arn} \
                        --type "{\"'"RepositoryAnalysis\"'":{\"'"RepositoryHead\"'":{\"'"BranchName\"'":\"'"'"${Branch_Name1}\"'"'"}}}"
                      '''
                }
            }
        }
        
        stage('Check Recommendations Provided By AWS CodeGuru') {
            input {
                message "Go to AWS Console, Check the Recommendations Provided by AWS CodeGuru & Take Appropriate Action."
                ok "Proceed"
            }
            steps {
                echo "If Clicked on Proceed, Pipeline will Continue to create EKS Cluster & Deploy Application on to it else Aborded."
            }
        }
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
                  sh './makedocker1.sh'
                  }
            }
        }
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
    
