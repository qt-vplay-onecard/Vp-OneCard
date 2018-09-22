import QtQuick 2.0
import VPlay 2.0


//包括游戏中的所有卡片和堆栈功能
Item {
    id: deck
    width: 82
    height: 134

    // 游戏中的纸牌数量
    property int cardsInDeck: 108
    // 在堆栈中要绘制的卡片数量
    property int cardsInStack: 108
    //  在游戏中包含所有纸牌的信息
    property var cardInfo: []
    // 在游戏中使用所有纸牌实体的数组
    property var cardDeck: []
    //  所有的卡片类型和颜色
    property var types: ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "draw2", "skip", "reverse", "wild", "wild4"]
    property var cardColor: ["yellow", "red", "green", "blue", "black"]

    // 在游戏开始时洗牌
    SoundEffectVPlay {
        volume: 0.5
        id: shuffleSound
        source: "../../assets/snd/shuffle.wav"
    }

    //领导者在游戏开始时创建了平台
    function createDeck() {
        reset()
        fillDeck()
        shuffleDeck()
        printDeck()
    }

    //  其他玩家在游戏开始时与领导者同步他们的牌面
    function syncDeck(deckInfo) {
        reset()
        for (var i = 0; i < cardsInDeck; i++) {
            cardInfo[i] = deckInfo[i]
        }
        printDeck()
    }

    // 为所有卡片创建信息
    function fillDeck() {
        var card
        var order = 0

        // 创建黄色、绿色、红色和蓝色的卡片
        for (var i = 0; i < 4; i++) {
            // one zero card per color 每一种颜色的零卡
            card = {
                variationType: types[0],
                cardColor: cardColor[i],
                points: 5,
                hidden: true,
                order: order
            }
            cardInfo.push(card)
            order++

            // 每一种颜色有2张1-9张值
            for (var j = 1; j <= 9; j++) {
                for (var k = 0; k < 2; k++) {
                    card = {
                        variationType: types[j],
                        cardColor: cardColor[i],
                        points: 5,
                        hidden: true,
                        order: order
                    }
                    cardInfo.push(card)
                    order++
                }
            }


            for (var l = 10; l <= 12; l++) {
                for (var m = 0; m < 2; m++) {
                    card = {
                        variationType: types[l],
                        cardColor: cardColor[i],
                        points: 20,
                        hidden: true,
                        order: order
                    }
                    cardInfo.push(card)
                    order++
                }
            }
        }


        for (var n = 13; n <= 14; n++) {
            for (var o = 0; o < 4; o++) {
                card = {
                    variationType: types[n],
                    cardColor: cardColor[4],
                    points: 50,
                    hidden: true,
                    order: order
                }
                cardInfo.push(card)
                order++
            }
        }
    }

    //用cardInfo数组创建卡片实体
    function printDeck() {
        shuffleSound.play()
        var id
        for (var i = 0; i < cardInfo.length; i++) {
            id = entityManager.createEntityFromUrlWithProperties(
                        Qt.resolvedUrl("Card.qml"), {
                            variationType: cardInfo[i].variationType,
                            cardColor: cardInfo[i].cardColor,
                            points: cardInfo[i].points,
                            order: cardInfo[i].order,
                            hidden: cardInfo[i].hidden,
                            z: i,
                            state: "stack",
                            parent: deck,
                            newParent: deck
                        })
            cardDeck.push(entityManager.getEntityById(id))
        }
        offsetStack()
    }

    //s 分发卡片
    function handOutCards(amount) {
        var handOut = []
        for (var i = 0; i < (cardsInStack + i) && i < amount; i++) {
            //最后一张卡片上的最高索引
            var index = deck.cardDeck.length - (deck.cardDeck.length - deck.cardsInStack) - 1
            handOut.push(cardDeck[index])
            cardsInStack--
        }
        //  在画完卡片后关闭ONU状态
        passedChance()
        //在画完卡片后取消激活卡片效果
        depot.effect = false
        var userId = multiplayer.activePlayer ? multiplayer.activePlayer.userId : 0
        multiplayer.sendMessage(gameLogic.messageSetEffect, {
                                    effect: false,
                                    userId: userId
                                })
        return handOut
    }

    //  在绘图卡后禁用ONU状态
    function passedChance() {
        for (var i = 0; i < playerHands.children.length; i++) {
            if (playerHands.children[i].player === multiplayer.activePlayer) {
                if (multiplayer.myTurn || !multiplayer.activePlayer
                        || !multiplayer.activePlayer.connected) {
                    playerHands.children[i].onu = false
                    var userId = multiplayer.activePlayer ? multiplayer.activePlayer.userId : 0
                    multiplayer.sendMessage(gameLogic.messagePressONU, {
                                                userId: userId,
                                                onu: false
                                            })
                }
            }
        }
    }

    // 在游戏开始的时候，领导者将洗牌
    function shuffleDeck() {
        //使用Durstenfeld 洗牌算法随机化数组元素顺序
        for (var i = cardInfo.length - 1; i > 0; i--) {
            var j = Math.floor(Math.random() * (i + 1))
            var temp = cardInfo[i]
            cardInfo[i] = cardInfo[j]
            cardInfo[j] = temp
        }
        cardsInStack = cardsInDeck
    }

    // 在游戏之间移除所有的牌和playerhands
    function reset() {
        var toRemoveEntityTypes = ["card"]
        entityManager.removeEntitiesByFilter(toRemoveEntityTypes)
        while (cardDeck.length) {
            cardDeck.pop()
            cardInfo.pop()
        }
        cardsInStack = cardsInDeck
        for (var i = 0; i < playerHands.children.length; i++) {
            playerHands.children[i].reset()
        }
    }

    //  在堆栈顶部获取卡片的id
    function getTopCardId() {
        //如果没有牌可以取出，从仓库卡创建一个新的堆栈
        reStack()
        var index = Math.max(
                    cardDeck.length - (cardDeck.length - cardsInStack) - 1, 0)
        return deck.cardDeck[index].entityId
    }

    // 重新定位剩余的卡片以创建一个堆栈
    function offsetStack() {
        for (var i = 0; i < cardDeck.length; i++) {
            if (cardDeck[i].state == "stack") {
                cardDeck[i].y = i * (-0.1)
            }
        }
    }

    //如果没有其他有效的卡片选项，则标记堆栈
    function markStack() {
        if (cardDeck.length <= 0)
            return
        var card = entityManager.getEntityById(getTopCardId())
        card.glowImage.visible = true
    }

    // 取消标记堆栈
    function unmark() {
        if (cardDeck.length <= 0)
            return
        var card = entityManager.getEntityById(getTopCardId())
        card.glowImage.visible = false
    }

    // 如果没有剩下的牌，把旧的仓库卡移到堆栈上。
    function reStack() {
        var cardIds = []
        if (cardsInStack <= 1) {
            // find all old depot cards 找到所有旧的仓库卡
            for (var i = 0; i < cardDeck.length; i++) {
                if (cardDeck[i].state === "depot"
                        && cardDeck[i].entityId !== depot.current.entityId) {
                    cardIds.push(cardDeck[i].entityId)
                }
            }
            // 重新启动并隐藏这些卡片并将它们移动到cardDeck数组的开头
            for (var j = 0; j < cardIds.length; j++) {
                for (var k = 0; k < cardDeck.length; k++) {
                    if (cardDeck[k].entityId == cardIds[j]) {
                        if (cardDeck[k].variationType == "wild"
                                || cardDeck[k].variationType == "wild4") {
                            cardDeck[k].cardColor = "black"
                        }
                        cardDeck[k].hidden = true
                        cardDeck[k].newParent = deck
                        cardDeck[k].state = "stack"
                        moveElement(k, 0)
                        cardsInStack++
                        break
                    }
                }
            }
        }
        // 重新定位新卡片以创建一个堆栈
        offsetStack()
    }

    // 将堆栈卡移到cardDeck数组的开头
    function moveElement(from, to) {
        cardDeck.splice(to, 0, cardDeck.splice(from, 1)[0])
        return this
    }
}
