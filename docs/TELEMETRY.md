# Read-only telemetry and benchmark format

## Current commands

- `maclean doctor [--json]` performs a one-shot, read-only inventory.
- `maclean monitor --interval SECONDS [--count SAMPLES]` emits JSON Lines to stdout.
- `maclean benchmark run --scenario NAME [options]` records repeated samples and summaries to JSON.
- `maclean benchmark compare BASELINE.json CANDIDATE.json` compares summary means for compatible same-scenario runs.

No command persists data unless the user supplies `benchmark --output PATH`, uploads data, or changes system settings. The benchmark output is a portable JSON contract in `MacLeanCore`. The current collector and CPU/power-source adapters are macOS-specific.

## Metric record

Every observation carries a stable name, numeric or categorical value, unit, source, quality, optional collection window, and unavailable reason. `direct`, `derived`, and `osEstimate` values remain distinct. Unavailable metrics have no numeric value; no zero or proxy is substituted. The host context records OS version/build, architecture, non-unique model identifier, and processor name when available.

## Current collection surface

| Area | Source | Meaning and limit |
|---|---|---|
| OS, architecture, model, CPU | `sw_vers`, `uname`, allowlisted `sysctl` and `system_profiler` fields | Inventory only; values may be unavailable in restricted contexts. |
| CPU utilization | Mach `host_statistics(HOST_CPU_LOAD_INFO)` tick deltas | Direct host aggregate. First sample establishes a counter baseline. |
| Battery charge and source | `pmset -g batt` | Charge is an OS-reported percentage; it is not watt-hours or a short-window discharge rate. |
| Battery voltage/current | IOPowerSources description of the present internal battery, with allowlisted fields only | Signed current in A and voltage in V when published; keys are optional. The full dictionary and identifiers are not retained. |
| Battery signed power | Voltage × signed current | Derived watts preserving the sign supplied by IOPowerSources; sign convention is not generalized from one host. |
| Battery discharge power | Absolute voltage × current when source is Battery Power and not charging | Derived watts; otherwise unavailable. Does not claim wall power or component power. |
| Battery energy | Trapezoidal integration of consecutive discharge-power samples | Reported in Wh only with at least 95% trial coverage; a gap or AC operation leaves total trial energy unavailable. |
| Thermal state | Foundation `ProcessInfo.thermalState` | Coarse OS state only; no physical temperature. |
| Collector cost | Monotonic wall time and `getrusage` CPU time | Collector work only; includes first-sample host discovery. Idle wait, JSON serialization, and output writing are excluded. |
| Frequency, CPU package power and C-state | Optional explicit `powermetrics` sampler | Disabled by default and accepted only when the process is already root. Package power is an OS estimate. Unparsed/unsupported values remain unavailable. |
| GPU activity/power | No validated source | Inventory does not prove the active GPU or its power state. |
| Thunderbolt topology/power | On-demand `system_profiler` inventory only | Controller power state is unavailable; topology is not sampled at monitor cadence. |
| Temperature/fan speed | No validated source | Unavailable; no private sensor keys are queried. |

### Power-source fields

The adapter uses Apple's IOPowerSources accessor functions. The installed `IOPSKeys.h` defines `Voltage` as a signed integer in mV and `Current` as a signed integer in mA, and says Apple-defined sources may omit either field. The current validation host reported positive current while charging but no voltage; this does not validate current polarity during discharge. See [IOPowerSources API](https://developer.apple.com/documentation/iokit/1523839-iopscopypowersourcesinfo) and the research note in [docs/research/iokit-telemetry.md](research/iokit-telemetry.md).

## Benchmark JSON

`BenchmarkResult` contains:

- `schemaVersion`, run ID, creation time, scenario and optional user-described workload;
- host/OS context, a privacy-filtered `doctor` hardware inventory, the inventory-collection duration, requested sample interval, target duration, repetition count, warm-up duration, and whether the explicit privileged sampler was enabled;
- one `BenchmarkTrial` per repetition, in execution order, with start/end timestamps, target/actual duration, optional task completion time, raw timestamped samples, per-metric summaries, integrated battery energy coverage, and total collector wall/CPU time.

Each sample offset uses a monotonic clock, so energy integration does not depend on wall-clock adjustments. Metric observations retain their source, units, quality, and unavailable reason. Trial summaries report available sample count and unavailable count, mean, sample standard deviation, minimum, maximum, source set, and quality set. Hardware context includes allowlisted non-unique inventory fields only; no serial or raw registry data is copied.

Benchmark commands do not launch the described workload, turn off a display, or force sleep. The named scenarios are labels and duration defaults, not prebuilt workload automation. Lid-closed sleep is deliberately unsupported because the process is suspended with the system. See [baseline benchmarking](../benchmarks/README.md) for scenario procedures, controls, and comparison limits.

## Privileged diagnostic boundary

The normal monitor and benchmark never request privileges. `benchmark run --powermetrics` is explicit and disabled by default; it is rejected unless already launched with effective UID 0. It calls `/usr/bin/powermetrics` directly and never invokes `sudo` or retries under higher privileges. Since the complete CLI process runs with that UID, the option is restricted to intentional diagnostic runs. `cpu_power,battery,interrupts` samplers run once per sample interval; their cost appears in collector timing. Only reviewed Intel frequency, package C-state, and package-power fields are parsed; power is labeled estimated. The exact OS manual remains authoritative for supported samplers, availability, and interpretation.

## Privacy and experiment record

The collectors do not enumerate process lists, serial numbers, account names, hostnames, SSIDs, IP addresses, or raw IORegistry trees. Benchmark workload descriptions are user-provided and should not contain personal paths or account details. Local result files are not committed or uploaded automatically. Before publishing, remove machine-specific identifiers and unrelated experiment context.

For every experiment record repeat count, trial order, task completion time, measurement method, sampling interval, actual duration, display/power/peripheral/thermal conditions, and confounders. A drop in frequency, utilization, or temperature alone does not establish an energy improvement.
