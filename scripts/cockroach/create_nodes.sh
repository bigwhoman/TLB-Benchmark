#!/bin/bash

num_nodes=$1

# Start of the docker-compose file
cat > cooka-compose.yml <<EOF
version: '3'
services:
EOF

# For each node, add a service to the docker-compose file
for ((i=1; i<=num_nodes; i++))
do
cat >> cooka-compose.yml <<EOF
  roach$i:
    image: cockroachdb/cockroach
    command: start --advertise-addr=roach$i:26357 --http-addr=roach$i:$((8080+$i-1)) --listen-addr=roach$i:26357 --sql-addr=roach$i:$((26256+$i)) --insecure --join=$(for j in $(seq 1 $num_nodes); do echo -n "roach$j:26357,"; done | sed 's/,$//')
    hostname: roach$i
    ports:
      - "$((26256+$i)):$((26256+$i))"
      - "$((8080+$i-1)):$((8080+$i-1))"
    volumes:
      - ./cockroach-data/roach$i:/cockroach/cockroach-data
    networks:
      - crdb_network
EOF
done

cat >> cooka-compose.yml <<EOF
networks:
  crdb_network:
    driver: bridge
EOF



