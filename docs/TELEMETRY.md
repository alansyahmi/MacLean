# Read-Only Telemetry Specification

## Status

The executable provides a one-shot doctor inventory and an explicitly invoked monitor. Both emit to stdout and do not persist measurements. The monitor writes one JSON object per line at a configurable cadence (five seconds by default, one second minimum) and can stop after a requested count. It is a read-only observation tool, not an energy benchmark.

The CLI deliberately excludes serial numbers, host names, user names, process lists, and raw power-assertion owner details. It never invokes sudo, prompts for privileges, or starts powermetrics sampling.

## Metric record

Each future metric record should contain:

| Field | Meaning |
|---|---|
| name | Stable identifier, such as cpu.utilization |
| value | Numeric or categorical value; absent when unavailable |
| unit | Explicit unit, or none for a categorical state |
| source | Public API or operating-system tool |
| timestamp | Timestamp with timezone |
| host | OS version/build, architecture, model identifier, and processor name when available |
| windowSeconds | Interval covered by the observation, if meaningful |
| quality | direct, derived, osEstimate, or unavailable |
| unavailableReason | Why no value was recorded |

An unavailable metric has no numeric value and includes its quality and reason. It must never be serialized as numeric zero. Derived values must name their inputs and formula. The monitor includes non-unique host model facts and OS build for reproducibility, but no serial number or user/device-unique identifier. Every sample is local by default.

## Doctor capability states

The CLI uses four states:

- supported — the requested host feature or observation source was positively identified;
- unsupported — the host architecture or explicit system response rules out the requested target;
- unknown — the probe did not establish support or absence;
- experimental — the capability is an isolated research track, not an enabled feature.

An installed tool does not prove that its samplers work for a particular Mac. An available System Profiler data type does not prove a controller is present or expose its power state. The doctor report records those distinctions explicitly.

## Initial collection surface

| Area | Initial source | Meaning and limitation |
|---|---|---|
| Model, CPU, memory, firmware | sysctl and allowlisted system_profiler fields | Inventory facts only; may be unavailable under a restricted execution context |
| OS and architecture | sw_vers and uname | Kernel and product versions must both be recorded |
| Graphics model | Filtered SPDisplaysDataType fields | Identifies a reported GPU; does not prove active use, power, or switching state |
| Battery | Allowlisted system_profiler health fields and pmset status | Cycle count/condition are OS-reported; state of charge and remaining-time values are estimates, not component power |
| CPU utilization | Mach `host_statistics(HOST_CPU_LOAD_INFO)` tick deltas | Direct host aggregate; first sample is unavailable until a counter interval exists |
| Battery status and charge percentage | `pmset -g batt` | OS-reported status and coarse percentage; not voltage, current, or energy |
| Thermal state | Foundation `ProcessInfo.thermalState` | Coarse system state; not a physical temperature sensor |
| Collector overhead | Wall duration around collection and `getrusage` process/child CPU time | First record includes one-time host-context discovery; excludes JSON encoding and does not yet measure the effect on battery energy |
| Frequency, package C-states, interrupts, wakeups | No monitor source enabled | See powermetrics access check below; values stay unavailable |

The monitor leaves CPU frequency and C-state residency, interrupt and wakeup rates, battery voltage/current/discharge rate, active GPU and GPU power, Thunderbolt topology/controller power, physical temperature, and fan speed unavailable. Battery percentage is too coarse for a reliable short-window discharge estimate. The doctor may report GPU and Thunderbolt inventory, but inventory does not prove live activity or a power state. PCIe link power states are also not observed by the monitor.

If a command fails or a field is blocked, the collector must show unavailable and continue with other fields. It must not prompt for a password or retry with higher privileges.

## powermetrics handling

The local powermetrics manual and help output are authoritative for the installed macOS release. Read them before selecting samplers. A one-sample, non-privileged attempt on the current validation host (`powermetrics -n 1 -i 1000 -s cpu_power,battery,interrupts -f text`) returned “powermetrics must be invoked as the superuser”. MacLean does not retry with elevated access. Support and permissions can vary by host, so the monitor does not launch this sampler automatically. Do not persist its output without user action or equate estimated CPU/GPU subsystem power with measured wall power. Preserve the raw source, OS build, sampler list, interval, and privilege context for any later experiment.

## Sampling budget

Inventory is on demand and one-shot. The monitor is on demand, defaults to a five-second cadence, permits one second minimum, and accepts an optional sample count; without a count it continues until interrupted. Each record contains collection wall duration and process/child CPU time. These fields describe collection cost but do not establish battery impact. The monitor does not yet mark sleep/wake gaps or reduce work based on visibility. A benchmark may use more instrumentation only when its overhead is measured and included in the report.

## Privacy

Inventory output omits serial numbers and unique device identifiers. Experiment records should retain model family and only the hardware details needed for reproducibility. Reports must be reviewed before publication to remove account names, paths, serial numbers, Wi-Fi identifiers, and unrelated process names.

## Validation questions

- Which fields are stable on the exact target model and macOS build?
- Does a requested collector require privileges or trigger additional OS activity?
- How much does sampling change CPU wakeups, task time, or discharge?
- Which output fields are estimates, counters, or instantaneous states?
- What minimum sample interval is useful without distorting idle measurements?
