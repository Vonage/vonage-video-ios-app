#!/usr/bin/env python3
"""Select the owned package's mode in a disposable CI checkout.

The checked-in manifest defaults to Swift 6. Editing its declaration makes the
selection visible to Xcode's manifest cache; process environment alone may not.
Per-target Swift 5/6 customer settings and dependency manifests remain intact.
"""
import argparse
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("mode", choices=["5.0", "6.0"])
args = parser.parse_args()
manifest = Path(__file__).resolve().parent.parent / "Package.swift"
source = manifest.read_text()
choices = ["swiftLanguageModes: [.v5]", "swiftLanguageModes: [.v6]"]
if sum(source.count(choice) for choice in choices) != 1:
    parser.error("expected exactly one supported package language-mode declaration")
selected = "swiftLanguageModes: [.v" + args.mode[0] + "]"
for choice in choices:
    source = source.replace(choice, selected)
manifest.write_text(source)
print("Owned package language mode: " + args.mode)
