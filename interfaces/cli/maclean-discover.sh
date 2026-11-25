#!/bin/sh
# One-shot, read-only Mac inventory and operating-system telemetry summary.
# This script prints selected fields only. It never writes a report or settings.

set -u

if [ "$(uname -s 2>/dev/null || true)" != "Darwin" ]; then
    printf '%s\n' "MacLean discovery requires macOS (Darwin)." >&2
    exit 1
fi

printf '%s\n' "MacLean read-only discovery"
printf 'Collected at (UTC): %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || printf unavailable)"
printf '%s\n' "No settings changed. No report saved. Unique serial numbers are omitted."

printf '\n%s\n' "System"
printf '  Architecture: %s\n' "$(uname -m 2>/dev/null || printf unavailable)"
printf '  Kernel: %s\n' "$(uname -r 2>/dev/null || printf unavailable)"
if command -v sw_vers >/dev/null 2>&1; then
    printf '  macOS version: %s\n' "$(sw_vers -productVersion 2>/dev/null || printf unavailable)"
    printf '  macOS build: %s\n' "$(sw_vers -buildVersion 2>/dev/null || printf unavailable)"
else
    printf '%s\n' "  macOS version: unavailable"
    printf '%s\n' "  macOS build: unavailable"
fi

printf '\n%s\n' "Hardware (sysctl fields)"
read_sysctl() {
    property=$1
    value=$(sysctl -n "$property" 2>/dev/null) || value=
    if [ -n "$value" ]; then
        printf '  %s: %s\n' "$property" "$value"
    else
        printf '  %s: unavailable\n' "$property"
    fi
}
read_sysctl hw.model
read_sysctl machdep.cpu.brand_string
read_sysctl hw.physicalcpu
read_sysctl hw.logicalcpu
read_sysctl hw.memsize

printf '\n%s\n' "Hardware and graphics (filtered system_profiler fields)"
if command -v system_profiler >/dev/null 2>&1; then
    system_profiler -detailLevel mini SPHardwareDataType SPDisplaysDataType 2>/dev/null |
        awk '
            /^[[:space:]]*(Model Name|Model Identifier|Processor Name|Processor Speed|Total Number of Cores|Memory|Chipset Model|VRAM \(Total\)|Metal Support):/ {
                label = $0
                value = $0
                sub(/:.*/, "", label)
                sub(/^[[:space:]]+/, "", label)
                sub(/^[^:]*:[[:space:]]*/, "", value)
                if (tolower(value) == "unknown" || value == "") value = "unavailable"
                print "  " label ": " value
                found = 1
            }
            END {
                if (!found) print "  graphics summary: unavailable"
            }
        '
else
    printf '%s\n' "  graphics summary: system_profiler unavailable"
fi

printf '\n%s\n' "Battery and power source (operating-system status/estimates)"
if command -v pmset >/dev/null 2>&1; then
    pmset -g batt 2>/dev/null |
        sed -E 's/ \(id=[0-9]+\)//' |
        sed 's/^/  /'
else
    printf '%s\n' "  battery summary: pmset unavailable"
fi

printf '\n%s\n' "One CPU/memory summary snapshot"
if command -v top >/dev/null 2>&1; then
    top -l 1 -n 1 2>/dev/null |
        awk '
            /^Processes:/ || /^CPU usage:/ || /^PhysMem:/ || /^VM:/ {
                print "  " $0
                found = 1
            }
            END {
                if (!found) print "  CPU/memory summary: unavailable"
            }
        '
else
    printf '%s\n' "  CPU/memory summary: top unavailable"
fi

printf '\n%s\n' "Detailed power samplers"
if command -v powermetrics >/dev/null 2>&1; then
    printf '%s\n' "  powermetrics is installed; sampling was not started."
    printf '%s\n' "  Check the local manual and sampler support before any explicit experiment."
else
    printf '%s\n' "  powermetrics is unavailable."
fi

printf '\n%s\n' "Interpretation: battery time/power fields are OS estimates; this is not a wattmeter or benchmark."
