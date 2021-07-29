
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.Layouts 1.2
import Qt.labs.platform 1.1
import "templates"
import org.julialang 1.0


ApplicationWindow {
    id: window
    visible: true
    title: qsTr("EasyML")
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
            function click1() {menubuttonRepeater.itemAt(0).clicked(null)}
            function exit() {window.close()}
            delay(100, click1)
            delay(500, exit)
        }
    }
    onClosing: {
        Julia.save_options()
    }

    Row {
        id: mainRow
        width: menuPane.width + optionsPane.width
        height: menuPane.height
        Pane {
            id: menuPane
            spacing: 0
            width: 1.3*buttonWidth
            height: 600*pix
            padding: -1
            topPadding: tabmargin/2
            bottomPadding: tabmargin/2
            backgroundColor: defaultpalette.window2
            Column {
                spacing: 0
                Repeater {
                    id: menubuttonRepeater
                    Component.onCompleted: {menubuttonRepeater.itemAt(0).buttonfocus = true}
                    model: [{"name": "Graphics", "stackview": graphicsView},
                        {"name": "Hardware resources", "stackview": hardwareresourcesView}]
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
                initialItem: graphicsView
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
                id: graphicsView
                Column {
                    spacing: 0.4*margin
                    property double rowHeight: 60*pix
                    Row {
                        height: rowHeight
                        spacing: 0.3*margin
                        Label {
                            id: guiscalingLabel
                            text: "GUI scaling:"
                        }
                        SpinBox {
                            anchors.verticalCenter: guiscalingLabel.verticalCenter
                            from: 5
                            value: 100
                            to: 400
                            stepSize: 5
                            property real realValue
                            textFromValue: function(value, locale) {
                                realValue = value/100
                                return realValue.toLocaleString(locale,'f',2)
                            }
                            onValueModified: {
                                Julia.set_options(
                                    ["GlobalOptions","Graphics","scaling_factor"],realValue)
                                pix = 0.75*Math.sqrt(Screen.pixelDensity)/Math.sqrt(6.430366116295766)*Julia.get_options(["GlobalOptions","Graphics","scaling_factor"])
                                window.width = mainRow.width
                                window.height = mainRow.height
                            }
                        }
                    }
                }
            }

            Component {
                id: hardwareresourcesView
                Column {
                    spacing: 0.4*margin
                    property double rowHeight: 60*pix
                    Row {
                        height: rowHeight
                        spacing: 0.3*margin
                        Label {
                            id: usegpuLabel
                            text: "Allow GPU:"
                            width: numthreadsLabel.width
                        }
                        CheckBox {
                            anchors.verticalCenter: usegpuLabel.verticalCenter
                            padding: 0
                            width: height
                            checkState : Julia.get_options(
                                        ["GlobalOptions","HardwareResources","allow_GPU"]) ?
                                        Qt.Checked : Qt.Unchecked
                            onClicked: {
                                var value = checkState==Qt.Checked ? true : false
                                Julia.set_options(
                                    ["GlobalOptions","HardwareResources","allow_GPU"],value)
                            }
                        }
                    }
                    Row {
                        height: rowHeight
                        spacing: 0.3*margin
                        Label {
                            id: numthreadsLabel
                            text: "Number of threads:"
                        }
                        SpinBox {
                            anchors.verticalCenter: numthreadsLabel.verticalCenter
                            from: 1
                            value: Julia.get_options(
                                        ["GlobalOptions","HardwareResources","num_threads"])
                            to: Julia.max_num_threads()
                            stepSize: 1
                            editable: true
                            onValueModified: {
                                Julia.set_options(
                                    ["GlobalOptions","HardwareResources","num_threads"],value)
                            }
                        }
                    }
                    Row {
                        height: rowHeight
                        spacing: 0.3*margin
                        Label {
                            id: numslicesLabel
                            text: "Number of slices:"
                            width: numthreadsLabel.width
                        }
                        SpinBox {
                            id: numslicesSpinBox
                            anchors.verticalCenter: numslicesLabel.verticalCenter
                            from: 1
                            value: Julia.get_options(
                                        ["GlobalOptions","HardwareResources","num_slices"])
                            to: 100
                            stepSize: 1
                            editable: true
                            onValueModified: {
                                Julia.set_options(
                                    ["GlobalOptions","HardwareResources","num_slices"],value)
                            }
                        }
                    }
                    Row {
                        visible: numslicesSpinBox.value>1
                        height: rowHeight
                        spacing: 0.3*margin
                        Label {
                            id: offsetLabel
                            text: "Offset:"
                            width: numthreadsLabel.width
                        }
                        SpinBox {
                            anchors.verticalCenter: offsetLabel.verticalCenter
                            from: 0
                            value: Julia.get_options(
                                        ["GlobalOptions","HardwareResources","offset"])
                            to: 100
                            stepSize: 1
                            editable: true
                            onValueModified: {
                                Julia.set_options(
                                    ["GlobalOptions","HardwareResources","offset"],value)
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
