import QtQuick

Item {
  id: root
  property string query: ""
  focus: true
  Keys.onPressed: function(event) {
    if (event.text) root.query += event.text
  }
  Text { text: "Type a reminder" }
  Text { text: Qt.formatDate(new Date(), "dddd") }
  Text { text: (3.14159).toFixed(1) }
  TextInput { echoMode: TextInput.Password }
}
