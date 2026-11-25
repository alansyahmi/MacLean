# E005 — Collector sampling overhead

## Hypothesis

Shorter requested intervals increase MacLean's own CPU and wall-time cost and can change the idle workload being measured. A coarser interval may lower collection cost while reducing temporal resolution.

## Controlled variables

Same host/build, prebuilt release executable, `desktop-idle` scenario, 300-second target duration, one trial per invocation, no warm-up, balanced interval order. MacLean does not enforce an idle desktop or suppress user/system activity, and no process list was collected. The repeated study was physically plugged in; `pmset` and IOPowerSources both reported AC during every sample. No source build occurred during measurements.

## Measurement sources

The benchmark's per-sample `collectorOverheadMilliseconds`, process CPU time, separately timed pretrial `hardwareContextCollectionMilliseconds`, actual sample offsets/count, aggregate CPU utilization, thermal state, and battery source. Sampling collector CPU percent is `collector CPU milliseconds / actual duration milliseconds × 100`. Sampling wall-time overhead percent is the sum of per-sample collector wall milliseconds divided by actual duration milliseconds. Combined measured wall-time overhead also includes the separately timed hardware-context collection. CPU use for that pretrial hardware inventory is not measured separately. JSON encoding, output writing, and sleep between samples are excluded. AC trials cannot measure battery energy impact.

## Procedure

1. Run the release binary for 300 seconds at 1, 5, 15, and 30 seconds; save results under a local temporary directory.
2. Record actual duration and sample count. Derive the observed interval from monotonic sample offsets rather than assuming the requested cadence was achieved.
3. Compare collector CPU and wall-time cost per minute and per sample. Repeat in a balanced or shuffled order at least three times before selecting a default cadence.
4. Run a separate battery-powered study if estimating battery impact is required.

## Acceptance criteria

All intervals use the same executable and condition; actual duration is within 2% of target; no build work overlaps a trial; output includes sample counts, measured collection overhead, and battery state; repeat trials are required before choosing a production interval.

## Results

### Current-release AC repeat study

Completed 2026-11-25 on macOS 26.7.3 build 25G342, x86_64 Intel Mac, using the prebuilt release executable from code commit `a5265c5`. Twelve 300-second trials were run, three at each interval, in this order: 15, 1, 30, 5, 30, 5, 15, 1, 5, 30, 1, 15 seconds. Physical AC connection was confirmed by the operator; both `pmset` and IOPowerSources reported `AC Power` throughout. The IOPowerSources charging flag varied between true and false, but the source remained AC. Thermal state was nominal in every sample. Actual durations ranged from 300.097 to 300.118 seconds (within 0.04% of target). All 12 result files remain in `/private/tmp/maclean-e005-current-release-20261125/`; no raw output is committed.

| Requested interval | Samples per trial | Mean observed interval | Sampling collector wall cost | Sampling wall overhead (mean ± SD) | Collector CPU overhead (mean ± SD) | Pretrial hardware inventory wall time (mean) | Combined measured wall overhead (mean ± SD) |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 s | 272–273 | 1.106 s | 27.915 s / 300 s | 9.302 ± 0.021% | 1.675 ± 0.005% | 3,041 ms | 10.315 ± 0.032% |
| 5 s | 60 | 5.085 s | 6.742 s / 300 s | 2.247 ± 0.020% | 0.384 ± 0.001% | 2,953 ms | 3.231 ± 0.029% |
| 15 s | 21 | 15.000 s | 2.795 s / 300 s | 0.931 ± 0.029% | 0.149 ± 0.0004% | 2,914 ms | 1.902 ± 0.018% |
| 30 s | 11 | 30.001 s | 1.861 s / 300 s | 0.620 ± 0.002% | 0.089 ± 0.0003% | 3,009 ms | 1.623 ± 0.040% |

Standard deviations are sample SD across the three trials. Combined measured wall overhead adds the separately timed pretrial hardware inventory to the sampling collector cost; it still excludes JSON encoding and output writing. Mean CPU utilization by interval was 1.56% (between-trial SD 0.63 pp), 1.22% (0.04 pp), 2.66% (2.34 pp), and 1.19% (0.26 pp), respectively. That variation, especially at 15 seconds, is unassigned workload variation and not an energy result. No battery-discharge watt-hours were available or expected while on AC.

The repeated measurements show the expected wall/CPU collection-cost trade-off: sampling wall overhead falls from 9.30% at a requested 1-second interval to 0.62% at 30 seconds. The 1-second observed cadence averaged 1.106 seconds because collection time is added between requested sleeps. These results characterize the current release under this host and AC condition; they do not establish battery impact or a universal default.

### Initial single-pass screening (historical)

The earlier screening used the IOPowerSources-only build, one 300-second trial per interval, and order 1, 5, 30, 15 seconds. The operator later confirmed the Mac was physically on battery despite `pmset` reporting AC. Battery voltage was unavailable, so all runs had zero valid discharge-energy coverage. Historical per-trial samples were 275, 60, 21, and 11; mean observed intervals were 1.095, 5.085, 15.000, and 30.001 seconds; sampling collector wall costs were 25.91, 6.56, 2.78, and 1.74 seconds, respectively. The historical run is retained for context but is not combined with the current-release repeat study.

## Limitations

The current AC study did not measure battery energy or battery-side overhead. Its wall-time measurements exclude JSON encoding and output writing, and pretrial hardware-context CPU time was not separately measured. The historical battery-powered pass had no discharge-energy coverage. MacLean does not enforce the idle condition, and the measured CPU variation was not attributed to processes. Run a separate battery-powered study with adequate coverage before making claims about battery impact or choosing a battery-oriented default. CPU utilization varied across intervals and cannot be interpreted as collector energy.
