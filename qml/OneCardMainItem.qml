import QtQuick 2.0
import VPlayPlugins 1.0
import "common"
import "scenes"
import "interface"

Item {
  id: mainItem
  width: window.width
  height: window.height

  property alias menuScene: menuScene
  property alias gameScene: gameScene



  // 主界面
  MenuScene {
    id: menuScene

    onMenuButtonPressed: {
          multiplayer.createSinglePlayerGame()
          window.state = "game"
    }
  }

  // 游戏界面
  GameScene {
    id: gameScene
    onBackButtonPressed: {
      if(!gameScene.leaveGame.visible)
        gameScene.leaveGame.visible = true
      else {
        window.state = "menu"
      }

    }
  }
}
