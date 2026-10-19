# asmagasy-docker-lab

Docker Compose lab that spins up a **Jenkins** controller, a **GitLab EE** instance, and a **GitLab Runner**, wired together on a dedicated Docker network. A single helper script (`deploy_containers.sh`) drives the whole lifecycle: build, start, stop, reset, backup and restore.

## Architecture

| Service | Image | Purpose |
|---|---|---|
| `jenkins_container_asmag` | `jenkins/jenkins:<version>-lts-jdk11` | CI controller, provisioned with a JCasC config and a pinned plugin list |
| `web` (`gitlab_container_asmag`) | `gitlab/gitlab-ee:<version>-ee.0` | GitLab server |
| `gitlab-runner` | `gitlab/gitlab-runner:alpine` | Executes GitLab CI jobs against the local Docker daemon |

All three containers share a user-defined bridge network (`network_asmag`) with static IPs so they can address each other directly (e.g. the runner registering against the GitLab server).

## Repository layout

```
.
├── deploy_containers.sh          # lifecycle script (build/start/stop/reset/backup/restore)
├── docker-compose.yaml           # service definitions
├── env/
│   └── env.env.example           # template for required environment variables
└── utils/
    └── images/
        ├── jenkins/               # Jenkins Dockerfile, JCasC config, plugin list, entrypoint, backup script
        └── gitlab/
            ├── web/                # GitLab Dockerfile + backup script
            └── gitlab-runner/      # GitLab Runner Dockerfile
```

`volumes/` (runtime data for all three containers) and `utils/backup/` (local backup artifacts) are intentionally **not** tracked — see [Data & backups](#data--backups).

## Prerequisites

- Docker and Docker Compose v2
- `sudo` access on the host (volume resets use `sudo rm`)
- A pre-created external Docker network matching `ASMAG_NETWORK_NAME` (the script does not create it until `--build` is passed)

## Setup

1. Copy the environment template and fill in real values:
   ```bash
   cp env/env.env.example env/env.env
   ```
   Set at minimum `SSH_USERNAME`/`SSH_PASSWORD` (used for restore/backup over SSH), `JENKINS_API_TOKEN`, `HOST_ADDRESS`, `GITLAB_EXTERNAL_URL`, `GITLAB_ADMIN`/`ADMIN_PASSWORD`, and the `RESTORED_GITLAB_BACKUP` identifier if you plan to restore from a backup. **Never commit `env/env.env`** — it is gitignored on purpose.

2. Source the script (it must be sourced, not executed, since it manipulates your shell environment):
   ```bash
   source deploy_containers.sh --help
   ```

## Common operations

```bash
# First build: create the network, build both images, start the stack
source deploy_containers.sh --build --build-jenkins-image --build-gitlab-image --start --verbose

# Start / stop / restart an existing stack
source deploy_containers.sh --start
source deploy_containers.sh --stop
source deploy_containers.sh --restart

# Full reset (drops containers, networks, and optionally volumes)
source deploy_containers.sh --reset --reset-jenkins-volume --reset-gitlab-volume

# Refresh the pinned Jenkins plugin list from a running instance
source deploy_containers.sh --username jenkins --token <your-jenkins-api-token> --update-plugins-file --no-proxy

# Backup / restore
source deploy_containers.sh --backup-jenkins --verbose
source deploy_containers.sh --backup-gitlab --verbose
source deploy_containers.sh --restore-jenkins-container --verbose
source deploy_containers.sh --restore-gitlab-container --verbose
```

Run `source deploy_containers.sh --help` for the full flag reference.

## Data & backups

- `volumes/` holds the live state of each container (Jenkins home, GitLab config/data/logs, the runner's Docker socket). It's host-specific and can contain credentials, SSH keys, and database contents — it must never be committed.
- `utils/backup/` is where the backup scripts drop GitLab/Jenkins exports (`gitlab.rb`, `gitlab-secrets.json`, Jenkins user data, etc.). Same rule: local only.

## Security notes

- `env/env.env` carries real credentials (SSH password, Jenkins API token, GitLab admin password) — keep it out of version control and rotate any value that was ever exposed elsewhere.
- The GitLab and Jenkins backup scripts (`gitlab_backup.sh`, `jenkins_backup.sh`) ship secrets and config files over SSH via `sshpass`; treat the target host/credentials as sensitive.
