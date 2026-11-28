# Provisional screen-on desktop-idle starter baseline

## Status

This is a reviewed, privacy-filtered starter reference for future experiments. It is not a controlled Thunderbolt comparison or a claim about component-level power. The raw benchmark JSON remains local and is not committed.

## Method

- Session date: 2026-11-28 according to the JSON timestamps; the output filename used by the operator says 2026-11-26.
- Platform context: Intel x86_64 Mac, macOS 26.7.3 build 25G342. The committed summary omits the exact model identifier and processor string.
- Scenario: screen-on `desktop-idle`; three 600-second trials, requested 5-second interval, prebuilt release executable, no warm-up, and no `powermetrics`.
- The operator reports Finder windows were opened and closed during Trial 1, then applications were closed. Trials 2 and 3 are used for this starter baseline; Trial 1 is retained locally but excluded from this idle estimate.
- Trial 2 and Trial 3 each lasted about 600.1 seconds with 119 samples and 99.984% discharge-power coverage. Mean observed sample spacing was about 5.085 seconds.
- `pmset` and IOPowerSources reported battery power and discharging/not charging throughout the two included trials. Discharge power is derived from direct voltage and signed-current readings; energy is trapezoidally integrated from those samples.
- The display was kept awake and idle system sleep inhibited with `caffeinate -di`. The benchmark does not verify that the user or background system remained idle.

## Result

| Trial | Integrated discharge energy | Mean discharge power | State of charge |
|---|---:|---:|---:|
| 2 | 0.730177 Wh | 4.380 W | 5% to 4% |
| 3 | 0.741506 Wh | 4.448 W | 4% to 3% |
| Mean of 2 trials | 0.735842 Wh per 10 minutes | 4.414 W | — |

Between-trial sample standard deviation is 0.008010 Wh and 0.048 W (about 1.1% coefficient of variation). With only two repeats, this describes these captures but does not establish typical run-to-run variation.

The thermal-state metric was nominal. MacLean collection cost averaged about 12.0 seconds of collector wall time and 2.07 seconds of process CPU time per 10-minute trial (about 2.0% wall time and 0.34% CPU time). Task completion time, physical temperature, display brightness, ambient conditions, and device/peripheral configuration were not measured or recorded.

## Interpretation and limits

Use 0.736 Wh per 10 minutes (about 4.41 W) as the provisional screen-on idle reference for this session. The two included trials began at only 5% and 4% charge and ended at 4% and 3%. Keep the low state of charge, unknown peripheral configuration, unverified idle condition, and small repeat count attached to any comparison. A future candidate run should match these conditions or establish a new matched reference before an optimization claim.

This result does not identify CPU package energy, C-state residency, GPU state, Thunderbolt controller power, or a causal source of battery load.
