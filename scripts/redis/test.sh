sudo perf record -o ./benchmark/redis-benchmark-bare-metal-$(uname -r).perf -e tlb:tlb_flush,dTLB-loads,dTLB-load-misses,iTLB-load-misses,cache-misses,page-faults redis-benchmark
strace redis-benchmark 2> ./benchmark/redis-benchmark-bare-metal-$(uname -r).strace 