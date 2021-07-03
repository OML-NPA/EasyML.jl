
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
        //trainingoptionsLoader.sourceComponent = null
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
                    model: [{"name": "Accuracy", "stackview": accuracyView},
                            {"name": "Testing", "stackview": testingView},
                            {"name": "Processing", "stackview": processingView},
                            {"name": "Hyperparameters", "stackview": hyperparametersView}]
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
                initialItem: accuracyView
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
                id: accuracyView
                Column {
                    property double rowHeight: 60*pix
                    spacing: 0.4*margin
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
                            checkState : Julia.get_options(
                                        ["TrainingOptions","Accuracy","weight_accuracy"]) ?
                                        Qt.Checked : Qt.Unchecked
                            onClicked: {
                                var value = checkState==Qt.Checked ? true : false
                                Julia.set_options(
                                    ["TrainingOptions","Accuracy","weight_accuracy"],value)
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
                                Julia.set_options(["TrainingOptions","Accuracy","accuracy_mode"],currentText)
                            }
                            Component.onCompleted: {
                                var current_mode = Julia.get_options(
                                    ["TrainingOptions","Accuracy","accuracy_mode"])
                                for (var i=0;i<modes.length;i++) {
                                    var mode = modes[i]
                                    modeModel.append({"name": mode})
                                    if (current_mode==mode) {
                                        currentIndex = i
                                    }
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
                                Julia.set_options(
                                    ["TrainingOptions","Testing","data_preparation_mode"],currentText)
                            }
                            Component.onCompleted: {
                                var current_mode = Julia.get_options(
                                    ["TrainingOptions","Testing","data_preparation_mode"])  
                                for (var i=0;i<modes.length;i++) {
                                    var mode = modes[i]
                                    datapreparationmodeModel.append({"name": mode})
                                    if (current_mode==mode) {
                                        currentIndex = i
                                    }
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
                            value: 100*Julia.get_options(
                                        ["TrainingOptions","Testing","test_data_fraction"])
                            to: 99
                            stepSize: 1
                            editable: true
                            property real realValue
                            textFromValue: function(value, locale) {
                                realValue = value/100
                                return realValue.toLocaleString(locale,'f',2)
                            }
                            onValueModified: {
                                Julia.set_options(
                                    ["TrainingOptions","Testing","test_data_fraction"],realValue)
                            }
                        }
                    }
                    Row {
                        height: rowHeight
                        spacing: 0.3*margin
                        Label {
                            id: testingfrLabel
                            text: "Number of tests (per epoch):"
                        }
                        SpinBox {
                            from: 0
                            value: Julia.get_options(
                                        ["TrainingOptions","Testing","num_tests"])
                            to: 10000
                            stepSize: 1
                            editable: true
                            onValueModified: {
                                Julia.set_options(
                                    ["TrainingOptions","Testing","num_tests"],value)
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
                            checkState : Julia.get_options(
                                        ["TrainingOptions","Processing","grayscale"]) ?
                                        Qt.Checked : Qt.Unchecked
                            onClicked: {
                                var value = checkState==Qt.Checked ? true : false
                                Julia.set_options(
                                    ["TrainingOptions","Processing","grayscale"],value)
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
                                        ["TrainingOptions","Processing","mirroring"]) ?
                                        Qt.Checked : Qt.Unchecked
                            onClicked: {
                                var value = checkState==Qt.Checked ? true : false
                                Julia.set_options(
                                    ["TrainingOptions","Processing","mirroring"],value)
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
                                        ["TrainingOptions","Processing","num_angles"])
                            to: 10
                            onValueModified: {
                                Julia.set_options(
                                    ["TrainingOptions","Processing","num_angles"],value)
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
                                        ["TrainingOptions","Processing","min_fr_pix"])
                            to: 100
                            stepSize: 10
                            property real realValue
                            textFromValue: function(value, locale) {
                                realValue = value/100
                                return realValue.toLocaleString(locale,'f',1)
                            }
                            onValueModified: {
                                Julia.set_options(
                                    ["TrainingOptions","Processing","min_fr_pix"],realValue)
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
                            property var optimisers: ["Descent","Momentum",
                                "Nesterov","RMSProp","ADAM","RADAM","AdaMax",
                                "ADAGrad","ADADelta","AMSGrad","NADAM","ADAMW"]
                            property var allow_lr: [true,true,true,true,true,true,true,
                                true,false,true,true,true]
                            onActivated: {
                                Julia.set_options(
                                    ["TrainingOptions","Hyperparameters","optimiser"],currentText)
                                var params = Julia.get_data(
                                    ["TrainingData","OptionsData","optimiser_params"])
                                var current_params = params[currentIndex]
                                Julia.set_options(
                                    ["TrainingOptions","Hyperparameters","optimiser_params"],current_params)
                                change_params()
                            }
                            Component.onCompleted: {
                                var name = Julia.get_options(
                                    ["TrainingOptions","Hyperparameters","optimiser"])
                                for (var i=0;i<optimisers.length;i++) {
                                    var optimiser_name = optimisers[i]
                                    optimisersModel.append({"name": optimisers[i]})
                                    if (name==optimiser_name) {
                                        currentIndex = i
                                    }
                                }
                                change_params()
                            }
                            function change_params() {
                                var values = Julia.get_options(
                                    ["TrainingOptions","Hyperparameters","optimiser_params"])
                                var names = Julia.get_data(
                                    ["TrainingData","OptionsData","optimiser_params_names"])
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
                                Julia.set_options(["TrainingOptions","Hyperparameters","optimiser_params"],
                                    1,parseFloat(text))
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
                                Julia.set_options(["TrainingOptions","Hyperparameters","optimiser_params"],
                                    2,parseFloat(text))
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
                                Julia.set_options(["TrainingOptions","Hyperparameters","optimiser_params"],
                                    3,parseFloat(text))
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
                            from: 1
                            value: 100000*Julia.get_options(
                                        ["TrainingOptions","Hyperparameters","learning_rate"])
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
                                Julia.set_options(
                                    ["TrainingOptions","Hyperparameters","learning_rate"],realValue)
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
                            value: Julia.get_options(
                                        ["TrainingOptions","Hyperparameters","batch_size"])
                            to: 10000
                            stepSize: 1
                            editable: true
                            onValueModified: {
                                Julia.set_options(
                                    ["TrainingOptions","Hyperparameters","batch_size"],
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
                            value: Julia.get_options(
                                        ["TrainingOptions","Hyperparameters","epochs"])
                            to: 100000
                            stepSize: 1
                            editable: true
                            onValueModified: {
                                Julia.set_options(
                                    ["TrainingOptions","Hyperparameters","epochs"],
                                    value)
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
