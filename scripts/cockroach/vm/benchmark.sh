# Load 2 gigabytes of mock data

warehouses=3
#sudo cockroach workload fixtures import tpcc --warehouses=$warehouses 'postgresql://localhost:26257?sslmode=disable'
#sudo cockroach workload run tpcc --warehouses=3 --ramp=3m --duration=10m 'postgresql://localhost:26257?sslmode=disable' >./output.txt 2>&1 &
#sleep 10
sudo perf record -p $(pidof cockroach | cut -d' ' -f2- | tr ' ' ',') -o ./benchmark/cockroach-benchmark-tpcc-vm-$(uname -r).perf -e tlb:tlb_flush,dTLB-loads,dTLB-load-misses,iTLB-load-misses,cache-misses,page-faults &
perf_id=$!
sudo strace -f -p "$(pidof cockroach | cut -d' ' -f2- | tr ' ' ',')" 2> ./benchmark/cockroach-benchmark-tpcc-vm-$(uname -r).strace &
strace_id=$!
echo $perf_id,$strace_id
sleep 9m
kill $perf_id
kill $strace_id
echo "done tracing"
