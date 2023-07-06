# Load 2 gigabytes of mock data

warehouses=10
sudo cockroach workload fixtures import tpcc --warehouses=$warehouses 'postgresql://localhost:26257?sslmode=disable'

sudo perf record -o ./benchmark/cockroach-benchmark-tpcc-bare-metal-$(uname -r).perf -e tlb:tlb_flush,dTLB-loads,dTLB-load-misses,iTLB-load-misses,cache-misses,page-faults cockroach workload run tpcc --warehouses=10 --ramp=3m --duration=10m 'postgresql://localhost:26257?sslmode=disable' 
# strace docker exec -it cockroach_roach1_1 sudo cockroach workload run tpcc --warehouses=10 --ramp=3m --duration=10m 'postgresql://localhost:26257?sslmode=disable'  2> ./benchmark/cockroach-benchmark-tpcc-bare-metal-$(uname -r).strace 