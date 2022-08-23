pipeline {
    agent any
environment {
        Cluster_Name = 'tbdcluster'
        Region = 'us-east-1'
        Vpc = 'vpc-fa45c687'
        Subnets = 'subnet-aed9a9f1,subnet-288da426'
        Launch_Type = 'EC2'
        Desired_Size = '1'
        Instance_Type = 't2.small'
        Key_Name = 'asad'
        LogGrp_Name = 'nginx-td-12'
        TaskDef_Family = 'nginx-td'
        Container_Name = 'nginx-c2'
        Image_Name = 'nginx'
        Port_No = '80'
        No_of_Task = '2'

    }
    stages {
        stage('List ECS Cluster') {
            steps {
                   withAWS(credentials:'aws_credentials') {
                   sh '''
                        ecsclsarn="$(aws ecs list-clusters --region ${Region} --output text | awk '{print $2}')"
                        ecscls="$(aws ecs describe-clusters --region ${Region} --cluster=${ecsclsarn} --output text | awk '{print $4}')"
                        echo ${ecscls} > myecsclusters.txt
                      '''
                    script {
                        myecsCls = readFile('myecsclusters.txt').trim()
                    }              
                    echo "${myecsCls} are ECS Clusters found on AWS"
                }
            }
        }

	    stage('ECS Cluster Creation') {
            steps {
                  withAWS(credentials:'aws_credentials') {
                script {
                    if ("${Cluster_Name}" == "${myecsCls}") {
                        echo "${Cluster_Name} is already present on AWS, jumping to the next stage"
                    } else {
                        echo "${Cluster_Name} not found on AWS, creating ${Cluster_Name}..."
                        sh '''
                            ecs-cli up --capability-iam \
                                --cluster ${Cluster_Name} \
                                --vpc ${Vpc} \
                                --subnets "${Subnets}" \
                                --launch-type ${Launch_Type} \
                                --size ${Desired_Size}  \
                                --region ${Region} \
                                --instance-type ${Instance_Type} \
                                --keypair ${Key_Name} \
                            '''
                        }
                    }
                }
            }
        }        
            
        stage('Create Log Group') {
            steps {
                  withAWS(credentials:'aws_credentials') {
                  sh '''
                      aws logs create-log-group \
                          --region ${Region} \
                          --log-group-name /ecs/${LogGrp_Name}
                      '''
                }
            }
        }
            
        stage('Registering a Task Definition') {
            steps {
                  withAWS(credentials:'aws_credentials') {
                  sh '''
                      aws ecs register-task-definition \
                          --region ${Region} \
                          --family ${TaskDef_Family} \
                          --requires-compatibilities ${Launch_Type} \
                          --container-definitions '[{\"'"name\"'":\"'"${Container_Name}\"'",\"'"image\"'":\"'"${Image_Name}\"'",\"memory\":256,\"'"essential\"'":true, "logConfiguration": {"logDriver": "awslogs", "options": {"awslogs-region": "'"${Region}"'", "awslogs-stream-prefix": "ecs", "awslogs-group": "'"/ecs/${LogGrp_Name}"'"}}, "portMappings": [{"containerPort": '${Port_No}', "hostPort": '${Port_No}', "protocol": "tcp" } ]}]'
                      sleep 100
                      '''
                  }
                }
            }
            
        stage('Run a Task on ECS Cluster') {
            steps {
                  withAWS(credentials:'aws_credentials') {
                  sh '''
                    aws ecs run-task \
                        --cluster ${Cluster_Name} \
                        --launch-type ${Launch_Type} \
                        --task-definition ${TaskDef_Family} \
                        --region ${Region} \
                        --count ${No_of_Task}
                      '''
                  }
                }
            }
            
        // stage('Verify Status of Task') {
        //     steps {
        //           withAWS(credentials:'aws_credentials') {
        //           sh '''
        //                 aws ecs list-tasks --cluster tbdcluster --region us-east-1
        //               '''
        //           }
        //         }
        //     }   
            
        // stage('Create Load Balancer, Target Groups & Service on ECS') {
        //     steps {
        //           withAWS(credentials:'aws_credentials') {
        //           sh '''
        //             lb="$(aws elbv2 create-load-balancer --name app-load-balancer \
	    //                --subnets subnet-aed9a9f1 subnet-42e59224 \
	    //                --security-groups sg-0ae1c1db565622ba8 \
	    //                --region us-east-1 \
	    //                --output text | awk '{print $6}')"
	                   
        //             targrp="$(aws elbv2 create-target-group --name ecs-targets \
	    //                --protocol HTTP \
	    //                --port 80 \
	    //                --region us-east-1 \
	    //                --vpc-id vpc-fa45c687 \
	    //                --output text | awk '{print $11}')"
	                   
	    //             ecsinstlist="$(aws ecs list-container-instances \
	    //                --region us-east-1 \
        //                --cluster tbdcluster --output text | awk '{print $2}')"
                       
        //             ecsinstid="$(aws ecs describe-container-instances --cluster tbdcluster \
        //                --region us-east-1 \
        //                --container-instances ${ecsinstlist} | grep ec2InstanceId | awk '{print $2}' | tr -d '"' | tr -d ',')"
	                   
        //             aws elbv2 register-targets --target-group-arn ${targrp} \
	    //                --targets Id=${ecsinstid} \
	    //                --region us-east-1 \
	    //                --debug
	                   
        //             aws elbv2 create-listener --load-balancer-arn ${lb} \
	    //                --protocol HTTP \
	    //                --port 80  \
	    //                --region us-east-1 \
	    //                --default-actions Type=forward,TargetGroupArn=${targrp}
	                   
        //             aws ecs create-service \
        //                     --cluster tbdcluster \
        //                     --region us-east-1 \
        //                     --service-name tbdservice \
        //                     --launch-type EC2 \
        //                     --load-balancers \"targetGroupArn=$targrp,containerName=nginx-c2,containerPort=80\" \
        //                     --task-definition nginx-td \
        //                     --desired-count 2 
        //             sleep 100
        //             aws elbv2 describe-load-balancers --region us-east-1 --names app-load-balancer | grep DNSName
        //               '''
        //           }
        //         }
        //     }
            
        // stage('Create a Service on ECS') {
        //     steps {
        //           withAWS(credentials:'aws_credentials') {
        //           sh '''
        //                 aws ecs create-service \
        //                     --cluster tbdcluster \
        //                     --region us-east-1 \
        //                     --service-name tbdservice \
        //                     --load-balancers '[{"targetGroupArn": "${targrp}","containerName": "nginx-c2","containerPort": 80}]' \
        //                     --task-definition nginx-td \
        //                     --desired-count 2
        //                 aws elbv2 describe-load-balancers --region us-east-1 --names app-load-balancer | grep DNSName
        //               '''
        //           }
        //         }
        //     }
            }
        }
    
