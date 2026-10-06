PROJECT RULES — KindDose (medication reminder, iOS 17+, SwiftUI + SwiftData)

Who it's for: everyone, designed elder-first and accessibility-first.
Goal: logging a dose takes under 5 seconds. Calm, kind, never guilt.

Accessibility (mandatory on every screen):
- Dynamic Type up to AX5, no truncated text, layouts scroll when needed
- Every control has a VoiceOver label + hint; logical reading order
- Tap targets ≥ 60pt; no swipe-only or long-press-only actions
- Never use colour alone (icon + word + colour)
- Respect Reduce Motion, Increase Contrast, Reduce Transparency
- Text always on solid cards, never directly on gradients
- Works with Voice Control and Switch Control

Tone: plain, warm, short sentences. Never "failed/forgot/missed" in a
blaming way. No red ❌ for missed doses (use soft grey).

Safety: never give medical advice. Never tell users to take a late or
double dose. For missed doses say: "Check your medicine leaflet or ask
your pharmacist." Scanned/spoken data is NEVER saved without a
"Is this correct?" confirmation screen.

Privacy: all data on device (SwiftData). No accounts, analytics, ads,
or network calls.

Newer APIs (iOS 26 alarms, HealthKit medications): use `if #available`
and fall back gracefully on iOS 17.

Code style: small focused SwiftUI views, one feature per folder.
Build after every change and fix all errors before finishing.
