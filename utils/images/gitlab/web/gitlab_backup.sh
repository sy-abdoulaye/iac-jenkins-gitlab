#!/bin/bash

echo "[INFO] Started backup of Gitlab"
echo "Target directory: ./utils/backup/gitlab"

# Backup all secrets and config
sshpass -p $SSH_PASSWORD  rsync -Prvh 'ssh -o StrictHostKeyChecking=no' /etc/gitlab/gitlab.rb $SSH_USERNAME@$HOST_ADDRESS:/home/asy/autoCOREBIB/workshop/utils/backup/gitlab/
sshpass -p $SSH_PASSWORD  rsync -Prvh 'ssh -o StrictHostKeyChecking=no' /var/opt/gitlab/backups $SSH_USERNAME@$HOST_ADDRESS:/home/asy/autoCOREBIB/workshop/utils/backup/gitlab/
sshpass -p $SSH_PASSWORD  rsync -Prvh 'ssh -o StrictHostKeyChecking=no' /etc/gitlab/gitlab-secrets.json $SSH_USERNAME@$HOST_ADDRESS:/home/asy/autoCOREBIB/workshop/utils/backup/gitlab/

echo "[INFO] Finished backup of Gitlab"
