ARG GITLAB_VERSION

FROM gitlab/gitlab-ee:"$GITLAB_VERSION-ee.0"

USER root

RUN apt-get update \
    && apt-get install sudo nano sshpass -y

USER root
COPY --chown=root:root ./gitlab_backup.sh /var/opt
RUN chmod +x /var/opt/gitlab_backup.sh 
# ENTRYPOINT ["/bin/bash", "-c"]