#!/bin/sh
perf record -o out.perf -e tlb:tlb_flush,dTLB-loads,dTLB-load-misses,iTLB-load-misses,cache-misses,page-faults ls
strace 2> strace.log
perf script -i out.perf