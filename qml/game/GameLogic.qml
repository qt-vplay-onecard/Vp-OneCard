import QtQuick 2.0
import VPlay 2.0

Item {
  id: gameLogic

  property bool singlePlayer: false
  property bool initialized: false
  onInitializedChanged: console.debug("GameLogic.initialized changed to:", initialized)
  property double remainingTime
  property int userInterval: multiplayer.myTurn && !multiplayer.amLeader ? 7 : 10
  property int aiTurnTime: 600
  property int restartTime: 8000
  property bool cardsDrawn: false
  property bool acted: false
  property bool gameOver: false

  property int messageSyncGameState: 0
  property int messageRequestGameState: 1
  property int messageMoveCardsHand: 2
  property int messageMoveCardsDepot: 3
  property int messageSetEffect: 4
  property int messageSetSkipped: 5
  property int messageSetReverse: 6
  property int messageSetDrawAmount: 7
  property int messagePickColor: 8
  property int messagePressONU: 9
  property int messageEndGame: 10
  property int messageSetPlayerInfo: 12
  property int messageTriggerTurn: 13
  property int messageRequestPlayerTags: 14


  property bool receivedMessageBeforeGameStateInSync: false

  //在选择wild或wild4的颜色时，发出的声音效果
  SoundEffectVPlay {
    volume: 0.5
    id: colorSound
    source: "../../assets/snd/color.wav"
  }

  //计时器减少了活动参与者的剩余时间
  Timer {
    id: timer
    repeat: true
    running: !gameOver
    interval: 1000

    onTriggered: {
      remainingTime -= 1
      //让AI在10秒后为连接的播放器播放
      if (remainingTime === 0) {
        gameLogic.turnTimedOut()
      }
      //为活动玩家标记有效的卡片选项
      if (multiplayer.myTurn){
        markValid()
        scaleHand()
      }
      //每秒钟在playerTag上重新绘制计时器圈
      for (var i = 0; i < playerTags.children.length; i++){
        playerTags.children[i].canvas.requestPaint()
      }
    }
  }

  //如果玩家没有连接，AI会在几秒钟后接管
  Timer {
    id: aiTimeOut
    interval: aiTurnTime
    onTriggered: {
      gameLogic.executeAIMove()
      endTurn()
    }
  }

  //几秒钟后开始一场新的比赛
  Timer {
    id: restartGameTimer
    interval: restartTime
    onTriggered: {
      restartGameTimer.stop()
      startNewGame()
    }
  }

  // 连接到游戏，并处理所有的信号
  Connections {
    target: gameScene

    //玩家选择了堆栈
    onStackSelected: {
      //如果轮到玩家，就点亮卡片
      if (multiplayer.myTurn && !depot.skipped && !acted && !cardsDrawn) {
        if (hasValidCards(multiplayer.localPlayer)){
          acted = true
        }

        var userId = multiplayer.activePlayer ? multiplayer.activePlayer.userId : 0
        getCards(depot.drawAmount, userId)
        multiplayer.sendMessage(messageMoveCardsHand, {cards: depot.drawAmount, userId: userId})

        if (acted || !hasValidCards(multiplayer.localPlayer)){
          acted = true
          endTurn()
        } else {
          //在玩家回合中重置draw金额
          depot.drawAmount = 1
          depot.effect = false
          multiplayer.sendMessage(gameLogic.messageSetDrawAmount, {amount: 1, userId: userId})

          // 按比例标记新获得的卡片
          scaleHand(1.6)
          markValid()
          //检查玩家是否有两张或更少的牌
          closeToWin()
        }

        flurry.logEvent("User.StackSelected", "singlePlayer", multiplayer.singlePlayer)
      }
    }

    //玩家选择了一张牌
    onCardSelected: {
      // 如果所选的卡片来自堆栈，请发出信号
      if (colorPicker.chosingColor) return
      if (entityManager.getEntityById(cardId).state === "stack"){
        stackSelected()
        // 存放有效卡
      } else if (entityManager.getEntityById(cardId).state === "player"){
        if (multiplayer.myTurn && !depot.skipped && !acted) {
          flurry.logEvent("User.CardSelected", "singlePlayer", multiplayer.singlePlayer)

          if (depot.validCard(cardId)){
            // 用户只能出一次牌，除非选择的卡片是一个wild，这允许用户选择一种颜色
            var currentType = entityManager.getEntityById(cardId).variationType
            if (currentType !== "wild" && currentType !== "wild4") acted = true

            depositCard(cardId, multiplayer.localPlayer.userId)
            multiplayer.sendMessage(messageMoveCardsDepot, {cardId: cardId, userId: multiplayer.localPlayer.userId})

            //主动玩家在玩了一个拖放或通配符之后增加了draw金额
            if (depot.current.variationType === "draw2") depot.draw(2)
            if (depot.current.variationType === "wild4") depot.draw(4)

            // 结束回合，除非连接的玩家必须选择一种颜色
            if (depot.current.cardColor !== "black" && multiplayer.myTurn){
              endTurn()
            }
          }
        }
      }
    }

    // player选择了一个颜色
    onColorPicked: {
      if (multiplayer.myTurn && !acted){
        acted = true
        colorSound.play()
        pickColor(pickedColor)
        multiplayer.sendMessage(messagePickColor, {color: pickedColor, userId: multiplayer.localPlayer.userId})
        endTurn()

        flurry.logEvent("User.ColorPicked", "singlePlayer", multiplayer.singlePlayer)
      }
    }
  }

  //与领导者同步，设置游戏
  function syncDeck(cardInfo){
    console.debug("syncDeck()")
    deck.syncDeck(cardInfo)
    // takes off 1st card
    depot.createDepot()

    //在游戏开始时重置所有值
    gameOver = false
    timer.start()
    scaleHand()
    markValid()
    gameScene.gameOver.visible = false
    gameScene.leaveGame.visible = false
    playerInfoPopup.visible = false
    onuButton.button.enabled = false
  }

  //存放所选卡
  function depositCard(cardId, userId){
    //取消标记所有突显出牌
    unmark()
    // 按比例缩小活跃的localPlayer播放器
    scaleHand(1.0)
    for (var i = 0; i < playerHands.children.length; i++) {
      //为活跃的玩家找到玩家的手
      if (playerHands.children[i].inHand(cardId)){

        playerHands.children[i].removeFromHand(cardId)
        depot.depositCard(cardId)

        if (depot.current.variationType === "reverse"){
          multiplayer.leaderCode(function() {
            depot.reverse()
          })
        }

        // if the card was a wild or wild4 card
        if (depot.current.cardColor === "black"){
          //显示活动连接播放器的颜色选择器
          if (multiplayer.activePlayer && multiplayer.activePlayer.connected && remainingTime > 0){
            if (multiplayer.myTurn){
              colorPicker.visible = true
            }
            colorPicker.chosingColor = true
          }else{
            //领导者为没连接玩家选择一种随机的颜色
            multiplayer.leaderCode(function() {
              if (!multiplayer.activePlayer || !multiplayer.activePlayer.connected) {
                var color = colorPicker.randomColor()
                pickColor(color)
                multiplayer.sendMessage(messagePickColor, {color: color, userId: userId})
              }
            })
          }
        }
        //在选择了颜色后，为断开连接的播放器发现卡。
        if (!multiplayer.activePlayer || !multiplayer.activePlayer.connected){
          depot.current.hidden = false
        }
      }
    }
  }

  //如果玩家没有被跳过，让AI接管
  function executeAIMove() {
    if(!depot.skipped){
      playRandomValid()
    }
  }

  //从活动玩家的玩家手中随机播放一张有效的牌
  function playRandomValid() {
    //找到活跃玩家
    for (var i = 0; i < playerHands.children.length; i++) {
      if (playerHands.children[i].player === multiplayer.activePlayer && !cardsDrawn){
        var validCardId = playerHands.children[i].randomValidId()
        var userId = multiplayer.activePlayer ? multiplayer.activePlayer.userId : 0
        // 将有效的卡或从堆栈中取出卡片
        if (validCardId){
          multiplayer.sendMessage(messageMoveCardsDepot, {cardId: validCardId, userId: userId})
          depositCard(validCardId, userId)

          if (depot.current.variationType === "draw2") depot.draw(2)
          if (depot.current.variationType === "wild4") depot.draw(4)

        } else {
          getCards(depot.drawAmount, userId)
          multiplayer.sendMessage(messageMoveCardsHand, {cards: depot.drawAmount, userId: userId})
        }
      }
    }
  }

  // 检查带有特定id的用户是否有有效的卡片
  function hasValidCards(userId){
    var playerHand = getHand(multiplayer.localPlayer.userId)
    var valids = playerHand.getValidCards()
    return valids.length > 0
  }

  //给连接的玩家10秒钟直到AI接管
  function startTurnTimer() {
    timer.stop()
    remainingTime = userInterval
    if (!gameOver) {
      timer.start()
      scaleHand()
      markValid()
    }
  }

  //为活动的玩家开启一个回合
  function turnStarted(playerId) {
    console.debug("turnStarted() called")

    if(!multiplayer.activePlayer) {
      console.debug("ERROR: activePlayer not valid in turnStarted!")
      return
    }

    console.debug("multiplayer.activePlayer.userId: " + multiplayer.activePlayer.userId)
    console.debug("Turn started")
    gameLogic.startTurnTimer()
    acted = false
    cardsDrawn = false
    unmark()
    scaleHand(1.0)
    colorPicker.visible = false
    colorPicker.chosingColor = false
    // 检查当前卡是否对活动玩家有影响
    depot.cardEffect()
    //放大活跃的本地玩家的手
    if (!depot.skipped && multiplayer.myTurn) scaleHand(1.6)
    //检查玩家是否有两张或更少的牌
    closeToWin()
    // 标记有效的卡片选项
    markValid()
    //重新画计时器圆
    for (var i = 0; i < playerTags.children.length; i++){
      playerTags.children[i].canvas.requestPaint()
    }
    //安排AI在3秒内接管，以防玩家离开
    multiplayer.leaderCode(function() {
      if (!multiplayer.activePlayer || !multiplayer.activePlayer.connected) {
        aiTimeOut.start()
      }
    })
  }

  //如果连接的播放器不活跃，10秒后，调度AI将接管
  function turnTimedOut(){
    if (multiplayer.myTurn && !acted){
      acted = true
      scaleHand(1.0)
    }
    //清理我们的UI
    timer.running = false
    // 玩家超时了，所以领导者应该接管
    multiplayer.leaderCode(function () {
      //如果玩家正在选择一种颜色
      if (!colorPicker.chosingColor){
        //
        executeAIMove()
      }
      endTurn()
    })
  }

  function createGame(){
    multiplayer.createGame()
  }

  //停止计时器，在游戏结束时重新设置平台
  function leaveGame(){
    aiTimeOut.stop()
    restartGameTimer.stop()
    timer.running = false
    depot.effectTimer.stop()
    deck.reset()
    multiplayer.leaveGame()
    scaleHand(1.0)
    initialized = false
    receivedMessageBeforeGameStateInSync = false

    flurry.logEvent("User.ExitGame", "singlePlayer", multiplayer.singlePlayer)
    flurry.endTimedEvent("Game.TimeInGameTotal", {"singlePlayer": multiplayer.singlePlayer})
  }

  function joinGame(room){
    multiplayer.joinGame(room)
  }

  //初始化游戏，当领导者重新开始这个游戏这个被调用从GameOverWindow ，从GameScene.onVisibleChanged 可见，当玩家重新启动游戏时，从游戏窗口开始，从游戏开始，当它从游戏中看到时，它就会被改变。
  function initGame(calledFromGameOverScreen){
    ga.logEvent("System", "Start Game", "singlePlayer", multiplayer.singlePlayer)
    flurry.logEvent("System.StartGame", "singlePlayer", multiplayer.singlePlayer)
    //添加自己的事件，无论游戏是从主菜单开始还是重新启动——这只是从领导者那里发送的，而不是来自客户端
    if(calledFromGameOverScreen) {
      flurry.logEvent("User.RestartGame", "singlePlayer", multiplayer.singlePlayer)
    } else {
      flurry.logEvent("User.StartNewGame", "singlePlayer", multiplayer.singlePlayer)
    }

    if(!multiplayer.initialized && !multiplayer.singlePlayer){
      createGame()
    }

    console.debug("multiplayer.localPlayer " + multiplayer.localPlayer)
    console.debug("multiplayer.players.length " + multiplayer.players.length)
    for (var i = 0; i < multiplayer.players.length; i++){
      console.debug("multiplayer.players[" + i +"].userId " + multiplayer.players[i].userId)
    }
    console.debug("multiplayer.myTurn " + multiplayer.myTurn)

    //在游戏开始时重置所有值
    gameOver = false
    timer.start()
    scaleHand()
    markValid()
    gameScene.gameOver.visible = false
    gameScene.leaveGame.visible = false
    onuButton.button.enabled = false

    // initialize the players, the deck and the individual hands 初始化玩家，牌组和单个手
    initPlayers()
    initDeck()
    initHands()
    //重置所有标记并设置领导者的标记数据
    initTags()

    //为所有玩家设置游戏状态
    multiplayer.leaderCode(function () {
      // 注意：只有领导者必须将其设置为真！客户端只有在收到初始同步游戏状态消息后才会初始化
      initialized = true

      //如果我们在这里调用这个，gameStarted被调用两次。它不需要调用，因为当房间设置时它已经被调用了
      if(calledFromGameOverScreen) {
        // 通过调用restartGame，我们会向领导者和客户发出一个游戏。
        multiplayer.restartGame()
      }

      //  我们想要将状态发送给所有玩家，从而将playerId设置为未定义的并且这个案例是在onMessageReceived中处理的因此所有玩家都可以处理游戏状态同步如果playerId没有定义
      // 在强力游戏后发送游戏状态，否则消息将不会被初始玩家接收！
      if (!multiplayer.singlePlayer) {
        sendGameStateToPlayer(undefined)
      }

      //让我们的领导者总是第一个回合，否则在之前结束比赛的那个球员将会是第一个转身的人
      gameLogic.triggerNewTurn(multiplayer.leaderPlayer.userId)
    })

    //从缩放活跃的localPlayer的playerHand开始
    scaleHand()
    // check if the player has two or less cards left
    closeToWin()

    ga.logEvent("User", "Restart Game", "singlePlayer", multiplayer.singlePlayer)
    flurry.logEvent("User.RestartGame", "singlePlayer", multiplayer.singlePlayer)

    console.debug("InitGame finished!")
  }

  /*
只有leader才能调用。无论如何，领导者都不会收到messageSyncGameState消息，因为消息不会发送给自己。
用于在一开始每一个新加入的玩家之间同步游戏。
在开始一场比赛和新球员玩家加入的时候，首先被leader调用。
如果playerId没有定义，它将由所有玩家处理。用这个来与已经在matchmaking room的玩家初始同步。
*/
  function sendGameStateToPlayer(playerId) {
    console.debug("sendGameStateToPlayer() with playerId", playerId)
    //保存所有需要的游戏同步数据
    var message = {}

    //保存其他玩家的所有手
    var currentPlayerHands = []
    for (var i = 0; i < playerHands.children.length; i++) {
      var currentPlayerHand = {}
      //将信息分配给正确的播放器，保存用户标识，将信息分配给正确的播放器
      currentPlayerHand.userId = playerHands.children[i].player.userId
      //保存玩家牌的id
      currentPlayerHand.handIds = []
      for (var j = 0; j < playerHands.children[i].hand.length; j++){
        currentPlayerHand.handIds[j] = playerHands.children[i].hand[j].entityId
      }
      // 添加单个玩家的手信息
      currentPlayerHands.push(currentPlayerHand)
    }
    //保存所有玩家的手信息
    message.playerHands = currentPlayerHands
    //保存甲板信息以创建相同的信息
    message.deck = deck.cardInfo
    //仓库变量同步
    message.current = depot.current.entityId
    message.currentCardColor = depot.current.cardColor

    message.skipped = depot.skipped
    message.clockwise = depot.clockwise
    message.effect = depot.effect
    message.drawAmount = depot.drawAmount
    message.gameOver = gameOver

    // 保存当前仓库的所有卡片id
    var depotIDs = []
    for (var k = 0; k < deck.cardDeck.length; k++){
      if (deck.cardDeck[k].state === "depot" && deck.cardDeck[k].entityId !== depot.current.entityId){
        depotIDs.push(deck.cardDeck[k].entityId)
      }
    }
    message.depot = depotIDs

    //将消息发送给新加入的播放器
    message.receiverPlayerId = playerId

    console.debug("Send Message: " + JSON.stringify(message))
    multiplayer.sendMessage(messageSyncGameState, message)
  }

  //将每个玩家手牌的数量与领导者的游戏状态进行比较，用于检查是否与领导者同步
  function compareGameStateWithLeader(messageHands){
    for (var i = 0; i < playerHands.children.length; i++){
      var currentUserId = playerHands.children[i].player.userId
      for (var j = 0; j < messageHands.length; j++){
        var messageUserId = messageHands[j].userId
        if (currentUserId == messageUserId){
          if (playerHands.children[i].hand.length != messageHands[j].handIds.length){
            // 如果纸牌的数量不同，返回false
            console.debug("ERROR: game state differentiates from the one of the leader because of the different amount of cards - resync the game of this player!")
            return false
          }
        }
      }
    }
    //如果所有的手都是同步的，返回true
    return true
  }

  //领导者初始化所有的玩家并将他们置于游戏的边界
  function initPlayers(){
    multiplayer.leaderCode(function () {
      console.debug("Leader Init Players")
      var clientPlayers = multiplayer.players
      var playerInfo = []
      for (var i = 0; i < clientPlayers.length; i++) {
        playerTags.children[i].player = clientPlayers[i]
        playerHands.children[i].player = clientPlayers[i]
        playerInfo[i] = clientPlayers[i].userId
      }
    })
  }

  // 通过userId找到玩家
  function getPlayer(userId){
    for (var i = 0; i < multiplayer.players.length; i++){
      console.debug("All UserIDs: " + multiplayer.players[i].userId + ", Looking for: " + userId)
      if (multiplayer.players[i].userId == userId){
        return multiplayer.players[i]
      }
    }
    console.debug("ERROR: could not find player with id", userId, "in the multiplayer.players list!")
    return undefined
  }
  //找到牌通过userid
  function getHand(userId){
    for (var i = 0; i < playerHands.children.length; i++){
      if (playerHands.children[i].player.userId == userId){
        return playerHands.children[i]
      }
    }
    console.debug("ERROR: could not find player with id", userId, "in the multiplayer.players list!")
    return undefined
  }

  //按玩家用户标识更新标签
  function updateTag(userId, level, highscore){
    for (var i = 0; i < playerTags.children.length; i++){
      if (playerHands.children[i].player.userId == userId){
        playerTags.children[i].level = level
        playerTags.children[i].highscore = highscore
      }
    }
  }

  //其他玩家将玩家定位在游戏场的边界上
  function syncPlayers(){
    console.debug("syncPlayers()")
    //这可能会发生在多人游戏中。玩家数组不同于本地用户
    //可能的原因是，一个玩家同时加入了游戏但是这并没有被转发到房间，或者没有被转发给领导者

    // 将玩家分配到游戏场边界的位置
    for (var j = 0; j < multiplayer.players.length; j++) {
      playerTags.children[j].player = multiplayer.players[j]
      playerHands.children[j].player = multiplayer.players[j]
    }
  }

  // 领导者创造了甲板和仓库
  function initDeck(){
    multiplayer.leaderCode(function () {
      deck.createDeck()
      depot.createDepot()
    })
  }

  // 领导者将牌分发给其他玩家
  function initHands(){
    multiplayer.leaderCode(function () {
      for (var i = 0; i < playerHands.children.length; i++) {
        playerHands.children[i].startHand()
      }
    })
  }

  //根据领导同步所有的手
  function syncHands(messageHands){
    console.debug("syncHands()")
    for (var i = 0; i < playerHands.children.length; i++){
      var currentUserId = playerHands.children[i].player.userId
      for (var j = 0; j < messageHands.length; j++){
        var messageUserId = messageHands[j].userId
        if (currentUserId == messageUserId){
          playerHands.children[i].syncHand(messageHands[j].handIds)
        }
      }
    }
  }

  //重置所有标记并为本地播放器初始化标记
  function initTags(){
    console.debug("initTags()")
    for (var i = 0; i < playerTags.children.length; i++){
      playerTags.children[i].initTag()
      if (playerHands.children[i].player && playerHands.children[i].player.userId == multiplayer.localPlayer.userId){
        playerTags.children[i].getPlayerData(true)
      }
    }
  }

  //绘制指定数量的卡片
  function getCards(cards, userId){
    cardsDrawn = true

    //找到活跃玩家的玩家手拿起卡片
    for (var i = 0; i < playerHands.children.length; i++) {
      if (playerHands.children[i].player.userId === userId){
        playerHands.children[i].pickUpCards(cards)
      }
    }
  }

  //将当前仓库的野生或通配符更改为选定的颜色并更新图像
  function pickColor(pickedColor){
    if ((depot.current.variationType === "wild4" || depot.current.variationType === "wild")
        && depot.current.cardColor === "black"){
      depot.current.cardColor = pickedColor
      depot.current.updateCardImage()
    }
  }

  //检查活动玩家是否接近胜利（手中有2张或更少的牌）
  function closeToWin(){
    for (var i = 0; i < playerHands.children.length; i++) {
      if (playerHands.children[i].player === multiplayer.activePlayer){
        playerHands.children[i].closeToWin()
      }
    }
  }

  // 找到活跃玩家的玩家，并标记所有有效的卡片选项
  function markValid(){
    if (multiplayer.myTurn && !acted && !colorPicker.chosingColor){
      for (var i = 0; i < playerHands.children.length; i++) {
        if (playerHands.children[i].player === multiplayer.activePlayer){
          playerHands.children[i].markValid()
        }
      }
    } else {
      unmark()
    }
  }

  //取消所有玩家的所有有效卡选项
  function unmark(){
    for (var i = 0; i < playerHands.children.length; i++) {
      playerHands.children[i].unmark()
    }
    // 取消突出显示的牌面卡
    deck.unmark()
  }

  //  缩放活跃的本地玩家的玩家手
  function scaleHand(scale){
    if (!scale) scale = multiplayer.myTurn && !acted && !depot.skipped && !colorPicker.chosingColor ? 1.6 : 1.0
    for (var i = 0; i < playerHands.children.length; i++){
      if (playerHands.children[i].player && playerHands.children[i].player.userId == multiplayer.localPlayer.userId){
        playerHands.children[i].scaleHand(scale)
      }
    }
  }

  //结束主动玩家的回合
  function endTurn(){
    //取消所有突出显示的有效卡选项
    unmark()
    // 按比例缩小活跃的本地玩家的手
    scaleHand(1.0)

    var userId = multiplayer.activePlayer ? multiplayer.activePlayer.userId : 0
    //检查活动玩家是否赢得了游戏并在这种情况下结束了
    for (var i = 0; i < playerHands.children.length; i++) {
      if (playerHands.children[i].player === multiplayer.activePlayer){
        if (playerHands.children[i].checkWin()){
          endGame()
          multiplayer.sendMessage(messageEndGame, {userId: userId})
          //如果他忘记按下活动的onu按钮，让玩家拿起两张牌
        }else if (playerHands.children[i].missedOnu()){
          getCards(2, userId)
          multiplayer.sendMessage(messageMoveCardsHand, {cards: 2, userId: userId})
          if (multiplayer.myTurn) onuHint.visible = true
        }
      }
    }
    // 如果游戏仍然活动则继续
    if (!gameOver){
      console.debug("trigger new turn in endTurn, clockwise: " + depot.clockwise)
      if (multiplayer.amLeader){
        console.debug("Still Leader?")
        triggerNewTurn()
      } else {
        // 向领导发送消息以触发新回合
        multiplayer.sendMessage(messageTriggerTurn, userId)
      }
    }
  }

  function triggerNewTurn(userId){
    if (depot.clockwise){
      multiplayer.triggerNextTurn(userId)
    } else {
      multiplayer.triggerPreviousTurn(userId)
    }
  }

  //计算每个玩家的点数
  function calculatePoints(userId){
    //通过添加所有卡片值来计算获胜者的分数
    var score = 0
    for (var i = 0; i < playerHands.children.length; i++) {
      score += playerHands.children[i].points()
    }
    if (multiplayer.singlePlayer){
      score = Math.round(score/3)
    }

    // 设置玩家姓名
    if (userId == undefined) {
      //计算其他三名球员的排名
      var tmpPlayers = [playerHands.children[0], playerHands.children[1], playerHands.children[2], playerHands.children[3]]
      var points = [score, 15, 10, 5]
      tmpPlayers.sort(function(a, b) {
        return a.hand.length - b.hand.length
      })

      var winnerHand = getHand(tmpPlayers[0].player.userId)
      if (winnerHand) gameScene.gameOver.winner = winnerHand.player

      for (var i = 0; i < tmpPlayers.length; i++){
        var tmpPlayer = getHand(tmpPlayers[i].player.userId)
        if (tmpPlayer) tmpPlayer.score = points[i]

        //检查两个玩家是否有相同数量的牌
        if (i > 0){
          var prevPlayer = getHand(tmpPlayers[i-1].player.userId)
          if (prevPlayer && prevPlayer.hand.length == tmpPlayer.hand.length){
            tmpPlayer.score = prevPlayer.score
          }
        }
      }
    } else {
      //让按下按钮的玩家获胜并简单地命令其他3个玩家
      var tmpPlayers2 = []
      for (i = 0; i < playerHands.children.length; i++){
        if (playerHands.children[i].player.userId != userId){
          tmpPlayers2[tmpPlayers2.length] = playerHands.children[i]
        }
      }
      var points2 = [15, 10, 5]
      tmpPlayers2.sort(function(a, b) {
        return a.hand.length - b.hand.length
      })

      var winnerHand2 = getHand(userId)
      if (winnerHand2) gameScene.gameOver.winner = winnerHand2.player
      var winner = getHand(userId)
      if (winner) winner.score = score

      for (var j = 0; j < tmpPlayers2.length; j++){
        var tmpPlayer2 = getHand(tmpPlayers2[j].player.userId)
        if (tmpPlayer2) tmpPlayer2.score = points2[j]
        if (j > 0){
          var prevPlayer2 = getHand(tmpPlayers2[j-1].player.userId)
          if (prevPlayer2 && prevPlayer2.hand.length == tmpPlayer2.hand.length){
            tmpPlayer2.score = prevPlayer2.score
          }
        }
      }
    }
  }

  // 结束游戏并显示分数

  function endGame(userId){
    //计算每个玩家的点数并设置获胜者的名字
    calculatePoints(userId)

    //用胜利者和得分来显示游戏的信息
    gameScene.gameOver.visible = true

    //添加点到获胜者的多玩家用户分数
    var currentHand = getHand(multiplayer.localPlayer.userId)
    if (currentHand) gameNetwork.reportRelativeScore(currentHand.score)

    var currentTag
    for (var i = 0; i < playerTags.children.length; i++){
      if (playerTags.children[i].player.userId == multiplayer.localPlayer.userId){
        currentTag = playerTags.children[i]
      }
    }

    // 计算等级
    var oldLevel = currentTag.level
    currentTag.getPlayerData(false)
    if (oldLevel != currentTag.level){
      gameScene.gameOver.level = currentTag.level
      gameScene.gameOver.levelText.visible = true
    } else {
      gameScene.gameOver.levelText.visible = false
    }

    // 结束计时
    scaleHand(1.0)
    gameOver = true
    onuButton.blinkAnimation.stop()
    aiTimeOut.stop()
    timer.running = false
    depot.effectTimer.stop()

    multiplayer.leaderCode(function () {
      restartGameTimer.start()
    })

    ga.logEvent("System", "End Game", "singlePlayer", multiplayer.singlePlayer)
    flurry.logEvent("System.EndGame", "singlePlayer", multiplayer.singlePlayer)
    flurry.endTimedEvent("Game.TimeInGameSingleMatch", {"singlePlayer": multiplayer.singlePlayer})
  }

  function startNewGame(){
    restartGameTimer.stop()
    gameLogic.initGame(true)
  }
}
