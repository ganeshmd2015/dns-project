FROM ubuntu:22.04

LABEL maintainer="DNS Project Team"
LABEL description="dnsdist - DNS load balancer and traffic router"

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dnsdist
RUN apt-get update && apt-get install -y \
    dnsdist \
    && rm -rf /var/lib/apt/lists/*

# Create configuration directory
RUN mkdir -p /etc/dnsdist

# Copy dnsdist configuration
COPY dnsdist.conf /etc/dnsdist/dnsdist.conf

# Expose DNS and management ports
EXPOSE 53/udp
EXPOSE 53/tcp
EXPOSE 8083/tcp

# Run dnsdist
CMD ["dnsdist", "--supervised", "--disable-syslog", "-C", "/etc/dnsdist/dnsdist.conf"]
