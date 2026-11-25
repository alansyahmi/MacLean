# CLI

The CLI currently provides a one-shot doctor command, implemented in Swift with no third-party dependencies. It uses allowlisted system_profiler fields, sysctl, pmset, and Foundation's coarse thermal-state API. It does not enumerate raw IORegistry trees, invoke powermetrics sampling, write files, or change settings.

Build and run it with:

    swift run maclean doctor
    swift run maclean doctor --json

The shell-only fallback is:

    sh interfaces/cli/maclean-discover.sh

The report distinguishes supported, unsupported, unknown, and experimental capability states. Unknown means the command did not establish support; it is not a claim that the hardware lacks the feature. Some values may be unavailable in a restricted shell, virtual machine, or unsupported macOS release. Do not rerun with elevated privileges as a fallback.
