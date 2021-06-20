
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
    minimumWidth: gridLayout.width
    minimumHeight: 600*pix
    maximumWidth: gridLayout.width
    maximumHeight: gridLayout.height

    //---Universal property block-----------------------------------------------
    property double pix: Screen.width/3840
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
        //trainingoptionsLoader.sourceComponent = null
        Julia.save_settings()
    }


    GridLayout {
        id: gridLayout
        RowLayout {
            id: rowlayout
            Pane {
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
                        model: [{"name": "General", "stackview": generalView},
                            {"name": "Testing", "stackview": testingView},
                            {"name": "Processing", "stackview": processingView},
                            {"name": "Hyperparameters", "stackview": hyperparametersView},]
                        delegate : MenuButton {
                            id: general
                            width: 1.3*buttonWidth
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
                        property double rowHeight: 60*pix
                        spacing: 0.4*margin
                        Row {
                            height: rowHeight
                            spacing: 0.3*margin
                            Label {
                                id: usegpuLabel
                                text: "Allow GPU:"
                                width: weightaccuracyLabel.width
                            }
                            CheckBox {
                                anchors.verticalCenter: usegpuLabel.verticalCenter
                                padding: 0
                                width: height
                                checkState : Julia.get_settings(
                                           ["Training","Options","General","allow_GPU"]) ?
                                           Qt.Checked : Qt.Unchecked
                                onClicked: {
                                    var value = checkState==Qt.Checked ? true : false
                                    Julia.set_settings(
                                        ["Training","Options","General","allow_GPU"],
                                        value)
                                }
                            }
                        }
                        Label {
                            text: "Accuracy"
                            font.bold: true
                        }
                        Row {
                            height: rowHeight
                            spacing: 0.3*margin
                            Label {
                                id: weightaccuracyLabel
                                text: "Weight accuracy:"
                            }
                            CheckBox {
                                id: weightaccuracyCheckBox
                                anchors.verticalCenter: weightaccuracyLabel.verticalCenter
                                padding: 0
                                width: height
                                checkState : Julia.get_settings(
                                           ["Training","Options","General","weight_accuracy"]) ?
                                           Qt.Checked : Qt.Unchecked
                                onClicked: {
                                    var value = checkState==Qt.Checked ? true : false
                                    Julia.set_settings(
                                        ["Training","Options","General","weight_accuracy"],
                                        value)
                                }
                            }
                        }
                        Row {
                            height: rowHeight
                            visible: weightaccuracyCheckBox.checkState==Qt.Checked ? true : false
                            Label {
                                id: modeLabel
                                text: "Mode:"
                                width: weightaccuracyLabel.width + 20*pix
                            }
                            ComboBox {
                                id: optimisersComboBox
                                anchors.verticalCenter: modeLabel.verticalCenter
                                editable: false
                                width: 0.4*buttonWidth
                                model: ListModel {
                                    id: modeModel
                                }
                                property var modes: ["Auto","Manual"]
                                onActivated: {
                                    if (currentIndex==0) {
                                        Julia.set_settings(
                                            ["Training","Options","General","manual_weight_accuracy"],false)
                                    }
                                    else {
                                        Julia.set_settings(
                                            ["Training","Options","General","manual_weight_accuracy"],true)
                                    }
                                }
                                Component.onCompleted: {
                                    for (var i=0;i<modes.length;i++) {
                                        modeModel.append({"name": modes[i]})
                                    }
                                    var mode = Julia.get_settings(
                                        ["Training","Options","General","manual_weight_accuracy"])
                                    
                                    if (mode) {
                                        currentIndex = 1
                                    }
                                    else {
                                        currentIndex = 0
                                    }
                                    
                                }
                            }
                        }
                    }
                }

                Component {
                    id: testingView
                    Column {
                        property double rowHeight: 60*pix
                        spacing: 0.4*margin
                        Row {
                            height: rowHeight
                            Label {
                                id: datapreparationmodeLabel
                                text: "Data preparation mode:"
                                width: testingfrLabel.width + 20*pix
                            }
                            ComboBox {
                                id: datapreparationmodeComboBox
                                anchors.verticalCenter: datapreparationmodeLabel.verticalCenter
                                editable: false
                                width: 0.4*buttonWidth
                                model: ListModel {
                                    id: datapreparationmodeModel
                                }
                                property var modes: ["Auto","Manual"]
                                onActivated: {
                                    if (currentIndex==0) {
                                        Julia.set_settings(
                                            ["Training","Options","Testing","manual_testing_data"],false)
                                    }
                                    else {
                                        Julia.set_settings(
                                            ["Training","Options","Testing","manual_testing_data"],true)
                                    }
                                }
                                Component.onCompleted: {
                                    for (var i=0;i<modes.length;i++) {
                                        datapreparationmodeModel.append({"name": modes[i]})
                                    }
                                    var mode = Julia.get_settings(
                                        ["Training","Options","Testing","manual_testing_data"])
                                    
                                    if (mode) {
                                        currentIndex = 1
                                    }
                                    else {
                                        currentIndex = 0
                                    }
                                    
                                }
                            }
                        }
                        Row {
                            height: rowHeight
                            spacing: 0.3*margin
                            visible: datapreparationmodeComboBox.currentIndex==0 ? true : false
                            Label {
                                id: testdatafractionLabel
                                text: "Test data fraction:"
                                width: testingfrLabel.width
                            }
                            SpinBox {
                                anchors.verticalCenter: testdatafractionLabel.verticalCenter
                                from: 0
                                value: 100*Julia.get_settings(
                                           ["Training","Options","Testing","test_data_fraction"])
                                to: 99
                                stepSize: 5
                                editable: true
                                property real realValue
                                textFromValue: function(value, locale) {
                                    realValue = value/100
                                    return realValue.toLocaleString(locale,'f',2)
                                }
                                onValueModified: {
                                    Julia.set_settings(
                                        ["Training","Options","Testing","test_data_fraction"],
                                        value/100)
                                }
                            }
                        }
                        Row {
                            height: rowHeight
                            spacing: 0.3*margin
                            visible: datapreparationmodeComboBox.currentIndex==0 ? true : false
                            Label {
                                id: testingfrLabel
                                text: "Number of tests (per epoch):"
                            }
                            SpinBox {
                                from: 0
                                value: Julia.get_settings(
                                           ["Training","Options","Testing","num_tests"])
                                to: 10000
                                stepSize: 1
                                editable: true
                                onValueModified: {
                                    Julia.set_settings(
                                        ["Training","Options","Testing","num_tests"],value)
                                }
                            }
                        }
                    }
                }

                Component {
                    id: processingView
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
                                anchors.verticalCenter: grayscaleLabel.verticalCenter
                                padding: 0
                                width: height
                                checkState : Julia.get_settings(
                                           ["Training","Options","Processing","grayscale"]) ?
                                           Qt.Checked : Qt.Unchecked
                                onClicked: {
                                    var value = checkState==Qt.Checked ? true : false
                                    Julia.set_settings(
                                        ["Training","Options","Processing","grayscale"],
                                        value)
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
                                checkState : Julia.get_settings(
                                           ["Training","Options","Processing","mirroring"]) ?
                                           Qt.Checked : Qt.Unchecked
                                onClicked: {
                                    var value = checkState==Qt.Checked ? true : false
                                    Julia.set_settings(
                                        ["Training","Options","Processing","mirroring"],
                                        value)
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
                                value: Julia.get_settings(
                                           ["Training","Options","Processing","num_angles"])
                                to: 10
                                onValueModified: {
                                    Julia.set_settings(
                                        ["Training","Options","Processing","num_angles"],value)
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
                                value: 100*Julia.get_settings(
                                           ["Training","Options","Processing","min_fr_pix"])
                                to: 100
                                stepSize: 10
                                property real realValue
                                textFromValue: function(value, locale) {
                                    realValue = value/100
                                    return realValue.toLocaleString(locale,'f',1)
                                }
                                onValueModified: {
                                    Julia.set_settings(
                                        ["Training","Options","Processing","min_fr_pix"],
                                        realValue)
                                }
                            }
                        }
                    }
                }
                Component {
                    id: hyperparametersView
                    Column {
                        property double rowHeight: 60*pix
                        spacing: 0.4*margin
                        Row {
                            height: rowHeight
                            spacing: 0.3*margin
                            Label {
                                id: optimiserLabel
                                text: "Optimiser:"
                                width: numberofepochsLabel.width
                            }
                            ComboBox {
                                id: optimisersComboBox
                                anchors.verticalCenter: optimiserLabel.verticalCenter
                                editable: false
                                width: 0.6*buttonWidth
                                topPadding: -100
                                bottomPadding: -100
                                currentIndex: 4
                                model: ListModel {
                                    id: optimisersModel
                                }
                                property var optimisers: ["Stochastic","Momentum",
                                    "Nesterov","RMSProp","ADAM","RADAM","AdaMax",
                                    "ADAGrad","ADADelta","AMSGrad","NADAM","ADAMW"]
                                property var allow_lr: [true,true,true,true,true,true,true,
                                    true,false,true,true,true]
                                onActivated: {
                                    Julia.set_settings(
                                        ["Training","Options","Hyperparameters","optimiser"],
                                        [currentText,currentIndex+1],"make_tuple")
                                    Julia.set_settings(
                                        ["Training","Options","Hyperparameters","allow_lr_change"],
                                        allow_lr[currentIndex])
                                    change_params()
                                }
                                Component.onCompleted: {
                                    for (var i=0;i<optimisers.length;i++) {
                                        optimisersModel.append({"name": optimisers[i]})
                                    }
                                    var index = Julia.get_settings(
                                        ["Training","Options","Hyperparameters","optimiser"],2)
                                    currentIndex = index-1
                                    change_params()
                                }
                                function change_params() {
                                    var values = Julia.get_settings(
                                        ["Training","Options","Hyperparameters","optimiser_params"])
                                    values = values[currentIndex]
                                    var names = Julia.get_settings(
                                        ["Training","Options","Hyperparameters","optimiser_params_names"])
                                    names = names[currentIndex]
                                    param1TextField.visible = false
                                    param2TextField.visible = false
                                    param3TextField.visible = false
                                    param1Label.visible = false
                                    param2Label.visible = false
                                    param3Label.visible = false
                                    if (names.length>0) {
                                        param1Label.text = names[0]+":"
                                        param1TextField.text = values[0]
                                        param1Label.visible = true
                                        param1TextField.visible = true
                                    }
                                    if (names.length>1) {
                                        param2Label.text = names[1]+":"
                                        param2TextField.text = values[1]
                                        param2Label.visible = true
                                        param2TextField.visible = true
                                    }
                                    if (names.length>2) {
                                        param3Label.text = names[2]+":"
                                        param3TextField.text = values[2]
                                        param3Label.visible = true
                                        param3TextField.visible = true
                                    }
                                    var visibility = allow_lr[currentIndex]
                                    learningrateLabel.visible = visibility
                                    learningrateSpinBox.visible = visibility
                                }
                            }
                        }
                        Row {
                            height: rowHeight
                            spacing: 0.3*margin
                            Label {
                                id: param1Label
                                text: ""
                                width: numberofepochsLabel.width
                            }
                            TextField {
                                id: param1TextField
                                anchors.verticalCenter: param1Label.verticalCenter
                                width: 140*pix
                                visible: false
                                validator: RegExpValidator { regExp: /(0.\d{1,3}|0)/ }
                                onEditingFinished: {
                                    Julia.set_settings(
                                        ["Training","Options","Hyperparameters","optimiser_params"],
                                        optimisersComboBox.currentIndex+1,1,parseFloat(text))
                                }
                            }
                        }
                        Row {
                            height: rowHeight
                            spacing: 0.3*margin
                            Label {
                                id: param2Label
                                text: ""
                                width: numberofepochsLabel.width
                            }
                            TextField {
                                id: param2TextField
                                anchors.verticalCenter: param2Label.verticalCenter
                                width: 140*pix
                                visible: false
                                validator: RegExpValidator { regExp: /(0.\d{1,3}|0)/ }
                                onEditingFinished: {
                                    Julia.set_settings(
                                        ["Training","Options","Hyperparameters","optimiser_params"],
                                        optimisersComboBox.currentIndex+1,2,parseFloat(text))
                                }
                            }
                        }
                        Row {
                            height: rowHeight
                            spacing: 0.3*margin
                            Label {
                                id: param3Label
                                text: ""
                                width: numberofepochsLabel.width
                            }
                            TextField {
                                id: param3TextField
                                anchors.verticalCenter: param3Label.verticalCenter
                                width: 140*pix
                                visible: false
                                validator: RegExpValidator { regExp: /(0.\d{1,3}|0)/ }
                                onEditingFinished: {
                                    Julia.set_settings(
                                        ["Training","Options","Hyperparameters","optimiser_params"],
                                        optimisersComboBox.currentIndex+1,3,parseFloat(text))
                                }
                            }
                        }
                        Row {
                            height: rowHeight
                            spacing: 0.3*margin
                            Label {
                                id: batchsizeLabel
                                text: "Batch size:"
                                width: numberofepochsLabel.width
                            }
                            SpinBox {
                                anchors.verticalCenter: batchsizeLabel.verticalCenter
                                from: 1
                                value: Julia.get_settings(
                                           ["Training","Options","Hyperparameters","batch_size"])
                                to: 10000
                                stepSize: 1
                                editable: true
                                onValueModified: {
                                    Julia.set_settings(
                                        ["Training","Options","Hyperparameters","batch_size"],
                                        value)
                                }
                            }
                        }
                        Row {
                            height: rowHeight
                            spacing: 0.3*margin
                            Label {
                                id: numberofepochsLabel
                                text: "Number of epochs:"
                            }
                            SpinBox {
                                anchors.verticalCenter: numberofepochsLabel.verticalCenter
                                from: 1
                                value: Julia.get_settings(
                                           ["Training","Options","Hyperparameters","epochs"])
                                to: 100000
                                stepSize: 1
                                editable: true
                                onValueModified: {
                                    Julia.set_settings(
                                        ["Training","Options","Hyperparameters","epochs"],
                                        value)
                                }
                            }
                        }
                        Row {
                            height: rowHeight
                            spacing: 0.3*margin
                            Label {
                                id: learningrateLabel
                                text: "Learning rate:"
                                width: numberofepochsLabel.width
                            }
                            SpinBox {
                                id: learningrateSpinBox
                                anchors.verticalCenter: learningrateLabel.verticalCenter
                                visible: Julia.get_settings(
                                           ["Training","Options","Hyperparameters","allow_lr_change"])
                                from: 1
                                value: 100000*Julia.get_settings(
                                           ["Training","Options","Hyperparameters","learning_rate"])
                                to: 1000
                                stepSize: value>100 ? 100 :
                                          value>10 ? 10 : 1
                                editable: false
                                property real realValue
                                textFromValue: function(value, locale) {
                                    realValue = value/100000
                                    return realValue.toLocaleString(locale,'e',0)
                                }
                                onValueModified: {
                                    Julia.set_settings(
                                        ["Training","Options","Hyperparameters","learning_rate"],
                                        value/100000)
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

    function rgbtohtml(colorRGB) {
        return(Qt.rgba(colorRGB[0]/255,colorRGB[1]/255,colorRGB[2]/255))
    }

}
