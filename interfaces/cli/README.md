# CLI

The CLI provides a one-shot doctor command and an on-demand monitor, implemented in Swift with no third-party dependencies. Doctor uses allowlisted system_profiler fields, sysctl, pmset, and Foundation's coarse thermal-state API. Monitor uses Mach CPU tick counters, pmset battery status, and Foundation thermal state. Neither enumerates raw IORegistry trees, invokes powermetrics sampling, writes reports to disk, or changes settings.

Build and run it with:

    swift run maclean doctor
    swift run maclean doctor --json
    swift run maclean monitor --interval 5 --count 12

The shell-only fallback is:

    sh interfaces/cli/maclean-discover.sh

The report distinguishes supported, unsupported, unknown, and experimental capability states. Unknown means the command did not establish support; it is not a claim that the hardware lacks the feature. Some values may be unavailable in a restricted shell, virtual machine, or unsupported macOS release. Do not rerun with elevated privileges as a fallback.

Monitor emits JSON Lines to stdout. Records include the OS version/build and non-unique model/processor facts when available. Its interval defaults to five seconds and may be set between one and 3600 seconds. `--count` limits the run; without it, press Ctrl-C to stop. The first CPU utilization record is unavailable because a preceding counter interval is needed. Frequency, C-state residency, wakeups, discharge rate, live GPU/controller power, physical temperatures, and fan speed remain unavailable until a safe source is validated.
