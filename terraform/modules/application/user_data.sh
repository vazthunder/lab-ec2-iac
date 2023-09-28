#!/bin/bash -ex

# docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo bash get-docker.sh
sudo usermod -aG docker admin

# codedeploy agent
curl -fsSL  https://aws-codedeploy-us-east-2.s3.us-east-2.amazonaws.com/latest/install -o install
sudo apt install ruby-full
sudo chmod +x install
sudo ./install auto > /tmp/codedeploy_agent_install.log
sudo service codedeploy-agent start
