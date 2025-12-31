#!/bin/bash
# DNS Infrastructure Validation Script
# This script helps verify that the DNS setup is configured correctly

set -e

echo "========================================="
echo "DNS Infrastructure Validation"
echo "========================================="
echo ""

# Check Docker
echo "Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed"
    exit 1
fi
DOCKER_VERSION=$(docker --version)
echo "✓ Docker found: $DOCKER_VERSION"
echo ""

# Check Docker Compose
echo "Checking Docker Compose installation..."
if ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose is not installed"
    exit 1
fi
COMPOSE_VERSION=$(docker compose version)
echo "✓ Docker Compose found: $COMPOSE_VERSION"
echo ""

# Validate docker-compose.yml
echo "Validating docker-compose.yml..."
if ! docker compose config --quiet; then
    echo "❌ docker-compose.yml is invalid"
    exit 1
fi
echo "✓ docker-compose.yml is valid"
echo ""

# Check Python syntax
echo "Validating Python DNS server script..."
if ! python3 -m py_compile pjdns/dns_server.py 2>/dev/null; then
    echo "❌ Python script has syntax errors"
    exit 1
fi
echo "✓ Python DNS server script is valid"
echo ""

# Check bash scripts
echo "Validating initialization scripts..."
for script in powerdns/zone*/init-db.sh; do
    if ! bash -n "$script"; then
        echo "❌ $script has syntax errors"
        exit 1
    fi
done
echo "✓ All initialization scripts are valid"
echo ""

# Check port availability
echo "Checking port availability..."
PORTS=(53 5353 5401 5402 5403 8081 8082 8083 8084)
PORTS_IN_USE=()

for port in "${PORTS[@]}"; do
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1 || nc -z localhost $port 2>/dev/null; then
        PORTS_IN_USE+=($port)
    fi
done

if [ ${#PORTS_IN_USE[@]} -gt 0 ]; then
    echo "⚠️  The following ports are already in use: ${PORTS_IN_USE[*]}"
    echo "   You may need to stop services using these ports or modify the docker-compose.yml"
    echo "   On Ubuntu, systemd-resolved often uses port 53:"
    echo "   sudo systemctl stop systemd-resolved"
    echo ""
else
    echo "✓ All required ports are available"
    echo ""
fi

# Check file permissions
echo "Checking file permissions..."
for script in powerdns/zone*/init-db.sh; do
    if [ ! -x "$script" ]; then
        echo "❌ $script is not executable"
        exit 1
    fi
done
echo "✓ All scripts have execute permissions"
echo ""

# Summary
echo "========================================="
echo "Validation Summary"
echo "========================================="
echo "✓ Docker and Docker Compose installed"
echo "✓ Configuration files are valid"
echo "✓ All scripts have correct syntax"
echo "✓ File permissions are correct"
if [ ${#PORTS_IN_USE[@]} -eq 0 ]; then
    echo "✓ All required ports are available"
else
    echo "⚠️  Some ports may need attention"
fi
echo ""
echo "Your DNS infrastructure is ready to deploy!"
echo ""
echo "Next steps:"
echo "  1. Review and update security settings in configuration files"
echo "  2. Start services: docker compose up -d --build"
echo "  3. Check status: docker compose ps"
echo "  4. View logs: docker compose logs -f"
echo ""
