git clone https://github.com/asad2733/spring-petclinic-docker.git
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 615441698862.dkr.ecr.us-east-1.amazonaws.com
docker build -t petclinic .
docker tag petclinic:latest 615441698862.dkr.ecr.us-east-1.amazonaws.com/petclinic:3.1
docker push 615441698862.dkr.ecr.us-east-1.amazonaws.com/petclinic:3.1
