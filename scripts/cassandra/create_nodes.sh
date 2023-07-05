#!/bin/bash

# Get the number of nodes from the user
echo "Enter the number of Cassandra nodes:"
read num_nodes

# Generate the cassandra-compose.yml file
echo "version: '3'" > cassandra-compose.yml
echo "services:" >> cassandra-compose.yml

for ((i=1;i<=$num_nodes;i++)); do
  echo "  cassandra_node_$i:" >> cassandra-compose.yml
  echo "    extends:" >> cassandra-compose.yml
  echo "      file: cassandra-compose.base.yml" >> cassandra-compose.yml
  echo "      service: cassandra_node_template" >> cassandra-compose.yml
  echo "    environment:" >> cassandra-compose.yml
  echo "      - CASSANDRA_SEEDS=cassandra_node_1" >> cassandra-compose.yml
  echo "    ports:" >> cassandra-compose.yml
  echo "      - '700$i:7000'" >> cassandra-compose.yml
  echo "      - '904$i:9042'" >> cassandra-compose.yml
done

echo "networks:" >> cassandra-compose.yml
echo "  cassandra_net:" >> cassandra-compose.yml
echo "    driver: bridge" >> cassandra-compose.yml
# # Start the containers
sudo docker-compose -f cassandra-compose.yml up -d

# # Allow some time for the containers to start
sleep 120


for ((i=1;i<=$num_nodes;i++)); do
  echo "Checking status of cassandra_node_$i"
  # Executing nodetool status on the node 
  status=$(docker exec cassandra_node_$i nodetool status | grep UN)
  
   # Check Status
  if [ -z "$status" ]
  then
    echo "Node cassandra_node_$i is not up"
    exit 1
  else
    echo "Node cassandra_node_$i is up"
  fi
done

#echo Starting Tests

sudo bash benchmark.sh
