# MomCare+ Publish Readiness Requirements

## Product Direction
- V1 is an offline-first pregnancy and pre-pregnancy health companion for users in Vietnam.
- V1 targets Vietnamese users and should avoid unsupported or sensitive claims.
- V1 does not include login, Supabase sync, analytics, ads, AI advice, wearable integration, expert chat, or diagnosis.
- Supabase cloud sync is planned for a later phase and must require explicit user consent.

## Publish Readiness Requirements
- Remove gender selection content and entry points from V1.
- Audit medical claims across nutrition, tracking, fertility, and health diary content before rewriting in later phases.
- Make the app Vietnamese-only in a later phase.
- Add Privacy Policy and Medical Disclaimer screens in a later phase.
- Add delete-all-data flow before store submission.
- Add emergency warning guidance before store submission.
- Add medical references and content metadata before store submission.
- Keep HealthKit/Google Fit menstrual cycle sync, with clear permission rationale before requesting access.
- Replace default tests with app-specific tests before store submission.

## Phase 1 Scope
- Remove gender selection from user-accessible flows.
- Produce a medical-claims audit artifact.
- Do not implement legal, privacy, Vietnamese-only, emergency, references, permissions, or testing phases yet.
