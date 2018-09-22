import VPlay 2.0
import QtQuick 2.0
import "../common"
import "../game"
import "../interface"

SceneBase {
  id: gameScene
  height: 640
  width: 960

  signal cardSelected(var cardId)
  signal stackSelected()
  signal colorPicked(var pickedColor)

  //从外部访问的property
  property alias deck: deck
  property alias depot: depot
  property alias gameLogic: gameLogic
  property alias onuButton: onuButton
  property alias gameOver: gameOver
  property alias leaveGame: leaveGame
  property alias drawCounter: drawCounter
  property alias bottomHand: bottomHand
  property alias onuHint: onuHint
  property alias rightPlayerTag: rightPlayerTag


  //连接到VPultuPosiver对象并处理所有信号
  Connections {

    target: multiplayer
    enabled: activeScene === gameScene

    onPlayersReady: {

    }

    onGameStarted: {

    }

    onPlayerLeft:{
      if(multiplayer.amLeader && activeScene === gameScene) {
        flurry.logEvent("System.PlayerLeft", "singlePlayer", multiplayer.singlePlayer)
      }
    }

    onActivePlayerChanged:{
    }

    onTurnStarted:{
      gameLogic.turnStarted(playerId)
    }
  }

  //背景
  Image {
    id: background
    source: "../../assets/img/BG.png"
    anchors.fill: gameScene.gameWindowAnchorItem
    fillMode: Image.PreserveAspectCrop
    smooth: true
  }

  //转向的图
  Image {
    id: depotImage
    source: "../../assets/img/Depot.png"
    width: 280
    height: width
    anchors.centerIn: depot
    smooth: true
    mirror: !depot.clockwise

    onMirrorChanged: {
      if (!mirror){
        mirrorAnimation.from = 0
        mirrorAnimation.to = 180
      } else {
        mirrorAnimation.from = 180
        mirrorAnimation.to = 0
      }
      mirrorAnimation.start()
    }

    NumberAnimation { id: mirrorAnimation; target: depotImage; properties: "rotation";
      from: 0; to: 180; duration: 400; easing.type: Easing.InOutQuad }
  }

  //逻辑函数
  GameLogic {
    id: gameLogic
  }


  //离开的按钮
  ButtonBase {
    id: backButton
    width: 50
    height: 50
    buttonImage.source: "../../assets/img/Home.png"
    anchors.right: gameWindowAnchorItem.right
    anchors.rightMargin: 20
    anchors.bottom: gameWindowAnchorItem.bottom
    anchors.bottomMargin: 20
    onClicked: leaveGame.visible = true
  }


  //左转动画
  ONUButton {
    id: onuButton
    anchors.verticalCenter: depot.verticalCenter
    anchors.right: depot.left
    anchors.rightMargin: 85
    visible: false // remove ONU button (ONU will auto-activate for all users then, makes game a bit easier and faster to play)
  }

  // 未使用的牌
  Deck {
    id: deck
    anchors.verticalCenter: depot.verticalCenter
    anchors.left: depot.right
    anchors.leftMargin: 90
  }

  // 加一张牌
  Text {
    id: drawCounter
    anchors.left: depot.right
    anchors.leftMargin: 18
    anchors.bottom: depot.top
    anchors.bottomMargin: 12
    text: "+" + depot.drawAmount
    color: "white"
    font.pixelSize: 20
    font.family: standardFont.name
    font.bold: true
    visible: depot.drawAmount > 1 && !onuHint.visible ? true : false
  }

  //加两张牌
  Text {
    id: onuHint
    anchors.left: depot.right
    anchors.leftMargin: 18
    anchors.bottom: depot.top
    anchors.bottomMargin: 12
    text: "+2"
    color: "white"
    font.pixelSize: 40
    font.family: standardFont.name
    font.bold: true
    visible: false

    onVisibleChanged: {
      if (visible){
        singleTimer.start()
      }
    }

    Timer {
      id: singleTimer
      interval: 3000
      repeat: false
      running: false

      onTriggered: {
        onuHint.visible = false
      }
    }
  }

  //玩家四面围绕着
  Item {
    id: playerHands
    anchors.fill: gameWindowAnchorItem

    PlayerHand {
      id: bottomHand
      anchors.bottom: parent.bottom
      anchors.horizontalCenter: parent.horizontalCenter
      z: 100
    }

    PlayerHand {
      id: leftHand
      anchors.left: parent.left
      anchors.leftMargin: -width/2 + height/2
      anchors.verticalCenter: parent.verticalCenter
      rotation: 90
    }

    PlayerHand {
      id: topHand
      anchors.top: parent.top
      anchors.horizontalCenter: parent.horizontalCenter
      rotation: 180
    }

    PlayerHand {
      id: rightHand
      anchors.right: parent.right
      anchors.rightMargin: -width/2 + height/2
      anchors.verticalCenter: parent.verticalCenter
      rotation: 270
    }
  }

  // 牌堆在中间
  Depot {
    id: depot
    //anchors.centerIn: gameWindowAnchorItem
    anchors.horizontalCenter: gameWindowAnchorItem.horizontalCenter
    anchors.bottom: gameWindowAnchorItem.bottom
    anchors.bottomMargin: move()

    function move(){
      return(gameWindowAnchorItem.height - depot.height ) / 2 + (bottomHand.height - bottomHand.originalHeight) / 2.5
    }
  }

  // 每个玩家的信息
  Item {
    id: playerTags
    anchors.fill: gameWindowAnchorItem

    PlayerTag {
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 5
      anchors.right: parent.right
      anchors.rightMargin: (parent.width - bottomHand.width) / 2 - width * 0.8
    }

    PlayerTag {
      anchors.left: parent.left
      anchors.leftMargin: 5
      anchors.top: parent.top
      anchors.topMargin: 10
    }

    PlayerTag {
      anchors.top: parent.top
      anchors.topMargin: 10
      anchors.left: parent.left
      anchors.leftMargin: (parent.width - topHand.width) / 2 - width
    }

    PlayerTag {
      id: rightPlayerTag
      anchors.right: parent.right
      anchors.rightMargin: 5
      anchors.top: parent.top
      anchors.topMargin: 10
    }
  }

  // 在中间选择颜色
  ColorPicker {
    id: colorPicker
    visible: false
    anchors.centerIn: depot
  }

  // 游戏结束和离开界面在中间
  GameOverWindow {
    anchors.centerIn: gameWindowAnchorItem
    id: gameOver
    visible: false
  }

  LeaveGameWindow {
    anchors.centerIn: gameWindowAnchorItem
    id: leaveGame
    visible: false
  }

  // 转到游戏见面后初始化
  onVisibleChanged: {
    if(visible){
      flurry.logEvent("Screen.GameScene")
      gameLogic.initGame()
    }
  }
}
