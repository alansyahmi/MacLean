# Baseline benchmarking

`maclean benchmark run` records repeated, read-only telemetry trials as one JSON result. It does not launch or control the workload. For example:

```sh
./.build/release/maclean benchmark run \
  --scenario desktop-idle \
  --interval 5 \
  --repetitions 3 \
  --output /private/tmp/maclean-idle.json
```

The default desktop-idle duration is ten minutes per trial. The screen-off idle preset is also ten minutes; light productivity and video playback are fifteen minutes. Non-idle scenarios require `--workload` so the result describes what was actually done. CPU-intensive trials also require a workload description and a duration. `--task-completion-seconds` records a measured task time supplied by the operator; MacLean does not run or time arbitrary tasks for them.

The result includes a run ID, scenario and workload label, target and actual durations, trial timestamps and order, OS version/build, architecture, model and processor when available, a privacy-filtered hardware inventory (core count, memory, graphics, and battery condition when available), sample offsets from a monotonic clock, requested sampling interval, per-metric source/unit/quality, unavailable reasons, and collector wall/CPU time. The one-time hardware inventory collection duration is recorded separately because it runs before trials. Samples and results are local. The default output is stdout; `--output` saves a JSON file. Keep machine-specific results outside the repository unless they have been reviewed and explicitly approved for publication.

Energy is integrated from consecutive valid `battery.discharge_power` samples using the trapezoidal rule and actual monotonic sample offsets. It is reported only when valid readings cover at least 95% of the trial. Missing voltage/current or AC operation leaves total discharge watt-hours unavailable; MacLean does not substitute state-of-charge percentage. The raw signed current remains available separately. Discharge magnitude is derived only when IOPowerSources reports Battery Power and not charging.

Compare two matched runs from the same scenario, workload description, duration, sampling interval, warm-up, privilege mode, macOS build, architecture, and hardware class:

```sh
./.build/release/maclean benchmark compare baseline.json candidate.json
```

The comparison reports changes in per-trial summary means only when the unit, measurement sources, and quality match. Percent changes are omitted when the baseline mean is zero. A comparison does not control workload order, display brightness, attached peripherals, ambient conditions, thermal history, background activity, or battery ageing. Match these conditions and alternate baseline/candidate order in a future controlled experiment. Do not infer savings from a single run or one metric.

## Scenario limits

| Scenario | Preset duration | Operator action and current limitation |
|---|---:|---|
| `desktop-idle` | 600 s | Leave the desktop in the declared idle condition. The CLI does not suppress user or system activity. |
| `screen-off-idle` | 600 s | Turn the display off using normal macOS controls; MacLean does not change display settings. |
| `light-productivity` | 900 s | Describe the application and repeatable task in `--workload`; no workload is bundled yet. |
| `video-playback` | 900 s | Describe the local content, player, and playback configuration in `--workload`; no content is launched. |
| `cpu-intensive` | Required | Identify the fixed task in `--workload` and provide its duration. Timing the task itself remains external. |

Lid-closed sleep is not an automated scenario yet: the MacLean process is suspended during system sleep, so continuous sampling and a trustworthy sleep-energy integral are unavailable. No sleep settings or wake assertions are changed.

## Optional privileged diagnostic

`--powermetrics` opts into the macOS `cpu_power`, `battery`, and `interrupts` samplers. The option is rejected unless the process is already running with effective UID 0. MacLean never calls `sudo`, opens an authorization prompt, or retries with higher privileges. Because this is an opt-in read-only diagnostic path, the operator must launch it explicitly with administrator authorization. This runs the benchmark process with that privilege; use it only for a diagnostic session. The sampler is invoked once per benchmark sample and adds collection overhead, which is included in the record.

Only recognizable Intel average-frequency, package C-state-residency, and Intel energy-model package-power text fields are currently parsed. Package power is marked as an OS estimate. Wakeup fields and any other unrecognized output remain unavailable. The exact sampler names, permissions, output, and supported counters vary by macOS and hardware; review the local `powermetrics(1)` manual before use. No benchmark runs this mode automatically.

## Measurement practice

- Record repeat count, trial order, task completion time, sampling method, actual duration, and conditions.
- Keep the Mac on the same power source for matched runs; do not count a battery estimate while charging as system energy consumption.
- Keep display brightness, external displays, network state, peripherals, and room conditions consistent.
- Run on a quiet system and record unexpected load or thermal changes. Telemetry alone does not identify unrelated process names.
- Treat unsupported fields as unavailable and include their coverage in any analysis.
- Include MacLean collector overhead in the report; JSON encoding and output writing are not included in the collector timing.
