duration=2m
r_pid=$(pgrep -f redis)
redis-benchmark >./output.txt 2>&1 &
sudo perft record -p $r_pid -o ./benchmark/redis-benchmark-bare-metal-$(uname -r).perf -e dTLB-loads,dTLB-load-misses,iTLB-load-misses,cache-misses,page-faults &
perf_id=$!
strace -f -p "$pid" 2> ./benchmark/redis-benchmark-bare-metal-$(uname -r).strace &
strace_id=$!
echo $perf_id,$strace_id
sleep $duration

# Check if strace process is still running before trying to kill it
if ps -p $strace_id > /dev/null; then
   kill $strace_id
fi

# Check if perf process is still running before trying to kill it
if ps -p $perf_id > /dev/null; then
   kill $perf_id
fi

echo "done redis test"
