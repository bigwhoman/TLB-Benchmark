#!/bin/bash

num_nodes=$1

# Start of the docker-compose file
cat > cockroach-compose.yml <<EOF
version: '3'
services:
EOF

# For each node, add a service to the docker-compose file
for ((i=1; i<=num_nodes; i++))
do
cat >> cockroach-compose.yml <<EOF
  roach$i:
    image: cockroachdb/cockroach
    hostname: roach$i
    command: start --insecure --join=$(for ((j=1; j<=num_nodes; j++)); do printf "roach$j:26257,"; done | sed 's/,$//')
    ports:
      - "2625$i:26257"
      - "808$i:8080"
    volumes:
      - ./cockroach-data/roach$i:/cockroach/cockroach-data
    networks:
      - crdb_network
EOF
done

cat >> cockroach-compose.yml <<EOF
networks:
  crdb_network:
    driver: bridge
EOF