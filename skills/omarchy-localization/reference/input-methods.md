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

- Bind by keycode/`event.key`, not by `event.text`. On Cyrillic or Greek layouts
  `Ctrl+C` produces no Latin "c" (upstream: "Keep universal clipboard shortcuts
  working across keyboard layouts", #18940).
- Leave Right Alt alone on layouts that use it as AltGr (#17504).
- Never bind `Super+I`, `Super+Shift+I`, or `Ctrl+Space` over a terminal. Those
  belong to input switching.
- `FilterInput` already accepts Alt and Super chords so they never become text.

## Rule 4: draw CJK with the theme's fonts

Do not hardcode `font.family` to a Latin-only face. Han characters fall back
through fontconfig, and `omarchy font cjk` decides whether `直` draws in its
Chinese or Japanese form. A hardcoded family that lacks CJK glyphs still falls
back, so it is mostly safe, but a hardcoded *CJK* family overrides the user's
chosen form. That one is a bug.

## Verifying for real

```bash
omarchy-language zh-CN
```

Then enable Chinese (Pinyin) under Setup > Typing, focus the plugin's field,
press `Super+I`, type `ceshi` and press Space. Expect `测试`. Capture the
screen. Repeat with Mozc (`nihon` → `日本`) and Hangul if the plugin targets
them.

Things not yet checked here, and so not claimed: Vietnamese (`fcitx5-unikey`,
upstream #17623 open) and Rime under the China region toggle (#9695 open).
