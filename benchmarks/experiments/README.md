# Phase 1.5 experiment registry

This registry records controlled, read-only studies for selecting MacLean's first optimization target. A result is evidence only for the exact machine, OS build, workload, settings, and measurement method recorded in its experiment document.

| ID | Question | Status |
|---|---|---|
| [E001](E001-graphics-baseline/README.md) | Does native automatic graphics switching change matched idle energy or package residency? | Not run; active GPU power state is unavailable |
| [E002](E002-thunderbolt-baseline/README.md) | Does an optional Thunderbolt peripheral change matched idle energy or package residency? | Not run; topology counts are available, controller power state is not |
| [E003](E003-background-wakeups/README.md) | Which background tasks and wakeups coincide with elevated idle CPU use? | Not run; privileged task sampling has not been authorized or validated |
| [E004](E004-native-low-power-mode/README.md) | Does native Low Power Mode change idle energy and performance on this host? | Not run; host support and battery-power trials remain to be confirmed |
| [E005](E005-collector-overhead/README.md) | How does MacLean collection overhead change with sampling interval? | One AC-powered screening pass recorded; repeat trials pending |

## Shared rules

- Keep power-source state, display brightness, display attachment, workload, user activity, ambient conditions, thermal state, peripheral topology, and OS build matched or recorded.
- Use the prebuilt release executable for measurements. Do not compile during a trial.
- Keep whole-system battery discharge power, Intel package-power estimates, GPU estimates, and other component estimates as separate measurements.
- Capture the trial order, repeat count, task completion time where applicable, sample interval, valid-data coverage, collector wall/CPU cost, and confounders.
- Never change settings automatically. Any native setting changes are made and restored by the operator through macOS controls.
- Keep raw process lists, device identifiers, and machine-specific raw output local and out of commits.
- Missing metrics remain unavailable. One pass, CPU utilization, frequency, temperature, or a single battery run cannot establish an optimization.
