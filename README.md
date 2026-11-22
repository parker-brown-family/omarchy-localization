# Omarchy localization

An agent skill that builds **fully localized** Omarchy plugins: not only
translated strings, but plurals, numbers, dates, right-to-left mirroring, CJK
glyph forms, and text entry that works with input methods such as Chinese
Pinyin and Rime, Japanese Mozc, Korean Hangul, Zhuyin and Cangjie.

Plug it into your coding agent and ask it to localize a plugin. The agent reads
your installed Omarchy source as its reference, picks how deep the work has to
go, and proves the result with an audit and a live typing check.

## Where keyboard input comes from

Short answer: **the operating system**. Omarchy 4 ships Fcitx5 as a user
service, sets the toolkit input-method variables globally, and offers presets for
Pinyin, Zhuyin, Cangjie, Mozc and Hangul, with `Super+I` to switch. A plugin
never installs or configures an input method.

The catch is that a plugin can still **break** one. Qt delivers input-method
text only to real text-input items. A prompt built from `Keys.onPressed`
appending `event.text` works perfectly in English and types raw `ceshi` instead
of `测试` for every Chinese user. Omarchy's own reminder prompt shipped exactly
this bug until upstream moved it to `FilterInput` (omacom/omarchy#16761). So the
skill sorts plugins into three tiers:

| Tier | The plugin… | Work |
|---|---|---|
| 0 | only shows text | catalogs, plurals, numbers, dates, RTL |
| 1 | takes typed text | Tier 0, plus a TextInput that input methods can reach |
| 2 | owns shortcuts or secrets | Tier 1, plus layout-proof shortcuts, and no composing in password fields |

## Install

Any agent that reads skills from a directory:

```bash
git clone https://github.com/parker-brown-family/omarchy-localization ~/src/omarchy-localization
```
```bash
ln -s ~/src/omarchy-localization/skills/omarchy-localization ~/.claude/skills/omarchy-localization
```

For Codex, Gemini or others, link the same directory into their skills folder,
or point the agent at `skills/omarchy-localization/SKILL.md`.

## The audit

```bash
python3 skills/omarchy-localization/scripts/omarchy-l10n-audit path/to/plugin
```

Standard library Python plus `jq`. It reads `$OMARCHY_PATH` (default
`/usr/share/omarchy`) for the language list and asks Omarchy's own `plural.jq`
which plural categories each language needs, so it stays current as Omarchy adds
languages. It finds:

- missing or misnamed catalogs (`zh_CN.json` rather than `zh-CN.json`)
- placeholder drift between a translation and English
- missing plural categories, computed per language
- text lines that input methods cannot reach
- dates and numbers frozen to the shell's start-up language
- hardcoded strings and hardcoded CJK font families
- password fields with no input-method guard

Exit 0 means clean, 1 means errors, and 2 means it could not run. A run that
could not check something says so instead of passing it. It is aimed at
third-party plugins: Omarchy's built-in plugins use Omarchy's own catalog on
purpose and will be flagged for it.

```bash
python3 -m unittest discover tests
```

## What's inside

```
skills/omarchy-localization/
  SKILL.md                     the workflow: tier, catalogs, text entry, keys, verify
  reference/plugin-catalogs.md the Omarchy i18n contract for plugins
  reference/input-methods.md   what the OS does, and the rules a plugin owes it
  reference/chinese-edition.md the Chinese build as a worked case, generalised
  reference/source-map.md      which Omarchy files to read, and why
  scripts/omarchy-l10n-audit
tests/                         fixtures: one clean plugin, one that breaks every rule
```

Verified against Omarchy 4.0.0.alpha on 2026-11-22. Where the installed source
disagrees with this repository, the source is right. Please open an issue.

MIT licensed.
