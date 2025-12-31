# DNS Infrastructure Project

A production-ready dual DNS setup combining PowerDNS and pjdns with intelligent traffic distribution via dnsdist.

## Overview

This project provides a complete DNS infrastructure solution that addresses load challenges and enables DNS zone transfers (AXFR) through a containerized architecture. The system combines:

- **pjdns**: Python-based DNS server for legacy domain handling
- **PowerDNS**: High-performance authoritative DNS servers with AXFR support
- **dnsdist**: Intelligent DNS load balancer and traffic router

## Features

✅ **Multi-Zone Support**: Separate PowerDNS containers for different zones (zone1, zone2, zone3)  
✅ **DNS Load Balancing**: Intelligent traffic distribution with dnsdist  
✅ **Zone Transfers**: Full AXFR support for DNS replication  
✅ **Docker Isolation**: Each component runs in isolated containers  
✅ **Scalability**: Easy vertical and horizontal scaling  
✅ **High Availability**: Health checks and automatic restart policies  
✅ **RESTful API**: PowerDNS API for programmatic management  
✅ **Monitoring**: Built-in statistics and web interfaces  

## Quick Start

### Prerequisites

- Docker Engine 20.10+
- Docker Compose 1.29+
- 2GB RAM minimum
- Ports 53, 5353, 5401-5403, 8081-8084 available

### Option 1: Automated Setup (Recommended)

```bash
# Clone the repository
git clone https://github.com/ganeshmd2015/dns-project.git
cd dns-project

# Validate configuration
./validate.sh

# Quick start (builds, starts, and tests services)
./quickstart.sh
```

### Option 2: Manual Setup

```bash
# Clone the repository
git clone https://github.com/ganeshmd2015/dns-project.git
cd dns-project

# Start all services
docker compose up -d --build

# Verify services are running
docker compose ps
```

### Test DNS Resolution

```bash
# Test Zone 1
dig @localhost zone1.example.com

# Test Zone 2
dig @localhost www.zone2.example.com

# Test Zone 3
dig @localhost mail.zone3.example.com

# Test legacy domain
dig @localhost example.com
```

## Architecture

```
Internet/Clients
       │
       ▼
   dnsdist (Port 53)
   Load Balancer
       │
       ├─────────────┬─────────────┬─────────────┐
       ▼             ▼             ▼             ▼
    pjdns      PowerDNS-Z1   PowerDNS-Z2   PowerDNS-Z3
  (Legacy)    (zone1.*)     (zone2.*)     (zone3.*)
```

### Traffic Routing

- `*.zone1.example.com` → PowerDNS Zone 1
- `*.zone2.example.com` → PowerDNS Zone 2  
- `*.zone3.example.com` → PowerDNS Zone 3
- `*.example.com` → pjdns (legacy)
- Other queries → Load balanced across PowerDNS servers

## Project Structure

```
dns-project/
├── docker-compose.yml          # Container orchestration
├── validate.sh                 # Configuration validation script
├── quickstart.sh               # Automated deployment script
├── pjdns/                      # Python DNS server
│   ├── Dockerfile
│   └── dns_server.py
├── powerdns/                   # PowerDNS configurations
│   ├── Dockerfile
│   ├── zone1/
│   │   ├── pdns.conf
│   │   └── init-db.sh
│   ├── zone2/
│   │   ├── pdns.conf
│   │   └── init-db.sh
│   └── zone3/
│       ├── pdns.conf
│       └── init-db.sh
├── dnsdist/                    # DNS load balancer
│   ├── Dockerfile
│   └── dnsdist.conf
└── DEPLOYMENT.md               # Detailed deployment guide
```

## Management

### Access Web Interfaces

- **dnsdist Dashboard**: http://localhost:8084
  - Username: `admin`
  - Password: `changeme-dnsdist-password`

- **PowerDNS Zone 1 API**: http://localhost:8081/api/v1/servers/localhost
- **PowerDNS Zone 2 API**: http://localhost:8082/api/v1/servers/localhost  
- **PowerDNS Zone 3 API**: http://localhost:8083/api/v1/servers/localhost

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f dnsdist
docker-compose logs -f powerdns-zone1
```

### Restart Services

```bash
# Restart all
docker-compose restart

# Restart specific service
docker-compose restart powerdns-zone1
```

### Stop Services

```bash
# Stop all services
docker-compose down

# Stop and remove volumes
docker-compose down -v
```

## Zone Transfers (AXFR)

Perform DNS zone transfers:

```bash
# Transfer zone1
dig @localhost -p 5401 zone1.example.com AXFR

# Transfer zone2
dig @localhost -p 5402 zone2.example.com AXFR

# Transfer zone3
dig @localhost -p 5403 zone3.example.com AXFR
```

## Adding DNS Records

### Via PowerDNS API

```bash
curl -X PATCH http://localhost:8081/api/v1/servers/localhost/zones/zone1.example.com \
  -H "X-API-Key: changeme-zone1-api-key" \
  -H "Content-Type: application/json" \
  -d '{
    "rrsets": [{
      "name": "app.zone1.example.com.",
      "type": "A",
      "ttl": 3600,
      "changetype": "REPLACE",
      "records": [{"content": "10.0.1.50", "disabled": false}]
    }]
  }'
```

### Via SQLite

```bash
docker exec -it dns-powerdns-zone1 sqlite3 /var/lib/powerdns/zone1.sqlite3
```

## Scaling

### Horizontal Scaling

Add more PowerDNS zones by:
1. Creating new zone configuration directory
2. Adding service to `docker-compose.yml`
3. Adding routing rules to `dnsdist/dnsdist.conf`

### Vertical Scaling

Adjust resource limits in `docker-compose.yml`:

```yaml
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 1G
```

## Documentation

For detailed information, see:

- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Complete deployment, configuration, and management guide
- **[PowerDNS Documentation](https://doc.powerdns.com/)**
- **[dnsdist Documentation](https://dnsdist.org/)**

## Security

⚠️ **Important**: Change default passwords and API keys before production use!

Edit the following files:
- `powerdns/zone*/pdns.conf` - Update `api-key`
- `dnsdist/dnsdist.conf` - Update `password` and `apiKey`

Restrict access by configuring:
- AXFR allowed IPs
- Web API allowed IPs
- dnsdist ACLs

See [DEPLOYMENT.md](DEPLOYMENT.md#security-considerations) for detailed security configuration.

## Troubleshooting

### Port 53 Already in Use

```bash
# On Ubuntu, disable systemd-resolved
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
```

### Check Service Health

```bash
# View status
docker-compose ps

# Check logs
docker-compose logs [service-name]

# Test DNS resolution
dig @localhost zone1.example.com
```

### Performance Testing

```bash
# Install dnsperf
sudo apt-get install dnsperf

# Run load test
dnsperf -s localhost -d queries.txt -l 30 -c 100
```

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is provided as-is for educational and production use.

## Support

For issues and questions:
- GitHub Issues: https://github.com/ganeshmd2015/dns-project/issues

## Acknowledgments

- [PowerDNS](https://www.powerdns.com/) - High-performance DNS server
- [dnsdist](https://dnsdist.org/) - DNS load balancer
- [dnslib](https://pypi.org/project/dnslib/) - Python DNS library
