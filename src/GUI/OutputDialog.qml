
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
    title: qsTr("  Open Machine Learning Software")
    minimumWidth: gridLayout.width
    minimumHeight: 800*pix
    maximumWidth: gridLayout.width
    maximumHeight: gridLayout.height

    //---Universal property block-----------------------------------------------
    property double pix: Screen.width/3840
    property double margin: 78*pix
    property double tabmargin: 0.5*margin
    property double buttonWidth: 384*pix
    property double buttonHeight: 65*pix
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

    //--------------------------------------------------------------------------

    color: defaultpalette.window

    property bool terminate: false

    onClosing: {
        var url = Julia.get_settings(["Application","model_url"])
        Julia.save_model(url)
        // applicationfeaturedialogLoader.sourceComponent = null
    }

    GridLayout {
        id: gridLayout
        RowLayout {
            id: rowlayout
            Pane {
                id: menuPane
                spacing: 0
                padding: -1
                width: 1.3*buttonWidth
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
                        model: [{"name": "Mask", "stackview": maskView},
                            {"name": "Area", "stackview": areaView},
                            {"name": "Volume", "stackview": volumeView}]
                        delegate : MenuButton {
                            id: general
                            width: 1.5*buttonWidth
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
                Layout.row: 2
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 2.125*buttonWidth
                StackView {
                    id: stack
                    initialItem: maskView
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
                    id: maskView
                    Column {
                        spacing: 0.2*margin
                        Label {
                            text: "Save masks:"
                        }
                        CheckBox {
                            text: "Output mask"
                            Component.onCompleted: {
                                checkState = Julia.get_output(["Mask","mask"],indTree+1)
                                    ? Qt.Checked : Qt.Unchecked
                            }
                            onClicked: {
                                var value = checkState===Qt.Checked ? true : false
                                Julia.set_output(["Mask","mask"],indTree+1,value)
                            }
                        }
                        CheckBox {
                            visible: false
                            text: "Border mask"
                            Component.onCompleted: {
                                if (Julia.get_feature_field(indTree+1,"border")) {
                                    visible = true
                                    checkState = Julia.get_output(["Mask","mask_border"],indTree+1)
                                        ? Qt.Checked : Qt.Unchecked
                                }
                            }
                            onClicked: {
                                var value = checkState===Qt.Checked ? true : false
                                Julia.set_output(["Mask","mask_border"],indTree+1,value)
                            }
                        }
                        CheckBox {
                            visible: false
                            text: "Applied border mask"
                            Component.onCompleted: {
                                if (Julia.get_feature_field(indTree+1,"border")) {
                                    visible = true
                                    checkState = Julia.get_output(["Mask","mask_applied_border"],indTree+1)
                                        ? Qt.Checked : Qt.Unchecked
                                }
                            }
                            onClicked: {
                                var value = checkState===Qt.Checked ? true : false
                                Julia.set_output(["Mask","mask_applied_border"],indTree+1,value)
                            }
                        }
                    }
                }
                Component {
                    id: areaView
                    Column {
                        spacing: 0.2*margin
                        Label {
                            text: "Outputs:"
                        }
                        CheckBox {
                            id: areadistributionCheckBox
                            text: "Area distribution"
                            Component.onCompleted: {
                                checkState = Julia.get_output(["Area","area_distribution"],
                                    indTree+1) ? Qt.Checked : Qt.Unchecked
                            }
                            onClicked: {
                                var value = checkState===Qt.Checked ? true : false
                                Julia.set_output(["Area","area_distribution"],indTree+1,value)
                            }
                        }
                        CheckBox {
                            id: objareaCheckBox
                            text: "Area of objects"
                            Component.onCompleted: {
                                checkState = Julia.get_output(["Area","obj_area"],
                                    indTree+1) ? Qt.Checked : Qt.Unchecked
                            }
                            onClicked: {
                                var value = checkState===Qt.Checked ? true : false
                                Julia.set_output(["Area","obj_area"],indTree+1,value)
                            }
                        }
                        CheckBox {
                            id: objareasumCheckBox
                            text: "Sum of areas of objects"
                            Component.onCompleted: {
                                checkState = Julia.get_output(["Area","obj_area_sum"],
                                    indTree+1) ? Qt.Checked : Qt.Unchecked
                            }
                            onClicked: {
                                var value = checkState===Qt.Checked ? true : false
                                Julia.set_output(["Area","obj_area_sum"],indTree+1,value)
                            }
                        }
                        Rectangle {
                            height: 0.2*margin
                            width: 0.2*margin
                            color: defaultpalette.window
                        }
                        Label {
                            text: "Histogram options:"
                        }
                        RowLayout {
                            spacing: 0.3*margin
                            ColumnLayout {
                                spacing: 0.5*margin
                                Label {
                                    id: label
                                    text: "Binning method:"
                                }
                                Label {
                                    id: valueareaLabel
                                    text: "Value:"
                                }
                                Label {
                                    text: "Normalisation:"
                                }
                            }
                            ColumnLayout {
                                ComboBox {
                                    id: binningareaComboBox
                                    function changeLabel() {
                                        if (currentIndex===0) {
                                            valueareaLabel.visible = false
                                            widthvalueareaTextField.visible = false
                                            numvalueareaTextField.visible = false

                                        }
                                        else if (currentIndex===1) {
                                            valueareaLabel.visible = true
                                            widthvalueareaTextField.visible = true
                                            numvalueareaTextField.visible = false
                                        }
                                        else {
                                            valueareaLabel.visible = true
                                            widthvalueareaTextField.visible = false
                                            numvalueareaTextField.visible = true
                                        }
                                    }
                                    editable: false
                                    width: 0.69*buttonWidth-1*pix
                                    currentIndex: 0
                                    model: ListModel {
                                        id: binningModel
                                        ListElement {text: "Automatic"}
                                        ListElement {text: "Number of bins"}
                                        ListElement {text: "Bin width"}
                                    }
                                    Component.onCompleted: {
                                        currentIndex = Julia.get_output(
                                            ["Area","binning"],indTree+1)
                                        changeLabel()
                                    }
                                    onActivated: {
                                        Julia.set_output(["Area","binning"],indTree+1,currentIndex)
                                        changeLabel()
                                    }
                                }
                                TextField {
                                    id: numvalueareaTextField
                                    Layout.preferredWidth: 0.35*buttonWidth
                                    Layout.preferredHeight: buttonHeight
                                    text: "10"
                                    maximumLength: 5
                                    validator: IntValidator { bottom: 1; top: 99999}
                                    Component.onCompleted: {
                                        text = Julia.get_output(
                                            ["Area","value"],indTree+1)
                                    }
                                    onEditingFinished: {
                                        var value = parseFloat(text)
                                        Julia.set_output(["Area","value"],indTree+1,value)
                                    }
                                }
                                TextField {
                                    id: widthvalueareaTextField
                                    Layout.preferredWidth: 0.35*buttonWidth
                                    Layout.preferredHeight: buttonHeight
                                    text: "1"
                                    maximumLength: 5
                                    validator: DoubleValidator { bottom: 0.001; top: 99999}
                                    Component.onCompleted: {
                                        text = Julia.get_output(
                                            ["Area","value"],indTree+1)
                                    }
                                    onEditingFinished: {
                                        var value = parseFloat(text)
                                        Julia.set_output(["Area","value"],indTree+1,value)
                                    }
                                }
                                ComboBox {
                                    id: normalisationareaComboBox
                                    editable: false
                                    width: 0.69*buttonWidth-1*pix
                                    currentIndex: 0
                                    model: ListModel {
                                        id: normalisationModel
                                        ListElement {text: "pdf"}
                                        ListElement {text: "Density"}
                                        ListElement {text: "Probability"}
                                        ListElement {text: "None"}
                                    }
                                    Component.onCompleted: {
                                        currentIndex = Julia.get_output(
                                            ["Area","normalisation"],indTree+1)
                                    }
                                    onActivated: {
                                        Julia.set_output(["Area","normalisation"],indTree+1,currentIndex)
                                    }
                                }
                            }
                        }
                    }
                }
                Component {
                    id: volumeView
                    Column {
                        spacing: 0.2*margin
                        Label {
                            text: "Outputs:"
                        }
                        CheckBox {
                            id: volumedistributionCheckBox
                            text: "Volume distribution"
                            Component.onCompleted: {
                                checkState = Julia.get_output(["Volume","volume_distribution"],
                                    indTree+1) ? Qt.Checked : Qt.Unchecked
                            }
                            onClicked: {
                                var value = checkState===Qt.Checked ? true : false
                                Julia.set_output(["Volume","volume_distribution"],indTree+1,value)
                            }
                        }
                        CheckBox {
                            id: objvolumeCheckBox
                            text: "Volume of objects"
                            Component.onCompleted: {
                                checkState = Julia.get_output(["Volume","obj_volume"],
                                    indTree+1) ? Qt.Checked : Qt.Unchecked
                            }
                            onClicked: {
                                var value = checkState===Qt.Checked ? true : false
                                Julia.set_output(["Volume","obj_volume"],indTree+1,value)
                            }
                        }
                        CheckBox {
                            id: objvolumesumCheckBox
                            text: "Sum of volume of objects"
                            Component.onCompleted: {
                                checkState = Julia.get_output(
                                    ["Volume","obj_volume_sum"],indTree+1) ? Qt.Checked : Qt.Unchecked
                            }
                            onClicked: {
                                var value = checkState===Qt.Checked ? true : false
                                Julia.set_output(["Volume","obj_volume_sum"],indTree+1,value)
                            }
                        }
                        Rectangle {
                            height: 0.2*margin
                            width: 0.2*margin
                            color: defaultpalette.window
                        }

                        Label {
                            text: "Histogram options:"
                        }
                        RowLayout {
                            spacing: 0.3*margin
                            ColumnLayout {
                                spacing: 0.5*margin
                                Label {
                                    id: label
                                    text: "Binning method:"
                                }
                                Label {
                                    id: valuevolumeLabel
                                    text: "Value:"
                                }
                                Label {
                                    text: "Normalisation:"
                                }
                            }
                            ColumnLayout {
                                ComboBox {
                                    id: binningvolumeComboBox
                                    function changeLabel() {
                                        if (currentIndex===0) {
                                            valuevolumeLabel.visible = false
                                            widthvaluevolumeTextField.visible = false
                                            numvaluevolumeTextField.visible = false
                                        }
                                        else if (currentIndex===1) {
                                            valuevolumeLabel.visible = true
                                            widthvaluevolumeTextField.visible = true
                                            numvaluevolumeTextField.visible = false
                                        }
                                        else {
                                            valuevolumeLabel.visible = true
                                            widthvaluevolumeTextField.visible = false
                                            numvaluevolumeTextField.visible = true
                                        }
                                    }
                                    editable: false
                                    width: 0.69*buttonWidth-1*pix
                                    currentIndex: 0
                                    model: ListModel {
                                        id: binningModel
                                        ListElement {text: "Automatic"}
                                        ListElement {text: "Number of bins"}
                                        ListElement {text: "Bin width"}
                                    }
                                    Component.onCompleted: {
                                        currentIndex = Julia.get_output(
                                            ["Volume","binning"],indTree+1)
                                        changeLabel()
                                    }
                                    onActivated: {
                                        Julia.set_output(["Volume","binning"],indTree+1,currentIndex)
                                        changeLabel()
                                    }
                                }
                                TextField {
                                    id: numvaluevolumeTextField
                                    Layout.preferredWidth: 0.35*buttonWidth
                                    Layout.preferredHeight: buttonHeight
                                    text: "10"
                                    maximumLength: 5
                                    validator: IntValidator { bottom: 1; top: 99999}
                                    Component.onCompleted: {
                                        text = Julia.get_output(
                                            ["Volume","value"],indTree+1)
                                    }
                                    onEditingFinished: {
                                        var value = parseFloat(text)
                                        Julia.set_output(["Volume","value"],indTree+1,value)
                                    }
                                }
                                TextField {
                                    id: widthvaluevolumeTextField
                                    Layout.preferredWidth: 0.35*buttonWidth
                                    Layout.preferredHeight: buttonHeight
                                    text: "1"
                                    maximumLength: 5
                                    validator: DoubleValidator { bottom: 0.001; top: 99999}
                                    Component.onCompleted: {
                                        text = Julia.get_output(
                                            ["Volume","value"],indTree+1)
                                    }
                                    onEditingFinished: {
                                        var value = parseFloat(text)
                                        Julia.set_output(["Volume","value"],indTree+1,value)
                                    }
                                }
                                ComboBox {
                                    id: normalisationvolumeComboBox
                                    editable: false
                                    width: 0.69*buttonWidth-1*pix
                                    currentIndex: 0
                                    model: ListModel {
                                        id: normalisationModel
                                        ListElement {text: "pdf"}
                                        ListElement {text: "Density"}
                                        ListElement {text: "Probability"}
                                        ListElement {text: "None"}
                                    }
                                    Component.onCompleted: {
                                        currentIndex = Julia.get_output(
                                            ["Volume","normalisation"],indTree+1)
                                    }
                                    onActivated: {
                                        Julia.set_output(["Volume","normalisation"],indTree+1,currentIndex)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        MouseArea {
            id: backgroundMouseArea
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
