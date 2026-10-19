ARG VERSION
FROM jenkins/jenkins:"$VERSION-lts-jdk11"
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false
ARG PLUGINS_FILE

ENV PLUGINS_FILE=$PLUGINS_FILE

USER root

RUN mkdir -p /var/jenkins_home &&  chown -R jenkins:jenkins /var/jenkins_home
RUN mkdir -p /var/plugins && chown -R jenkins:jenkins /var/plugins

RUN apt-get update \
    && apt-get install -y lsb-release rsync sudo sshpass

USER jenkins
COPY --chown=jenkins:jenkins ./plugins/$PLUGINS_FILE /var/plugins
COPY --chown=jenkins:jenkins ./config/jenkins.yaml /var/jenkins_home
COPY --chown=jenkins:jenkins ./jenkins_backup.sh /var/jenkins_home
COPY --chown=jenkins:jenkins ./jenkins_entrypoint.sh /home/
RUN chmod +x /home/jenkins_entrypoint.sh /var/jenkins_home/jenkins_backup.sh

RUN  java -jar /opt/jenkins-plugin-manager.jar  -f  /var/plugins/$PLUGINS_FILE  --verbose
ENTRYPOINT ["/bin/bash", "-c", "source ./home/jenkins_entrypoint.sh"]
