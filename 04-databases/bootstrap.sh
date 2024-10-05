#!/bin/bash
component=$1
environment=$2 # Dont use env here, it is reserved in linux
yum install python3.11-devel python3.11-pip -y
pip3.11 install ansible botocore boto3
ansible-pull -U https://github.com/daws-76s/roboshop-ansible-roles-tf.git -e component=$component -e env=$environment main-tf.yaml


# Ansible and aws is developed on python

# We need to install ansible in individual nodes also using python, we can install ansible using python or we can install directly,using python we can install other modules also like pip,ansible uses botocore and boto3 python modules to connect to the aws.so for that we need to have aws packages those are botocore and boto3

# Ansible requirements :- 1.botocore and boto3 should install in ansible server | 2.IAM policy should also be there to pull, if these two conditions are there we can implement vault
