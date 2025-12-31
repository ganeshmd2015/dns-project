FROM ubuntu:22.04

LABEL maintainer="DNS Project Team"
LABEL description="PowerDNS Authoritative Server with SQLite backend"

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install PowerDNS and dependencies
RUN apt-get update && apt-get install -y \
    pdns-server \
    pdns-backend-sqlite3 \
    sqlite3 \
    && rm -rf /var/lib/apt/lists/*

# Create directories for PowerDNS
RUN mkdir -p /etc/powerdns /var/lib/powerdns

# Copy PowerDNS configuration
COPY pdns.conf /etc/powerdns/pdns.conf

# Copy initialization script
COPY init-db.sh /usr/local/bin/init-db.sh
RUN chmod +x /usr/local/bin/init-db.sh

# Expose DNS ports
EXPOSE 53/udp
EXPOSE 53/tcp
EXPOSE 8081/tcp

# Initialize database and start PowerDNS
CMD ["/usr/local/bin/init-db.sh"]
