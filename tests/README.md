# Test locations

- `mobile/test`: curriculum validation, durable SQLite reopen, save failure/concurrency, microphone transitions, widget journey, routing and accessibility checks.
- `mobile/integration_test`: real native journey, SQLite and recording smoke test. Grant microphone permission on the test device before running.
- `backend/tests`: health/schema contract, environment settings and absent future AI endpoints.
- `docs/SPRINT_1_VALIDATION.md`: executed evidence and remaining device checks.

Run commands are in the root README. Test doubles exist only under mobile tests; the production app uses native adapters.
