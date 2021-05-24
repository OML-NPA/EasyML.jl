
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.Layouts 1.2
import Qt.labs.platform 1.1
import QtQml.Models 2.15
import Qt.labs.folderlistmodel 2.15
import "Templates"
//import org.julialang 1.0

Component {
    StackView {
        id: stack
        initialItem: newsView
        pushEnter: Transition {
            PropertyAnimation {
                from: 0
                to:1
                duration: 0
            }
        }
        pushExit: Transition {
            PropertyAnimation {
                from: 1
                to:0
                duration: 0
            }
        }
        popEnter: Transition {
            PropertyAnimation {
                property: "opacity"
                from: 0
                to:1
                duration: 0
            }
        }
        popExit: Transition {
            PropertyAnimation {
                from: 1
                to:0
                duration: 0
            }
        }
        Component {
            id: repeaterComponent
            Row {
                x: 1.3*buttonWidth-2*pix
                Repeater {
                    id: menubuttonRepeater
                    Component.onCompleted: {menubuttonRepeater.itemAt(0).buttonfocus = true}
                    model: [{"name": "News", "stackview": newsView},
                        {"name": "Member area", "stackview": memberareaView}]
                    delegate : MenuButton {
                        id: general
                        width: 0.8*buttonWidth
                        height: 1*buttonHeight
                        font_size: 11
                        horizontal: true
                        onClicked: {
                            stack.push(modelData.stackview);
                            for (var i=0;i<(menubuttonRepeater.count);i++) {
                                menubuttonRepeater.itemAt(i).buttonfocus = false
                            }
                            buttonfocus = true
                        }
                        text: modelData.name
                    }
                }
            }
        }
        Component {
            id: newsView
            Frame {
                id: newsFrame
                height: window.height - header.height - margin*2
                width: window.width - menuPane.width - margin*2.3
                backgroundColor: defaultcolors.light
                ScrollView {
                    clip: true
                    anchors.fill: parent
                    padding: 0
                    spacing: 0
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    Flickable {
                        boundsBehavior: Flickable.StopAtBounds
                        contentHeight: newsListView.height+buttonHeight-2*pix
                        Item {
                            ListView {
                                id: newsListView
                                height: childrenRect.height
                                spacing: 0
                                boundsBehavior: Flickable.StopAtBounds
                                model: ListModel {id: newsModel
                                    Component.onCompleted: {
                                        for (var i=0;i<1;i++) {
                                        newsModel.append({"headingText": "09.12.20 Welcome!",
                                                    "bodyText": "I am an example of a news block. "+
                                                     "Hopefully, there will be more of me soon. :)"})
                                        }
                                    }
                                }
                                delegate: NewsPanel {
                                    id: control
                                    hoverEnabled: false
                                    width: newsFrame.width-26*pix
                                    height: 3*buttonHeight
                                    heading: headingText
                                    body: bodyText
                                }
                            }
                        }
                    }
                }
            }
        }
        Component {
            id: memberareaView
            Text {
            }
        }
        Component.onCompleted: {
            repeaterComponent.createObject(window.header);
        }
    }

}
