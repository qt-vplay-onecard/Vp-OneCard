import QtQuick 2.0
import VPlay 2.0

//玩家手中的牌
Item {
  id: playerHand
  width: 400
  height: 134

  property double zoom: 1.0
  property int originalWidth: 400
  property int originalHeight: 134

  property int start: 7
  property var hand: []
  property var player: MultiplayerUser{}
  property bool onu: false
  property int score: 0
  property double offset: width/10


  //抽牌时的音响效果
  SoundEffectVPlay {
    volume: 0.5
    id: drawSound
    source: "../../assets/snd/draw.wav"
  }

  // 声音效果在存放卡片时起作用
  SoundEffectVPlay {
    volume: 0.5
    id: depositSound
    source: "../../assets/snd/deposit.wav"
  }

  // 声音效果在赢得比赛时起作用
  SoundEffectVPlay {
    volume: 0.5
    id: winSound
    source: "../../assets/snd/win.wav"
  }

  //玩家背景图像，活动玩家的图像变化
  Image {
    id: playerHandImage
    source: multiplayer.activePlayer === player && !gameLogic.acted? "../../assets/img/PlayerHand2.png" : "../../assets/img/PlayerHand1.png"
    width: parent.width / 400 * 560
    height: parent.height / 134 * 260
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: parent.height * (-0.5)
    z: 0
    smooth: true

    onSourceChanged: {
      z = 0
      neatHand()
    }
  }

  // 当玩家被跳过时，玩家手被阻挡的图像是可见的。
  Image {
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    source: "../../assets/img/Blocked.png"
    width: 170
    height: width
    z: 100
    visible: depot.skipped && multiplayer.activePlayer == player
    smooth: true
  }

  // 当玩家按下ONUButton时，玩家的手泡图像是可见的
  Image {
    anchors.top: parent.top
    anchors.right: parent.right
    source: "../../assets/img/Bubble.png"
    rotation: parent.rotation * (-1)
    width: 60
    height: width
    z: 100
    visible: onu
    smooth: true
  }

  //捡起指定数量的卡片，开始分发。
  function startHand(){
    pickUpCards(start)
  }

  // 通过移除所有卡重新分发
  function reset(){
    while(hand.length) {
      hand.pop()
    }
    onu = false
    scaleHand(1.0)
  }

  // 整理手展牌
  function neatHand(){
    hand.sort(function(a, b) {
      return a.order - b.order
    })

    // 如果手头有太多，重新计算卡之间的偏移量，确保他们留在剧中。
    offset = originalWidth * zoom / 10
    if (hand.length > 7){
      offset = playerHand.originalWidth * zoom / hand.length / 1.5
    }

    //计算手的卡位置和旋转并改变Z顺序
    for (var i = 0; i < hand.length; i ++){
      var card = hand[i]
      //手牌展开角度跨度
      var handAngle = 40
      // 卡片角度取决于阵列位置
      var cardAngle = handAngle / hand.length * (i + 0.5) - handAngle / 2
      //所有卡的偏移+一卡通宽度
      var handWidth = offset * (hand.length - 1) + card.originalWidth * zoom
      // X值取决于阵列位置
      var cardX = (playerHand.originalWidth * zoom - handWidth) / 2 + (i * offset)

      card.rotation = cardAngle
      card.y = Math.abs(cardAngle) * 1.5
      card.x = cardX
      card.z = i + 50 + playerHandImage.z
    }
  }

  //拾取指定数量的卡
  function pickUpCards(amount){
    onuButton.button.enabled = false
    var pickUp = deck.handOutCards(amount)
    // 将栈卡添加到playerhand数组
    for (var i = 0; i < pickUp.length; i ++){
      hand.push(pickUp[i])
      changeParent(pickUp[i])
      if (multiplayer.localPlayer == player){
        pickUp[i].hidden = false
      }
      drawSound.play()
    }
    neatHand()
  }

  // 更改当前的手卡数组
  function syncHand(cardIDs) {
    hand = []
    for (var i = 0; i < cardIDs.length; i++){
      var tmpCard = entityManager.getEntityById(cardIDs[i])
      hand.push(tmpCard)
      changeParent(tmpCard)
      deck.cardsInStack --
      if (multiplayer.localPlayer == player){
        tmpCard.hidden = false
      }
      drawSound.play()
    }

    neatHand()
  }

  // 将玩家的卡更改为playerhand
  function changeParent(card){
    card.newParent = playerHand
    card.state = "player"
  }

  //检查带有特定ID的卡是否在这只手上
  function inHand(cardId){
    for (var i = 0; i < hand.length; i ++){
      if(hand[i].entityId === cardId){
        return true
      }
    }
    return false
  }

  // 从手上删除带有特定ID的卡
  function removeFromHand(cardId){
    for (var i = 0; i < hand.length; i ++){
      if(hand[i].entityId === cardId){
        hand[i].width = hand[i].originalWidth
        hand[i].height = hand[i].originalHeight
        hand.splice(i, 1)
        depositSound.play()
        neatHand()
        return
      }
    }
  }

  //通过设置可见图像来突出所有有效的卡片
  function markValid(){
    if (!depot.skipped && !gameLogic.gameOver && !colorPicker.chosingColor){
      for (var i = 0; i < hand.length; i ++){
        if (depot.validCard(hand[i].entityId)){
          hand[i].glowImage.visible = true
          hand[i].updateCardImage()
        }else{
          hand[i].glowImage.visible = false
          hand[i].saturation = -0.5
          hand[i].lightness = 0.5
        }
      }
      //如果手头没有有效的卡片，请标记堆栈。
      var validId = randomValidId()
      if(validId == null){
        deck.markStack()
      }
    }
  }

  //取消标记
  function unmark(){
    for (var i = 0; i < hand.length; i ++){
      hand[i].glowImage.visible = false
      hand[i].updateCardImage()
    }
  }

  //用缩放活跃的本地玩家的整个玩家手
  function scaleHand(scale){
    zoom = scale
    playerHand.height = playerHand.originalHeight * zoom
    playerHand.width = playerHand.originalWidth * zoom
    for (var i = 0; i < hand.length; i ++){
      hand[i].width = hand[i].originalWidth * zoom
      hand[i].height = hand[i].originalHeight * zoom
    }
    neatHand()
  }

  //从玩家手中获得随机有效的卡ID
  function randomValidId(){
    var valids = getValidCards()
    if (valids.length > 0){
      var randomIndex = Math.floor(Math.random() * (valids.length))
        //从数组返回一个随机有效的卡
      return valids[randomIndex].entityId
    }else{
      return null
    }
  }

  //获取所有有效卡的数组
  function getValidCards(){
    var valids = []
    // 将所有有效的卡选项放在数组中
    for (var i = 0; i < hand.length; i ++){
      if (depot.validCard(hand[i].entityId)){
        valids.push(entityManager.getEntityById(hand[i].entityId))
      }
    }
    return valids
  }

  // 如果玩家在没有按下ONU的情况下将他们的第二个存入最后一张牌， 他们错过了激活ONUButton的机会。
  function missedOnu(){
    if (hand.length === 0 && !onu){
      if (multiplayer.myTurn) onuButton.button.enabled = false
      return true
    } else {
      return false
    }
  }

  // 检查玩家是否可以激活ONU按钮
  function closeToWin(){
    // if the player has 2 or less cards in his hand
    if (hand.length == 2){
      var userDisconnected = (!multiplayer.activePlayer || !multiplayer.activePlayer.connected)
      if ((!onuButton.visible || userDisconnected) && !depot.skipped && !onu && !gameLogic.gameOver){
        var userId = multiplayer.activePlayer ? multiplayer.activePlayer.userId : 0
        onuButton.onu(userId)
      }
      // 如果激活播放器连接，则启用按钮
      var valids = getValidCards()
      if (multiplayer.myTurn && !depot.skipped && !gameLogic.gameOver && !onu && valids.length > 0){
        onuButton.button.enabled = true
      } else if (multiplayer.myTurn){
        onuButton.button.enabled = false
      }
      return true
    }else if (multiplayer.myTurn){
      //如果玩家手上有2张以上的牌，则停用按钮
      onuButton.button.enabled = false
      return false
    }
  }

  // 检查玩家是否以零卡获胜
  function checkWin(){
    if (hand.length == 0 && onu){
      winSound.play()
      return true
    }else{
      return false
    }
  }

  //计算分数
  function points(){
    var points = 0
    for (var i = 0; i < hand.length; i++) {
      points += hand[i].points
    }
    return points
  }

  //动画玩家的手宽和高度
  Behavior on width {
    NumberAnimation { easing.type: Easing.InOutQuad; duration: 400 }
  }

  Behavior on height {
    NumberAnimation { easing.type: Easing.InOutQuad; duration: 400 }
  }
}
