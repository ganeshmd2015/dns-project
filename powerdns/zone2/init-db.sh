#!/bin/bash
set -e

DB_PATH="/var/lib/powerdns/zone2.sqlite3"

echo "Initializing PowerDNS SQLite database for Zone 2..."

# Create database if it doesn't exist
if [ ! -f "$DB_PATH" ]; then
    echo "Creating new database at $DB_PATH"
    
    # Create the database schema
    sqlite3 "$DB_PATH" << 'EOF'
CREATE TABLE domains (
  id INTEGER PRIMARY KEY,
  name VARCHAR(255) NOT NULL COLLATE NOCASE,
  master VARCHAR(128) DEFAULT NULL,
  last_check INTEGER DEFAULT NULL,
  type VARCHAR(6) NOT NULL,
  notified_serial INTEGER DEFAULT NULL,
  account VARCHAR(40) DEFAULT NULL
);

CREATE UNIQUE INDEX name_index ON domains(name);

CREATE TABLE records (
  id INTEGER PRIMARY KEY,
  domain_id INTEGER DEFAULT NULL,
  name VARCHAR(255) DEFAULT NULL,
  type VARCHAR(10) DEFAULT NULL,
  content VARCHAR(65535) DEFAULT NULL,
  ttl INTEGER DEFAULT NULL,
  prio INTEGER DEFAULT NULL,
  disabled BOOLEAN DEFAULT 0,
  ordername VARCHAR(255),
  auth BOOL DEFAULT 1
);

CREATE INDEX rec_name_index ON records(name);
CREATE INDEX nametype_index ON records(name,type);
CREATE INDEX domain_id ON records(domain_id);
CREATE INDEX orderindex ON records(ordername);

CREATE TABLE supermasters (
  ip VARCHAR(64) NOT NULL,
  nameserver VARCHAR(255) NOT NULL COLLATE NOCASE,
  account VARCHAR(40) DEFAULT NULL
);

CREATE TABLE comments (
  id INTEGER PRIMARY KEY,
  domain_id INTEGER NOT NULL,
  name VARCHAR(255) NOT NULL,
  type VARCHAR(10) NOT NULL,
  modified_at INT NOT NULL,
  account VARCHAR(40) DEFAULT NULL,
  comment VARCHAR(65535) NOT NULL
);

CREATE INDEX comments_domain_id_index ON comments (domain_id);
CREATE INDEX comments_nametype_index ON comments (name, type);
CREATE INDEX comments_order_idx ON comments (domain_id, modified_at);

CREATE TABLE domainmetadata (
 id INTEGER PRIMARY KEY,
 domain_id INT NOT NULL,
 kind VARCHAR(32) COLLATE NOCASE,
 content TEXT
);

CREATE INDEX domainmetaidindex ON domainmetadata(domain_id);

CREATE TABLE cryptokeys (
 id INTEGER PRIMARY KEY,
 domain_id INT NOT NULL,
 flags INT NOT NULL,
 active BOOL,
 published BOOL DEFAULT 1,
 content TEXT
);

CREATE INDEX domainidindex ON cryptokeys(domain_id);

CREATE TABLE tsigkeys (
 id INTEGER PRIMARY KEY,
 name VARCHAR(255) COLLATE NOCASE,
 algorithm VARCHAR(50) COLLATE NOCASE,
 secret VARCHAR(255)
);

CREATE UNIQUE INDEX namealgoindex ON tsigkeys(name, algorithm);
EOF

    echo "Database schema created successfully"
    
    # Insert sample zone data for zone2.example.com
    sqlite3 "$DB_PATH" << 'EOF'
INSERT INTO domains (name, type) VALUES ('zone2.example.com', 'NATIVE');

INSERT INTO records (domain_id, name, type, content, ttl, prio) VALUES 
    (1, 'zone2.example.com', 'SOA', 'ns1.zone2.example.com hostmaster.zone2.example.com 2024010101 10800 3600 604800 3600', 3600, NULL),
    (1, 'zone2.example.com', 'NS', 'ns1.zone2.example.com', 3600, NULL),
    (1, 'ns1.zone2.example.com', 'A', '10.0.2.10', 3600, NULL),
    (1, 'zone2.example.com', 'A', '10.0.2.1', 3600, NULL),
    (1, 'www.zone2.example.com', 'A', '10.0.2.2', 3600, NULL),
    (1, 'mail.zone2.example.com', 'A', '10.0.2.3', 3600, NULL),
    (1, 'zone2.example.com', 'MX', 'mail.zone2.example.com', 3600, 10);
EOF

    echo "Sample zone data inserted for zone2.example.com"
fi

# Change ownership
chown -R pdns:pdns /var/lib/powerdns

echo "Starting PowerDNS for Zone 2..."
exec /usr/sbin/pdns_server --config-dir=/etc/powerdns
