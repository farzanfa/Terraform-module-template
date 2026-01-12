#!/bin/bash
# =============================================================================
# EC2 User Data Script
# Installs Docker and runs PostgreSQL 18 & Valkey as containers
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
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# -----------------------------------------------------------------------------
# Create Data Directories
# -----------------------------------------------------------------------------
echo "=== Creating data directories ==="
mkdir -p /opt/password-manager/data/postgresql
mkdir -p /opt/password-manager/data/valkey
mkdir -p /opt/password-manager/logs

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
        "resources": ["/"]
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
# Create Docker Compose Configuration
# -----------------------------------------------------------------------------
echo "=== Creating Docker Compose configuration ==="

cat > /opt/password-manager/docker-compose.yml << 'EOF'
version: '3.8'

services:
  # ---------------------------------------------------------------------------
  # PostgreSQL 18
  # ---------------------------------------------------------------------------
  postgresql:
    image: postgres:18
    container_name: password-manager-postgresql
    restart: unless-stopped
    ports:
      - "127.0.0.1:5432:5432"
    environment:
      POSTGRES_DB: password_manager
      POSTGRES_USER: password_manager
      POSTGRES_PASSWORD: $${DB_PASSWORD:-changeme}
    volumes:
      - /opt/password-manager/data/postgresql:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U password_manager -d password_manager"]
      interval: 10s
      timeout: 5s
      retries: 5
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  # ---------------------------------------------------------------------------
  # Valkey (Redis 8 Compatible)
  # ---------------------------------------------------------------------------
  valkey:
    image: valkey/valkey:8
    container_name: password-manager-valkey
    restart: unless-stopped
    ports:
      - "127.0.0.1:6379:6379"
    volumes:
      - /opt/password-manager/data/valkey:/data
    command: valkey-server --maxmemory 256mb --maxmemory-policy allkeys-lru --appendonly yes
    healthcheck:
      test: ["CMD", "valkey-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  # ---------------------------------------------------------------------------
  # Backend Application
  # ---------------------------------------------------------------------------
  backend:
    image: $${BACKEND_IMAGE:-backend:latest}
    container_name: password-manager-backend
    restart: unless-stopped
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://password_manager:$${DB_PASSWORD:-changeme}@postgresql:5432/password_manager
      - REDIS_URL=redis://valkey:6379/0
      - ENVIRONMENT=$${ENVIRONMENT:-dev}
    depends_on:
      postgresql:
        condition: service_healthy
      valkey:
        condition: service_healthy
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

networks:
  default:
    name: password-manager-network
EOF

# -----------------------------------------------------------------------------
# Create Environment File Template
# -----------------------------------------------------------------------------
cat > /opt/password-manager/.env.example << 'EOF'
# Database password (CHANGE THIS!)
DB_PASSWORD=your_secure_password_here

# Backend Docker image
BACKEND_IMAGE=your-registry/password-manager-backend:latest

# Environment
ENVIRONMENT=dev
EOF

# Copy as default .env if not exists
cp /opt/password-manager/.env.example /opt/password-manager/.env

# -----------------------------------------------------------------------------
# Start PostgreSQL and Valkey Containers
# -----------------------------------------------------------------------------
echo "=== Starting PostgreSQL and Valkey containers ==="
cd /opt/password-manager
docker-compose up -d postgresql valkey

# Wait for services to be healthy
echo "=== Waiting for services to be healthy ==="
sleep 30

echo "=== User data script completed ==="
echo "PostgreSQL and Valkey are running as Docker containers"
echo "To start the backend: cd /opt/password-manager && docker-compose up -d backend"
