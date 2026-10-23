#!/usr/bin/env python3
"""Require actual compiler invocations for the SDK and both customer modes."""
import argparse
from pathlib import Path
import shlex

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("mode", choices=["5.0", "6.0"])
parser.add_argument("logs", nargs="+", type=Path)
args = parser.parse_args()
expected = {
    "VERAMeetingRoomSDK": {args.mode[0]},
    "Swift5CustomerTests": {"5"},
    "Swift6CustomerTests": {"6"},
}
observed = {target: set() for target in expected}
for log in args.logs:
    for line in log.read_text().splitlines():
        if "-module-name " not in line or "-swift-version " not in line:
            continue
        flags = shlex.split(line)
        target = flags[flags.index("-module-name") + 1]
        if target in observed:
            observed[target].add(flags[flags.index("-swift-version") + 1])
if observed != expected:
    parser.error("missing or unexpected compiler modes: " + str(observed))
print("Verified SDK and customer compiler modes: " + str(observed))
