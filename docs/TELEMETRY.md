# Read-Only Telemetry Specification

## Status

The first executable collector is a one-shot CLI inventory. It emits selected hardware and OS facts, one CPU/memory summary, and the operating-system battery status when available. It prints to stdout only and does not persist measurements. It is not a continuous sampler or an energy benchmark.

The CLI deliberately excludes serial numbers, host names, user names, process lists, and raw power-assertion owner details. It does not invoke sudo or start powermetrics sampling.

## Metric record

Each future metric record should contain:

| Field | Meaning |
|---|---|
| name | Stable identifier, such as cpu.utilization |
| value | Numeric or categorical value; absent when unavailable |
| unit | Explicit unit, or none for a categorical state |
| source | Public API or operating-system tool and version |
| observed_at | Timestamp with timezone |
| window | Interval covered by the observation, if meaningful |
| quality | direct, derived, os_estimate, stale, unsupported, or failed |
| capability | Host and OS conditions required to interpret the value |
| notes | Known uncertainty, transform, or collection error |

An unsupported metric must never be serialized as numeric zero. Derived values must name their inputs and formula. Every sample is local by default.

## Initial collection surface

| Area | Initial source | Meaning and limitation |
|---|---|---|
| Model, CPU, memory | sysctl and filtered system_profiler output | Inventory facts only; may be unavailable under a restricted execution context |
| OS and architecture | sw_vers and uname | Kernel and product versions must both be recorded |
| Graphics model | Filtered SPDisplaysDataType fields | Identifies a reported GPU; does not prove active use, power, or switching state |
| Battery | pmset battery status | State of charge and remaining-time values are operating-system estimates, not component power |
| CPU and memory summary | One top summary sample | Brief process-table-free snapshot; not an energy or C-state measurement |
| Thermal state | Future Foundation ProcessInfo adapter | Coarse system state; not a physical temperature sensor |
| CPU counters and wakeups | Optional powermetrics research | Samplers and privileges vary; no automatic invocation in the initial CLI |

If a command fails or a field is blocked, the collector must show unavailable and continue with other fields. It must not prompt for a password or retry with higher privileges.

## powermetrics handling

The local powermetrics manual and help output are authoritative for the installed macOS release. Read them before selecting samplers. Sampling may require administrator privileges, and supported output varies by hardware. Do not start a process with sudo automatically, persist its output without user action, or equate estimated CPU/GPU subsystem power with measured wall power. Preserve the raw source, OS build, sampler list, interval, and privilege context for any later experiment.

## Sampling budget

Initial inventory is on demand and one-shot. A future interactive sampler must expose its interval and stop condition, default to a conservative cadence, stop or reduce work when hidden/idle, and record gaps across sleep. A benchmark may use more instrumentation only when its overhead is measured and included in the report.

## Privacy

Inventory output omits serial numbers and unique device identifiers. Experiment records should retain model family and only the hardware details needed for reproducibility. Reports must be reviewed before publication to remove account names, paths, serial numbers, Wi-Fi identifiers, and unrelated process names.

## Validation questions

- Which fields are stable on the exact target model and macOS build?
- Does a requested collector require privileges or trigger additional OS activity?
- How much does sampling change CPU wakeups, task time, or discharge?
- Which output fields are estimates, counters, or instantaneous states?
- What minimum sample interval is useful without distorting idle measurements?
