#!/bin/bash
component=$1
environment=$2 # dont use env here, it is reserved in linux
yum install python3.11-devel python3.11-pip -y
pip3.11 install ansible botocore boto3
ansible-pull -U https://github.com/daws-76s/roboshop-ansible-roles-tf.git -e component=$component -e env=$environment main-tf.yaml


# ansible and aws is developed on python
# We need to install ansible in individual nodes also using python we can install using python or we can install directly,using python we can install other modules also like pip,botocore and boto3 is used to connect ansible to aws,we need to have aws packages those are botocore and boto3
