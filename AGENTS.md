# omarchy-localization

Public, MIT. An agent skill plus a stdlib audit script for localizing Omarchy plugins.

- The skill lives in `skills/omarchy-localization/`; keep `SKILL.md` the workflow and push detail into `reference/`.
- Every factual claim about Omarchy names a path under `$OMARCHY_PATH` or an upstream PR on omacom/omarchy, and says the version it was checked against.
- The audit reuses Omarchy's own data (`locales.json`, `plural.jq`): never copy those tables into this repo.
- Unknown is not zero: a check that could not run reports itself as not checked, never as passed.
- Tests: `python3 -m unittest discover tests` (needs an Omarchy source tree; skips otherwise).
- Public repository: no personal paths, names or private project references.
