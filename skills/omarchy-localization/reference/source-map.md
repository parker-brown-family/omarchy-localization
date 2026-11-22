# Source map: what to read in Omarchy, and why

`$OMARCHY_PATH` (defaults to `/usr/share/omarchy`). Verified on 4.0.0.alpha,
2026-11-22. Re-run `ls` on each before relying on it.

| Path | Read it for |
|---|---|
| `default/agents/skills/omarchy/plugins.md` § Translations | The plugin i18n contract, from upstream |
| `shell/Commons/Translations.qml` | How plugin catalogs load and fall back |
| `shell/Commons/Plural.js`, `default/i18n/plural.jq` | CLDR plural rules (kept in agreement by `i18n-test.sh`) |
| `default/i18n/locales.json` | Every language code, its direction, decimal, zero digit, POSIX locale |
| `default/i18n/<code>/{shell,menu,cli,keybindings}.json` | Omarchy's own translations: a glossary for consistent terms |
| `default/i18n/extract-allowlist.json` | Strings Omarchy deliberately never translates (brands) |
| `default/i18n/translation-manifest.json` | Per-string source hashes: how upstream detects stale translations |
| `bin/omarchy-i18n`, `bin/omarchy-language`, `bin/omarchy-locale-generate` | CLI lookup, the current language, locale generation |
| `install/config/language.sh`, `install/config/locale.sh` | ISO language marker; why the system locale stays `en_US` |
| `shell/Ui/FilterInput.qml` | The IME-safe text line to reuse |
| `shell/Ui/NumberField.qml` | Keeping IME out of numeric fields |
| `shell/Commons/InputMethodState.qml` | The shell's view of the active engine |
| `default/input-methods/{presets.json,configure.py,typing_setup.py}` | Which languages need an engine, and how one is set up |
| `default/environment.d/10-omarchy-fcitx.conf` | Toolkit IM variables |
| `default/systemd/user/omarchy-fcitx5.service` | Daemon lifecycle |
| `default/hypr/bindings/input-method.lua` | Reserved switching keys |
| `bin/omarchy-font-cjk`, `default/fontconfig/conf.avail/50-omarchy.conf` | CJK glyph forms |
| `config/fcitx5/` | Default Fcitx and Pinyin config |

Upstream repository: https://github.com/omacom/omarchy
