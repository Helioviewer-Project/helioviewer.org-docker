#!/bin/bash
# bootstrap.sh — EC2 first-boot initialization for Helioviewer
#
# This file is a Terraform templatefile. Tokens like ${api_port} are
# substituted by Terraform before the script reaches the instance.
# Shell variables ($PUBLIC_IP, $REPO, etc.) are expanded at runtime by bash.
#
# NOTE: Passwords set in terraform.tfvars must not contain $, `, or \
# as these have special meaning inside an unquoted bash heredoc.
#
# Runs as root via cloud-init. Full output is logged to:
#   /var/log/helioviewer-bootstrap.log

set -euo pipefail
exec > /var/log/helioviewer-bootstrap.log 2>&1

echo "=== Helioviewer bootstrap started at $(date) ==="

# ── 1. Install Docker CE + Compose plugin ─────────────────────────────────────
apt-get update -y
apt-get install -y ca-certificates curl gnupg git openssl

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y \
  docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin

usermod -aG docker ubuntu

# ── 2. Set public IP ──────────────────────────────────────────────────────────
# Injected by Terraform from the aws_eip resource — stable across instance
# type changes and recreations.
PUBLIC_IP=${public_ip}

echo "Public IP: $PUBLIC_IP"

# ── 3. Clone repository and submodules ────────────────────────────────────────
REPO=/home/ubuntu/helioviewer.org-docker

git clone --branch ${git_docker_branch} ${git_docker_remote} "$REPO"

# Initialize submodule config from .gitmodules, then override the remote URLs
# so forks are used before any code is fetched.
git -C "$REPO" submodule init
git -C "$REPO" submodule set-url api             ${git_api_remote}
git -C "$REPO" submodule set-url helioviewer.org ${git_helioviewer_remote}
git -C "$REPO" submodule update

# Checkout the requested branches (submodule update leaves a detached HEAD)
git -C "$REPO/api"             fetch origin && git -C "$REPO/api"             checkout ${git_api_branch}
git -C "$REPO/helioviewer.org" fetch origin && git -C "$REPO/helioviewer.org" checkout ${git_helioviewer_branch}

chown -R ubuntu:ubuntu "$REPO"

# ── 4. Write .env ─────────────────────────────────────────────────────────────
# Terraform substitutes $${...} tokens; bash expands $PUBLIC_IP and $REPO at runtime.
cat > "$REPO/.env" <<ENVEOF
# Bind to all interfaces so ports are reachable from outside the instance
BIND_ADDRESS=0.0.0.0

API_PORT=${api_port}
API_URL=http://$PUBLIC_IP:${api_port}
CLIENT_PORT=${client_port}
CLIENT_URL=http://$PUBLIC_IP
COORDINATOR_PORT=${coordinator_port}
COORDINATOR_URL=http://$PUBLIC_IP:${coordinator_port}

HOST_JPEG2000_PATH=$REPO/data/jp2
HOST_CACHE_PATH=$REPO/data/cache
HOST_LOG_PATH=$REPO/data/log

DATABASE_ROOT_PASSWORD=${database_root_password}
HV_DB_NAME=${hv_db_name}
HV_DB_USER=${hv_db_user}
HV_DB_PASS=${hv_db_pass}

LOCAL_DATA_DIR=/tmp/jp2/push

SUPERSET_CONFIG_FILE=$REPO/superset/superset_config.py
SUPERSET_DB_HOST=postgres
SUPERSET_DB_NAME=${superset_db_name}
SUPERSET_DB_USER=${superset_db_user}
SUPERSET_DB_PASS=${superset_db_pass}
SUPERSET_ADMIN_USER=${superset_admin_user}
SUPERSET_ADMIN_PASS=${superset_admin_pass}
SUPERSET_READ_USER=${superset_read_user}
SUPERSET_READ_PASS=${superset_read_pass}
SUPERSET_GUEST_PK=$REPO/superset/pk.pem
SUPERSET_GUEST_JWT_AUD=helioviewer_audience
SUPERSET_GUEST_ALLOWED_DASHBOARDS=[]

HV_DB_HOST=database
HV_REDIS_HOST=redis
ENVEOF

chown ubuntu:ubuntu "$REPO/.env"

# ── 5. Run manage up as ubuntu ─────────────────────────────────────────────
# Runs as ubuntu so Docker commands use the correct UID/GID (1000:1000)
# for volume-mounted files. runuser -l creates a login shell which picks up
# the docker group membership added above.
runuser -l ubuntu -c "cd '$REPO' && ./manage up"

echo "=== Helioviewer bootstrap completed at $(date) ==="
