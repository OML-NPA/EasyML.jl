

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.Layouts 1.2
import Qt.labs.platform 1.1
import "../common/gui/templates"
import org.julialang 1.0


ApplicationWindow {
    id: window
    visible: true
    title: qsTr("  EasyML")
    minimumHeight: 750*pix
    minimumWidth: mainRow.width
    width: mainRow.width
    height: mainRow.height

    //---Universal property block-----------------------------------------------
    property double pix: 0.75*Math.sqrt(Screen.pixelDensity)/Math.sqrt(6.430366116295766)*Julia.get_options(["GlobalOptions","Graphics","scaling_factor"])
    property double margin: 78*pix
    property double tabmargin: 0.5*margin
    property double buttonWidth: 384*pix
    property double buttonHeight: 65*pix
    property double defaultPixelSize: 33*pix
    property var defaultcolors: {"light": rgbtohtml([254,254,254]),"light2": rgbtohtml([253,253,253]),
        "midlight": rgbtohtml([245,245,245]),"midlight2": rgbtohtml([240,240,240]),
        "midlight3": rgbtohtml([235,235,235]),
        "mid": rgbtohtml([220,220,220]),"middark": rgbtohtml([210,210,210]),
        "middark2": rgbtohtml([180,180,180]),"dark2": rgbtohtml([160,160,160]),
        "dark": rgbtohtml([130,130,130])}
    property var defaultpalette: {"window": defaultcolors.midlight,
                                  "window2": defaultcolors.midlight3,
                                  "button": defaultcolors.light2,
                                  "buttonhovered": defaultcolors.mid,
                                  "buttonpressed": defaultcolors.middark,
                                  "buttonborder": defaultcolors.dark2,
                                  "controlbase": defaultcolors.light,
                                  "controlborder": defaultcolors.middark2,
                                  "border": defaultcolors.dark2,
                                  "listview": defaultcolors.light
                                  }
    function rgbtohtml(colorRGB) {
        return(Qt.rgba(colorRGB[0]/255,colorRGB[1]/255,colorRGB[2]/255))
    }
    //-------------------------------------------------------------------------

    color: defaultpalette.window

    FolderDialog {
            id: folderDialog
            onAccepted: {
                Julia.browsefolder(folderDialog.folder)
                Qt.quit()
            }
    }

    onClosing: {
        Julia.save_options()
    }

    Component.onCompleted: {
        if (Julia.unit_test()) {
            function Timer() {
                return Qt.createQmlObject("import QtQuick 2.0; Timer {}", window);
            }
            function delay(delayTime, cb) {
                var timer = new Timer();
                timer.interval = delayTime;
                timer.repeat = false;
                timer.triggered.connect(cb);
                timer.start();
            }
            delay(1000, window.close)
        }
    }

    Row {
        id: mainRow
        width: menuPane.width + optionsPane.width
        height: menuPane.height
        Pane {
            id: menuPane
            spacing: 0
            width: 1.3*buttonWidth
            height: window.height
            padding: -1
            topPadding: tabmargin/2
            bottomPadding: tabmargin/2
            backgroundColor: defaultpalette.window2
            Column {
                spacing: 0
                Repeater {
                    id: menubuttonRepeater
                    Component.onCompleted: {menubuttonRepeater.itemAt(0).buttonfocus = true}
                    model: [{"name": "Images", "stackview": imagesView}]
                    delegate : MenuButton {
                        id: general
                        width: 1.3*buttonWidth + 1
                        height: 1.25*buttonHeight
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
        Pane {
            id: optionsPane
            width: 2.125*buttonWidth
            height: 600*pix
            padding: 0.5*margin
            StackView {
                id: stack
                initialItem: imagesView
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
            }

            Component {
                id: imagesView
                Column {
                    property double rowHeight: 60*pix
                    spacing: 0.4*margin
                    Row {
                        height: rowHeight
                        spacing: 0.3*margin
                        Label {
                            id: grayscaleLabel
                            text: "Convert to grayscale:"
                            width: minfrpixLabel.width
                        }
                        CheckBox {
                            id: grayscaleCheckBox
                            anchors.verticalCenter: grayscaleLabel.verticalCenter
                            padding: 0
                            width: height
                            checkState : Julia.get_model_data("input_properties","Grayscale") ?
                                        Qt.Checked : Qt.Unchecked
                            onClicked: {
                                var value = checkState==Qt.Checked ? true : false
                                Julia.set_options(
                                    ["DataPreparationOptions","Images","grayscale"],value)
                                if (value) {
                                    Julia.set_model_data("input_properties","Grayscale")
                                }
                                else {
                                    Julia.rm_model_data("input_properties","Grayscale")
                                }
                            }
                        }
                    }
                    Row {
                        height: rowHeight
                        spacing: 0.3*margin
                        Label {
                            id: cropbackgroundLabel
                            text: "Crop background:"
                            width: minfrpixLabel.width
                        }
                        CheckBox {
                            id: cropbackgroundCheckBox
                            anchors.verticalCenter: cropbackgroundLabel.verticalCenter
                            padding: 0
                            width: height
                            checkState : Julia.get_options(
                                        ["DataPreparationOptions","Images","BackgroundCropping","enabled"]) ?
                                        Qt.Checked : Qt.Unchecked
                            onClicked: {
                                var value = checkState==Qt.Checked ? true : false
                                Julia.set_options(
                                    ["DataPreparationOptions","Images","BackgroundCropping","enabled"],value)
                            }
                        }
                    }
                    Row {
                        visible: cropbackgroundCheckBox.checkState==Qt.Checked
                        height: rowHeight
                        spacing: 0.3*margin
                        Label {
                            id: thresholdLabel
                            text: "    - Threshold:"
                            width: minfrpixLabel.width
                        }
                        SpinBox {
                            anchors.verticalCenter: thresholdLabel.verticalCenter
                            id: thresholdSpinBox
                            from: 0
                            value: 100*Julia.get_options(
                                        ["DataPreparationOptions","Images","BackgroundCropping","threshold"])
                            to: 100
                            stepSize: 10
                            property real realValue
                            textFromValue: function(value, locale) {
                                realValue = value/100
                                return realValue.toLocaleString(locale,'f',1)
                            }
                            onValueModified: {
                                Julia.set_options(
                                    ["DataPreparationOptions","Images","BackgroundCropping","threshold"],realValue)
                            }
                        }
                    }
                    Row {
                        visible: cropbackgroundCheckBox.checkState==Qt.Checked
                        height: rowHeight
                        spacing: 0.3*margin
                        Label {
                            id: closingLabel
                            text: "    - Morphological closing value:"
                            width: minfrpixLabel.width
                        }
                        SpinBox {
                            anchors.verticalCenter: closingLabel.verticalCenter
                            id: closingSpinBox
                            from: 0
                            value: Julia.get_options(
                                        ["DataPreparationOptions","Images","BackgroundCropping","closing_value"])
                            to: 100
                            stepSize: 1
                            onValueModified: {
                                Julia.set_options(
                                    ["DataPreparationOptions","Images","BackgroundCropping","closing_value"],value)
                            }
                        }
                    }
                    Row {
                        height: rowHeight
                        spacing: 0.3*margin
                        Label {
                            id: minfrpixLabel
                            text: "Minimum fraction of labeled pixels:"
                        }
                        SpinBox {
                            anchors.verticalCenter: minfrpixLabel.verticalCenter
                            id: minfrpixSpinBox
                            from: 0
                            value: 100*Julia.get_options(
                                        ["DataPreparationOptions","Images","min_fr_pix"])
                            to: 100
                            stepSize: 10
                            property real realValue
                            textFromValue: function(value, locale) {
                                realValue = value/100
                                return realValue.toLocaleString(locale,'f',1)
                            }
                            onValueModified: {
                                Julia.set_options(
                                    ["DataPreparationOptions","Images","min_fr_pix"],realValue)
                            }
                        }
                    }
                    Label {
                        text: "Augmentation"
                        font.bold: true
                    }
                    Row {
                        id: mirroringLabel
                        height: rowHeight
                        spacing: 0.3*margin
                        Label {
                            text: "Mirroring:"
                            width: minfrpixLabel.width
                        }
                        CheckBox {
                            anchors.verticalCenter: mirroringLabel.verticalCenter
                            padding: 0
                            width: height
                            checkState : Julia.get_options(
                                        ["DataPreparationOptions","Images","mirroring"]) ?
                                        Qt.Checked : Qt.Unchecked
                            onClicked: {
                                var value = checkState==Qt.Checked ? true : false
                                Julia.set_options(
                                    ["DataPreparationOptions","Images","mirroring"],value)
                            }
                        }
                    }
                    Row {
                        height: rowHeight
                        spacing: 0.3*margin
                        Label {
                            id: rotationLabel
                            text: "Rotation (number of angles):"
                            width: minfrpixLabel.width
                        }
                        SpinBox {
                            anchors.verticalCenter: rotationLabel.verticalCenter
                            id: numanglesSpinBox
                            from: 1
                            value: Julia.get_options(
                                        ["DataPreparationOptions","Images","num_angles"])
                            to: 10
                            onValueModified: {
                                Julia.set_options(
                                    ["DataPreparationOptions","Images","num_angles"],value)
                            }
                        }
                    }
                }
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