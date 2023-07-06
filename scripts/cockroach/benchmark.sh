# Load 2 gigabytes of mock data

warehouses=10
sudo docker exec -it cockroach_roach1_1 ./cockroach workload fixtures import tpcc --warehouses=$warehouses 'postgresql://root@roach1:26257?sslmode=disable'

sudo perf record -o ./benchmark/cockroach-benchmark-tpcc-bare-metal-$(uname -r).perf -e tlb:tlb_flush,dTLB-loads,dTLB-load-misses,iTLB-load-misses,cache-misses,page-faults docker exec -it cockroach_roach1_1 cockroach workload run tpcc --warehouses=10 --ramp=3m --duration=10m 'postgresql://root@roach1:26257?sslmode=disable' 
strace docker exec -it cockroach_roach1_1 sudo docker exec -it cockroach_roach1_1 cockroach workload run tpcc --warehouses=10 --ramp=3m --duration=$test_durationm 'postgresql://root@roach1:26257?sslmode=disable'  2> ./benchmark/cockroach-benchmark-tpcc-bare-metal-$(uname -r).strace 