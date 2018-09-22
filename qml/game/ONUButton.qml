import QtQuick 2.0
import VPlay 2.0
import "../common"


// 当玩家手中有2张或更少的牌时使用
Item {
    id: onuButton
    width: 110
    height: 110

    property alias button: button
    property alias blinkAnimation: blinkAnimation

    //当用户激活ONUButton时，效果会起作用
    SoundEffectVPlay {
        volume: 0.5
        id: onuSound
        source: "../../assets/snd/onu.wav"
    }

    // 按钮在启用更改时启动渐变动画
    ButtonBase {
        id: button
        radius: width / 2
        enabled: false
        anchors.fill: parent

        onClicked: {
            //如果ONUButton设置为不可见（=从游戏中删除/不可供用户使用），则不要对点击作出反应。
            if (onuButton.visible) {
                ga.logEvent("User", "ONU", "singlePlayer",
                            multiplayer.singlePlayer)
                flurry.logEvent("User.ONU", "singlePlayer",
                                multiplayer.singlePlayer)
                button.enabled = false
                onu(multiplayer.localPlayer.userId)
            }
        }

        onEnabledChanged: {
            if (enabled) {
                blinkAnimation.start()
            } else {
                blinkAnimation.stop()
            }
        }
    }

    //

    //暗去激活按钮图像
    Image {
        id: onuButton1
        anchors.fill: parent
        source: "../../assets/img/ONUButton1.png"
        smooth: true
    }

    // 激活按钮图像
    Image {
        id: onuButton2
        anchors.fill: parent
        source: "../../assets/img/ONUButton2.png"
        opacity: 0
        smooth: true
    }

    // 两个按钮图像之间的渐变动画
    SequentialAnimation {
        id: blinkAnimation
        running: false
        loops: Animation.Infinite
        alwaysRunToEnd: true

        NumberAnimation {
            target: onuButton2
            property: "opacity"
            easing.type: Easing.InOutQuad
            to: 1.0
            duration: 400
        }
        NumberAnimation {
            target: onuButton2
            property: "opacity"
            easing.type: Easing.InOutQuad
            to: 0.0
            duration: 400
        }
    }

    // 激活玩家的ONU状态
  function onu(userId){
    onuSound.play()
    var hand = gameLogic.getHand(userId)
    if (hand) hand.onu = true
    multiplayer.sendMessage(gameLogic.messagePressONU, {userId: userId, onu: true})
  }
}
