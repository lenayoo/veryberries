# AGENTS.md - Very Berry Days Functional Refactor Only

## Scope
This refactor must be functional only.

Do not change the visual design.
Do not redesign the UI.
Do not change layout, colors, spacing, animations, icons, cards, buttons, or background.

Only fix:
1. Daily/monthly reset behavior
2. Localization for English, Japanese, and Korean

## 1. Fix Daily / Monthly Reset Bug

Current bug:
- Daily goals remain visible after the day changes.
- Monthly goals remain visible after the month changes.

Required behavior:
- Today goals must be shown only for the current calendar date.
- Monthly goals must be shown only for the current calendar month.

Use date-based storage keys:
- Daily goals key: yyyy-MM-dd
- Monthly goals key: yyyy-MM

Example:
- A goal created on 2026-05-27 should only appear on 2026-05-27.
- It should not appear on 2026-05-28.
- A monthly goal created in 2026-05 should only appear during 2026-05.
- It should not appear in 2026-06.

Implementation rules:
- Keep past data if already stored, but do not show it on the current main screen.
- On app launch/resume, check the current date and current month.
- Load only the goals matching today’s key and current month key.
- Do not clear all storage globally.
- Do not overwrite past records accidentally.
- Separate daily goals and monthly goals clearly.

Recommended helpers:
- getTodayKey() -> yyyy-MM-dd
- getCurrentMonthKey() -> yyyy-MM
- loadTodayGoals()
- loadCurrentMonthGoals()
- saveTodayGoals()
- saveCurrentMonthGoals()

## 2. Localization

Current issue:
- The app only supports Japanese.

Required languages:
- English
- Japanese
- Korean

Behavior:
- App language should follow the system language automatically.
- If the system language is unsupported, default to English.

All user-facing strings must be localized:
- App title
- Text field placeholder
- Add to this month button
- Add to today button
- Monthly goal title
- Today goal title
- Empty state messages
- Any alert/error/helper text

Do not keep hardcoded Japanese strings in widgets.

Suggested localization tone:

English:
- "One Berry at a Day"
- "Enter a goal."
- "Add to this month"
- "Add to today"
- "This month’s goals"
- "Today’s goals"
- "No goals yet."

Japanese:
- "One Berry at a Day"
- "やることを入力してください。"
- "今月に追加"
- "今日に追加"
- "今月の目標"
- "今日の目標"
- "予定がないです。"

Korean:
- "One Berry at a Day"
- "할 일을 입력해 주세요."
- "이번 달에 추가"
- "오늘에 추가"
- "이번 달 목표"
- "오늘의 목표"
- "아직 목표가 없어요."

## Non-Goals

Do not:
- Change UI design
- Change colors
- Change background
- Change button design
- Change card design
- Add animations
- Add new screens
- Add new features
- Rename the app
- Change the current component structure unnecessarily

## Final Check

After refactoring, confirm:
- Today goals reset when the date changes.
- Monthly goals reset when the month changes.
- English/Japanese/Korean switch by system language.
- Unsupported languages fall back to English.
- No hardcoded Japanese text remains in UI widgets.
- The visual design remains unchanged.