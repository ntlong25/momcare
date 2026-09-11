# Agent Instructions

## Project Context
- This is a Flutter app named MomCare+.
- The current implementation is local-first and uses Hive for persistence.
- The publish-readiness work is intentionally phased; do not jump ahead of the active phase.

## Current Active Scope
- Implement Phase 1 only unless the user explicitly asks for another phase.
- Phase 1 means removing gender selection entry points/content and documenting medical claim risks.

## Guardrails
- Do not add Supabase, auth, analytics, ads, AI, wearable, or expert-chat features in V1 readiness tasks.
- Do not make broad UI rewrites unless required by the active phase.
- Do not revert unrelated deleted/modified files already present in the working tree.
- Keep changes small enough that another agent can test independently.

## Verification
- After implementation changes, run a build and tests.
- If build/tests fail due to the implemented scope, fix the errors.
- If failures are pre-existing or outside scope, document them in `PLAN.md` and the final summary.
