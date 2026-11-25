# CLI

The initial CLI contains a one-shot inventory script only. It is read-only, writes no files, has no network access, and does not start a persistent collector. The script is an operator aid and does not select MacLean's eventual implementation language.

Run it with:

    sh interfaces/cli/maclean-discover.sh

Some values may be unavailable in a restricted shell, virtual machine, or unsupported macOS release. Do not rerun with elevated privileges as a fallback.
