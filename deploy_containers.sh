# /bin/bash
unset NO_CACHE_CMD SSH_PASSWORD JENKINS_API_TOKEN JENKINS_USER_NAME NO_PROXY PLUGINS_FILE SSH_USERNAME SSH_PASSWORD

# set parameters 
BACKUP_JENKINS=0
BACKUP_GITLAB=0
BUILD_CONTAINER=0
BUILD_JENKINS_IMAGE=0
BUILD_GITLAB_IMAGE=0
NO_CACHE=0
RESTART_CONTAINER=0
RESET_CONTAINER=0
RESTORE_JENKINS_CONTAINER=0
RESET_GTILAB_VOLUME=0
RESET_JENKINS_VOLUME=0
RESTORE_GITLAB_CONTAINER=0
START_CONTAINER=0
STOP_CONTAINER=0
UPDATE_JENKINS_PLUGINS=0


DOCKER_COMPOSE="docker-compose"
DOCKER="docker"
STDIN_REDIRECT="2>/dev/null 1>&2"
source env/env.env
PLUGINS_FILE="jenkins-$VERSION.txt"
BUILD_PROGRESS="plain"

if [ ${BASH_SOURCE[0]} == ${0} ]; then
    echo "[ERROR]: > You have to run the script as source: 'source ${BASH_SOURCE[0]} [ARGS...]'"
    return 1
fi

helper="
        HELP:           
            [ -b|--build ]                          create containers network.
            [ -bji|--build-jenkins-image ]          build jenkins container image.
            [ -bgi|--build-gitlab-image ]           build gitlab container image.
            [ -BJ|--backup-jenkins ]                backup the Jenkins service running in the container.
            [ -BG|--backup-gitlab ]                 backup the Gitlab service running in the container.
            [ -h|--help ]                           outputs this helper.
            [ -n|--no-proxy ]                       disables proxy for plugins retrieval.
            [ -nc|--no-cache ]                      build the container image without relying on cache.
            [ -P|--sudo ]                           sudo password.
            [ -r|--reset ]                          reset the container networks and images orphans.
            [ -rjv|--reset-jenkins-volume ]         reset jenkins container volumes.
            [ -rgv|--reset-gitlab-volume ]          reset gitlab container volumes.
            [ -rt|--restart ]                       start the container.
            [ -RJ|--restore-jenkins-container ]     restores jenkins containers from backups.
            [ -RG|--restore-gitlab-container ]      restores gitlab containers from backups.
            [ -st|--start ]                         start the container.
            [ -sp|--stop ]                          stop the container.
            [ -t|--token ]                          jenkins api token.
            [ -u|--username ]                       username to ssh into the host containing the secrets for jenkins.
            [ -U|--update-plugins-file ]            updates the plugins file from your jenkins environment.
            [ -v|--verbose ]                        enable verbosity.

    "
while [ $# -gt 0 ]; do
    case $1 in 
        -h|--help)
        echo "
###############################################################################################################################
                                                        Script for deploying container infrastructures
###############################################################################################################################
$helper
EXAMPLE:
    To build the container, you must use:
        clear && source deploy_containers.sh username jenkins -P '<your-sudo-password>' --reset --build --start --restore --verbose
        clear && source deploy_containers.sh --reset --reset-jenkins-volume --build --build-jenkins-image --start --restore-jenkins-container --no-cache --verbose

        source deploy_containers.sh --reset --reset-jenkins-volume --build --build-jenkins-image  --start  --no-cache --verbose
        source deploy_containers.sh  --restore-gitlab-container --no-cache --verbose --build-gitlab-image --reset-gitlab-volume 

    You can update and save the plugins in a file like this:
        source deploy_containers.sh username jenkins --token <jenkins_api_token> --update-plugins-file --no-proxy
        source deploy_containers.sh --username jenkins --token <your-jenkins-api-token> --update-plugins-file --no-proxy

    You can backup the container with:
        source deploy_containers.sh --backup-<service> --verbose

    You can restore the backups to the container with:
        source deploy_containers.sh --restore-<service> --verbose
        "
        return
        ;;
        -b|--build)
            BUILD_CONTAINER=1
            shift
            ;;
        -bji|--build-jenkins-image)
            BUILD_JENKINS_IMAGE=1
            shift
            ;;
        -bgi|--build-gitlab-image)
            BUILD_GITLAB_IMAGE=1
            shift
            ;;
        -n|--no-proxy)
            NO_PROXY=1
            shift
            ;;
        -nc|--no-cache)
            NO_CACHE=1
            shift
            ;;
        -st|--start)
            START_CONTAINER=1
            shift
            ;;
        -rt|--restart)
            RESTART_CONTAINER=1
            shift
            ;;
        -sp|--stop)
            STOP_CONTAINER=1
            shift
            ;;
        -r|--reset)
            RESET_CONTAINER=1
            shift
            ;;
        -rgv|--reset-gitlab-volume)
            RESET_GTILAB_VOLUME=1
            shift
            ;;
        -rjv|--reset-jenkins-volume)
            RESET_JENKINS_VOLUME=1
            shift
            ;;
        -P|--sudo-password)
            SSH_PASSWORD=$2
            shift
            shift
            ;;
        -U|--update-plugins-file)
            UPDATE_JENKINS_PLUGINS=1
            shift
            ;;
        -t|--token)
            JENKINS_API_TOKEN=$2
            shift
            shift
            ;;
        -u|--username)
            JENKINS_USER_NAME=$2
            shift
            shift
            ;;
        -RJ|--restore-jenkins-container)
            RESTORE_JENKINS_CONTAINER=1
            shift
            ;;
        -RG|--restore-gitlab-container)
            RESTORE_GITLAB_CONTAINER=1
            shift
            ;;
        -BJ|--backup-jenkins)
            BACKUP_JENKINS=1
            shift
            ;;
        -BG|--backup-gitlab)
            BACKUP_GITLAB=1
            shift
            ;;
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        -*|--*)
        echo "
################################################################################################################
                                    [ERROR] unknown argument $1
################################################################################################################
$helper
################################################################################################################
"   
    return
    ;;
    *)
    VERSION=("$1")
    shift
    ;;

    esac
done

if [[ $VERBOSE -eq 1 ]]; then
    BUILD_PROGRESS="plain"
    STDIN_REDIRECT=
fi

if [[ $NO_CACHE -eq 1 ]]; then
    NO_CACHE_CMD="--no-cache"
fi

# Section: Resetting containers
if [[ $RESET_CONTAINER -eq 1 ]]; then
    echo "[START] Resetting containers..."

    echo "[INFO] Removing orphans..."
    $DOCKER_COMPOSE --env-file env/env.env down -v --remove-orphans

    if [[ $RESET_JENKINS_VOLUME -eq 1 ]]; then
        echo "[INFO]Removing Jenkins containers volumes..."
        # echo "$SSH_PASSWORD" | sudo -S rm -rf ./volumes/jenkins/jenkins_home/* 2>/dev/null
        echo "$SSH_PASSWORD" | sudo -S rm -rf ./volumes/jenkins/jenkins_home/{.,}* 2>/dev/null
        echo "[INFO] Finished removing gitlab container volumes."
    fi

    if [[ $RESET_GTILAB_VOLUME -eq 1 ]]; then
        echo "[INFO] Removing gitlab containers volumes..."
        echo "$SSH_PASSWORD" | sudo -S find ./volumes/gitlab/gitlab-runner/ -type f -not -name 'config.toml' -exec rm -f {} \;
        echo "$SSH_PASSWORD" | sudo -S rm -rf ./volumes/gitlab/web/* 2>/dev/null
    fi

    echo "[INFO] Deleting network"
    $DOCKER network rm $ASMAG_NETWORK_NAME

    echo "[END] Finished resetting container."
fi

# # Section: Building containers
# if [[ $BUILD_CONTAINER -eq 1 ]]; then
#     echo "[START] Building containers started..."
    
#     # Create Docker network
#     echo "[INFO] Creating Docker network..."
#     $DOCKER network create $ASMAG_NETWORK_NAME --subnet $SUBNET
#     echo "[INFO] Docker network creation finished..."
    
#     if [[ $BUILD_JENKINS_IMAGE -eq 1 ]]; then
#         # Build Jenkins container image with plugins
#         echo "[INFO] Building Jenkins container image with plugins started..."
#         if ! $DOCKER_COMPOSE --env-file env/env.env build $NO_CACHE_CMD --progress $BUILD_PROGRESS --build-arg PLUGINS_FILE=$PLUGINS_FILE; then
#             echo "[ERROR] Failed to build Jenkins container image with plugins."
#             return 1
#         fi
#         echo "[INFO] Building Jenkins container with plugin finished..."
#     fi
    
#     if [[ $BUILD_GITLAB_IMAGE -eq 1 ]]; then
#         echo "[INFO] Building Gitlab container image started..."
#         if ! $DOCKER_COMPOSE --env-file env/env.env build $NO_CACHE_CMD --progress $BUILD_PROGRESS; then
#         echo "[ERROR] Failed to build Gitlab container image."
#             return 1
#         fi
#         echo "[INFO] Building Gitlab container finished..."
#         # Change volume permissions
#         echo "[INFO] Changing volume permissions..."
#         echo "$SSH_PASSWORD" | sudo -S chown -R 1000:1000 volumes/jenkins/jenkins_home
#         echo "[INFO] Changing volume permissions finished..."

#     fi
    
#     # Remove unused images
#     echo "[INFO] Removed unused images"
#     $DOCKER image prune -f 
#     echo "[INFO] Remove unused images finished"

#     echo "[END] Building containers Finished..."
# fi

# Section: Building containers
if [[ $BUILD_CONTAINER -eq 1 ]]; then
    echo "[START] Building containers started..."
    
    # Create Docker network
    echo "[INFO] Creating Docker network..."
    $DOCKER network create $ASMAG_NETWORK_NAME --subnet $SUBNET
    echo "[INFO] Docker network creation finished..."
    
    # Building Jenkins and GitLab container images
    echo "[INFO] Building Jenkins and GitLab container images started..."
    if ! $DOCKER_COMPOSE --env-file env/env.env build $NO_CACHE_CMD --progress $BUILD_PROGRESS --build-arg PLUGINS_FILE=$PLUGINS_FILE; then
        echo "[ERROR] Failed to build Jenkins and GitLab container images."
        return 1
    fi
    echo "[INFO] Building Jenkins and GitLab containers finished..."

    # Changing GitLab volumes permissions
    echo "[INFO] Changing volume permissions..."
    echo "$SSH_PASSWORD" | sudo -S chown -R 1000:1000 volumes/jenkins/jenkins_home
    echo "[INFO] Changing volume permissions finished..."
    
    # Remove unused images
    echo "[INFO] Removed unused images"
    $DOCKER image prune -f 
    echo "[INFO] Remove unused images finished"

    echo "[END] Building containers Finished..."
fi


# Section: Starting containers
if [[ $START_CONTAINER -eq 1 ]]; then
    echo "[START] Starting the containers..."
    $DOCKER_COMPOSE --env-file env/env.env up -d
    echo "[END] Containers started..."
fi

if [[ $STOP_CONTAINER -eq 1 ]]; then
    echo "[START] Starting the containers..."
    $DOCKER_COMPOSE --env-file env/env.env down
    echo "[END] Containers started..."
fi

# Section: Restarting containers
if [[ $RESTART_CONTAINER -eq 1 ]]; then
    echo "[START] Stopping containers execution..."
    $DOCKER_COMPOSE --env-file env/env.env restart
    echo "[END] ContainerS have been stopped..."
fi

# Section: Updating and storing containers plugins
if [[ $UPDATE_JENKINS_PLUGINS -eq 1 ]]; then

    echo "[START] Updating and storing jenkins plugins in a file..."
    if [ -z $JENKINS_API_TOKEN ]; then
        echo "[ERROR]: you need to specify the JENKINS_API_TOKEN"
        unset NO_CACHE_CMD SSH_PASSWORD JENKINS_API_TOKEN
        return 1
    fi

    if [ -z $JENKINS_USER_NAME ]; then
        echo "[ERROR]: you need to specify the JENKINS_USER_NAME";
        unset NO_CACHE_CMD SSH_PASSWORD JENKINS_API_TOKEN
        return 1
    fi

    if [ $NO_PROXY -eq 1 ]; then
        NO_PROXY="--noproxy $HOST_ADDRESS"
    fi

    echo "[INFO] Retrieve Jenkins plugins by querying the Jenkins API..."
    PLUGINS_LIST=$(curl $NO_PROXY -H 'Accept: application/json' -H 'Content-Type: application/json' -X POST --user $JENKINS_USER_NAME:$JENKINS_API_TOKEN -L $HOST_ADDRESS:$HTTP_PORT/pluginManager/api/json?depth=1 | jq -r '.plugins[] | "\(.shortName):\(.version)" ' 2>/dev/null )

    if [[ -z $PLUGINS_LIST ]]; then
        echo "[ERROR]: PLUGINS_LIST was not parsed successfully";
        unset NO_CACHE_CMD SSH_PASSWORD JENKINS_API_TOKEN
        return 1
    fi
    echo "[INFO] Retrieve Jenkins plugins by querying the Jenkins API finished..."

    echo "[INFO] Saving plugins list to ./plugins/$PLUGINS_FILE"
    echo $PLUGINS_LIST | sed 's/\s\+/\n/g' > ./plugins/$PLUGINS_FILE
    echo "[INFO] Updating and storing jenkins plugins in a file..."

    echo "[END] Updating and storing jenkins plugins in a file finished..."
fi 

# Section: Backup containers files
if [[ $BACKUP_JENKINS -eq 1 ]]; then
    echo "[START] Backup jenkins config"
    eval """
        docker exec -t -u jenkins $CONTAINER_NAME bash -c '''
            cd /var/jenkins_home
            source jenkins_backup.sh
        '''
    """

    if [[ $? -ne 0 ]]; then
        echo "[ERROR] failed to backup jenkins context."
        return 30000
    fi
    echo "[END] Backup jenkins config finished"
fi

# Section: Backup containers files 
if [[ $BACKUP_GITLAB -eq 1 ]]; then
    echo "[START] Backup gitlab config"

    echo "Created the Gitlab Backup"
    # docker exec -t -u root $GITLAB_CONTAINER_NAME gitlab-backup create STRATEGY=copy -c 
    docker exec -t -u root $GITLAB_CONTAINER_NAME gitlab-rake gitlab:backup:create
    echo "Gitlab backup has created"

    echo "Executed gitlab bash script"
    eval """
        docker exec -t -u root $GITLAB_CONTAINER_NAME bash -c '''
        cd /var/opt/
        source gitlab_backup.sh '''
    """

    if [[ $? -ne 0 ]]; then
        echo "[ERROR] failed to backup jenkins context."
        return 30000
    fi
    echo "[END] Backup jenkins config finished"
fi

# Section: Restoring containers
if [[ $RESTORE_JENKINS_CONTAINER -eq 1 ]]; then
    echo "[START] started restoring jenkins service"
    CONTAINER_RUNNING="$(
        $DOCKER_COMPOSE --env-file env/env.env top -c $CONTAINER_NAME
    )"
   
    if [[ -z ${CONTAINER_RUNNING} ]]; then
        echo "[INFO] Containers are currently stopped, Starting the containers..."
        eval "$STDIN_REDIRECT $DOCKER_COMPOSE --env-file env/env.env up -d"
        echo "[INFO] Containers started..."
    fi

    if [[ -z ${HOST_ADDRESS} ]]; then
        echo "[ERROR]: > you need to specify the remote server address where the secrets and certs are stored.";
        unset NO_CACHE_CMD SSH_PASSWORD JENKINS_API_TOKEN
        return 1
    fi

    if [[ -z ${SSH_USERNAME} || -z ${SSH_PASSWORD} ]]; then
        echo "[ERROR]: > you need to specify the credentials to authenticate to the remote server where the secrets and certs are stored.";
        unset NO_CACHE_CMD SSH_PASSWORD JENKINS_API_TOKEN
        return 1
    fi

    if [[ $? -ne 0 ]]; then
        echo "[ERROR] failed to build container image."
        unset
        return 30000
    fi

    echo "[INFO] starting process"
    docker exec --user jenkins -ti $CONTAINER_NAME /bin/bash -c """
        sshpass -p ${SSH_PASSWORD} scp -o LogLevel=Error -pr ${SSH_USERNAME}@${HOST_ADDRESS}:/home/asy/autoCOREBIB/workshop/utils/backup/jenkins/* /var/jenkins_home/
    """
    echo "[END] started restoring jenkins service finished"

fi

if [[ $RESTORE_GITLAB_CONTAINER -eq 1 ]]; then
    echo "[START] started restoring gitlab service"

    echo "[INFO] GitLab service restoration is performed using this file...."
    docker cp ./utils/backup/gitlab/backups/$RESTORED_GITLAB_BACKUP'_gitlab_backup.tar' $GITLAB_CONTAINER_NAME:/var/opt/gitlab/backups
    docker exec $GITLAB_CONTAINER_NAME chown -R git:git /var/opt/gitlab/backups/$RESTORED_GITLAB_BACKUP'_gitlab_backup.tar'
    docker cp ./utils/backup/gitlab/gitlab.rb $GITLAB_CONTAINER_NAME:/etc/gitlab/
    docker cp ./utils/backup/gitlab/gitlab-secrets.json $GITLAB_CONTAINER_NAME:/etc/gitlab/
    echo "[INFO] Finished copying the file in the GitLab service."

    # Stop GitLab Runner service
    echo "[INFO] Stopping GitLab Runner service..."
    docker stop gitlab-runner
    echo "[INFO] GitLab Runner service stopped."

    echo "[INFO] Stopped some Gitlab services..."
    eval """
            docker exec -it $GITLAB_CONTAINER_NAME bash -c '''
                gitlab-ctl stop unicorn
                gitlab-ctl stop sidekiq
                gitlab-ctl status
                ls -lart /var/opt/gitlab/backups
            '''
        """
    
   
    # # Stop the processes that are connected to the database
    # docker exec -it $GITLAB_CONTAINER_NAME gitlab-ctl stop puma
    # docker exec -it $GITLAB_CONTAINER_NAME gitlab-ctl stop sidekiq
    # sleep 5
    # # Verify that the processes are all down before continuing
    # docker exec -it $GITLAB_CONTAINER_NAME gitlab-ctl status

    if [[ $? -ne 0 ]]; then
        echo "[INFO] continuing to restore gitlab services..."
    fi
    echo "[INFO] Stopped some Gitlab services finished"

    echo "[INFO] Starting the restoration process..."
    # docker exec -it $GITLAB_CONTAINER_NAME gitlab-rake gitlab:backup:restore BACKUP=/var/opt/gitlab/backups/$RESTORED_GITLAB_BACKUP --trace
    echo "yes" | docker exec -i $GITLAB_CONTAINER_NAME gitlab-rake gitlab:backup:restore BACKUP=/var/opt/gitlab/backups/$RESTORED_GITLAB_BACKUP --trace
    echo "[INFO] The restoration process is complete"

    echo "[INFO] Restart the GitLab container..."
    docker restart $GITLAB_CONTAINER_NAME
    # Check GitLab
    # docker exec -it $GITLAB_CONTAINER_NAME gitlab-rake gitlab:check SANITIZE=true
    # if [[ $? -ne 0 ]]; then
    #     echo "[ERROR] failed to restart gitlab services..."
    #     unset
    #     return 30000
    # fi
    echo "[INFO] Restart Gitlab with sanity check is complete"
    
    # Restart GitLab Runner service
    echo "[INFO] Restarting GitLab Runner service..."
    docker start gitlab-runner 
    docker cp /home/asy/autoCOREBIB/workshop/volumes/gitlab/gitlab-runner/config.toml gitlab-runner:/home/gitlab-runner/.gitlab-runner/config.toml
    echo "[INFO] GitLab Runner service restarted."

    echo "[END] started restoring gitlab service"
fi

