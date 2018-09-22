import QtQuick 2.0
import VPlay 2.0

Item {
  id: depot
  width: 82
  height: 134

  property var current
  property alias effectTimer: effectTimer
  property bool effect: false
  property bool skipped: false
  property bool clockwise: true
  property int drawAmount: 1


  // 当一个玩家被跳过时，声音效果就会发挥作用
  SoundEffectVPlay {
    volume: 0.5
    id: skipSound
    source: "../../assets/snd/skip.wav"
  }

  // 声音效果在玩家跳过时起作用
  SoundEffectVPlay {
    volume: 0.5
    id: reverseSound
    source: "../../assets/snd/reverse.wav"
  }

  // 在短时间内阻止玩家，当他被跳过时触发一个新的回合
  Timer {
    id: effectTimer
    repeat: false
    interval: 3000
    onTriggered: {
      effectTimer.stop()
      skipped = false
      var userId = multiplayer.activePlayer ? multiplayer.activePlayer.userId : 0
      multiplayer.sendMessage(gameLogic.messageSetSkipped, {skipped: false, userId: userId})
      console.debug("<<<< Trigger new turn after effect, clockwise: " + clockwise)
      gameLogic.triggerNewTurn()
    }
  }

  // create the depot by placing a single stack card 通过放置一个堆栈卡来创建仓库
  function createDepot(){
    depositCard(deck.getTopCardId())
    deck.cardsInStack --
  }

  //在两个值之间返回一个随机数
  function randomIntFromInterval(min,max)
  {
    return Math.floor(Math.random() * (max - min + 1) + min)
  }

  //将选定的卡片添加到仓库中
  function depositCard(cardId){
    var card = entityManager.getEntityById(cardId)
    changeParent(card)
    if (!multiplayer.activePlayer || multiplayer.activePlayer.connected){
      card.hidden = false
    }

    // 把卡片移到仓库，改变位置和旋转
    var rotation = randomIntFromInterval(-5, 5)
    var xOffset = randomIntFromInterval(-5, 5)
    var yOffset = randomIntFromInterval(-5, 5)
    card.rotation = rotation
    card.x = xOffset
    card.y = yOffset

    //第一张牌从z 0开始，其他的牌放在上面
    if (!current) {
      card.z = 0
    }else{
      card.z = current.z + 1
    }

    //存卡是当前的参考卡
    current = card

    var userId = multiplayer.activePlayer ? multiplayer.activePlayer.userId : 0

    //  如果放置的卡片对下一个玩家有影响发信号
    if(hasEffect()){
      effect = true
      multiplayer.sendMessage(gameLogic.messageSetEffect, {effect: true, userId: userId})
    } else {
      effect = false
      multiplayer.sendMessage(gameLogic.messageSetEffect, {effect: false, userId: userId})
    }
  }

  // 把卡片的父母改成仓库
  function changeParent(card){
    card.newParent = depot
    card.state = "depot"
  }

  // 检查卡片是否对下一个玩家有影响
  function hasEffect(){
    if (current.variationType === "skip" ||
        current.variationType === "draw2" ||
        current.variationType === "wild4"){
      return true
    }else{
      return false
    }
  }

  //检查所选的卡片是否与当前的参考卡相匹配
  function validCard(cardId){
    // 只有在选定的牌在活跃玩家的手中时才会继续
    for (var i = 0; i < playerHands.children.length; i++) {
      if (playerHands.children[i].player === multiplayer.activePlayer){
        if (!playerHands.children[i].inHand(cardId)) return false
      }
    }
    var card = entityManager.getEntityById(cardId)

    // draw2和wild4卡片只能由同一类型的其他卡片进行匹配
    if (effect && current.variationType === "draw2" && card.variationType !== "draw2") return false
    if (effect && current.variationType === "wild4" && card.variationType !== "wild4") return false
    if (card.cardColor === current.cardColor) return true
    if (card.variationType === current.variationType) return true
    if (card.cardColor === "black") return true
    if (current.cardColor === "black") return true
  }

  //根据卡片类型打出卡片
  function cardEffect(){
    if (effect){
      if (current && current.variationType === "skip") {
        skip()
      }
    } else {
      //  如果它们不活跃，就重置卡片效果
      skipped = false
      depot.drawAmount = 1
      var userId = multiplayer.activePlayer ? multiplayer.activePlayer.userId : 0
      multiplayer.sendMessage(gameLogic.messageSetDrawAmount, {amount: 1, userId: userId})
    }
  }

  //  跳过当前播放器，播放一个声音，设置跳过的变量并启动跳跃计时器
  function skip(){
    skipSound.play()
    effect = false
    var userId = multiplayer.activePlayer ? multiplayer.activePlayer.userId : 0
    multiplayer.sendMessage(gameLogic.messageSetEffect, {effect: false, userId: userId})
    skipped = true

    if (multiplayer.activePlayer && multiplayer.activePlayer.connected){
      multiplayer.leaderCode(function() {
        effectTimer.start()
      })
    }
  }

  // 反转当前的转向方向
  function reverse(){
    reverseSound.play()
    // 改变方向
    clockwise ^= true
    // 向其他玩家发送当前的方向
    var userId = multiplayer.activePlayer ? multiplayer.activePlayer.userId : 0
    multiplayer.sendMessage(gameLogic.messageSetReverse, {clockwise: clockwise, userId: userId})
  }

  // 当一个draw2或wild4效果激活时增加draw金额
  function draw(amount){
    if (drawAmount == 1) {
      drawAmount = amount
    } else {
      drawAmount += amount
    }
    var userId = multiplayer.activePlayer ? multiplayer.activePlayer.userId : 0
    multiplayer.sendMessage(gameLogic.messageSetDrawAmount, {amount: depot.drawAmount, userId: userId})
  }

  // 重置仓库
  function reset(){
    skipped = false
    clockwise = true
    drawAmount = 1
    effect = false
    effectTimer.stop()
  }

  //与领导同步仓库
  function syncDepot(depotCardIDs, currentId, currentCardColor, skipped, clockwise, effect, drawAmount){
    for (var i = 0; i < depotCardIDs.length; i++){
      depositCard(depotCardIDs[i])
      deck.cardsInStack --
    }

    depositCard(currentId)
    current.cardColor = currentCardColor
    depot.skipped = skipped
    depot.clockwise = clockwise
    depot.effect = effect
    depot.drawAmount = drawAmount
  }
}
