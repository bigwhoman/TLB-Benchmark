#initialize the database
duration=1m
pids=$(pgrep -f cassandra | paste -s -d,)
sudo cassandra-stress write n=1000000 -rate threads=50 > ./write_output.txt

#first test : 3,7

echo -e $pids
sudo cassandra-stress mixed ratio\(write=3,read=7\) duration=$duration -rate threads=50 >./output-3-7.txt 2>&1 &
sudo strace -f -p "$pids" 2> ./benchmark/cassandra-benchmark-3-7-bare-metal-$(uname -r).strace &
strace_id=$!
sudo perft record -p $pids -o ./benchmark/cassandra-benchmark-3-7-bare-metal-$(uname -r).perf -e dTLB-loads,dTLB-load-misses,iTLB-load-misses,cache-misses,page-faults &
perf_id=$!
echo $perf_id
sleep $duration
# Check if strace process is still running before trying to kill it
if ps -p $strace_id > /dev/null; then
   kill $strace_id
fi

# Check if perf process is still running before trying to kill it
if ps -p $perf_id > /dev/null; then
   kill $perf_id
fi
echo "done first test"
sleep 20

#second test : 5,5
echo -e $pids
sudo cassandra-stress mixed ratio\(write=5,read=5\) duration=$duration -rate threads=50 >./output-5-5.txt 2>&1 &
sudo strace -f -p "$pids" 2> ./benchmark/cassandra-benchmark-5-5-bare-metal-$(uname -r).strace &
strace_id=$!
sudo perft record -p $pids -o ./benchmark/cassandra-benchmark-5-5-bare-metal-$(uname -r).perf -e dTLB-loads,dTLB-load-misses,iTLB-load-misses,cache-misses,page-faults &
perf_id=$!
echo $perf_id
sleep $duration
# Check if strace process is still running before trying to kill it
if ps -p $strace_id > /dev/null; then
   kill $strace_id
fi

# Check if perf process is still running before trying to kill it
if ps -p $perf_id > /dev/null; then
   kill $perf_id
fi
echo "done second test"
sleep 20

#third test 7,3
sudo cassandra-stress mixed ratio\(write=7,read=3\) duration=$duration -rate threads=50 >./output-7-3.txt 2>&1 &
sudo strace -f -p "$pids" 2> ./benchmark/cassandra-benchmark-7-3-bare-metal-$(uname -r).strace &
strace_id=$!
sudo perft record -p $pids -o ./benchmark/cassandra-benchmark-7-3-bare-metal-$(uname -r).perf -e dTLB-loads,dTLB-load-misses,iTLB-load-misses,cache-misses,page-faults &
perf_id=$!
echo $perf_id
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

# # sudo perf record -o ./benchmark/cassandra-benchmark-3-7-bare-metal-$(uname -r).perf -e dTLB-loads,dTLB-load-misses,iTLB-load-misses,cache-misses,page-faults cassandra-stress write n=1000000 -rate threads=50

# sudo perf record -o ./benchmark/cassandra-benchmark-3-7-bare-metal-$(uname -r).perf -e dTLB-loads,dTLB-load-misses,iTLB-load-misses,cache-misses,page-faults cassandra-stress mixed ratio\(write=3,read=7\) n=1000000 -rate threads=50
# strace cassandra-stress mixed ratio\(write=3,read=7\) n=1000000 -rate threads=50 2> ./benchmark/cassandra-benchmark-3-7-bare-metal-$(uname -r).strace 


# sudo perf record -o ./benchmark/cassandra-benchmark-5-5-bare-metal-$(uname -r).perf -e dTLB-loads,dTLB-load-misses,iTLB-load-misses,cache-misses,page-faults cassandra-stress mixed ratio\(write=3,read=7\) n=1000000 -rate threads=50
# strace cassandra-stress mixed ratio\(write=5,read=5\) n=1000000 -rate threads=50 2> ./benchmark/cassandra-benchmark-5-5-bare-metal-$(uname -r).strace 


# sudo perf record -o ./benchmark/cassandra-benchmark-7-3-bare-metal-$(uname -r).perf -e dTLB-loads,dTLB-load-misses,iTLB-load-misses,cache-misses,page-faults cassandra-stress mixed ratio\(write=3,read=7\) n=1000000 -rate threads=50
# strace cassandra-stress mixed ratio\(write=7,read=3\) n=1000000 -rate threads=50 2> ./benchmark/cassandra-benchmark-7-3-bare-metal-$(uname -r).strace 
