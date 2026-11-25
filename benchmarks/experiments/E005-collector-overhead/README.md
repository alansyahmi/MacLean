# E005 — Collector sampling overhead

## Hypothesis

Shorter requested intervals increase MacLean's own CPU and wall-time cost and can change the idle workload being measured. A coarser interval may lower collection cost while reducing temporal resolution.

## Controlled variables

Same host/build, prebuilt release executable, `desktop-idle` scenario, AC power, 300-second target duration, one trial per interval, no warm-up, same foreground/background state. Order: 1 s, 5 s, 30 s, 15 s. No source build occurred during measurements.

## Measurement sources

The benchmark's per-sample `collectorOverheadMilliseconds`, process CPU time, actual sample offsets/count, aggregate CPU utilization, and battery source. Collector CPU percent is `collector CPU milliseconds / actual duration milliseconds × 100`. Wall-time overhead percent is the sum of measured collector wall milliseconds divided by actual duration milliseconds. AC trials cannot measure battery energy savings.

## Procedure

1. Run the release binary for 300 seconds at 1, 5, 15, and 30 seconds; save results under a local temporary directory.
2. Record actual duration and sample count. Derive the observed interval from monotonic sample offsets rather than assuming the requested cadence was achieved.
3. Compare collector CPU and wall-time cost per minute and per sample. Repeat in shuffled order at least three times before selecting a default cadence.
4. Run a separate battery-powered study if estimating battery impact is required.

## Acceptance criteria

All intervals use the same executable and condition; actual duration is within 2% of target; no build work overlaps a trial; output includes sample counts, measured collection overhead, and battery state; repeat trials are required before choosing a production interval.

## Results

Single screening pass on 2026-11-25, macOS 26.7.3 build 25G342, x86_64 Intel Mac, on AC; release executable, 300 seconds each, one repetition each. Trial order was 1, 5, 30, 15 seconds. All runs had zero valid battery-discharge samples.

| Requested interval | Samples | Mean observed interval | Collector wall cost | Wall cost / duration | Collector CPU | CPU / duration |
|---:|---:|---:|---:|---:|---:|---:|
| 1 s | 275 | 1.095 s | 25.91 s | 8.63% | 4.79 s | 1.60% |
| 5 s | 60 | 5.085 s | 6.56 s | 2.19% | 1.08 s | 0.36% |
| 15 s | 21 | 15.000 s | 2.78 s | 0.93% | 0.43 s | 0.14% |
| 30 s | 11 | 30.001 s | 1.74 s | 0.58% | 0.26 s | 0.09% |

All actual durations were about 300.1 seconds. The 1-second run produced fewer than 300 samples because collection time extends the effective interval; use actual timestamps for cadence. The initial result supports a clear cost/resolution trade-off, but one run per interval does not establish repeatability or energy impact.

## Limitations

The Mac was AC-powered, battery voltage was unavailable to the IOPowerSources-only build, and no discharge energy was measured. These trials predate the documented IOPMPowerSource scalar fallback, which adds property reads when IOPS omits an electrical field; repeat the interval study against the updated release. The run order was not fully counterbalanced. CPU utilization varied across intervals and cannot be interpreted as collector energy. Repeat each cadence at least three times, then repeat on battery with adequate discharge-power coverage before choosing a default.
