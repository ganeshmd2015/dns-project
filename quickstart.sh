#!/bin/bash
# Quick Start Script for DNS Infrastructure
# This script helps users quickly deploy and test the DNS setup

set -e

echo "========================================="
echo "DNS Infrastructure Quick Start"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check if Docker is running
echo "Checking Docker status..."
if ! docker info &> /dev/null; then
    print_error "Docker is not running. Please start Docker and try again."
    exit 1
fi
print_success "Docker is running"
echo ""

# Stop and remove existing containers if any
echo "Cleaning up existing containers..."
docker compose down -v 2>/dev/null || true
print_success "Cleanup complete"
echo ""

# Build and start services
echo "Building and starting DNS services..."
echo "This may take a few minutes on first run..."
if docker compose up -d --build; then
    print_success "All services started successfully"
else
    print_error "Failed to start services"
    exit 1
fi
echo ""

# Wait for services to be ready
echo "Waiting for services to initialize (30 seconds)..."
sleep 30
echo ""

# Check service status
echo "Checking service status..."
docker compose ps
echo ""

# Test DNS resolution
echo "========================================="
echo "Testing DNS Resolution"
echo "========================================="
echo ""

# Test function
test_dns() {
    local domain=$1
    local expected_pattern=$2
    echo "Testing: $domain"
    
    if dig @localhost "$domain" +short | grep -q "$expected_pattern" 2>/dev/null; then
        print_success "Resolved $domain"
        return 0
    else
        print_warning "Could not resolve $domain (service may still be starting)"
        return 1
    fi
}

# Check if dig is available
if ! command -v dig &> /dev/null; then
    print_warning "dig command not found. Install dnsutils to test DNS queries:"
    echo "  Ubuntu/Debian: sudo apt-get install dnsutils"
    echo "  CentOS/RHEL: sudo yum install bind-utils"
    echo ""
    echo "You can test manually with:"
    echo "  dig @localhost zone1.example.com"
    echo "  dig @localhost zone2.example.com"
    echo "  dig @localhost zone3.example.com"
else
    # Test each zone
    test_dns "zone1.example.com" "10.0.1"
    test_dns "www.zone2.example.com" "10.0.2"
    test_dns "zone3.example.com" "10.0.3"
fi

echo ""

# Display access information
echo "========================================="
echo "Access Information"
echo "========================================="
echo ""
echo "DNS Services:"
echo "  Main DNS (dnsdist):     localhost:53"
echo "  pjdns (legacy):         localhost:5353"
echo "  PowerDNS Zone 1:        localhost:5401"
echo "  PowerDNS Zone 2:        localhost:5402"
echo "  PowerDNS Zone 3:        localhost:5403"
echo ""
echo "Web Interfaces:"
echo "  dnsdist Dashboard:      http://localhost:8084"
echo "    Username: admin"
echo "    Password: changeme-dnsdist-password"
echo ""
echo "  PowerDNS Zone 1 API:    http://localhost:8081"
echo "    API Key: changeme-zone1-api-key"
echo ""
echo "  PowerDNS Zone 2 API:    http://localhost:8082"
echo "    API Key: changeme-zone2-api-key"
echo ""
echo "  PowerDNS Zone 3 API:    http://localhost:8083"
echo "    API Key: changeme-zone3-api-key"
echo ""
echo "========================================="
echo "Next Steps"
echo "========================================="
echo ""
echo "View logs:        docker compose logs -f"
echo "Stop services:    docker compose down"
echo "Restart service:  docker compose restart <service-name>"
echo ""
echo "For detailed documentation, see DEPLOYMENT.md"
echo ""
print_success "DNS Infrastructure is ready!"
echo ""
