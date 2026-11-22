# Input methods: what the OS does, and what a plugin owes it

Checked against Omarchy 4.0.0.alpha (`$OMARCHY_PATH`, usually `/usr/share/omarchy`).

## The OS side, which you never rebuild

| Piece | Where | What it does |
|---|---|---|
| Fcitx5 daemon | `default/systemd/user/omarchy-fcitx5.service` | Starts at graphical login, restarts forever, skips sessions with no Wayland |
| Toolkit wiring | `default/environment.d/10-omarchy-fcitx.conf` | `QT_IM_MODULE=fcitx`, `XMODIFIERS=@im=fcitx`, `SDL_IM_MODULE=fcitx`, `INPUT_METHOD=fcitx` |
| Presets | `default/input-methods/presets.json` | `mozc` (ja), `hangul` (ko), `pinyin` (zh-CN), `chewing` (zh-TW Zhuyin), `cangjie5` (HK), each with its packages and CJK font form |
| Configure and seed | `default/input-methods/configure.py`, `bin/omarchy-input-method` | Writes the Fcitx profile, installs packages, seeds the CJK font form |
| Switching | `default/hypr/bindings/input-method.lua` | `Super+I` / `Super+Shift+I` cycle, `Ctrl+Space` drops to direct input in terminals |
| Shell state | `shell/Commons/InputMethodState.qml` | The bar indicator and the shell's `cycleInput` |
| Glyph forms | `bin/omarchy-font-cjk` | `jp kr sc tc hk default`: which Noto CJK forms win fallback |
| Pinyin defaults | `config/fcitx5/conf/pinyin.conf` | Omarchy's tuned engine config |

A plugin does not install an engine, set `QT_IM_MODULE`, or ship a font. When a
user says "Chinese input doesn't work in your plugin", the fault is in the
plugin's text item almost every time, and in the OS almost never.

## Rule 1: text goes into a TextInput

Qt delivers committed and preedit text only to items that answer input-method
queries (`TextInput`, `TextEdit`, `TextField`). The pattern below is broken for
every IME language, and it passes every English test:

```qml
// BROKEN: fcitx never engages; Pinyin users type raw "ceshi"
Item {
  focus: true
  Keys.onPressed: (event) => { if (event.text) root.query += event.text }
}
```

Use Omarchy's `Ui/FilterInput` (a `TextInput` that forwards keys to your
handler first), as the menu and the reminder prompt now do:

```qml
import qs.Ui

FilterInput {
  id: input
  keyHandler: keyCatcher          // keeps Escape, Enter, Ctrl+U, arrows
  onTextChanged: root.query = text
}
Text {                            // placeholder
  anchors.fill: input
  visible: !input.text && !input.preeditText
  text: strings.t("search.placeholder")
}
```

Your key handler must leave printable keys unaccepted, and it must not act on
Enter, Space or digits while `input.preeditText` is non-empty. Those keys belong
to the engine while it is composing.

Upstream evidence: the reminder prompt was a `Text` fed by `Keys.onPressed`
until "Let input methods type into the reminder prompt" (omacom/omarchy#16761)
moved it to `FilterInput`. The menu search had the same bug earlier (#11682,
fixed by #15508). Verified live there with Boshiamy, committing `測試`.

Number-only fields can keep IME out with `inputMethodHints: Qt.ImhFormattedNumbersOnly`
(see `shell/Ui/NumberField.qml`).

## Rule 2: secrets never compose

With Fcitx's `ShareInputState=All`, an active engine follows focus into a
password field. It shows the Pinyin in the clear and commits something other
than what was typed. The lock screen fix ("Keep the lock screen password hidden
when typing in another language", omacom/omarchy#18604) does this:

1. On focus, read `~/.config/fcitx5/config`. Only if it contains
   `ShareInputState=All` and `fcitx5-remote` reports `2` (active), run
   `fcitx5-remote -c` (direct input) and remember that you did.
2. Hold input disabled until that switch has finished.
3. On leaving, run `fcitx5-remote -o` only if you switched it off yourself.
   Under the default per-window state, leave the engine alone. The first version
   of that fix broke the browser by not doing so.

Also set `echoMode: TextInput.Password`.

## Rule 3: shortcuts survive every layout

Measured with `scripts/ime-probe` (Qt 6 on X11; Omarchy's shell runs on Wayland, which also reports xkb keycodes, but that was not measured): on a Russian layout the physical A key reports `event.key` 1060 (Cyrillic ф), **with or without Ctrl**, and `event.nativeScanCode` 38. So:

- `ctrl && event.key === Qt.Key_K` never fires for a Cyrillic, Greek or Hebrew typist. Neither does a plain-letter shortcut.
- `event.text` is worse: it is the layout's character, and under an input method it is the raw Latin the engine was about to compose.
- Fall back to the physical key **only when the reported key is outside ASCII**, so Dvorak and AZERTY keep their own letters:

```js
// Model.js (.pragma library): one tested helper for the whole plugin.
// For a non-ASCII character typed on a letter key, return the US QWERTY letter
// at that key's position, keeping its case. ASCII is returned unchanged, so
// Latin layouts (Dvorak, AZERTY) keep their own letters. xkb keycodes: evdev + 8.
var QWERTY_LETTER_ROWS = [[24, "qwertyuiop"], [38, "asdfghjkl"], [52, "zxcvbnm"]]
function shortcutText(text, scanCode) {
  var raw = String(text || "")
  if (raw.length !== 1 || raw.charCodeAt(0) < 0x80) return raw
  for (var i = 0; i < QWERTY_LETTER_ROWS.length; i++) {
    var offset = Number(scanCode) - QWERTY_LETTER_ROWS[i][0]
    var letters = QWERTY_LETTER_ROWS[i][1]
    if (offset >= 0 && offset < letters.length) {
      var latin = letters.charAt(offset)
      return raw !== raw.toLowerCase() ? latin.toUpperCase() : latin
    }
  }
  return raw
}
// In the key handler:
//   var text = Model.shortcutText(event.text, event.nativeScanCode)
//   if (ctrl && text.toLowerCase() === "k") …
```

Put it in a pure JS file so tests can call it with plain values; QTest cannot
synthesise non-ASCII key events on every Qt version. Reel's
`tests/tst_layout_keys.qml` is a ready test to copy. The secrets plugin used a
26-entry map from scan code to `Qt.Key_*` instead, which also works, but it
compares keys rather than text and loses Shift.

**Qt's own shortcuts fail too.** Measured with `scripts/probe/paste.qml` (X11):
on Russian, Ctrl+V reports key 1052 (М), `event.matches(StandardKey.Paste)` is
false, and a TextInput's built-in paste does nothing. So a field's Ctrl+C, Ctrl+V
and Ctrl+A are dead for Cyrillic typists unless the plugin handles them. That is
a usability gap, not a hole in a paste guard, because nothing pastes at all.

  The table assumes the user's Latin layout is QWERTY, as GTK and Qt menus do. Worked example: the secrets plugin (parker-brown-family/omarchy-secrets-plugin#4).
- Leave Right Alt alone on layouts that use it as AltGr (upstream #17504, open).
- Never bind `Super+I`, `Super+Shift+I`, or `Ctrl+Space` over a terminal. Those belong to input switching.
- `FilterInput` already accepts Alt and Super chords so they never become text.

Compositor-level shortcuts across layouts are a separate, unsolved upstream problem: "Keep universal clipboard shortcuts working across keyboard layouts" (#18940) is a **draft with open regressions** as of 2026-11-22. A plugin cannot fix those; do not claim it does.

## Rule 4: draw CJK with the theme's fonts

Do not hardcode `font.family` to a Latin-only face. Han characters fall back
through fontconfig, and `omarchy font cjk` decides whether `直` draws in its
Chinese or Japanese form. A hardcoded family that lacks CJK glyphs still falls
back, so it is mostly safe, but a hardcoded *CJK* family overrides the user's
chosen form. That one is a bug.

## Verifying for real, without touching anyone's desktop

`scripts/ime-probe` runs a private Xvfb, a private D-Bus session and a real
Fcitx5 with Pinyin, then types into a TextInput and into a `Keys.onPressed`
collector side by side, and presses keys on a Russian layout. Measured
2026-11-22 (fcitx5 5.1.23, Qt 6): the TextInput shows preedit and commits
`测试`; the collector receives `ceshi `.

To drive the plugin itself the same way, copy the pattern the secrets plugin's
`tests/ui.sh` uses: run the plugin's QML under `quickshell` on Xvfb with a stub
`OverlayWindow`, start `fcitx5 -d` inside `dbus-run-session` with a profile
whose `DefaultIM=pinyin`, wait for "Loaded addon pinyin" in its log, export
`QT_IM_MODULE=fcitx`, then `fcitx5-remote -o` and `xdotool type ceshi`. Log the
plugin's filter property and assert on it. **Run the new check against the old
code too: it must fail there**, or it proves nothing.

Two traps that cost a run each:

- Qt sends `console.log` to the systemd journal when stderr is not a terminal.
  Set `QT_FORCE_STDERR_LOGGING=1` or the probe sees nothing and a "never
  received" check passes vacuously.
- `xdotool key a` on a Russian layout remaps a spare keycode to produce Latin
  `a`, hiding the bug. Send the layout's own keysym (`Cyrillic_ef` for the A key).

By hand, on a real desktop:

```bash
omarchy-language zh-CN
```

Then enable Chinese (Pinyin) under Setup > Typing, focus the plugin's field,
press `Super+I`, type `ceshi` and press Space. Expect `测试`. Capture the
screen. Repeat with Mozc (`nihon` → `日本`) and Hangul if the plugin targets
them.

Things not yet checked here, and so not claimed: Vietnamese (`fcitx5-unikey`,
upstream #17623 open) and Rime under the China region toggle (#9695 open).
