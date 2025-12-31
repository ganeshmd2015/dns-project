FROM python:3.9-slim

LABEL maintainer="DNS Project Team"
LABEL description="pjdns - Python-based DNS server"

# Install dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Install pjdns
RUN pip install --no-cache-dir dnslib

# Create working directory
WORKDIR /app

# Copy DNS server script
COPY dns_server.py /app/

# Expose DNS port
EXPOSE 53/udp
EXPOSE 53/tcp

# Run the DNS server
CMD ["python", "dns_server.py"]
