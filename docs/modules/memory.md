# Memory Efficiency Research Specification

## Goal

Understand when memory pressure, compression, swapping, and storage activity correlate with energy or task-time changes on supported Intel Macs.

## Read-only measurements

Prefer public host memory statistics and system memory-pressure signals. Record page counts, compression/swap indicators, sampling interval, and OS build. Distinguish capacity, current use, pressure, and I/O; they are not interchangeable.

## Hypotheses

- Avoiding unnecessary allocation and repeated scans can reduce CPU and memory traffic.
- Memory compression or swap can change task latency and storage activity; forcing lower memory use is not automatically more efficient.
- Cache purges can create extra disk/network work and should not be treated as an optimization.

## Boundaries

Do not clear caches, force compression, alter swap configuration, pin pages, or kill applications. Do not infer DRAM power from memory use or pressure. Compare energy per completed task, latency, memory pressure, and I/O under matched workloads.

## Open questions

- Which public memory counters are stable across the oldest intended macOS release?
- Can their collection remain low overhead?
- How do browser, compilation, and media workloads affect compression and swap on the target?
