# Development Roadmap

MacLean advances only when each phase produces reviewable evidence. Safety requirements apply to every phase, not just the final integration milestone.

| Phase | Focus | Deliverable | Exit evidence |
|---|---|---|---|
| 0 | Hardware discovery | Privacy-conscious host inventory and capability matrix | Initial `doctor` inventory exists; target model/build and remaining unknown capabilities still need confirmation |
| 1 | Baseline measurement and extended telemetry | Repeatable JSON benchmark trials, native battery current/voltage reads, comparison utility, optional privileged diagnostics | Tooling is implemented; a provisional two-repeat screen-on battery idle starter reference exists. A larger matched set is still needed to characterize normal variation |
| 1.5 | Energy bottleneck attribution | Validated telemetry and controlled experiment registry | Starter baseline exists; target `powermetrics` output validation and a controlled E002 peripheral comparison remain outstanding |
| 2 | First measurable optimization | Select a module from E001–E005 evidence | Repeatable energy-per-task improvement with acceptable performance and stability |
| 3 | Graphics | Read-only integrated/discrete GPU activity and switching study | Scenarios mapped to OS/driver behaviour; no forced GPU disablement |
| 4 | Thunderbolt and PCIe | Peripheral activity, link, sleep/wake, and ASPM research | Device/controller effects distinguished; connectivity and wake behaviour preserved |
| 5 | Intelligent workload management | Recommendations for MacLean-owned work using QoS, timer tolerance, and system deferral | Demonstrated effect on MacLean's own energy cost without harming foreground responsiveness |
| 6 | Adaptive engine | Explainable workload-aware power-profile simulation | Stable state transitions, hysteresis, dwell times, and offline results; still no automatic writes |
| 7 | Experimental research | Isolated T2, deep-idle, PCIe ASPM, and power-gating feasibility studies | Written feasibility and safety review before any prototype that can alter system state |
| 8 | Additional modules | Memory, thermal, network, and storage research | Each module has a source inventory and controlled workload evidence |
| 9 | Integration and safety | Optional controls only where a documented interface exists | Compatibility checks, consent, watchdog, verified rollback, and sleep/wake/peripheral regression evidence |

## Immediate work

1. E005's current-release AC overhead study is complete with three repeats per interval; review its wall/CPU trade-offs. Battery-side overhead and energy impact remain unmeasured.
2. A provisional screen-on battery idle reference now uses Trials 2 and 3; Trial 1 is excluded because the operator reports Finder-window activity. The two included trials began at 4–5% charge, and their peripheral configuration is unknown. Use the reference as a starter only; collect better-matched repeats before making an optimization claim.
3. Validate the exact `powermetrics` C-state and interrupt output in a short, explicitly authorized privileged session. The current backend does not parse interrupt-source detail; MacLean must never elevate automatically.
4. Use read-only Thunderbolt counts only as topology inventory. Driver-reported GPU utilization is available when published, but actual GPU selection/power state and Thunderbolt controller power remain unavailable. A device interrupt, if observed, is not proof of controller power state or causal package wakeups.
5. Select the first optimization only after repeatable energy and performance measurements identify an actionable bottleneck. Do not implement invasive hardware controls until a documented reversible interface exists.

## Promotion criteria

A feature can move from research to a stable module only when its source is understood, capability checks are explicit, missing data is safe, overhead is measured, the effect is repeatable, and regressions are documented. A control remains experimental if the only path is private, undocumented, privileged without narrow justification, or difficult to roll back.

## Success measures

- Energy or discharge change under matched repeated workloads, with uncertainty.
- Task completion time and responsiveness.
- Thermal state and fan behaviour.
- Sleep/wake success, battery charging, peripheral connectivity, and security posture.
- MacLean's own idle CPU, wakeup, and memory cost.

Lower frequency, fewer wakeups, or lower temperature alone do not establish an energy benefit.
