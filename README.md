<img src="images/app-icon.jpg" width="96" alt="KindDose app icon">

# KindDose

**Gentle medicine reminders, designed elder-first for everyone.** An iOS app (SwiftUI, iOS 17+) where logging a dose takes seconds and feels good: one big button, a kind word and a joke afterwards, and no guilt when a dose is missed.

🌐 **Live page:** https://shruezee.github.io/KindDose/ · 🔒 [Privacy policy](https://shruezee.github.io/KindDose/privacy.html)

<p>
<img src="https://is1-ssl.mzstatic.com/image/thumb/Yno2J3yKIewo1hfzUnoDBw/600x1300bb.jpg" width="200" alt="Home screen with a large I took it button">
<img src="https://is1-ssl.mzstatic.com/image/thumb/DR3XOLIzEOKMLYwyEKdxzQ/600x1300bb.jpg" width="200" alt="Kind message and joke after logging">
<img src="https://is1-ssl.mzstatic.com/image/thumb/3_SFPCJAtZ8ftbjybm0C0g/600x1300bb.jpg" width="200" alt="Scan, speak, type, or import from Health">
</p>

## Why
Many medicine apps have small text, dense lists, and red warnings that make missing a dose feel like failing. KindDose is built for older adults first, and that makes it easier for everyone.

## Design principles
- **Under 5 seconds to log a dose.** Just the next medicine and one large "I took it" button, also available on the notification.
- **Accessible.** Largest Dynamic Type sizes, full VoiceOver, Voice Control and Switch Control, 60pt+ tap targets, never colour alone.
- **Kind, never guilt.** No red crosses or broken streaks. Missed doses get reassurance and a one-minute breathing exercise.
- **Safe.** Scanned or spoken medicines always go through an "Is this correct?" screen. No medical advice.
- **Private.** No accounts, ads, analytics, or network calls. Data stays on the device.

<p>
<img src="https://is1-ssl.mzstatic.com/image/thumb/uFBQsNNZHQyRtWLeyYjiXQ/600x1300bb.jpg" width="200" alt="Is this correct? confirmation">
<img src="images/05-breathe.jpg" width="200" alt="Breathing exercise">
<img src="https://is1-ssl.mzstatic.com/image/thumb/N33lV6VIn-80MbDy94OwUQ/900x1200bb.jpg" width="300" alt="Missed dose reassurance">
</p>

## Features
- Adaptive onboarding (text size, VoiceOver detection, "for me" or "for someone I care for")
- Add medicines by scanning (VisionKit, on-device), speaking (Speech), typing, or importing from Apple Health
- Actionable, time-sensitive reminders with gentle escalation, and an AlarmKit alarm on iOS 26
- Validation messages and all-ages jokes after each dose
- Kind history and streaks, widgets, and Siri App Shortcuts

## Built with
Swift · SwiftUI · SwiftData · WidgetKit · App Intents · UserNotifications · AlarmKit · VisionKit · Speech · HealthKit · Swift Testing

---
© 2026 ShruthiRamKum · Support: shruthianthropic@gmail.com
