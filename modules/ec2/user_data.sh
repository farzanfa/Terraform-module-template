#!/bin/bash
# =============================================================================
# EC2 User Data Script
# Installs and configures: Docker, PostgreSQL 18, Valkey (Redis 8 compatible)
# =============================================================================

set -e

# -----------------------------------------------------------------------------
# Variables from Terraform
# -----------------------------------------------------------------------------
ENVIRONMENT="${environment}"
BACKEND_LOG_GROUP="${backend_log_group_name}"
SYSTEM_LOG_GROUP="${system_log_group_name}"
AWS_REGION="${aws_region}"

# -----------------------------------------------------------------------------
# System Updates
# -----------------------------------------------------------------------------
echo "=== Updating system packages ==="
dnf update -y

# -----------------------------------------------------------------------------
# Install Docker
# -----------------------------------------------------------------------------
echo "=== Installing Docker ==="
dnf install -y docker

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add ec2-user to docker group
usermod -aG docker ec2-user

# -----------------------------------------------------------------------------
# Install Docker Compose
# -----------------------------------------------------------------------------
echo "=== Installing Docker Compose ==="
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# -----------------------------------------------------------------------------
# Install PostgreSQL 18
# -----------------------------------------------------------------------------
echo "=== Installing PostgreSQL 18 ==="

# Install PostgreSQL repository
dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm

# Disable default PostgreSQL module
dnf -qy module disable postgresql

# Install PostgreSQL 18
dnf install -y postgresql18-server postgresql18

# Initialize PostgreSQL database
/usr/pgsql-18/bin/postgresql-18-setup initdb

# Configure PostgreSQL to listen on localhost only
cat >> /var/lib/pgsql/18/data/postgresql.conf << 'EOF'
listen_addresses = 'localhost'
port = 5432
max_connections = 100
shared_buffers = 256MB
effective_cache_size = 768MB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 8MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200
min_wal_size = 1GB
max_wal_size = 4GB
EOF

# Configure PostgreSQL authentication
cat > /var/lib/pgsql/18/data/pg_hba.conf << 'EOF'
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all             postgres                                peer
local   all             all                                     peer
host    all             all             127.0.0.1/32            scram-sha-256
host    all             all             ::1/128                 scram-sha-256
EOF

# Start and enable PostgreSQL
systemctl start postgresql-18
systemctl enable postgresql-18

# -----------------------------------------------------------------------------
# Install Valkey (Redis 8 compatible)
# -----------------------------------------------------------------------------
echo "=== Installing Valkey ==="

# Install build dependencies
dnf groupinstall -y "Development Tools"
dnf install -y tcl

# Download and compile Valkey
cd /tmp
curl -L -o valkey.tar.gz https://github.com/valkey-io/valkey/archive/refs/tags/8.0.0.tar.gz
tar xzf valkey.tar.gz
cd valkey-8.0.0
make
make install PREFIX=/usr/local

# Create Valkey user and directories
useradd -r -s /sbin/nologin valkey
mkdir -p /var/lib/valkey /var/log/valkey /etc/valkey
chown valkey:valkey /var/lib/valkey /var/log/valkey

# Configure Valkey
cat > /etc/valkey/valkey.conf << 'EOF'
bind 127.0.0.1
port 6379
daemonize no
pidfile /var/run/valkey/valkey.pid
loglevel notice
logfile /var/log/valkey/valkey.log
databases 16
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir /var/lib/valkey
maxmemory 256mb
maxmemory-policy allkeys-lru
EOF

chown valkey:valkey /etc/valkey/valkey.conf

# Create systemd service for Valkey
cat > /etc/systemd/system/valkey.service << 'EOF'
[Unit]
Description=Valkey In-Memory Data Store
After=network.target

[Service]
Type=simple
User=valkey
Group=valkey
ExecStart=/usr/local/bin/valkey-server /etc/valkey/valkey.conf
ExecStop=/usr/local/bin/valkey-cli shutdown
Restart=always
RuntimeDirectory=valkey

[Install]
WantedBy=multi-user.target
EOF

# Start and enable Valkey
systemctl daemon-reload
systemctl start valkey
systemctl enable valkey

# -----------------------------------------------------------------------------
# Mount Data Volume
# -----------------------------------------------------------------------------
echo "=== Mounting data volume ==="

# Wait for the volume to be attached
while [ ! -e /dev/sdf ]; do
  echo "Waiting for data volume..."
  sleep 5
done

# Check if the volume has a filesystem
if ! blkid /dev/sdf; then
  echo "Formatting data volume..."
  mkfs -t xfs /dev/sdf
fi

# Create mount point and mount
mkdir -p /data
mount /dev/sdf /data

# Add to fstab for persistence
echo "/dev/sdf /data xfs defaults,nofail 0 2" >> /etc/fstab

# Create data directories
mkdir -p /data/postgresql /data/valkey /data/backend
chown postgres:postgres /data/postgresql
chown valkey:valkey /data/valkey

# -----------------------------------------------------------------------------
# Install CloudWatch Agent
# -----------------------------------------------------------------------------
echo "=== Installing CloudWatch Agent ==="

dnf install -y amazon-cloudwatch-agent

# Configure CloudWatch Agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "$SYSTEM_LOG_GROUP",
            "log_stream_name": "{instance_id}/messages",
            "retention_in_days": 30
          },
          {
            "file_path": "/var/log/docker",
            "log_group_name": "$BACKEND_LOG_GROUP",
            "log_stream_name": "{instance_id}/docker",
            "retention_in_days": 30
          },
          {
            "file_path": "/var/log/valkey/valkey.log",
            "log_group_name": "$SYSTEM_LOG_GROUP",
            "log_stream_name": "{instance_id}/valkey",
            "retention_in_days": 30
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "PasswordManager/$ENVIRONMENT",
    "metrics_collected": {
      "cpu": {
        "measurement": ["cpu_usage_idle", "cpu_usage_user", "cpu_usage_system"],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": ["disk_used_percent"],
        "metrics_collection_interval": 60,
        "resources": ["/", "/data"]
      },
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      }
    }
  }
}
EOF

# Start CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# -----------------------------------------------------------------------------
# Create Docker Compose template for backend
# -----------------------------------------------------------------------------
echo "=== Creating Docker Compose template ==="

mkdir -p /opt/password-manager
cat > /opt/password-manager/docker-compose.yml << 'EOF'
version: '3.8'

services:
  backend:
    image: ${BACKEND_IMAGE:-backend:latest}
    container_name: password-manager-backend
    restart: unless-stopped
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://password_manager:${DB_PASSWORD}@host.docker.internal:5432/password_manager
      - REDIS_URL=redis://host.docker.internal:6379/0
      - ENVIRONMENT=${ENVIRONMENT:-dev}
    extra_hosts:
      - "host.docker.internal:host-gateway"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
EOF

echo "=== User data script completed ==="
