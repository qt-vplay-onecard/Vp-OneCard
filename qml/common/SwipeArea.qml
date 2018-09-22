import QtQuick 2.0

//场景之间的滑动和切换
MouseArea {
  property int startX
  property int startY

  //方向信号
  signal swipeRight
  signal swipeLeft

  onPressed: {
    startX = mouse.x
    startY = mouse.y
  }

  onReleased: {
    var deltax = mouse.x - startX
    var deltay = mouse.y - startY

    if (Math.abs(deltax) > 50 || Math.abs(deltay) > 50) {
      if (deltax > 30 && Math.abs(deltay) < 30) {
        swipeLeft();
      } else if (deltax < -30 && Math.abs(deltay) < 30) {
        swipeRight();
      }
    }
  }
}

