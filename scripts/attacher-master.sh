#!/bin/sh
# ps -e | grep xray
perf record -p 4127 -o out.perf -e tlb:tlb_flush,dTLB-loads,dTLB-load-misses,iTLB-load-misses,cache-misses,page-faults
strace -p "$(pidof bash)" 2> strace.log
perf script -i out.perf