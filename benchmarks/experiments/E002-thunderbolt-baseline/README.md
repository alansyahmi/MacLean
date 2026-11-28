# E002 — Thunderbolt peripheral baseline

## Hypothesis

An attached Thunderbolt peripheral may change whole-system discharge power, interrupts, or CPU package idle residency during matched idle periods. The proposed controller-to-package-wakeup mechanism remains a hypothesis.

## Controlled variables

Keep the Mac model/build, battery state, screen brightness, displays, apps, network, workload, thermal state, sample interval, and trial duration fixed. Change only one peripheral connection. Record the device class and port without saving serial numbers, UUIDs, route strings, or unrelated device identifiers. Use at least three repeats per condition and alternate trial order.

## Measurement sources

- Battery discharge watts and integrated watt-hours from MacLean when battery-powered coverage is valid.
- The installed `powermetrics(1)` manual lists an `interrupts` sampler and an Intel `cpu_power` sampler that reports package C-state residency. A target-build sample validated the package-residency and interrupt-vector text fields; MacLean now emits per-source-label interrupt rates summed across logical CPUs. These labels are not mapped to Thunderbolt controllers, and package-idle exits remain unavailable.
- Optional explicitly authorized `powermetrics` package-power output is an Intel energy-model estimate and must remain separate from whole-system battery measurements.
- `system_profiler` Thunderbolt topology counts from `maclean doctor`; counts do not imply runtime power state.
- Thunderbolt controller power, PCIe ASPM, and power-gating state: unavailable from a validated source.

## Procedure

1. Before repeated measurements, run a quiet structured MacLean benchmark with `--powermetrics` at the intended interval and quantify its added collector wall/CPU cost. The complete CLI must already be explicitly launched with administrator authorization; MacLean never elevates itself. Do not include task/process sampling unless its privacy and attribution value are separately justified.
2. Inventory connected devices and confirm which are nonessential. Do not disconnect required storage, displays, networking, charging, or safety equipment.
3. Run at least three 10-minute desktop-idle trials with the selected peripheral connected, then three with it disconnected. The operator handles physical connections; MacLean does not alter device state.
4. Keep all other conditions fixed, record trial order, and reject trials with sleep/wake, AC transitions, thermal pressure, or substantial user activity.
5. Compare system energy, package estimates, interrupt evidence, and C-state data separately. Restore the original connections and verify normal operation.

## Acceptance criteria

Three valid repeats per condition; 95% or greater battery-power coverage; the peripheral is the only intended independent variable; measured energy and performance/availability effects are reported; no claim of controller power gating without a direct validated state reading.

## Results

The controlled peripheral comparison has not been run. A provisional two-repeat, screen-on desktop-idle reference is recorded in [`../../baseline/desktop-idle-starter-2026-11-28.md`](../../baseline/desktop-idle-starter-2026-11-28.md), but its peripheral configuration is unknown, so it is not an E002 control condition. On this host, System Profiler exposes a Thunderbolt data type and MacLean can report controller/receptacle counts. The target-build powermetrics capture reported 0% package C-state residency and active CPU/GPU fields, so it was not a quiet baseline. Its short sample showed no Thunderbolt-specific interrupt label; this is not evidence of controller inactivity. No causal Thunderbolt-to-package-wakeup link has been established.

## Limitations

Interrupt counts are evidence of activity, not proof of controller watts or link power state. A peripheral may affect unrelated subsystems. Do not use private driver properties or infer power gating from a missing device.
