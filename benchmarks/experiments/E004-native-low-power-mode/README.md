# E004 — Native Low Power Mode

## Hypothesis

If the target macOS and Intel Mac support native Low Power Mode, enabling it may reduce battery discharge power at the cost of task completion time or responsiveness.

## Controlled variables

Keep host/build, battery state, brightness, display arrangement, apps, network, peripherals, workload, thermal state, and sampling interval matched. Use three or more repeats per state and alternate or randomize order. Record workload completion time and responsiveness for any fixed task.

## Measurement sources

- Read-only MacLean benchmark battery voltage/current and integrated watt-hours.
- Read-only native support/status as exposed by this OS; do not infer support from a setting that is absent.
- Optional authorized `powermetrics` CPU package estimate and C-state observations, kept separate from whole-system energy.
- Task completion time, CPU utilization, and coarse system thermal state.

## Procedure

1. Confirm support and record the current native setting. If the operator chooses the comparison, change the setting only through macOS controls and restore it at the end.
2. Run three matched 10-minute idle trials per state on battery and, separately, three repeats of a fixed representative task.
3. Use the same prebuilt release binary, display brightness, apps, network and peripheral configuration. Record trial order, task completion time, and any sleep/wake or thermal event.
4. Compare system watt-hours and average discharge power separately from package estimates; compare task energy with completion time and responsiveness.

## Acceptance criteria

At least three valid battery trials per state; 95% or greater discharge-power coverage; confirmed feature support; matched conditions; quantified task performance trade-off; no claim based on one battery run or OS estimates alone.

## Results

Not run. The operator confirms earlier benchmark sessions were physically battery-powered, despite `pmset` reporting AC in some captures. Native Low Power Mode support and its battery-powered performance effect have not been confirmed.

## Limitations

Native mode may alter several system policies simultaneously. Results are OS- and model-specific and cannot be attributed to a single hardware mechanism.
