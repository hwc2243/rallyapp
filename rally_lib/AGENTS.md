# Instructions for rally_lib Agent

## Source of Truth
- Service Requirements: ./docs/PRD.md
- Implementation Details: ./docs/IMPLEMENTATION.md

## Rules
- This is a pure service/logic library. DO NOT place UI widgets, dialogs, or screens here.
- Maintain high float precision for distance calculations.
- Never block the main thread; throttle disk writes (SharedPreferences) to every 5s or on app pause.
- Export all public APIs via `lib/rally_lib.dart`.
