sudo perf record -o ./benchmark/cassandra-benchmark-3-7-bare-metal-$(uname -r).perf -e tlb:tlb_flush,dTLB-loads,dTLB-load-misses,iTLB-load-misses,cache-misses,page-faults cassandra-stress mixed ratio\(write=3,read=7\) n=1000000 -rate threads=50 &> output.txt
# strace cassandra-stress mixed ratio\(write=3,read=7\) n=1000000 -rate threads=50 2> ./benchmark/cassandra-benchmark-3-7-bare-metal-$(uname -r).strace 


# sudo perf record -o ./benchmark/cassandra-benchmark-5-5-bare-metal-$(uname -r).perf -e tlb:tlb_flush,dTLB-loads,dTLB-load-misses,iTLB-load-misses,cache-misses,page-faults cassandra-stress mixed ratio\(write=3,read=7\) n=1000000 -rate threads=50
# strace cassandra-stress mixed ratio\(write=5,read=5\) n=1000000 -rate threads=50 2> ./benchmark/cassandra-benchmark-5-5-bare-metal-$(uname -r).strace 


# sudo perf record -o ./benchmark/cassandra-benchmark-7-3-bare-metal-$(uname -r).perf -e tlb:tlb_flush,dTLB-loads,dTLB-load-misses,iTLB-load-misses,cache-misses,page-faults cassandra-stress mixed ratio\(write=3,read=7\) n=1000000 -rate threads=50
# strace cassandra-stress mixed ratio\(write=7,read=3\) n=1000000 -rate threads=50 2> ./benchmark/cassandra-benchmark-7-3-bare-metal-$(uname -r).strace 