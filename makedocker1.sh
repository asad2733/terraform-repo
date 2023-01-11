git clone https://github.com/asad2733/spring-petclinic-docker.git
aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin 460606100227.dkr.ecr.ap-southeast-1.amazonaws.com
docker build -t awsbg .
docker tag awsbg:latest 460606100227.dkr.ecr.ap-southeast-1.amazonaws.com/awsbg:latest
docker push 460606100227.dkr.ecr.ap-southeast-1.amazonaws.com/awsbg:latest
