# The Chinese edition as a worked case, and how it generalises

DHH, asked whether the Chinese build "ship[s] with a Chinese input method set
up, or is that still the painful part?", answered "All setup." Here is what that
means in the source, as of 2026-11-22.

## What is already in Omarchy 4.0 (installed source)

- A full `zh-CN` and `zh-TW` catalog set: `shell`, `menu`, `cli`, `keybindings`.
- Fcitx5 as a base package and user service, with toolkit variables set globally.
- Presets for `pinyin` (Simplified), `chewing` (Taiwan Zhuyin) and `cangjie5`
  (Hong Kong), each paired with its Noto CJK form (SC / TC / HK).
- `Super+I` switching, a bar indicator, and a terminal-safe `Ctrl+Space`.
- An ISO language marker (`/etc/omarchy/language`) that presets the desktop
  language per user while the console stays English, because the console cannot
  draw every script.

## In flight upstream (open pull requests on omacom/omarchy, 2026-11-22)

| PR | What it does | Lesson for plugins |
|---|---|---|
| #9695 Setup > Region toggle | China region: zh_CN, Rime (rime-ice), Ctrl+Space toggle, Chinese menu | Region is more than language: defaults, apps, engine |
| #19249 China default apps | WeChat, Bing China counterparts | A plugin that links a web service may need a regional alternative |
| #16358 Remaining zh-CN strings | Completes the catalog | Untranslated stragglers are the norm; audit coverage |
| #17799 Chinese Rime indicator label | Indicator says 中 rather than an English name | Status glyphs are strings too |
| #16026 Maple Mono NF CN | Chinese-capable monospace | Fonts are the OS's job, not the plugin's |
| #19471 Hide Fcitx's first label | The engine's popup covered the menu | Leave room for the candidate window near the caret |
| #18604 Lock screen password | Switch a shared engine off for secrets | Rule 2 in `input-methods.md` |
| #16761 Reminder prompt IME | `Text` + `Keys.onPressed` → `FilterInput` | Rule 1. The bug every hand-rolled text line has |
| #17623 Vietnamese input | `unikey` preset | The pattern extends past CJK |

## Generalising: a localization profile per language

For any target language, fill this in from the source before writing code:

| Field | From |
|---|---|
| Omarchy code | `locales.json` key |
| Direction | `locales.json` `direction` (absent means ltr) |
| Decimal, digits | `locales.json` `decimal`, `zeroDigit` |
| Plural categories | the audit (from `plural.jq`) |
| Needs an engine? | `presets.json`, plus upstream PRs for languages not yet preset |
| Glyph form | the preset's `font` (SC/TC/HK/JP/KR) |
| Glossary | `default/i18n/<code>/shell.json`: reuse Omarchy's terms for the same concepts |

Examples:

| Language | Dir | Plural | Engine | Plugin work beyond catalogs |
|---|---|---|---|---|
| zh-CN | ltr | other | Pinyin / Rime | Rule 1 for every text field |
| zh-TW | ltr | other | Zhuyin (chewing) | Rule 1, TC forms |
| ja | ltr | other | Mozc | Rule 1, JP forms |
| ko | ltr | other | Hangul | Rule 1; Hangul composes per syllable, so preedit is short but still present |
| ar / he / fa / ur | rtl | ar six; others vary | none (layout) | Mirroring, `Util.readingKey` |
| ru / uk | ltr | one few many | none (layout) | Rule 3: shortcuts by keycode |
| vi | ltr | other | unikey (upstream) | Rule 1 |
