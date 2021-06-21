
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.Layouts 1.2
import Qt.labs.platform 1.1
import "Templates"
import org.julialang 1.0


ApplicationWindow {
    id: window
    visible: true
    title: qsTr("  EasyML")
    minimumWidth: mainColumn.width
    minimumHeight: mainColumn.height
    maximumWidth: mainColumn.width
    maximumHeight: mainColumn.height

    color: defaultpalette.window

    property double margin: 0.02*Screen.width
    property double buttonWidth: 0.1*Screen.width
    property double buttonHeight: 0.03*Screen.height
    property double tabmargin: 0.5*margin
    property double pix: Screen.width/3840
    property double defaultPixelSize: 33*pix

    FolderDialog {
        id: folderDialog
        onAccepted: {
            Julia.browsefolder(folderDialog.folder)
            Qt.quit()
        }
    }

    onClosing: {
        Julia.save_settings()
        //designoptionsLoader.sourceComponent = null
    }

    Item {
        id: mainItem
        Column {
            id: mainColumn
            padding: 0.5*margin
            spacing: 0.4*margin
            Row {
                spacing: margin
                Column {
                    spacing: 0.3*margin
                    Label {
                        id: sizeLabel
                        text: "Layer rectangle size"
                        font.bold: true
                    }
                    Row {
                        spacing: 0.3*margin
                        Label {
                            id: heightLabel
                            text: "Height:"
                            topPadding: 10*pix
                        }
                        TextField {
                            id: heightTextField
                            property bool need_update: false
                            property double value: 0
                            text: Julia.get_settings(["Design","height"])
                            width: 140*pix
                            validator: RegExpValidator { regExp: /([1-2]\d{2})|([5-9]\d{1}|^$)/ }
                            onEditingFinished: {
                                value = parseFloat(text)
                                if (text.length===0) {
                                    text = Julia.get_settings(["Design","height"])
                                }
                                else {
                                    need_update = true
                                }
                            }
                        }
                    }
                    Row {
                        spacing: 0.3*margin
                        Label {
                            id: widthLabel
                            text: "Width:"
                            width: heightLabel.width
                            topPadding: 10*pix
                        }
                        TextField {
                            id: widthTextField
                            property bool need_update: false
                            property double value: 0
                            text: Julia.get_settings(["Design","width"])
                            width: 140*pix
                            validator: RegExpValidator { regExp: /([1-5]\d{2})|^$/ }
                            onEditingFinished: {
                                value = parseFloat(text)
                                if (text.length===0) {
                                    text = Julia.get_settings(["Design","width"])
                                }
                                else {
                                    need_update = true
                                }
                            }
                        }
                    }
                }
                Column {
                    spacing: 0.3*margin
                    Label {
                        id: viewOptions
                        text: "Auto-arrangement options"
                        font.bold: true
                    }
                    Row {
                        spacing: 0.3*margin
                        Label {
                            id: horizontaldistanceLabel
                            text: "Horizontal distance:"
                            topPadding: 10*pix
                        }
                        TextField {
                            id: horizontaldistanceTextField
                            property bool need_update: false
                            property double value: 0
                            text: Julia.get_settings(["Design","min_dist_x"])
                            width: 140*pix
                            validator: RegExpValidator { regExp: /([1-9]\d{0,2})|0/ }
                            onEditingFinished: {
                                value = parseFloat(text)
                                if (text.length===0) {
                                    text = Julia.get_settings(["Design","min_dist_x"])
                                }
                                else {
                                    need_update = true
                                }
                            }
                        }
                    }
                    Row {
                        spacing: 0.3*margin
                        Label {
                            id: verticaldistanceLabel
                            text: "Vertical distance:"
                            topPadding: 10*pix
                            width: horizontaldistanceLabel.width
                        }
                        TextField {
                            id: verticaldistanceTextField
                            property bool need_update: false
                            property double value: 0
                            text: Julia.get_settings(["Design","min_dist_y"])
                            width: 140*pix
                            validator: RegExpValidator { regExp: /([1-9]\d{0,2})|0/ }
                            onEditingFinished: {
                                value = parseFloat(text)
                                if (text.length===0) {
                                    text = Julia.get_settings(["Design","min_dist_y"])
                                }
                                else {
                                    need_update = true
                                }
                            }
                        }
                    }
                }
            }
            Button {
                text: "Apply"
                width: buttonWidth/2
                height: buttonHeight
                anchors.horizontalCenter: mainColumn.horizontalCenter
                onClicked: {
                    var num = layers.children.length
                    if (heightTextField.need_update) {
                        var value = heightTextField.value
                        if (layers.children[0].height!==value) {
                            Julia.set_data(["Training","Design","height"],value)
                            for (var i=0;i<num;i++) {
                                layers.children[i].height = value
                            }
                        }
                    }
                    if (widthTextField.need_update) {
                        value = widthTextField.value
                        if (layers.children[0].width!==value) {
                            Julia.set_data(["Training","Design","width"],value)
                            for (i=0;i<num;i++) {
                                layers.children[i].width = value
                            }
                        }
                    }
                    if (horizontaldistanceTextField.need_update) {
                        value = horizontaldistanceTextField.value
                        Julia.set_data(["Training","Design","min_dist_x"],value)
                    }
                    if (verticaldistanceTextField.need_update) {
                        value = verticaldistanceTextField.value
                        Julia.set_data(["Training","Design","min_dist_y"],value)
                    }
                    var data = Julia.arrange()
                    var coordinates = data[0]
                    var inds = data[1]
                    for (i=0;i<inds.length;i++) {
                        var layer = layers.children[inds[i]]
                        layer.x = coordinates[i][0]
                        layer.y = coordinates[i][1]
                    }
                    updateMainPane(layers.children[0])
                    updateConnections()
                    Julia.save_data()
                }
            }
        }
        MouseArea {
            width: window.width
            height: window.height
            onPressed: {
                focus = true
                mouse.accepted = false
            }
            onReleased: mouse.accepted = false;
            onDoubleClicked: mouse.accepted = false;
            onPositionChanged: mouse.accepted = false;
            onPressAndHold: mouse.accepted = false;
            onClicked: mouse.accepted = false;
        }
    }
}
