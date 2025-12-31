#!/usr/bin/env python3
"""
Simple DNS server using dnslib for pjdns component
Handles basic DNS queries for demonstration purposes
"""

import socket
import sys
import time
from dnslib import DNSRecord, DNSHeader, RR, QTYPE, A
from dnslib.server import DNSServer, DNSHandler, BaseResolver

class SimpleResolver(BaseResolver):
    """
    Simple DNS resolver that returns predefined responses
    """
    def __init__(self):
        self.records = {
            'example.com.': '192.168.1.100',
            'test.example.com.': '192.168.1.101',
            'www.example.com.': '192.168.1.102',
        }
    
    def resolve(self, request, handler):
        """
        Resolve DNS query
        """
        reply = request.reply()
        qname = str(request.q.qname)
        qtype = QTYPE[request.q.qtype]
        
        print(f"Received query: {qname} ({qtype})")
        
        # Handle A records
        if qtype == 'A' and qname in self.records:
            reply.add_answer(
                RR(qname, QTYPE.A, rdata=A(self.records[qname]), ttl=60)
            )
            print(f"Resolved {qname} to {self.records[qname]}")
        else:
            print(f"No record found for {qname}")
        
        return reply

def main():
    """
    Start DNS server
    """
    print("Starting pjdns DNS server on port 53...")
    print("Configured records:")
    resolver = SimpleResolver()
    for domain, ip in resolver.records.items():
        print(f"  {domain} -> {ip}")
    
    # Start UDP and TCP servers
    udp_server = DNSServer(resolver, port=53, address='0.0.0.0', tcp=False)
    tcp_server = DNSServer(resolver, port=53, address='0.0.0.0', tcp=True)
    
    try:
        udp_server.start_thread()
        tcp_server.start_thread()
        print("DNS server started successfully (UDP and TCP on port 53)")
        
        # Keep the main thread running
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\nShutting down DNS server...")
        udp_server.stop()
        tcp_server.stop()
        sys.exit(0)
    except Exception as e:
        print(f"Error starting DNS server: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
