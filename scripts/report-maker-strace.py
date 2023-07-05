import sys
import re

if len(sys.argv) < 2:
    print("Pass the filename to create report from it as first argument")
    exit(1)

# Regex to extract syscalls
base_syscall_matcher = re.compile('\[pid\s+(\d+)\] (\w+)\(')

# Dict from PID to dict of syscall and the number of times used
syscall_usage: dict[int, dict[str, int]] = {}
merged_syscall_usage: dict[str, int] = {}

# Open the strace result
with open(sys.argv[1], "r") as strace_file:
    for line in strace_file:
        matched_line = base_syscall_matcher.search(line)
        if matched_line:
            pid = int(matched_line.group(1))
            syscall_name = matched_line.group(2)
            if pid not in syscall_usage:
                syscall_usage[pid] = {}
            # Filter out allocated mmaps
            if syscall_name == "mmap":
                if "-1, 0)" in line: # acts as malloc
                    syscall_name = "malloc_mmap"
            # Insert to dicts
            pid_dict = syscall_usage[pid]
            pid_dict[syscall_name] = pid_dict.get(syscall_name, 0) + 1
            merged_syscall_usage[syscall_name] = merged_syscall_usage.get(syscall_name, 0) + 1

# Write result
with open("usage.csv", "w") as usage_file:
    usage_file.write("syscall,usage\n")
    for syscall in sorted(merged_syscall_usage, key=merged_syscall_usage.get, reverse=True):
        usage_file.write(f"{syscall},{merged_syscall_usage[syscall]}\n")