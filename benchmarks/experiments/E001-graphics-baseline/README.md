# E001 — Native graphics switching baseline

## Hypothesis

On a dual-GPU Intel Mac, native automatic graphics switching may affect whole-system discharge power and CPU package idle residency during otherwise matched light and idle workloads. GPU inventory alone does not show which GPU is active or its power state.

## Controlled variables

Use the same Mac and macOS build, battery state and power source, screen brightness, display arrangement, workload, foreground applications, network state, peripheral connections, thermal state, and trial duration. Record the order and any user interaction. Use at least three repeats per setting, with the order alternated or randomized.

## Measurement sources

- MacLean benchmark battery voltage/current and integrated discharge watt-hours, only with adequate battery-powered coverage.
- Optional, explicitly authorized `powermetrics` CPU package estimate and package C-state data, reported separately from whole-system power.
- MacLean doctor GPU inventory and the native graphics-switching setting recorded by the operator.
- Active GPU, GPU power state, and GPU watts: unavailable until a supported and validated source is identified.

## Procedure

1. Confirm the Mac model, OS build, battery health, and whether native automatic graphics switching is available.
2. Record the initial setting. If the operator chooses to compare states, change it only in macOS settings and restore it after the experiment; MacLean does not write it.
3. Run three matched 10-minute desktop-idle trials per state on battery, using the release binary and a fixed sample interval. Keep brightness, displays, apps, network and peripherals unchanged.
4. Do not include a trial if the system changes power source, sleeps, has thermal pressure, or has inadequate discharge-data coverage. Record the reason and repeat it.
5. Compare whole-system watt-hours and average discharge watts separately from package estimates, with CPU use, thermal state, and repeat variability.

## Acceptance criteria

At least three valid trials per state; matching machine/build and conditions; at least 95% battery-power coverage; no unexplained charging or AC intervals; separate reporting of system energy and package estimate; active GPU state evidence before attributing a change to graphics switching.

## Results

Not run. The host inventory contains Intel UHD 630 and AMD Radeon Pro 5500M, but no validated live active-GPU or GPU-power reading.

## Limitations

System Profiler inventory is not active-device evidence. There is no validated public cross-driver GPU power-state property on this host. A result without active-GPU evidence can compare native settings but cannot establish the causal GPU state. No MacLean graphics control is implemented.
