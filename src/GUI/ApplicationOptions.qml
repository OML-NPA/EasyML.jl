
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
    minimumWidth: 1480*pix
    minimumHeight: 800*pix
    maximumWidth: rowLayout.width
    maximumHeight: rowLayout.height
    
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

     onClosing: { 
        Julia.save_options()
        //applicationoptionsLoader.sourceComponent = null
     }

    RowLayout {
        id: rowLayout
        RowLayout {
            id: rowlayout
            Pane {
                id: menuPane
                spacing: 0
                padding: -1
                width: buttonWidth
                height: window.height
                topPadding: tabmargin/2
                bottomPadding: tabmargin/2
                backgroundColor: defaultpalette.window2

                Column {
                    id: menubuttonColumn
                    spacing: 0
                    Repeater {
                        id: menubuttonRepeater
                        Component.onCompleted: {menubuttonRepeater.itemAt(0).buttonfocus = true}
                        model: [{"name": "General", "stackview": generalView}]
                        delegate : MenuButton {
                            id: general
                            width: buttonWidth
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
            ColumnLayout {
                id: columnLayout
                Layout.margins: 0.5*margin
                StackView {
                    id: stack
                    initialItem: generalView
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
                    id: generalView
                    Column {
                        spacing: 0.5*margin
                        ColumnLayout {
                            spacing: 0.4*margin
                            RowLayout {
                                spacing: 0.3*margin
                                ColumnLayout {
                                    Layout.alignment : Qt.AlignHCenter
                                    spacing: 0.5*margin
                                    Label {
                                        Layout.alignment : Qt.AlignLeft
                                        text: "Save path:"
                                    }
                                    Label {
                                        Layout.alignment : Qt.AlignLeft
                                        text: "Analyse by:"
                                    }
                                    Label {
                                        Layout.alignment : Qt.AlignLeft
                                        text: "Output data type:"
                                    }
                                    Label {
                                        Layout.alignment : Qt.AlignLeft
                                        text: "Output image type:"
                                    }
                                    /*Label {
                                        Layout.alignment : Qt.AlignLeft
                                        text: "Downsize images:"
                                        bottomPadding: 0.05*margin
                                    }
                                    Label {
                                        Layout.alignment : Qt.AlignLeft
                                        text: "Reduce framerate (video):"
                                        bottomPadding: 0.05*margin
                                    }*/
                                }
                                Column {
                                    spacing: 0.15*margin
                                    Row {
                                        spacing: 0.25*margin
                                        TextField {
                                            id: savepathTextField
                                            width: buttonWidth
                                            height: buttonHeight
                                            readOnly: true
                                            Component.onCompleted: {
                                                text = Julia.get_options(["ApplicationOptions","savepath"])
                                                if (text==="") {
                                                    text = Julia.fix_slashes(Julia.pwd()+"/Output data")
                                                    Julia.set_options(["ApplicationOptions","savepath"],text)
                                                }
                                                applicationoptionsFolderDialog.currentFolder = text
                                            }
                                            FolderDialog {
                                                id: applicationoptionsFolderDialog
                                                onAccepted: {
                                                    var url = stripURL(folder)
                                                    Julia.set_options(["ApplicationOptions","savepath"],url)
                                                    savepathTextField.text = url
                                                }
                                            }
                                        }
                                        Button {
                                            id: savepathButton
                                            text: "Browse"
                                            width: buttonWidth/2
                                            height: buttonHeight
                                            onClicked: {applicationoptionsFolderDialog.open()}
                                        }
                                    }
                                    ComboBox {
                                        width: 0.5*buttonWidth
                                        model: ListModel {
                                            id: analysebyModel
                                            ListElement { text: "file" }
                                            ListElement { text: "folder" }
                                        }
                                        Component.onCompleted: {
                                            currentIndex =
                                                Julia.get_options(["ApplicationOptions","apply_by"],2)
                                        }
                                        onActivated: {
                                            Julia.set_options(["ApplicationOptions","apply_by"],
                                                [currentText,currentIndex],"make_tuple")
                                        }
                                    }
                                    ComboBox {
                                        width: 0.5*buttonWidth
                                        model: ListModel {
                                            id: modelData
                                            ListElement { text: "CSV" }
                                            ListElement { text: "XLSX" }
                                            ListElement { text: "JSON" }
                                            ListElement { text: "BSON" }
                                        }
                                        Component.onCompleted: {
                                            currentIndex =
                                                Julia.get_options(["ApplicationOptions","data_type"])
                                        }
                                        onActivated: {
                                            Julia.set_options(["ApplicationOptions","data_type"],currentIndex)
                                        }
                                    }
                                    ComboBox {
                                        width: 0.5*buttonWidth
                                        model: ListModel {
                                            id: modelImages
                                            ListElement { text: "PNG" }
                                            ListElement { text: "TIFF" }
                                            ListElement { text: "BSON" }
                                        }
                                        Component.onCompleted: {
                                            currentIndex =
                                                Julia.get_options(["ApplicationOptions","image_type"])
                                        }
                                        onActivated: {
                                            Julia.set_options(["ApplicationOptions","image_type"],currentIndex)
                                        }
                                    }
                                    /*ComboBox {
                                        width: 0.5*buttonWidth
                                        model: ListModel {
                                            id: resizeModel
                                            ListElement { text: "Disable" }
                                            ListElement { text: "1.5x" }
                                            ListElement { text: "2x" }
                                            ListElement { text: "3x" }
                                            ListElement { text: "4x" }
                                        }
                                        Component.onCompleted: {
                                            currentIndex =
                                                Julia.get_options(["ApplicationOptions","downsize"])
                                        }
                                        onActivated: {
                                            Julia.set_options(
                                                ["ApplicationOptions","downsize"],currentIndex)
                                        }
                                    }
                                    ComboBox {
                                        width: 0.5*buttonWidth
                                        model: ListModel {
                                            id: skipframesModel
                                            ListElement { text: "Disable" }
                                            ListElement { text: "2x" }
                                            ListElement { text: "3x" }
                                            ListElement { text: "4x" }
                                        }
                                        Component.onCompleted: {
                                            currentIndex =
                                                Julia.get_options(["ApplicationOptions","skip_frames"])
                                        }
                                        onActivated: {
                                            Julia.set_options(
                                                ["ApplicationOptions","skip_frames"],currentIndex)
                                        }
                                    }*/
                                }
                            }
                        }
                        RowLayout {
                            spacing: 0.3*margin
                            Label {
                                text: "Scaling:"
                                bottomPadding: 0.05*margin
                            }
                            TextField {
                                Layout.preferredWidth: 0.3*buttonWidth
                                Layout.preferredHeight: buttonHeight
                                maximumLength: 6
                                validator: DoubleValidator { bottom: 0.0001; top: 999999;
                                    decimals: 4; notation: DoubleValidator.StandardNotation}
                                Component.onCompleted: {
                                    text = Julia.get_options(["ApplicationOptions","scaling"])
                                }
                                onEditingFinished: {
                                    var value = parseFloat(text)
                                    Julia.set_options(["ApplicationOptions","scaling"],value)
                                }
                            }
                            Label {
                                text: "pixels per measurment unit"
                                bottomPadding: 0.05*margin
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

}
