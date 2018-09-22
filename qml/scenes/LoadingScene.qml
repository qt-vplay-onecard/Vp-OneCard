import VPlay 2.0
import QtQuick 2.0
import "../common"

SceneBase {
  id: loadingScene

  // 背景
  Image {
    id: background
    source: "../../assets/img/BG.png"
    anchors.fill: loadingScene.gameWindowAnchorItem
    fillMode: Image.PreserveAspectCrop
    smooth: true
  }

  // loading
  Text {
    id: loaderText
    horizontalAlignment: Text.AlignHCenter
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: titleImage.bottom
    anchors.topMargin: 40
    font.pixelSize: 14
    color: "#f9c336"
    text: "Loading ..."
    font.family: standardFont.name
  }

  // loading 动画
  SequentialAnimation {
    running: true
    loops: Animation.Infinite

    PropertyAnimation {
      target: loaderText
      property: "scale"
      to: 1.05
      duration: 2000
    }
    PropertyAnimation {
      target: loaderText
      property: "scale"
      to: 1
      duration: 2000
    }
  }

  Component.onCompleted: {
    flurry.logEvent("Screen.LoadingScene")
  }
}
