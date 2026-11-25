# Network Efficiency Research Specification

## Goal

Measure network activity and determine whether a workload's transfer timing, radio use, or connectivity state affects total battery behaviour.

## Read-only measurements

Record interface identity only as needed for the experiment, byte counters, transfer duration, link type, signal/connection state when exposed, and the exact workload. Avoid collecting SSIDs, IP addresses, packet contents, hostnames, or unrelated process names in public reports.

## Hypotheses

- Batching small transfers may reduce repeated wakeups and radio activity.
- Deferrable background transfers may benefit from system-managed scheduling.
- A fixed amount of transferred data can still have different energy costs depending on signal quality, interface, retries, and display/CPU activity.

## Boundaries

Do not disable Wi-Fi, alter routes, change DNS, disconnect interfaces, or intercept traffic. Connectivity is preserved. Network byte counts are not a direct measure of radio energy.

## Open questions

- Which counters and link-state sources are public and stable on the target?
- Can radio energy be isolated from total battery discharge?
- Which conditions must be held constant for network trials?
