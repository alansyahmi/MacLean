# CLI

The CLI provides a one-shot doctor command, an on-demand monitor, and a repeated benchmark runner, implemented in Swift with no third-party dependencies. Doctor uses allowlisted system_profiler fields, sysctl, pmset, and Foundation's coarse thermal-state API. Monitor and benchmark use Mach CPU tick counters, pmset battery status, allowlisted IOPowerSources battery fields, and Foundation thermal state. They do not enumerate raw IORegistry trees or change settings.

Build and run it with:

    swift run maclean doctor
    swift run maclean doctor --json
    swift run maclean monitor --interval 5 --count 12
    swift run maclean benchmark run --scenario desktop-idle --repetitions 3 --output /private/tmp/idle.json
    swift run maclean benchmark compare baseline.json candidate.json

The shell-only fallback is:

    sh interfaces/cli/maclean-discover.sh

The report distinguishes supported, unsupported, unknown, and experimental capability states. Unknown means the command did not establish support; it is not a claim that the hardware lacks the feature. Some values may be unavailable in a restricted shell, virtual machine, or unsupported macOS release. Do not rerun with elevated privileges as a fallback.

Monitor emits JSON Lines to stdout. Records include OS version/build and non-unique model/processor facts when available. Its interval defaults to five seconds and may be set between one and 3600 seconds. `--count` limits the run; without it, press Ctrl-C to stop. The first CPU utilization record is unavailable because a preceding counter interval is needed.

Benchmark emits a structured JSON result with an allowlisted hardware inventory, ordered trials, sample provenance, actual monotonic offsets, metric summaries, unavailable counts, integrated discharge energy when coverage is sufficient, and collector overhead. The command does not launch workloads. See [benchmark procedures](../../benchmarks/README.md). The optional `--powermetrics` mode requires that the user already launch the whole CLI process as root; no elevation is attempted automatically. CPU package power is marked as an operating-system estimate.
