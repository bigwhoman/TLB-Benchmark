import sys
import subprocess
from typing import Tuple, Union

NORMAL_EVENTS = ["dTLB-loads", "dTLB-load-misses", "iTLB-load-misses", "dTLB-prefetch-misses", "cache-misses", "page-faults"]

# Checks if a line is a sample line in perf script result and returns the extracted info
def extract_normal_event(line: str) -> Union[Tuple[int, int, str, str], None]:
    line = line.split()
    if len(line) != 8:
        return None
    event = line[4][:-1] # remove the last :
    if event not in NORMAL_EVENTS:
        return None
    pid = int(line[1])
    happened = int(line[3])
    source = line[7]
    return pid, happened, event, source

# Checks if line is about TLB shootdown and reports the number of pages 
def extract_tlb_flush_event(line: str) -> Union[Tuple[int, int, str], None]:
    if "tlb:tlb_flush" not in line:
        return None
    reason = line[line.rfind(":")+1:]
    line = line.split()
    pid = int(line[1])
    pages = int(line[5].split(":")[1])
    return pid, pages, reason

if len(sys.argv) < 2:
    print("Pass the filename to create report from it as first argument")
    exit(1)

# Call perf command
proc = subprocess.Popen(["perf", "script", "-i", sys.argv[1]], stdout=subprocess.PIPE)

# Log data
# event name -> source -> times happened
normal_events_log: dict[str, dict[str, int]] = {}
for events in NORMAL_EVENTS:
    normal_events_log[events] = {}
# reason -> number of occurrence
tlb_flush_events_log: dict[str, int] = {}

# Read each line of input
while True:
    line = proc.stdout.readline()
    if not line:
        break
    line = line.rstrip().decode("utf-8")
    normal_data = extract_normal_event(line)
    if normal_data:
        (pid, happened, event, source) = normal_data
        this_event_logs = normal_events_log[event]
        this_event_logs[source] = this_event_logs.get(source, 0) + happened
    tlb_flush_data = extract_tlb_flush_event(line)
    if tlb_flush_data:
        (pid, pages, reason) = tlb_flush_data
        tlb_flush_events_log[reason] = tlb_flush_events_log.get(reason, 0) + 1

# Report data
with open("events.csv", "w") as events_csv:
    events_csv.write("event,occurrence\n")
    for event, occurrence in normal_events_log.items():
        events_csv.write(f"{event},{sum(occurrence.values())}\n")
    events_csv.write(f"tlb:tlb_flush,{sum(tlb_flush_events_log.values())}")

with open("shootdowns.csv", "w") as shootdowns_tlb:
    shootdowns_tlb.write("reason,occurrence\n")
    for reason, occurrence in tlb_flush_events_log.items():
        shootdowns_tlb.write(f"{reason},{occurrence}\n")