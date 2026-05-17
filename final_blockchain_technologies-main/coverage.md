# Coverage Report

Target requirement: line coverage >= 90% across `contracts/`, measured with `forge coverage`.

This repository is configured to run:

```bash
forge coverage --report summary
```

Current local status:

| Metric | Requirement | Status |
|---|---:|---|
| Line coverage | >= 90% | Pending measured run |
| Tool | Foundry `forge coverage` | Configured in CI |
| Scope | `contracts/` | Foundry default project scope |

The execution environment used for this update does not have `forge` installed in PATH, so the numeric coverage output could not be generated here. Run the command above in a Foundry-enabled environment and replace this placeholder with the emitted summary before final submission.
