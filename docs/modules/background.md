# Background Work and Scheduling Specification

## Goal

Reduce avoidable wakeups and batch MacLean-owned discretionary work while preserving interactive response and user-requested tasks.

## Native mechanisms

macOS exposes QoS classes for work priority and NSBackgroundActivityScheduler for flexible, low-priority maintenance tasks. Timers can often tolerate a firing window, and background URL sessions can defer eligible transfers. App Nap and timer coalescing are OS-managed behaviours.

These mechanisms express how MacLean's own work should be scheduled. They do not let MacLean change QoS or timer behaviour for arbitrary third-party processes.

## Initial policy

- Avoid a resident polling daemon.
- Collect only on demand until actual cadence requirements are known.
- Batch independent reads where the underlying source allows it.
- Use a long, flexible interval for future maintenance.
- Let the user defer or cancel research work.
- Do not delay urgent user-visible work or network traffic.

## Research questions

- What is MacLean's own CPU, wakeup, and energy cost while visible, hidden, and idle?
- Which collection tasks are safely deferrable?
- Does a wider sampling interval materially reduce wakeups without losing useful evidence?
- How do Low Power Mode, battery state, and thermal state affect the right sampling cadence?

## Safety and evaluation

Compare before/after with the same collector and workload. Track response latency, task completion, wakeups, thermal state, and battery estimate. A reduction in sampling frequency is not a product benefit if it makes telemetry misleading or hides regressions.

No global task reprioritization, process suspension, timer rewriting, or application termination is permitted.
