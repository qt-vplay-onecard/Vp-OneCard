import QtQuick 2.0
import '.'

//按钮切换场景
ButtonBase {
  id: menuButton
  width: 140

  property string action: (typeof text !== "undefined") ? text.toLowerCase() : undefined

  onClicked: menuButtonPressed(action)
}

