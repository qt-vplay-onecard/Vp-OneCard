import QtQuick 2.0
import VPlay 2.0
import "../common"

Item {
    id: changeheadWindow
    visible: false
    anchors.fill: parent
    z: 5
    PlayerTag {
        id: playerTag
    }

    Rectangle {
        id: heads
        color: "white"
        anchors.fill: parent

        Column {
            id: headImage
            anchors.centerIn: parent
            spacing: 6

            Row {
                Image {
                    //                anchors.fill: parent
                    id: head1
                    width: 80
                    height: 80
                    source: "../../assets/img/head1.jpg"
                    //                    anchors.left: heads.left
                    //                    anchors.top: heads.top
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            gameNetwork.user.profileImageUrl = head1.source
                        }
                    }
                }
                Image {
                    //                anchors.fill: parent
                    id: head2
                    width: 80
                    height: 80
                    source: "../../assets/img/head2.jpg"

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            gameNetwork.user.profileImageUrl = head2.source
                        }
                    }
                }
                Image {
                    //                anchors.fill: parent
                    id: head5
                    width: 80
                    height: 80
                    source: "../../assets/img/head5.jpg"
                    //                    anchors.left: heads.left
                    //                    anchors.top: heads.top
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            gameNetwork.user.profileImageUrl = head5.source
                        }
                    }
                }
            }
            //            Image {
            //                //                anchors.fill: parent
            //                id: head3
            //                width: 100
            //                height: 100
            //                source: "../../assets/img/head3.jpg"
            //                //                    anchors.left: heads.left
            //                //                    anchors.top: heads.top
            //                anchors.left: head2.right
            //                MouseArea {
            //                    anchors.fill: parent
            //                    onClicked: {
            //                        gameNetwork.user.profileImageUrl = head3.source
            //                    }
            //                }
            //            }
            Row {
                Image {
                    //                anchors.fill: parent
                    id: head3
                    width: 80
                    height: 80
                    source: "../../assets/img/head3.jpg"
                    //                    anchors.left: heads.left
                    //                    anchors.top: heads.top
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            gameNetwork.user.profileImageUrl = head3.source
                        }
                    }
                }
                Image {
                    //                anchors.fill: parent
                    id: head6
                    width: 80
                    height: 80
                    source: "../../assets/img/head6.jpg"

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            gameNetwork.user.profileImageUrl = head6.source
                        }
                    }
                }
                Image {
                    //                anchors.fill: parent
                    id: head7
                    width: 80
                    height: 80
                    source: "../../assets/img/head7.jpg"
                    //                    anchors.left: heads.left
                    //                    anchors.top: heads.top
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            gameNetwork.user.profileImageUrl = head7.source
                        }
                    }
                }
            }
            Row {
                Image {
                    //                anchors.fill: parent
                    id: head8
                    width: 80
                    height: 80
                    source: "../../assets/img/head8.jpg"
                    //                    anchors.left: heads.left
                    //                    anchors.top: heads.top
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            gameNetwork.user.profileImageUrl = head8.source
                        }
                    }
                }
                Image {
                    //                anchors.fill: parent
                    id: head9
                    width: 80
                    height: 80
                    source: "../../assets/img/head9.jpg"
                    //                    anchors.left: heads.left
                    //                    anchors.top: heads.top
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            gameNetwork.user.profileImageUrl = head9.source
                        }
                    }
                }
                Image {
                    //                anchors.fill: parent
                    id: head10
                    width: 80
                    height: 80
                    source: "../../assets/img/head10.jpg"
                    //                    anchors.left: heads.left
                    //                    anchors.top: heads.top
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            gameNetwork.user.profileImageUrl = head10.source
                        }
                    }
                }
            }
        }
    }

    Row {
        anchors.bottom: heads.bottom
        anchors.horizontalCenter: heads.horizontalCenter
        ButtonBase {
            id: sethead
            text: "Save"
            onClicked: changeheadWindow.visible = false
        }
        ButtonBase {
            id: cancel
            text: "Cancel"
            onClicked: changeheadWindow.visible = false
        }
        ButtonBase {
            id: reset
            text: "initial image"
            onClicked: {
                gameNetwork.user.profileImageUrl = "../../assets/img/User.png"
                changeheadWindow.visible = false
            }
        }
    }
}
