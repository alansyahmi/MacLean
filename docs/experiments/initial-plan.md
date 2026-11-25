# Initial Experimental Plan

This procedure is an initial baseline proposal. The canonical metric and quality requirements are in [the telemetry specification](../TELEMETRY.md); subsystem-specific limitations are in the [module research specifications](../modules/cpu.md).

## Purpose

Establish a trustworthy baseline before implementing optimisation controls. The first experiments are observational and should be repeatable on the same machine.

## Required machine record

Capture the exact Mac model identifier, CPU brand string and core/thread count, GPU model, RAM, macOS version and build, firmware version where available, battery cycle count and condition, full-charge capacity where available, active power mode, display brightness, network state, connected displays/peripherals, and ambient conditions where practical.

Never publish serial numbers or other unique device identifiers.

## Baseline controls

Keep conditions consistent: same brightness and keyboard backlight, network state, peripherals, applications and browser tabs, power mode, starting battery state, and initial thermal condition. Run trials more than once. Randomise or alternate test order where practical to reduce time-of-day and thermal bias.

## Experiment 01 — Idle baseline

1. Reboot and allow background startup activity to settle.
2. Record a quiet desktop baseline.
3. Sample available telemetry for a fixed period.
4. Record power assertions, wakeups, thermal state, and battery discharge estimate.
5. Repeat with the normal development environment open.

Primary question: what background activity prevents the system from remaining in low-power idle states?

## Experiment 02 — macOS Low Power Mode

Compare Low Power Mode enabled and disabled under matched conditions. Record task completion time, CPU utilisation and frequency observations where available, thermal behaviour, battery discharge estimate, and responsiveness as a secondary observation.

Do not infer CPU package power from battery discharge alone.

## Experiment 03 — Compilation workload

Use a fixed project revision and reproducible clean build. Record build command and toolchain version, wall-clock completion time, CPU utilisation and frequency distribution where available, thermal pressure and fan behaviour, and battery energy change if measurable.

Compare energy per completed build, not just peak frequency or temperature.

## Experiment 04 — Wakeup investigation

Compare a quiet desktop against a normal development session. Inspect available power assertions and process activity. Avoid aggressive sampling that itself creates significant wakeups.

## Experiment 05 — GPU activity

Compare a controlled lightweight desktop workload with a known GPU-accelerated workload. Record GPU process/activity indicators and battery behaviour. Keep display configuration identical.

## Measurement limitations

macOS does not expose every hardware counter or sensor on every Intel Mac. Tools such as `powermetrics` vary by OS release and hardware. Check local help and available samplers before relying on a metric. Store missing values as unavailable; do not estimate C-state residency, package power, or temperature from unrelated signals.

## Success criteria

An experiment is useful when its conditions are documented, it can be repeated, measurement sources and limitations are explicit, it distinguishes energy/performance/thermal outcomes, and conclusions do not exceed the evidence.

No optimisation should be declared successful based on a single run or on lower CPU frequency alone.
