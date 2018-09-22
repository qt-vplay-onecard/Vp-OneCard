import QtQuick 2.0
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4
import "../common"
import "../scenes"

Item {
    id: changeName
    visible: false
    z: 50

    Column{
        id: setName
        anchors.horizontalCenter: menuScene.horizontalCenter
        anchors.top: menuScene.horizontalCenter
        height: 10
        anchors.margins: 40
        spacing: 20

        TextField {
          id: inputText
//          anchors.horizontalCenter: parent.horizontalCenter

          horizontalAlignment: Text.AlignHCenter
          font.pixelSize: 30
          maximumLength: 16
          placeholderText: gameNetwork.user.name //初始名
          inputMethodHints: Qt.ImhNoPredictiveText  //不能查找
          validator: RegExpValidator{regExp: /^[a-zA-Z0-9äöüßÄÖÜß_ -]{3,}$/}  //文本验证器


          //输入框
          style: TextFieldStyle {
            textColor: "black"
            background: Rectangle {
                radius: 30
                anchors.fill: setName
                color: "white"
                border.color: "#28a3c1"
                border.width: 5
              }
          }

          // disable and reset the inputField when closed
          onVisibleChanged: {
            readOnly = visible ? false : true
            if (!visible) focus = false
            text = ""
          }

          // check, send and reset the text after hitting enter
          onAccepted: {
            if (text){
              var set = gameNetwork.updateUserName(text)
              gameScene.playerHands.children[0].player.nickName = text
              gameScene.playerTags.children[0].player.nickName = text

              if (set) {
                changeName.visible = false
              } else {
                hintText.text = "Invalid username"
              }
            }
          }
        }

        ButtonBase {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: inputText.bottom
          anchors.topMargin: 10
          height: (buttonText.height + paddingVertical * 2)
          paddingHorizontal: 8
          paddingVertical: 4
          box.border.width: 5
          box.radius: 30
          textSize: 28
          text: "Do not set a name now"
          onClicked: changeName.visible = false
        }
    }
}
