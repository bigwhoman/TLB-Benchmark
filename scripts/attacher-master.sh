#!/bin/sh
# ps -e | grep xray
perf record -p 4127 -o out.perf -e tlb:tlb_flush,dTLB-loads,dTLB-load-misses,iTLB-load-misses,cache-misses,page-faults
# Or use $(pidof sqlite_benchmark | tr ' ' ',') to get the PID of running processes
strace -p "$(pidof bash)" 2> strace.log
# Or use this to exclude stuff strace -f -p "$(pidof bash)" -e 'trace=!futex,io_getevents' 2> strace.log
perf script -i out.perf