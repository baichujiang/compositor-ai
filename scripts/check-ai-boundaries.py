#!/usr/bin/env python3
"""Keep editor dependencies inside the AI adapter and the app composition root."""
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parents[1]
source = root / "Compositor"
leaks = []
reference = re.compile(r"\b(?:AI[A-Z]\w*|aiAssistant|showsAIAssistant)\b")
for path in source.rglob("*.swift"):
    relative = path.relative_to(source)
    if relative.parts[0] == "AI" or relative == Path("CompositorApp.swift"):
        continue
    for number, line in enumerate(path.read_text().splitlines(), 1):
        if reference.search(line):
            leaks.append(f"{relative}:{number}: AI dependency outside the integration boundary")

if leaks:
    sys.exit("\n".join(leaks))
print("Native source has no AI type/state references outside CompositorApp.")
