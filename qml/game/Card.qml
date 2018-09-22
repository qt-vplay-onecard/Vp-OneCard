import QtQuick 2.0
import VPlay 2.0
import QtGraphicalEffects 1.0
import "../scenes"

EntityBase {
  id: card
  entityType: "card"
  width: 82
  height: 134
  transformOrigin: Item.Bottom

  // 原始牌的大小
  property int originalWidth: 82
  property int originalHeight: 134

  variationType: "wild4"
  property int points: 50
  property string cardColor: "black"
  property int order

  // 隐藏的卡片显示背面
  property bool hidden: !forceShowAllCards


  property bool forceShowAllCards: system.debugBuild && !system.publishBuild

  // 从外部访问图像和文本
  property alias cardImage: cardImage
  property alias glowImage: glowImage
  property alias cardButton: cardButton

  // 颜色的卡片
  property real hue: 60/360 // red
  property real lightness: 0
  property real saturation: 0

  property var newParent


  // 使图像发光
  Image {
    id: glowImage
    anchors.centerIn: parent
    width: parent.width * 1.3
    height: parent.height * 1.2
    source: "../../assets/img/cards/glow.png"
    visible: false
    smooth: true
  }

  // 显示卡片的正面或背面
  Image {
    id: cardImage
    anchors.fill: parent
    source: "../../assets/img/cards/back.png"
    smooth: true

    // 根据卡片颜色改变卡片的色度
    layer.enabled: true
    layer.effect: HueSaturation {
      hue: parent.hue
      lightness: parent.lightness
      saturation: parent.saturation

      Behavior on lightness {
        NumberAnimation { easing.type: Easing.InOutQuad; duration: 400 }
      }

      Behavior on saturation {
        NumberAnimation { easing.type: Easing.InOutQuad; duration: 400 }
      }
    }
  }

  // 可点击卡地区
  MouseArea {
    id: cardButton
    anchors.fill: parent
    onClicked: {
      gameScene.cardSelected(entityId)
    }
  }

  // 卡片翻转动画调整卡片并切换图像源
  SequentialAnimation {
    id: hiddenAnimation
    running: false

    NumberAnimation { target: scaleTransform; property: "xScale"; easing.type: Easing.InOutQuad; to: 0; duration: 80 }

    PropertyAction { target: cardImage; property: "source"; value: updateCardImage() }

    NumberAnimation { target: scaleTransform; property: "xScale"; easing.type: Easing.InOutQuad; to: 1.0; duration: 80 }
  }


  // 行为激活了卡片x和y的运动和旋转
  Behavior on x {
    NumberAnimation { easing.type: Easing.InOutQuad; duration: 400 }
  }

  Behavior on y {
    NumberAnimation { easing.type: Easing.InOutQuad; duration: 400 }
  }

  Behavior on rotation {
    NumberAnimation { easing.type: Easing.InOutQuad; duration: 400 }
  }

  Behavior on width {
    NumberAnimation { easing.type: Easing.InOutQuad; duration: 400 }
  }

  Behavior on height {
    NumberAnimation { easing.type: Easing.InOutQuad; duration: 400 }
  }

  // 当它改变它的状态时，重新父牌
  states: [
    State {
      name: "depot"
      ParentChange { target: card; parent: newParent; x: 0; y: 0; rotation: 0}
    },
    State {
      name: "player"
      ParentChange { target: card; parent: newParent; x: 0; y: 0; rotation: 0}
    },
    State {
      name: "stack"
      ParentChange { target: card; parent: newParent; x: 0; y: 0; rotation: 0}
    }
  ]

  // 翻转动画中的卡片中心
  transform: Scale {
    id: scaleTransform
    origin.x: width/2
    origin.y: height/2
  }

  // 当隐藏的var变化时启动卡片翻转动画
  onHiddenChanged: {
    if(hidden && forceShowAllCards) {
      hidden = false
    }

    hiddenAnimation.start()
  }

  function updateCardImage(){
    // 隐藏的卡片显示背面没有效果
    if (hidden){
      cardImage.layer.enabled = false // 禁用色素的卡片
      cardImage.source = "../../assets/img/cards/back.png"
      // wild wild4使用普通的多色图像，没有效果
    } else if (variationType == "wild" || variationType == "wild4"){
      card.hue = 0
      card.saturation = 0
      card.lightness = 0.0
      cardImage.layer.enabled = true //使颜色卡
      cardImage.source = "../../assets/img/cards/" + variationType + "_" + cardColor + ".png"
      // 有编号的卡片，跳跃和draw2是在用色化的帮助下着色的
    } else {
      cardImage.layer.enabled = true // enable coloring of card
      card.lightness = 0.0
      if (cardColor == "yellow") {
        card.hue = 55/360
        card.saturation = 0
      } else if (cardColor == "red") {
        card.hue = 0/360
        card.saturation = 0
      } else if (cardColor == "green") {
        card.hue = 110/360
        card.saturation = -0.1
      } else if (cardColor == "blue") {
        card.hue = 220/360
        card.saturation = -0.1
      }
      cardImage.source = "../../assets/img/cards/" + variationType + "_red.png"
    }
  }
}
