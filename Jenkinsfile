pipeline {
    agent any
environment {
        Cluster_Name = 'awsbgcluster'
        K8s_Version = '1.22'
        Region = 'us-east-1'
        Availability_Zones = 'us-east-1b,us-east-1c'
        NodeGroup_Name = 'awsbgng'
        Instance_Type = 't2.medium'
        Desired_Nodes = '1'
        Min_Nodes = '1'
        Max_Nodes = '5'

    }
    stages {
        stage('List EKS Cluster') {
            steps {
                   withAWS(credentials:'aws_credentials') {
                   sh '''
                        clusters="$(aws eks list-clusters --region us-east-1 --output text | awk '{print $2}')"
                        echo ${clusters} > myfile.txt
                      '''
                    script {
                        myVar = readFile('myfile.txt').trim()
                    }              
                    echo "${myVar} are EKS Clusters found on AWS"
                }
            }
        }
	    stage('EKS Cluster & Node Group Creation & Update Kubeconfig') {
            steps {
                   withAWS(credentials:'aws_credentials') {
                script {
                    if ("${Cluster_Name}" == "${myVar}") {
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
                            sleep 50
                            kubectl get svc -o wide
                     '''
                  }
            }
        }
    }
}
    
