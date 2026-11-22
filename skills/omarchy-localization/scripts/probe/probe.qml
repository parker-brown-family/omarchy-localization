import QtQuick
import QtQuick.Window

// Two typing surfaces side by side, as a plugin might build them. Every change
// is printed so the driver can read what each surface actually received.
Window {
  id: win
  width: 640; height: 200; visible: true; color: "#202020"
  property string mode: Qt.application.arguments[Qt.application.arguments.length - 1]
  Component.onCompleted: console.log("PROBE mode=" + mode + " args=" + JSON.stringify(Qt.application.arguments))

  // The IME-safe pattern: a real TextInput.
  TextInput {
    id: field
    visible: win.mode === "textinput"
    focus: win.mode === "textinput"
    anchors.centerIn: parent; width: 500; color: "white"; font.pixelSize: 28
    onTextChanged: console.log("PROBE text=" + text)
    onPreeditTextChanged: console.log("PROBE preedit=" + preeditText)
  }

  // The broken pattern: an Item collecting Keys.onPressed event.text.
  Item {
    id: catcher
    visible: win.mode === "keys"
    focus: win.mode === "keys"
    anchors.fill: parent
    property string typed: ""
    Keys.onPressed: function(event) {
      console.log("PROBE key=" + event.key + " scan=" + event.nativeScanCode + " mods=" + event.modifiers + " text=" + JSON.stringify(event.text))
      if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32) {
        typed += event.text
        console.log("PROBE text=" + typed)
      }
    }
  }
}
