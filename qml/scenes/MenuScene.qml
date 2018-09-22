import VPlay 2.0
import QtQuick 2.0
import QtQuick.Controls 1.4
import VPlayApps 1.0
import "../common"
import "../interface"

SceneBase {
    id: menuScene

    // 其他场景应该显示的信号
    signal menuButtonPressed(string button)

    property alias localStorage: localStorage

    //背景音乐
    BackgroundMusic {
        volume: 0.20
        id: ambienceMusic
        source: "../../assets/snd/bg.mp3"
    }

    //背景音乐的计时
    Timer {
        id: timerMusic
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            ambienceMusic.play()
            running = false
        }
    }

    //背景
    AnimatedImage {
        id: bg
        width: 640
        height: 480
        anchors.centerIn: parent
        source: "../../assets/img/BG.gif"
    }
    //玩家信息
    Rectangle {
        id: info
        radius: 15
        color: "white"
        border.color: "#28a3c1"
        border.width: 2.5
        visible: true
        width: 130

        anchors {
            top: localTag.top
            bottom: localTag.bottom
            right: localTag.right
            topMargin: localTag.height / 2 - 9
            bottomMargin: -6
            rightMargin: -3
        }
        ButtonBase {
            id: changeName
            text: "Change Avatar"
            anchors.bottom: info.top
            width :130
            MouseArea {
                anchors.fill: parent
                onClicked: changeheadWindow.visible = true
            }
        }

        Item {
            y: 34

            Text {
                id: infoText
                text: "Level: " + localTag.level + "\nScore: " + localTag.highscore
                font.family: standardFont.name
                color: "black"
                font.pixelSize: 8
                width: contentWidth
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 14
                verticalAlignment: Text.AlignVCenter

                property string rank: localTag.rank > 0 ? "#" + localTag.rank : "-"
            }
        }
        MouseArea {
            anchors.fill: parent
            onClicked: changenameWindow.visible = true
        }
    }
    ChangeNameWindow {
        id: changenameWindow
        anchors.centerIn: parent
        visible: false
    }
    ChangeHeadWindow {
        id: changeheadWindow
        anchors.centerIn: parent
        visible: false
    }

    //本地玩家信息
    PlayerTag {
        id: localTag
        player: gameNetwork.user
        nameColor: info.visible ? "#28a3c1" : "white"
        menu: true
        avatarSource: gameNetwork.user.profileImageUrl ? gameNetwork.user.profileImageUrl : "../../assets/img/User.png"
        level: Math.max(
                   1, Math.min(
                       Math.floor(
                           gameNetwork.userHighscoreForCurrentActiveLeaderboard / 300),
                       999))
        highscore: gameNetwork.userHighscoreForCurrentActiveLeaderboard

        scale: 0.5
        transformOrigin: Item.BottomRight
        anchors.bottom: gameWindowAnchorItem.bottom
        anchors.bottomMargin: 10
        anchors.right: gameWindowAnchorItem.right
        anchors.rightMargin: 10
    }

    Column {
        id: menu
        spacing: 6
        anchors.horizontalCenter: gameWindowAnchorItem.horizontalCenter
        anchors.centerIn: parent
        MenuButton {
            id: single
            text: "Start"
            action: "single"
            onClicked: {
                ga.logEvent("User", "Single Game")
                flurry.logEvent("User.Single Game")
            }
        }
        ButtonBase {
            width: single.width
            text: "introduce"
            onClicked: introduce.visible = true
        }

        ButtonBase {
            id: quit
            width: single.width
            text: "Quit Game"
            onClicked: {
                Qt.quit()
            }
        }
        ButtonBase{
            id: conect
            width: single.width
            text: "multiplayer"
            onClicked: {
                connection.visible = true
            }
        }
    }
    ConnectionWindow{
        id: connection
        anchors.centerIn: parent
        visible: false
    }

    IntroduceWindow {
        anchors.centerIn: parent
        id: introduce
        visible: false
    }

    //声音
    ButtonBase {
        color: "transparent"
        width: 38
        height: 38
        anchors.bottom: gameWindowAnchorItem.bottom
        buttonImage.source: "../../assets/img/Sound.png"
        opacity: settings.musicEnabled ? 1.0 : 0.6
        onClicked: {
            ga.logEvent("User", "Music")
            flurry.logEvent("User.Music")
            settings.musicEnabled ^= true
        }
    }

    //本地存储
    Storage {
        id: localStorage
        property int appStarts: 0
        property int gamesPlayed: 0 // store number of games played

        Component.onCompleted: {

            var nr = localStorage.getValue("appstarts")
            if (nr === undefined)
                nr = 0

            nr++
            localStorage.setValue("appstarts", nr)
            appStarts = nr

            //初始化或存储登录次数
            if (localStorage.getValue("gamesplayed") === undefined)
                localStorage.setValue("gamesplayed", 0)
            gamesPlayed = localStorage.getValue("gamesplayed")
        }

        // 在本地设置和存储游戏
        function setGamesPlayed(count) {
            localStorage.setValue("gamesplayed", count)
            localStorage.gamesPlayed = count
        }
    }

    // 同步信息到主页面
    onVisibleChanged: {
        if (visible) {
            ga.logScreen("MenuScene")
            flurry.logEvent("Screen.MenuScene")
        }
    }
}
