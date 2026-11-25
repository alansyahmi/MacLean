# CPU Efficiency Research Specification

## Goal

Reduce energy per completed task while preserving latency, responsiveness, system stability, and the processor's firmware-managed safety behaviour.

## Questions

- Which CPU family and exact SKU are in the test Mac?
- Which CPU utilization, frequency, QoS, wakeup, and package-residency fields does the installed macOS build expose?
- Does the hardware expose Speed Shift/HWP data through a supported sampler?
- Which workload classes benefit from finishing quickly and returning to idle?
- How much do timer wakeups and background activity change package idle residency?

## Read-only work

Record CPU model, logical and physical processor count, OS build, utilization over a documented window, wakeup rate where supported, and available frequency/residency fields with their source and quality. Check the local powermetrics manual and sampler list before each platform-specific study. Mark unsupported counters as unavailable.

The stated target is consistent with an i9-9980HK, which Intel lists with Speed Shift and idle-state support. The workspace inventory did not expose the CPU name or model identifier, so this remains a candidate, not a confirmed processor. Even a confirmed silicon feature does not prove macOS exposes a usable counter or control. See [Intel's product specification](https://www.intel.com/content/www/us/en/products/sku/192990/intel-core-i99980hk-processor-16m-cache-up-to-5-00-ghz/specifications.html).

Do not infer C-state residency from average frequency, CPU utilization, battery percentage, fan speed, or elapsed idle time. Do not treat Intel's rated frequency or a requested frequency as the observed effective frequency.

## Hypotheses to test

- A short, efficient burst followed by a long idle interval can use less energy than prolonged low-frequency execution.
- Reducing unnecessary timers and background wakeups may let the OS remain in deeper idle states.
- Lower CPU utilization or frequency can increase task duration enough to raise total energy.
- macOS already coordinates Intel frequency selection and thermal limits; persistent userspace overrides may fight that control loop.

## Benchmark design

Use a fixed input and software revision. Record completion time, battery conditions, power source, CPU utilization, temperature/thermal state when available, wakeups, and the measurement source. Repeat trials and alternate ordering when practical. Report absolute results and variability; do not publish a single-run winner.

## Control boundary

No C-state, voltage, Turbo Boost, MSR, HWP, or package power-limit writes are in scope. A future proposal must identify a documented macOS interface, model-specific support, and an independent rollback before implementation. Firmware and thermal protections remain authoritative.
