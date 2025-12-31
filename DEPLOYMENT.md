# DNS Infrastructure Deployment Guide

This document provides comprehensive instructions for deploying, managing, and scaling the dual DNS infrastructure with PowerDNS, pjdns, and dnsdist.

## Table of Contents
- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Component Details](#component-details)
- [Configuration](#configuration)
- [Testing](#testing)
- [Scaling](#scaling)
- [Management](#management)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)

## Architecture Overview

The DNS infrastructure consists of the following components:

```
                        ┌─────────────┐
                        │   Clients   │
                        └──────┬──────┘
                               │
                               │ DNS Queries (Port 53)
                               ▼
                        ┌─────────────┐
                        │   dnsdist   │  (Load Balancer & Router)
                        └──────┬──────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
              ▼                ▼                ▼
        ┌──────────┐    ┌──────────┐    ┌──────────┐
        │  pjdns   │    │ PowerDNS │    │ PowerDNS │
        │ (Legacy) │    │  Zone 1  │    │  Zone 2  │
        └──────────┘    └──────────┘    └──────────┘
                              │
                              ▼
                        ┌──────────┐
                        │ PowerDNS │
                        │  Zone 3  │
                        └──────────┘
```

### Components

1. **pjdns**: Python-based DNS server handling legacy queries for `example.com` domain
2. **PowerDNS**: High-performance authoritative DNS servers for three zones:
   - Zone 1: `zone1.example.com`
   - Zone 2: `zone2.example.com`
   - Zone 3: `zone3.example.com`
3. **dnsdist**: DNS load balancer routing traffic to appropriate backends based on domain patterns

## Prerequisites

- Docker Engine 20.10 or later
- Docker Compose 1.29 or later
- At least 2GB of available RAM
- 5GB of available disk space
- Ports 53 (UDP/TCP), 5353, 5401-5403, 8081-8084 available

### Installation

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install -y docker.io docker-compose
sudo usermod -aG docker $USER
```

**CentOS/RHEL:**
```bash
sudo yum install -y docker docker-compose
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
```

## Quick Start

### 1. Clone the Repository
```bash
git clone https://github.com/ganeshmd2015/dns-project.git
cd dns-project
```

### 2. Build and Start All Services
```bash
docker-compose up -d --build
```

### 3. Verify Services are Running
```bash
docker-compose ps
```

Expected output:
```
NAME                  STATUS              PORTS
dns-dnsdist           Up                  53/tcp, 53/udp, 8084/tcp
dns-pjdns             Up                  5353/tcp, 5353/udp
dns-powerdns-zone1    Up                  5401/tcp, 5401/udp, 8081/tcp
dns-powerdns-zone2    Up                  5402/tcp, 5402/udp, 8082/tcp
dns-powerdns-zone3    Up                  5403/tcp, 5403/udp, 8083/tcp
```

### 4. Test DNS Resolution
```bash
# Test Zone 1 through dnsdist
dig @localhost zone1.example.com

# Test Zone 2 through dnsdist
dig @localhost www.zone2.example.com

# Test Zone 3 through dnsdist
dig @localhost mail.zone3.example.com

# Test legacy pjdns
dig @localhost example.com
```

## Component Details

### pjdns (Legacy DNS Server)

**Purpose**: Python-based DNS server handling legacy `example.com` queries

**Configuration**: `pjdns/dns_server.py`

**Direct Testing**:
```bash
# Query pjdns directly (bypassing dnsdist)
dig @localhost -p 5353 example.com
```

**Logs**:
```bash
docker logs dns-pjdns -f
```

### PowerDNS Servers

**Purpose**: Authoritative DNS servers with AXFR support for zone transfers

**Zones**:
- **Zone 1**: `zone1.example.com` (IP range: 10.0.1.x)
- **Zone 2**: `zone2.example.com` (IP range: 10.0.2.x)
- **Zone 3**: `zone3.example.com` (IP range: 10.0.3.x)

**Backend**: SQLite database per zone

**Direct Testing**:
```bash
# Test Zone 1 directly
dig @localhost -p 5401 zone1.example.com

# Test Zone 2 directly
dig @localhost -p 5402 zone2.example.com

# Test Zone 3 directly
dig @localhost -p 5403 zone3.example.com
```

**API Access**:
```bash
# Zone 1 API
curl -H "X-API-Key: changeme-zone1-api-key" http://localhost:8081/api/v1/servers/localhost

# Zone 2 API
curl -H "X-API-Key: changeme-zone2-api-key" http://localhost:8082/api/v1/servers/localhost

# Zone 3 API
curl -H "X-API-Key: changeme-zone3-api-key" http://localhost:8083/api/v1/servers/localhost
```

**AXFR Zone Transfer**:
```bash
# Perform zone transfer for Zone 1
dig @localhost -p 5401 zone1.example.com AXFR

# Perform zone transfer for Zone 2
dig @localhost -p 5402 zone2.example.com AXFR
```

### dnsdist (Load Balancer)

**Purpose**: Distribute DNS traffic based on routing rules

**Configuration**: `dnsdist/dnsdist.conf`

**Routing Rules**:
- `*.zone1.example.com` → PowerDNS Zone 1
- `*.zone2.example.com` → PowerDNS Zone 2
- `*.zone3.example.com` → PowerDNS Zone 3
- `*.example.com` → pjdns (legacy)
- Other queries → Load balanced across PowerDNS servers

**Management Interface**: http://localhost:8084
- Username: `admin`
- Password: `changeme-dnsdist-password`

**Statistics**:
```bash
docker exec dns-dnsdist dnsdist -e "showServers()"
docker exec dns-dnsdist dnsdist -e "showRules()"
```

## Configuration

### Adding DNS Records to PowerDNS

**Using API**:
```bash
# Add A record to Zone 1
curl -X PATCH http://localhost:8081/api/v1/servers/localhost/zones/zone1.example.com \
  -H "X-API-Key: changeme-zone1-api-key" \
  -H "Content-Type: application/json" \
  -d '{
    "rrsets": [{
      "name": "app.zone1.example.com.",
      "type": "A",
      "ttl": 3600,
      "changetype": "REPLACE",
      "records": [{
        "content": "10.0.1.50",
        "disabled": false
      }]
    }]
  }'
```

**Using SQLite Directly**:
```bash
# Access Zone 1 database
docker exec -it dns-powerdns-zone1 sqlite3 /var/lib/powerdns/zone1.sqlite3

# Insert record
INSERT INTO records (domain_id, name, type, content, ttl) 
VALUES (1, 'api.zone1.example.com', 'A', '10.0.1.60', 3600);

# Exit and restart
.exit
docker-compose restart powerdns-zone1
```

### Modifying dnsdist Routing Rules

Edit `dnsdist/dnsdist.conf` and add new rules:

```lua
-- Add custom routing rule
addAction(SuffixMatchNodeRule("custom.example.com"), PoolAction("zone1"))
```

Restart dnsdist:
```bash
docker-compose restart dnsdist
```

### Adjusting Resource Limits

Edit `docker-compose.yml` to add resource limits:

```yaml
services:
  powerdns-zone1:
    # ... existing config ...
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
```

## Testing

### Basic DNS Queries

```bash
# A record lookup
dig @localhost www.zone1.example.com A

# MX record lookup
dig @localhost zone2.example.com MX

# NS record lookup
dig @localhost zone3.example.com NS

# SOA record lookup
dig @localhost zone1.example.com SOA
```

### Load Testing

Use `dnsperf` for load testing:

```bash
# Install dnsperf
sudo apt-get install dnsperf

# Create query file
cat > queries.txt << EOF
zone1.example.com A
www.zone2.example.com A
mail.zone3.example.com A
EOF

# Run load test
dnsperf -s localhost -d queries.txt -l 30 -c 100
```

### Health Checks

```bash
# Check all container health status
docker-compose ps

# Manual health check for specific service
docker exec dns-dnsdist dnsdist -e "showServers()"
docker exec dns-powerdns-zone1 pdns_control ping
```

## Scaling

### Vertical Scaling (Increase Resources)

Edit `docker-compose.yml` to increase CPU and memory:

```yaml
services:
  powerdns-zone1:
    deploy:
      resources:
        limits:
          cpus: '4'
          memory: 2G
```

Apply changes:
```bash
docker-compose up -d --no-deps powerdns-zone1
```

### Horizontal Scaling (Add More Instances)

**Add PowerDNS Zone 4**:

1. Create zone4 directory:
```bash
mkdir -p powerdns/zone4
cp powerdns/zone1/pdns.conf powerdns/zone4/
cp powerdns/zone1/init-db.sh powerdns/zone4/
```

2. Update configuration files for zone4

3. Add to `docker-compose.yml`:
```yaml
  powerdns-zone4:
    build:
      context: ./powerdns
      dockerfile: Dockerfile
    container_name: dns-powerdns-zone4
    networks:
      dns-network:
        ipv4_address: 172.20.0.14
    ports:
      - "5404:53/udp"
      - "5404:53/tcp"
      - "8085:8081/tcp"
    volumes:
      - ./powerdns/zone4/pdns.conf:/etc/powerdns/pdns.conf:ro
      - ./powerdns/zone4/init-db.sh:/usr/local/bin/init-db.sh:ro
      - powerdns-zone4-data:/var/lib/powerdns
    restart: unless-stopped
```

4. Update `dnsdist/dnsdist.conf`:
```lua
newServer({address="powerdns-zone4:53", name="powerdns-zone4", pool="zone4"})
addAction(SuffixMatchNodeRule("zone4.example.com"), PoolAction("zone4"))
```

5. Rebuild and restart:
```bash
docker-compose up -d --build
```

### Load Balancing Between Multiple Backends

Add multiple PowerDNS instances to the same pool in `dnsdist.conf`:

```lua
-- Multiple backends for zone1
newServer({address="powerdns-zone1a:53", name="zone1a", pool="zone1"})
newServer({address="powerdns-zone1b:53", name="zone1b", pool="zone1"})
```

## Management

### Starting Services

```bash
# Start all services
docker-compose up -d

# Start specific service
docker-compose up -d powerdns-zone1

# Start with rebuild
docker-compose up -d --build
```

### Stopping Services

```bash
# Stop all services
docker-compose down

# Stop specific service
docker-compose stop powerdns-zone1

# Stop and remove volumes
docker-compose down -v
```

### Viewing Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f dnsdist
docker-compose logs -f powerdns-zone1

# Last 100 lines
docker-compose logs --tail=100 powerdns-zone1
```

### Restarting Services

```bash
# Restart all
docker-compose restart

# Restart specific service
docker-compose restart dnsdist
```

### Backup and Restore

**Backup PowerDNS Database**:
```bash
# Backup Zone 1
docker exec dns-powerdns-zone1 sqlite3 /var/lib/powerdns/zone1.sqlite3 .dump > zone1-backup.sql

# Backup all zones
for zone in zone1 zone2 zone3; do
  docker exec dns-powerdns-$zone sqlite3 /var/lib/powerdns/$zone.sqlite3 .dump > $zone-backup.sql
done
```

**Restore PowerDNS Database**:
```bash
# Restore Zone 1
cat zone1-backup.sql | docker exec -i dns-powerdns-zone1 sqlite3 /var/lib/powerdns/zone1.sqlite3
docker-compose restart powerdns-zone1
```

### Monitoring

**dnsdist Statistics**:
```bash
# Show backend server status
docker exec dns-dnsdist dnsdist -e "showServers()"

# Show routing rules
docker exec dns-dnsdist dnsdist -e "showRules()"

# Show cache statistics
docker exec dns-dnsdist dnsdist -e "showCacheHitResponseRules()"
```

**PowerDNS Statistics**:
```bash
# Get statistics via API
curl -H "X-API-Key: changeme-zone1-api-key" \
  http://localhost:8081/api/v1/servers/localhost/statistics
```

## Troubleshooting

### Common Issues

**1. Port Conflicts**

Error: `Bind for 0.0.0.0:53 failed: port is already allocated`

Solution:
```bash
# Check what's using port 53
sudo lsof -i :53
sudo netstat -tulpn | grep :53

# Stop conflicting service (e.g., systemd-resolved on Ubuntu)
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
```

**2. Container Won't Start**

Check logs:
```bash
docker-compose logs [service-name]
```

Check health status:
```bash
docker inspect dns-powerdns-zone1 | grep -A 10 Health
```

**3. DNS Resolution Fails**

Test each component:
```bash
# Test dnsdist
dig @localhost zone1.example.com

# Test PowerDNS directly
dig @localhost -p 5401 zone1.example.com

# Check dnsdist routing
docker exec dns-dnsdist dnsdist -e "showServers()"
```

**4. AXFR Zone Transfer Fails**

Verify PowerDNS AXFR settings:
```bash
# Check configuration
docker exec dns-powerdns-zone1 cat /etc/powerdns/pdns.conf | grep axfr

# Test zone transfer
dig @localhost -p 5401 zone1.example.com AXFR
```

### Debug Mode

**Enable PowerDNS Debug Logging**:

Edit `powerdns/zone1/pdns.conf`:
```
loglevel=9
```

Restart:
```bash
docker-compose restart powerdns-zone1
docker-compose logs -f powerdns-zone1
```

**Enable dnsdist Verbose Logging**:

Add to `dnsdist/dnsdist.conf`:
```lua
setVerbose(true)
```

Restart:
```bash
docker-compose restart dnsdist
docker-compose logs -f dnsdist
```

### Performance Issues

**Check Resource Usage**:
```bash
docker stats
```

**Check DNS Query Performance**:
```bash
# Measure query time
dig @localhost zone1.example.com | grep "Query time"

# Use dnsperf for detailed metrics
dnsperf -s localhost -d queries.txt
```

## Security Considerations

### Change Default Passwords and API Keys

**PowerDNS API Keys**:
Edit `powerdns/zone*/pdns.conf`:
```
api-key=your-secure-random-key-here
```

**dnsdist Credentials**:
Edit `dnsdist/dnsdist.conf`:
```lua
setWebserverConfig({
  password="your-secure-password",
  apiKey="your-secure-api-key"
})
```

### Restrict Access

**Limit AXFR Transfers**:
Edit `powerdns/zone*/pdns.conf`:
```
allow-axfr-ips=192.168.1.0/24,10.0.0.0/8
```

**Restrict Web API Access**:
Edit `powerdns/zone*/pdns.conf`:
```
webserver-allow-from=127.0.0.1,192.168.1.0/24
```

**Restrict dnsdist Queries**:
Edit `dnsdist/dnsdist.conf`:
```lua
setACL({'192.168.1.0/24', '10.0.0.0/8'})
```

### Firewall Configuration

```bash
# Allow DNS queries
sudo ufw allow 53/udp
sudo ufw allow 53/tcp

# Restrict API access to specific IPs
sudo ufw allow from 192.168.1.0/24 to any port 8081
sudo ufw allow from 192.168.1.0/24 to any port 8082
sudo ufw allow from 192.168.1.0/24 to any port 8083
sudo ufw allow from 192.168.1.0/24 to any port 8084
```

### Enable DNSSEC (Optional)

**PowerDNS DNSSEC**:
```bash
# Enable DNSSEC for zone1
docker exec dns-powerdns-zone1 pdnsutil secure-zone zone1.example.com
docker exec dns-powerdns-zone1 pdnsutil show-zone zone1.example.com
```

### Regular Updates

```bash
# Update base images
docker-compose pull
docker-compose up -d --build

# Update packages in containers (rebuild)
docker-compose build --no-cache
docker-compose up -d
```

## Additional Resources

- [PowerDNS Documentation](https://doc.powerdns.com/)
- [dnsdist Documentation](https://dnsdist.org/documentation.html)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [DNS Best Practices](https://datatracker.ietf.org/doc/html/rfc8499)

## Support

For issues and questions:
- GitHub Issues: https://github.com/ganeshmd2015/dns-project/issues
- PowerDNS Community: https://community.powerdns.com/
