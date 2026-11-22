# Plugin catalogs: the Omarchy translation contract

Source of truth: the "Translations" section of
`$OMARCHY_PATH/default/agents/skills/omarchy/plugins.md`, and
`shell/Commons/Translations.qml`, `shell/Commons/Plural.js`,
`default/i18n/locales.json`. This file summarises them; when they disagree, they
win.

## Layout

```
my-plugin/
  Widget.qml
  i18n/
    en.json      # required, the fallback for everything
    zh-CN.json
    zh-TW.json
    ar.json
```

File names are Omarchy language codes, the keys of `locales.json` (50 entries in
4.0.0.alpha: `en`, `zh-CN`, `zh-TW`, `pt-BR`, `es-MX`, `ja`, `ko`, `ar`, …). Not
POSIX locales: `zh-CN.json`, never `zh_CN.json`.

Fallback order: `pt-BR` → `pt` → `en` → the key itself.

## Entries

```json
{
  "panel.title": "Disk",
  "panel.free": "%1 free of %2",
  "panel.items": { "one": "%1 item", "other": "%1 items" }
}
```

- Whole sentences with `%1…%n`. Translators may reorder tokens, and every
  translation must carry the same token set as English.
- Plurals are objects keyed by CLDR category. The categories each language needs
  come from `default/i18n/plural.jq`. For whole numbers: zh/ja/ko/th/vi/id/ms
  need only `other`, ru/uk `one few many`, ar six, fr `one many other`. Do not
  guess them; run the audit, which asks `plural.jq` itself.

## Reading them in QML

```qml
import qs.Commons as Commons

Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

Text {
  textFormat: Text.PlainText
  text: strings.tn("panel.items", n).arg(Commons.I18n.formatNumber(n))
}
```

- Call `strings.t()` inside bindings. Text built imperatively once keeps the old
  language after a switch.
- `Commons.I18n.formatNumber(v, decimals)` gives `13,1` in Danish and native
  digits where the registry says so (`zeroDigit`).
- Dates: `Qt.locale(Commons.I18n.formatLocale)`. `Qt.formatDate` and a bare
  `Qt.locale()` are frozen at shell start.
- Do not borrow `Commons.I18n.t()` keys. Omarchy's catalog can rename them in any
  update.

## Right to left

`ar`, `he`, `fa` and `ur` carry `"direction": "rtl"`. `KeyboardPanel` and
`PopupCard` mirror for free. Explicit `x` positions follow
`LayoutMirroring.enabled`, back and forward glyphs swap on
`Commons.I18n.rightToLeft`, and Left/Right keys go through
`Util.readingKey(event)`.

## Commands and scripts

A plugin's shell scripts print through Omarchy's own lookup only for Omarchy
keys (`omarchy-i18n <key>`). For your own script strings, ship a JSON catalog
and resolve the language the way `omarchy-language` reports it, with English as
the fallback. Keep log and diagnostic output in English.
