---
name: omarchy-localization
description: "Localize an Omarchy plugin all the way down: string catalogs in every language Omarchy ships, plurals, numbers, dates, right-to-left mirroring, CJK glyph forms, and text entry that works with input methods (Chinese Pinyin and Rime, Japanese Mozc, Korean Hangul, Zhuyin, Cangjie, Vietnamese). Use when building or repairing an Omarchy shell plugin, bar widget, panel or omarchy-* command for other languages; when asked to 'localize', 'translate', 'add Chinese', 'make it work with fcitx', 'IME', 'input method', 'RTL', or when a plugin types only Latin letters under an input method. Reads the installed Omarchy source as the reference."
license: MIT
---

# Omarchy localization

Omarchy draws every surface in the language picked under Setup > Language, and it
types every language through Fcitx5. A localized plugin joins both systems. It
does not bring its own translation runtime, and it never brings its own input
method.

**Who owns what.** Keep this split in mind throughout:

| Concern | Owner | The plugin's job |
|---|---|---|
| Which language the desktop speaks | Omarchy (`omarchy-language`, `default/i18n/locales.json`) | Follow it, live |
| Strings | The plugin (`i18n/<code>.json`) | Ship catalogs, read them through `Commons.Translations` |
| Input methods (Pinyin, Rime, Mozc, Hangul…) | The OS: Fcitx5, Omarchy presets, `environment.d` | **Not break them**: take text through a real `TextInput` |
| Keyboard layouts (AZERTY, Cyrillic, AltGr) | The OS: Hyprland + xkb | Bind shortcuts that survive any layout |
| CJK glyph forms (SC/TC/HK/JP/KR) | fontconfig, `omarchy font cjk` | Leave font families to the theme |
| Direction (ar, he, fa, ur) | `Commons.I18n.rightToLeft`, `LayoutMirroring` | Mirror explicit positions and arrow glyphs |

So "does a Chinese user get their input method" is answered by the OS. Whether
**this plugin** accepts what that input method types is answered by the plugin.

## Step 0: Find the reference, and say which one you read

```bash
echo "${OMARCHY_PATH:-/usr/share/omarchy}"; cat "${OMARCHY_PATH:-/usr/share/omarchy}/version"
```

Every claim below was checked against Omarchy 4.0.0.alpha. Read the installed
copy before trusting a path in this skill, and say which version you read:
`reference/source-map.md` lists the files. If a path has moved, the installed
source wins and this skill is stale. Say that, and file an issue here.

## Step 1: Classify the plugin on three independent questions

Answer each one separately. They are not a ladder: Reel has almost no text entry
and is entirely keyboard-driven, while the secrets card had both problems.

- **Does it show text?** Then catalogs, plurals, numbers, dates and mirroring
  apply (Step 2). Every plugin with a UI does.
- **Does a person type words into it?** A search line, a prompt, a rename box.
  Then the input-method contract applies (Step 3).
- **Does it own keys?** Letter shortcuts, vim-style movement, a password field,
  or anything running while a lock or overlay holds focus. Then layouts and
  secrets apply (Step 4).

Write the three answers and the reason for each at the top of your plan.

## Step 2: Catalogs (if it shows text)

Follow `reference/plugin-catalogs.md`. In short:

1. Move every person-facing string into `i18n/en.json` (flat keys, `%1` tokens,
   plural objects keyed by CLDR category). Leave logs, ids and protocol values in
   English, and keep brand names and key names as they are.
2. Read through `Commons.Translations { directory: Qt.resolvedUrl("i18n") }`, with
   every `strings.t()` inside a binding so a language switch re-renders it.
3. Numbers through `Commons.I18n.formatNumber`, dates through
   `Qt.locale(Commons.I18n.formatLocale)`.
4. Add languages one file at a time. A missing key falls back to the base
   language, then to English, then to the key, so a partial file is safe.
5. For each language, supply exactly the plural categories it uses. The audit
   computes them from Omarchy's own `plural.jq`.

To translate in bulk, use the general `localization` skill's batch, validate and
insert loop if you have it. This skill supplies the Omarchy contract that loop
writes into.

## Step 3: Text entry (if a person types words into it)

Read `reference/input-methods.md`. The rule that matters most:

> Qt hands input-method text only to items that answer input-method queries. A
> `Text` fed by `Keys.onPressed` appending `event.text` never receives Pinyin,
> Kana or Hangul. The user sees raw Latin letters.

Use a `TextInput`, preferably Omarchy's own `Ui/FilterInput` with your key
handler as its `keyHandler`. Hide the placeholder while there is `preeditText`.
Let the composition window draw where the caret is, and do not swallow the keys
the engine uses (Space, Enter and digits while it is composing).

## Step 4: Keys and secrets (if it owns keys)

- Letter shortcuts must survive non-Latin layouts. Both `event.key` and
  `event.text` name the layout's letter (Ctrl+K on Russian reports a Cyrillic
  key), and so does Qt's own `StandardKey` matching: on X11, Ctrl+V on Russian
  matched nothing and pasted nothing. Fall back to the physical key when the
  typed character is outside ASCII, with the shared snippet in
  `reference/input-methods.md`, Rule 3. Follow `event.text` into any function it
  is handed to; most of Reel's shortcuts were matched there, not in the handler.
- **Before making a key work on more layouts, check what it does.** If it
  discards, deletes or sends something, confirm no text field can reach that
  handler while someone is typing (Reel: `blocked: typingPrefix ||
  takeMenuRenaming`), and say in the change that a destructive key now works on
  layouts where it did nothing.
- Let `Super+I` and `Super+Shift+I` (switch input language) and `Ctrl+Space`
  in terminals pass through untouched.
- A password or secret field must not compose. Set
  `echoMode: TextInput.Password` and switch a shared, active engine to direct
  input while the field is focused, then hand it back afterwards, the way the
  lock screen does (`reference/input-methods.md` § Secrets).

## Step 5: Verify, in this order

1. `python3 scripts/omarchy-l10n-audit <plugin-dir>`. Exit 1 means errors to fix,
   and warnings are judgment calls you resolve or explain. Its hardcoded-string
   count is a lower bound: it does not see text built in JavaScript, so read the
   files before estimating the size of a translation.
2. Switch language live: `omarchy-language zh-CN`, then `ar`, then back to `en`.
   The plugin must re-render without a shell restart, and Arabic must mirror.
3. Text entry, isolated: `scripts/ime-probe` proves the platform behaviour,
   and a plugin-level scenario (the recipe is in `reference/input-methods.md`)
   proves the plugin. The new check must fail against the old code.
   By hand: enable an input method under Setup > Typing, press `Super+I`, and type `ceshi` into every field. You must
   see preedit inline, a candidate popup, and `测试` committed. A screenshot of
   the committed CJK text is the evidence. Exit code 0 is not.
4. Keys: press each letter shortcut on a Russian layout (`setxkbmap ru` on the
   private display, then the layout's own keysym, e.g. `Cyrillic_ka`). For secrets: lock or focus the secret field with Pinyin active. It must show dots,
   and the engine must come back afterwards.

Report what you ran and what you saw. A check you could not run is reported as
**not run**, never as passed.

## Someone else's plugin

Your plugin: fix it, prove it, merge it. Someone else's: be more conservative,
and make every choice reversible until the person you work for has read it.

1. Find their rules. Reel kept its agent guide in `docs/contributing/`, not at
   the root, because the plugin directory is copied verbatim into installs. Use
   their commit style, test runner and definition of done, not ours.
2. Clone their source fresh. Never work from the installed copy, which may carry
   local patches.
3. Search their issues and pull requests by exact symbol (`nativeScanCode`,
   the function name) as well as topic words, just before you push.
4. Keep the change to one problem. Translating a whole plugin is a conversation
   with the maintainer first. Ask in the pull request; do not send it unasked.
5. Push to a fork and open the pull request form filled in, unsubmitted, for
   your principal to read. Say what was not tested.

## Going beyond Chinese

The Chinese edition is the worked case (`reference/chinese-edition.md`). The
same approach covers every language Omarchy ships: the locale registry tells you
direction, decimal and digits, `presets.json` tells you which languages need an
engine, and the audit tells you which plural categories each file owes. A
language whose input method Omarchy does not preset yet (Vietnamese is in flight
upstream) still works through Fcitx5 if the plugin follows Step 3. That is why
Step 3 is the part that generalises.
