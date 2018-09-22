import QtQuick 2.0
import "../common"

Item {
    id: introduce
    visible: false
    Rectangle {
        anchors.centerIn: parent
        anchors.fill: parent
        color: "black"
        opacity: 0.7

        // catch the mouse clicks
        MouseArea {
            anchors.fill: parent
        }
    }
    Column{
        anchors.centerIn: parent
        Rectangle{
            radius: 30
            width: 250
            height: 230
            color: "white"
            border.color: "#28a3c1"
            border.width: 5
            Text {
                x: 8
                anchors.top: parent.top
                anchors.verticalCenter: parent.verticalCenter
                width: 230
                anchors{
                    top: parent.top
                    bottom: parent.bottom
                }

                font.pixelSize: 14
                text: "    Hello,friends\n    Welcome to the rules of the game, as follows:
    The basic rule is when the opponents play, you can start your own hands to choose the same color or the same number of card, no card can extract.\nIn addition, there are many special rules card waiting for you to find."
                color: "#28a3c1"
                wrapMode: Text.WrapAnywhere
            }
        }
        ButtonBase{
            width: 250
            height: 50
            text: "Understand"
            onClicked: introduce.visible = false
        }
    }
}
