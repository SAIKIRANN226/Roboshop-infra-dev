#!/bin/bash
component=$1
environment=$2 # Dont use short name "env" here, it is reserved in linux
yum install python3.11-devel python3.11-pip -y
pip3.11 install ansible botocore boto3
ansible-pull -U https://github.com/daws-76s/roboshop-ansible-roles-tf.git -e component=$component -e env=$environment main-tf.yaml


# We need to install ansible in individual nodes also
# If ansible wants to connect to aws then we need to install boto3 and botocore
# Because ansible and aws is developed on the python only
# ansible-pull -U "URL" pulls the ansible-playbooks from the a VCS repo and execute them on target machine, so we give only "localhost"