import QtQuick 2.0
import "../common"

 //离开游戏界面
Item {
  id: leaveGame
  width: 400
  height: content.height + content.anchors.topMargin * 2
  z: 110


  Rectangle {
    anchors.centerIn: parent
    width: gameScene.width * 2
    height: gameScene.height * 2
    color: "black"
    opacity: 0.3

    MouseArea {
      anchors.fill: parent
    }
  }

  Rectangle {
    id: leaveRect
    radius: 30
    anchors.fill: parent
    color: "white"
    border.color: "#28a3c1"
    border.width: 5
  }

  //关闭窗口
  ButtonBase {
    anchors.left: parent.left
    anchors.top: parent.bottom
    anchors.topMargin: 10
    width: parent.width / 2 - anchors.topMargin / 2
    height: (20 + buttonText.height + paddingVertical * 2)
    paddingHorizontal: 8
    paddingVertical: 4
    box.border.width: 5
    box.radius: 30
    textSize: 28
    text: "Cancel"
    onClicked: leaveGame.visible = false
  }

  //离开游戏按钮
  ButtonBase {
    anchors.right: parent.right
    anchors.top: parent.bottom
    anchors.topMargin: 10
    width: parent.width / 2 - anchors.topMargin / 2
    height: (20 + buttonText.height + paddingVertical * 2)
    paddingHorizontal: 8
    paddingVertical: 4
    box.border.width: 5
    box.radius: 30
    textSize: 28
    text: "Quit Game"
    onClicked: {
      gameLogic.leaveGame()
      backButtonPressed()
      leaveGame.visible = false
    }
  }
}
