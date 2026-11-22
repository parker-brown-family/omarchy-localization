import QtQuick
import qs.Commons as Commons
import qs.Ui

Item {
  id: root
  property int count: 0
  property string query: ""
  Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

  Item { id: keyCatcher }
  FilterInput {
    id: input
    keyHandler: keyCatcher
    onTextChanged: root.query = text
  }
  Text {
    textFormat: Text.PlainText
    visible: !input.text && !input.preeditText
    text: strings.t("search.placeholder")
  }
  Text {
    textFormat: Text.PlainText
    text: strings.tn("panel.items", root.count).arg(Commons.I18n.formatNumber(root.count))
  }
}
