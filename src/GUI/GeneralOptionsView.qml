import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.Layouts 1.2
import Qt.labs.platform 1.1
import "Templates"
import org.julialang 1.0

Component {
    id: generalOptionsView
    StackView {
        id: stack
        initialItem: hardwareView
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
                    model: [{"name": "Hardware resources", "stackview": hardwareView},
                        {"name": "About", "stackview": aboutView}]
                    delegate : MenuButton {
                        id: general
                        //width: 0.8*buttonWidth
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
            id: hardwareView
            Column {
                spacing: 0.2*margin
                Row {
                    spacing: 0.55*margin
                    Label {
                        text: "Allow GPU:"
                        width: allowedcpucoresLabel.width
                    }
                    CheckBox {
                        visible: Julia.has_cuda()
                        padding: 0
                        width: height-18*pix
                        checkState: Julia.get_settings(
                                   ["Options","Hardware_resources","allow_GPU"]) ?
                                   Qt.Checked : Qt.Unchecked
                        onClicked: {
                            var value = checkState==Qt.Checked ? true : false
                            Julia.set_data(
                                ["Options","Hardware_resources","allow_GPU"],
                                value)
                        }
                    }
                    Label {
                        visible: !Julia.has_cuda()
                        text: "No CUDA capable device found!"
                        topPadding: 10*pix
                    }
                }
                Row {
                    visible: false
                    spacing: 0.4*margin
                    Label {
                        id: allowedcpucoresLabel
                        text: "Allowed CPU cores:"
                        topPadding: 10*pix
                    }
                    ComboBox {
                        editable: false
                        width: 0.3*buttonWidth
                        model: ListModel {id: coresModel}
                        onActivated: {
                            Julia.set_data(
                                ["Options","Hardware_resources","num_cores"],
                                parseInt(currentText,10))
                        }
                        Component.onCompleted: {
                            var val = Julia.get_settings(
                                ["Options","Hardware_resources","num_cores"])
                            var num_cores = Julia.num_cores()
                            for (var i=0;i<num_cores;i++) {
                                coresModel.append({"text": i+1})
                                var num = parseInt(coresModel.get(i).text,10)
                                if (num===val) {
                                    currentIndex = i
                                }
                            }
                            if (currentIndex===-1) {
                                currentIndex = num_cores-1
                            }
                        }
                    }
                }
            }
        }
        Component {
                id: aboutView
                Column {
                    spacing: 0.2*margin
                    TextArea {
                        id: descriptionTextArea
                        width: panel_width
                        font.pointSize: 10
                        font.family: "Proxima Nova"
                        readOnly: true
                        padding: 0
                        anchors.left: parent.left
                        wrapMode: TextEdit.WordWrap
                        horizontalAlignment: TextEdit.AlignJustify
                        text: "Software for creation and application of machine "+
                               "learning models without the need for programming.\n\n"+
                                "Copyright (C) 2020 Open Machine Learning MTÜ\n"
                    }
                    Label {
                        id: licenseLabel
                        text: "License:"
                        font.pointSize: 10
                        bottomPadding: 0.1*margin
                    }
                    Flickable {
                        clip: true
                        //anchors.top: licenseLabel.bottom
                        leftMargin: 0
                        height: 600*pix
                        width: contentWidth
                        contentWidth: licenseTextArea.width;
                        contentHeight: licenseTextArea.height
                        boundsBehavior: Flickable.StopAtBounds
                        /*ScrollBar.vertical: ScrollBar{
                            id: vertical
                            policy: ScrollBar.AsNeeded
                            contentItem:
                                Rectangle {
                                    implicitWidth: 25*pix
                                    implicitHeight: 100
                                    color: "transparent"
                                    Rectangle {
                                        anchors.right: parent.right
                                        implicitWidth: 10*pix
                                        implicitHeight: parent.height
                                        radius: width / 2
                                        color: defaultpalette.border
                                    }
                            }
                        }*/
                        TextArea {
                            id: licenseTextArea
                            width: panel_width
                            font.pointSize: 10
                            font.family: "Proxima Nova"
                            readOnly: true
                            leftPadding: 0
                            rightPadding: 20*pix
                            anchors.left: parent.left
                            wrapMode: TextEdit.WordWrap
                            horizontalAlignment: TextEdit.AlignJustify
                            text: "This software is dual-licensed. All Julia code is "+
                                  "licensed under the MIT license and all QML code under"+
                                  " the GPL-3.0 license."
                        }
                    }
                }
        }
        Component.onCompleted: {
            repeaterComponent.createObject(window.header);
        }
    }
}

