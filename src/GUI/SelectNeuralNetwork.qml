
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.Layouts 1.2
import Qt.labs.platform 1.1
import "Templates"
//import org.julialang 1.0


ApplicationWindow {
    id: window
    visible: true
    title: qsTr("  Open Machine Learning Software")
    minimumWidth: 1600*pix
    minimumHeight: 885*pix
    maximumWidth: Screen.width
    maximumHeight: Screen.height
    color: defaultpalette.window

    onClosing: { selectneuralnetworkLoader.sourceComponent = null }

    GridLayout {
        id: gridLayout
        Row {
            Pane {
                id: dataselectionPane
                width: dataselectionRowLayout.width + 2*padding + 0.2*margin
                height: window.height
                backgroundColor: defaultpalette.window2
                padding: 0.6*margin
                topPadding: 0.3*margin
                bottomPadding: 0.3*margin
                RowLayout {
                    id: dataselectionRowLayout
                    spacing: 0.2*margin
                    ColumnLayout {
                        id: labelColumnLayout
                        Layout.alignment : Qt.AlignHCenter | Qt.AlignTop
                        spacing: 0.56*margin
                        Layout.topMargin: 0.16*margin
                        Label {
                            Layout.alignment : Qt.AlignLeft
                            Layout.row: 1
                            text: "Data type:"
                        }
                        Label {
                            Layout.alignment : Qt.AlignLeft
                            Layout.row: 1
                            text: "Data subtype:"
                        }
                        Label {
                            Layout.alignment : Qt.AlignLeft
                            Layout.row: 1
                            text: "Cell type:"
                        }
                    }
                    Column {
                        spacing: 0.2*margin
                        ComboBox {
                            editable: false
                            width: 300*pix
                            onActivated: {}
                            model: ListModel {
                                id: datatypeModel
                                ListElement { text: "Image" }
                                ListElement { text: "Other" }
                            }
                        }
                        ComboBox {
                            editable: false
                            width: 300*pix
                            model: ListModel {
                                id: datasubtypeModel
                                ListElement { text: "Biological image" }
                                ListElement { text: "Other" }
                            }
                        }
                        ComboBox {
                            editable: false
                            width: 300*pix
                            model: ListModel {
                                id: datasub2typeModel
                                ListElement { text: "Bacteria" }
                                ListElement { text: "Yeast" }
                                ListElement { text: "Plant" }
                                ListElement { text: "Animal" }
                            }
                        }
                    }
                }
                Label {
                    id: neuralnetworksLabel
                    y: dataselectionRowLayout.height + dataselectionPane.y + 0.4*margin
                    width: dataselectionPane.width - dataselectionPane.padding*2
                    text: "Neural networks:"
                    padding: 0.2*margin
                    leftPadding: 0.2*margin
                    background: Rectangle {
                        anchors.fill: parent.fill
                        color: "transparent"
                        border.color: defaultpalette.border
                        border.width: 2*pix
                    }
                }
                Frame {
                    id: neuralnetworksFrame
                    y: neuralnetworksLabel.y + neuralnetworksLabel.height - 2*pix
                    height: 500*pix
                    width: dataselectionPane.width - dataselectionPane.padding*2
                    backgroundColor: defaultpalette.listview
                    padding: 0
                    ScrollableItem {
                        id: neuralnetworksFlickable
                        y: 2*pix
                        height: 500*pix - 4*pix
                        width: dataselectionPane.width - 2*dataselectionPane.padding - 2*pix
                        contentHeight: neuralnetworksModel.count*buttonHeight
                        scrollbarColor: defaultpalette.window2
                        backgroundColor: defaultpalette.listview
                        ScrollBar.horizontal.visible: false
                        clip: true
                        ListView {
                            id: neuralnetworksView
                            height: childrenRect.height
                            spacing: 0
                            boundsBehavior: Flickable.StopAtBounds
                            model: ListModel {id: neuralnetworksModel
                                              ListElement{
                                                  name: "Element1"
                                              }
                                              ListElement{
                                                  name: "Element2"
                                              }
                                              ListElement{
                                                  name: "Element3"
                                              }
                            }
                            delegate: ButtonNN {
                                    x: 2*pix
                                    width: dataselectionPane.width - 2*dataselectionPane.padding -
                                           24*pix
                                    height: buttonHeight
                                    onPressed: {}
                                    Label {
                                        y: 14*pix
                                        leftPadding: 14*pix
                                        text: name
                                    }
                            }
                        }
                    }
                }
            }
            Column {
                Label {
                    id: nameLabel
                    text: "Element"
                    font.bold: true
                    font.pointSize: 12*pix
                    padding: 0.4*margin
                    leftPadding: 0.6*margin
                    bottomPadding: 0.45*margin
                }
                ScrollableItem {
                    id: dataScrollableItem
                    width : window.width - dataselectionPane.width - 4*pix - 0.3*margin
                    height : window.height - nameLabel.height - 0.6*margin
                    contentWidth: window.width - dataselectionPane.width - 16*pix - 0.4*margin
                    contentHeight: dataPane.height
                    showBackground: false
                    backgroundColor: defaultpalette.window
                    clip: true
                    Pane {
                        id: dataPane
                        width: window.width - dataselectionPane.width - 16*pix
                        height: dataColumn.height
                        padding: 0.4*margin
                        leftPadding: 0.6*margin
                        topPadding: 0
                        bottomPadding: 0
                        backgroundColor: defaultpalette.window
                        Column {
                            id: dataColumn
                            Label {
                                text: "Preview:"
                                font.bold: true
                                bottomPadding: 0.3*margin
                            }
                            Rectangle {
                                width: dataPane.width - 2*dataPane.padding
                                height: 200
                            }
                            Label {
                                topPadding: 0.4*margin
                                text: "Description:"
                                font.bold: true
                            }
                            TextArea {
                                id: descriptionsTextArea
                                width: dataPane.width - 2*dataPane.padding
                                readOnly: true
                                wrapMode: TextEdit.WordWrap
                                horizontalAlignment: TextEdit.AlignJustify
                                text: "\n\n\n\n"
                            }
                            Label {
                                topPadding: 0.4*margin
                                text: "Architecture variants:"
                                font.bold: true
                                bottomPadding: 0.4*margin
                            }
                            ComboBox {
                                id: variantsComboBox
                                defaultWidth: 390*pix
                                currentIndex: 0
                                model: ListModel {
                                   id: variantModel
                                   ListElement { text: "Encoder: 3; Decoder: 4" }
                                   ListElement { text: "Encoder: 5; Decoder: 6" }
                                }
                                onActivated: {}
                            }
                            Label {
                                topPadding: 0.4*margin
                                text: "Image examples:"
                                font.bold: true
                                bottomPadding: 0.3*margin
                            }
                            Pane {
                                width: dataPane.width - 2*dataPane.padding
                                height: 300*pix
                                padding: 0
                                Rectangle {anchors.fill: parent}
                            }
                        }
                    }
                }
            }
        }
    }
}










