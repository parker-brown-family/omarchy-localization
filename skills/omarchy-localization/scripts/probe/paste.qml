import QtQuick
import QtQuick.Window

// Does Ctrl+V on a Cyrillic layout reach a TextInput's built-in paste, and does
// event.matches(StandardKey.Paste) or event.key === Qt.Key_V see it?
Window {
  width: 400; height: 120; visible: true
  TextInput { id: source; text: "PASTED"; visible: false }
  TextInput {
    id: target
    focus: true
    anchors.fill: parent
    Keys.onPressed: function(event) {
      if (event.modifiers & Qt.ControlModifier)
        console.log("PROBE key=" + event.key + " matchesPaste=" + event.matches(StandardKey.Paste) + " isKeyV=" + (event.key === Qt.Key_V))
    }
    onTextChanged: console.log("PROBE text=" + text)
  }
  Component.onCompleted: { source.selectAll(); source.copy(); console.log("PROBE ready") }
}
