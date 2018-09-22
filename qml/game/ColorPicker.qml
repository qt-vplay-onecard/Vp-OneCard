import QtQuick 2.0
import VPlay 2.0
import "../common"

// 选择野生和通配符的颜色
Item {
  id: colorPicker
  width: 200
  height: 200
  z: 110

  property bool chosingColor: false


  //彩色选择的视觉表示
  Image {
    id: colorImage
    anchors.fill: parent
    source: "../../assets/img/ColorPicker.png"
    smooth: true
  }

  ButtonBase {
    radius: 10
    width: parent.width/2
    height: parent.height/2
    anchors.top: parent.top
    anchors.left: parent.left
    onClicked: colorPicked("yellow")
  }

  ButtonBase {
    radius: 10
    width: parent.width/2
    height: parent.height/2
    anchors.top: parent.top
    anchors.right: parent.right
    onClicked: colorPicked("red")
  }

  ButtonBase {
    radius: 10
    width: parent.width/2
    height: parent.height/2
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    onClicked: colorPicked("green")
  }

  ButtonBase {
    radius: 10
    width: parent.width/2
    height: parent.height/2
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    onClicked: colorPicked("blue")
  }

  //返回一个随机的颜色
  function randomColor(){
    var colors = ["yellow", "red", "green", "blue"]
    var index = Math.floor(Math.random() * (4))
    return colors[index]
  }
}
