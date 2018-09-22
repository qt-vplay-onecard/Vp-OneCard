import VPlay 2.0
import QtQuick 2.2

 //玩家名，图像和剩余时间
EntityBase {
  id: playerTag
  width: 120
  height: canvas.height + name.contentHeight + name.anchors.topMargin

  property var player: MultiplayerUser{}
  property int level: 1
  property string activeColor: "#f9c336"
  property string inactiveColor: "#28a3c1"
  property alias canvas: canvas
  property alias avatar: avatar
  property alias avatarSource: avatar.source
  property alias name: name.text
  property alias nameColor: name.color
  property bool menu: false
  property int highscore


  //玩家姓名
  Text {
    id: name
    text: player && player.name ? player.name : ""
    anchors.top: canvas.bottom
    anchors.topMargin: 3
    anchors.horizontalCenter: canvas.horizontalCenter
    font.pixelSize: 12
    font.bold: true
    font.family: standardFont.name
    color: "white"
    wrapMode: Text.WrapAnywhere
    horizontalAlignment: Text.AlignHCenter
  }

  //剩余时间
  Canvas {
    id: canvas
    width: 92
    height: 92
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    onPaint: {
      var ctx = getContext("2d")
      ctx.reset()

      if (multiplayer.activePlayer === player){
        var centreX = canvas.width / 2
        var centreY = canvas.height / 2
        var step = 360 / gameLogic.userInterval - 1

        ctx.beginPath()
        ctx.fillStyle = player.connected ? activeColor : inactiveColor
        ctx.moveTo(centreX, centreY)

        // x, y, r,起始角，端点，逆时针方向
        ctx.arc(centreX, centreY, 46, 315 * Math.PI / 180, (gameLogic.userInterval - 1 - gameLogic.remainingTime) * step * Math.PI / 180, true)
        ctx.lineTo(centreX, centreY)
        ctx.fill()
      }
    }
  }

  //玩家图像
  UserImage {
    id: avatar
    width: 80
    height: 80
    anchors.centerIn: canvas
    source: getAvatar()
    locale: player && player.locale ? player.locale : ""
  }

  Image {
    height: 38
    fillMode: Image.PreserveAspectFit
    visible: ((player && player.connected) || menu) && level > 10
    anchors.top: canvas.top
    anchors.left: canvas.left
    source: {
      if (level >= 500){
        return "../../assets/img/PlatinumBadge.png"
      } else if (level >= 100){
        return "../../assets/img/GoldBadge.png"
      } else if (level >= 50){
        return "../../assets/img/SilverBadge.png"
      } else {
        return "../../assets/img/BronzeBadge.png"
      }
    }
  }

  //玩家和AI的头像
  function getAvatar(){
    var tmpAvatar = player && player.connected ? "../../assets/img/User.png" : "../../assets/img/auto.jpg"
    if (player && player.connected && player.profileImageUrl.length > 0){
      tmpAvatar = player.profileImageUrl
    }
    return tmpAvatar
  }

  //游戏开始时重置
  function initTag(){
    canvas.requestPaint()
  }

  function getPlayerData(sendToOthers){
      gameNetwork.sync()

    var highScore = gameNetwork.userHighscoreForLeaderboard()
    var level = 1
    if (highScore > 0){
      level = Math.floor(highScore / 300)
      level = Math.max(1, Math.min(level, 999)) //玩家等级在1-999
      playerTag.level = level
    }

    highscore = gameNetwork.userHighscoreForCurrentActiveLeaderboard

    if (sendToOthers){
      multiplayer.sendMessage(gameLogic.messageSetPlayerInfo, {userId: multiplayer.localPlayer.userId, level: level, highscore: highscore})
    }
  }
}
