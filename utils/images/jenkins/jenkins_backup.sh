#!/bin/bash

echo "[INFO] Started backup of Jenkins"
echo "Target directory: ./images/backup"

# Backup all secrets and users
sshpass -p $SSH_PASSWORD  rsync -Prvh /var/jenkins_home/users $SSH_USERNAME@$HOST_ADDRESS:/home/asy/autoCOREBIB/workshop/images/backup/jenkins/
sshpass -p $SSH_PASSWORD  rsync -Prvh /var/jenkins_home/jenkins.yaml $SSH_USERNAME@$HOST_ADDRESS:/home/asy/autoCOREBIB/workshop/images/backup/jenkins/

echo "[INFO] Finished backup of Jenkins"
