#!/bin/bash
# Extract each file
for arg in "$@"; do
    echo "Processing $arg"
    # Create a temp folder
    rm -rf /tmp/advos-reports/
    mkdir /tmp/advos-reports/
    # Extract the files
    7za e "$arg" -o/tmp/advos-reports/
    # Create results folder
    filename=$(basename -- "$arg")
    filename="${filename%.*}"
    results_folder="$filename-results"
    mkdir "$results_folder"
    # For perf file in that folder run the perf report maker
    for perf_file in /tmp/advos-reports/*.perf; do
        filename=$(basename -- "$perf_file")
        filename="${filename%.*}"
        echo "Parsing perf file of $filename"
        python3 report-maker-perf.py "$perf_file"
        mv events.csv "$results_folder/$filename-events.csv"
        mv shootdowns.csv "$results_folder/$filename-shootdowns.csv"
    done
    # For each strace file also make the reports
    for strace_file in /tmp/advos-reports/*.strace; do
        filename=$(basename -- "$strace_file")
        filename="${filename%.*}"
        echo "Parsing strace file of $filename"
        python3 report-maker-strace.py "$strace_file"
        mv usage.csv "$results_folder/$filename-syscall-usage.csv"
    done
done
# Cleanup
rm -rf /tmp/advos-reports/