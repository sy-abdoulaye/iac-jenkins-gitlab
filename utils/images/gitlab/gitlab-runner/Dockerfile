# Start with the gitlab/gitlab-runner:alpine image
FROM gitlab/gitlab-runner:alpine

# Switch to the root user to perform administrative tasks
USER root

# Create the necessary directories and files
RUN echo "####################################" && \
    echo "Creating config.toml file" && \
    mkdir -p /etc/gitlab-runner && \
    touch /etc/gitlab-runner/config.toml && \
    mkdir -p /home/gitlab-runner/.gitlab-runner/&& \
    touch /home/gitlab-runner/.gitlab-runner/config.toml \
    echo "####################################" 

# # Install required packages using apk
RUN echo "Apk update"
RUN apk update && \
    apk add --no-cache sudo nano


# Switch back to the non-root user used by the gitlab-runner image
USER gitlab-runner
