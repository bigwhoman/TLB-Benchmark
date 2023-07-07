duration=1m
pids=$(pgrep -f cassandra | paste -s -d,)
#sudo cassandra-stress write n=1000000 -rate threads=50 > ./write_output.txt

#third test : 7,3
echo -e $pids
sudo cassandra-stress mixed ratio\(write=7,read=3\) duration=$duration -rate threads=50 >./output-7-3.txt 2>&1 &
sudo strace -f -p "$pids" 2> ./benchmark/cassandra-benchmark-7-3-vm-$(uname -r).strace &
strace_id=$!
sudo perf record -p $pids -o ./benchmark/cassandra-benchmark-7-3-vm-$(uname -r).perf -e tlb:tlb_flush,dTLB-loads,dTLB-load-misses,iTLB-load-misses,cache-misses,page-faults &
perf_id=$!
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
echo "done Third test"
sleep 20
