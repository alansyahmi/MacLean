# Storage Efficiency Research Specification

## Goal

Study whether storage reads, writes, filesystem state, or external-volume activity change energy per task, wakeups, and latency.

## Read-only measurements

Use operating-system I/O counters where their semantics are understood. Record volume type, task input, bytes read/written, completion time, and external-device state. Do not scan entire volumes as a background inventory task.

## Hypotheses

- Batching small writes and avoiding redundant work can reduce I/O activity.
- Cache deletion, forced cleanup, or aggressive sleep can cause extra work and regressions.
- External storage may add device and Thunderbolt energy that cannot be separated from a battery estimate without further instrumentation.

## Boundaries

No cache purges, filesystem modification, forced unmounts, TRIM controls, write-cache changes, or device sleep commands. Never report I/O bytes as watts.

## Open questions

- Which public counters exist for internal storage and common Thunderbolt devices?
- How can device power be distinguished from host-controller and workload effects?
- Which benchmark inputs avoid being dominated by filesystem cache?
