# Instructions for rally_odometer Agent

## Source of Truth
- Product Requirements: ./docs/PRD.md
- Design Specification: ./docs/DESIGN.md
- Implementation Details: ./docs/IMPLEMENTATION.md

## Rules
- All calculations, GPS parsing, and telemetry logic MUST come from `package:rally_lib/rally_lib.dart`.
- Do not duplicate calculation logic inside UI widgets or dialogs.
- Always follow layout, typography, and contrast standards in `DESIGN.md`.
- Ensure all full-screen routes use `SafeArea` + `SingleChildScrollView` to prevent RenderFlex overflow errors.
