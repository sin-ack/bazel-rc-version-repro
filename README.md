# Bazel conditional imports skip release candidates

Run `./run.sh` (requires Bash and Bazelisk; downloads upstream Bazel binaries).
On NixOS the script automatically uses `steam-run` when available.
Optional arguments replace the default version list, e.g. `./run.sh 9.0.0rc6`.

## Observed results

All three commands exited successfully (0).

| Condition | 9.0.0 | 9.0.0rc5 | 10.0.0-pre.20260104.1 |
|---|---|---|---|
| unconditional control | imported | imported | imported |
| >=9.0.0 | imported | skipped | imported |
| >=9.0.0-0 | imported | skipped | imported |
| >=9.0.0-rc.1 | imported | skipped | imported |
| <9.0.0 | skipped | skipped | skipped |
| >=10.0.0 | skipped | skipped | skipped |
| >=10.0.0-0 | skipped | skipped | imported |

Full captured output: `results/<version>.log`.
Machine-readable summary: `results/summary.tsv`.

The RC imports **none** of the conditional files, including both `<9.0.0`
and `>=9.0.0`. This is not merely normal prerelease ordering. Its build label
`9.0.0rc5` cannot be parsed as strict SemVer, so conditional imports are skipped.
If normalized to `9.0.0-rc.5`, we would expect `>=9.0.0-0`,
`>=9.0.0-rc.1`, and `<9.0.0` to match.

The rolling release demonstrates working SemVer prerelease comparison:
it matches `>=10.0.0-0` but not `>=10.0.0`. A 10.x rolling release is used
so the test runs a rolling binary containing the conditional-import feature.

All conditions intentionally use valid SemVer. Putting `>=9.0.0rc1` directly
in the shared rc file would instead cause valid-SemVer builds to reject that
condition, obscuring the separate problem with parsing the running build label.

Relevant original proposal (explicitly included RC matching):
https://github.com/bazelbuild/bazel/issues/24043#issuecomment-3502702961
