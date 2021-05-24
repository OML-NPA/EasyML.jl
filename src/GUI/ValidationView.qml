
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.Layouts 1.2
import Qt.labs.platform 1.1
import "Templates"
import org.julialang 1.0

Component {
    Item {
        id: mainItem
        property string colorR: "0"
        property string colorG: "0"
        property string colorB: "0"
        property int indTree: 0
        property var model: []
        property string dialogtarget

        Loader { id: featuredialogLoader}
        Loader { id: validationplotLoader}

        FolderDialog {
            id: folderDialog
            currentFolder: currentfolder
            options: FolderDialog.ShowDirsOnly
            onAccepted: {
                var dir = folder.toString().replace("file:///","")
                updatemodelButton.visible = false
                var count = featureModel.count
                if (dialogtarget=="Images") {
                    imagesTextField.text = dir
                    Julia.set_settings(["Validation","input"],dir)
                }
                else if (dialogtarget=="Labels") {
                    labelsTextField.text = dir
                    Julia.set_settings(["Validation","labels"],dir)
                }
                Julia.save_settings()
            }
        }
        FileDialog {
            id: fileDialog
            nameFilters: [ "*.model"]
            onAccepted: {
                var url = file.toString().replace("file:///","")
                neuralnetworkTextField.text = url
                Julia.set_settings(["Validation","model"],url)
                importmodel(model,url)
                load_model_features(featureModel)
                updatemodelButton.visible = true
                var type = Julia.get_model_type()
                if (type[1]==="Images") {
                    inputLabel.text = "Images:"
                    previewdataButton.visible = false
                }
                else {
                    inputLabel.text = "Data:"
                    previewdataButton.visible = true
                }
            }
        }

        Timer {
            id: labelscolorsTimer
            running: false
            repeat: true
            interval: 300
            property double max_value: 0
            property double value: 0
            property double loading_state: 1
            onTriggered: {
                var data = Julia.get_results("Labels colors")
                if (loading_state===0) {
                    progressRepeater.itemAt(2).visible = false
                    progressRepeater.itemAt(1).visible = false
                    progressRepeater.itemAt(0).visible = false
                    loading_state+=1
                }
                else if (loading_state===1) {
                    progressRepeater.itemAt(2).visible = true
                    loading_state+=1
                }
                else if (loading_state===2) {
                    progressRepeater.itemAt(1).visible = true
                    loading_state+=1
                }
                else {
                    progressRepeater.itemAt(0).visible = true
                    loading_state = 0
                }
                if (data!==false) {
                    if (max_value==0) {
                        max_value = data
                        return
                    }
                    if (value===max_value) {
                        for (var i=0;i<data.length;i++) {
                            var feature = {
                                "name": "feature "+(i+1),
                                "colorR": data[i][0],
                                "colorG": data[i][1],
                                "colorB": data[i][2],
                                "border": false,
                                "border_thickness": 3,
                                "borderRemoveObjs": false,
                                "min_area": 1,
                                "parent": "",
                                "notFeature": false}
                            featureModel.append(feature)
                            Julia.append_features(feature.name,
                                                  feature.colorR,
                                                  feature.colorG,
                                                  feature.colorB,
                                                  feature.border,
                                                  feature.border_thickness,
                                                  feature.borderRemoveObjs,
                                                  feature.min_area,
                                                  feature.parent,
                                                  feature.notFeature)
                        }
                        max_value = 0
                        value = 0
                        loading_state = 1
                        running = false
                        progressRepeater.itemAt(0).visible = false
                        progressRepeater.itemAt(1).visible = false
                        progressRepeater.itemAt(2).visible = false
                        updateButton.visible = true
                        updatemodelButton.visible = true
                    }
                    else {
                        value = value + 1
                    }
                }
            }
        }
        Column {
            id: mainColumn
            spacing: 0.7*margin
            Column {
                id: dataColumn
                spacing: 0.5*margin
                Row {
                    spacing: 0.3*margin
                    Label {
                        text: "Network:"
                        topPadding: 10*pix
                        width: 0.34*buttonWidth
                    }
                    TextField {
                        id: neuralnetworkTextField
                        readOnly: true
                        width: 1.55*buttonWidth
                        height: buttonHeight
                        Component.onCompleted: {
                            var url = Julia.get_settings(["Validation","model"])
                            if (Julia.isfile(url)) {
                                text = url
                                importmodel(model,url)
                                load_model_features(featureModel)
                                updatemodelButton.visible = true
                            }
                        }
                    }
                    Button {
                        width: buttonWidth/2
                        height: buttonHeight
                        text: "Browse"
                        onClicked: {
                            dialogtarget = "Network"
                            fileDialog.open()
                        }
                    }
                }
                Row {
                    spacing: 0.3*margin
                    Label {
                        id: inputLabel
                        text: "Images:"
                        topPadding: 10*pix
                        width: 0.34*buttonWidth
                    }
                    TextField {
                        id: imagesTextField
                        readOnly: true
                        width: 1.55*buttonWidth
                        height: buttonHeight
                        Component.onCompleted: {
                            var url = Julia.get_settings(["Validation","input"])
                            if (Julia.isdir(url)) {
                                text = url
                            }
                        }
                    }
                    Button {
                        width: buttonWidth/2
                        height: buttonHeight
                        text: "Browse"
                        onClicked: {
                            dialogtarget = "Images"
                            folderDialog.open()
                        }
                    }
                }
                Row {
                    id: uselabelsRow
                    spacing: 0.3*margin
                    Label {
                        id: uselabelsLabel
                        text: "Use labels:"
                    }
                    CheckBox {
                        id: uselabelsCheckBox
                        onClicked: {
                            var state = checkState==Qt.Checked
                            labelsRow.visible = state
                            Julia.set_settings(["Validation","use_labels"],state)
                        }
                        Component.onCompleted: {
                            var state = Julia.get_settings(["Validation","use_labels"])
                            labelsRow.visible = state
                            checkState = state ? Qt.Checked : Qt.Unchecked
                        }
                    }

                }

                Row {
                    id: labelsRow
                    spacing: 0.3*margin
                    Label {
                        id: labelsLabel
                        text: "Labels:"
                        topPadding: 10*pix
                        width: 0.34*buttonWidth
                    }
                    TextField {
                        id: labelsTextField
                        readOnly: true
                        width: 1.55*buttonWidth
                        height: buttonHeight
                        Component.onCompleted: {
                            var url = Julia.get_settings(["Validation","labels"])
                            if (Julia.isdir(url)) {
                                text = url
                            }
                        }
                    }
                    Button {
                        id: browselabelsButton
                        width: buttonWidth/2
                        height: buttonHeight
                        text: "Browse"
                        onClicked: {
                            dialogtarget = "Labels"
                            folderDialog.open()
                        }
                    }
                }
            }
            Row {
                Column {
                    id: featuresColumn
                    spacing: -2
                    Label {
                        width: buttonWidth + 0.5*margin
                        text: "Features:"
                        padding: 0.1*margin
                        leftPadding: 0.2*margin
                        background: Rectangle {
                            anchors.fill: parent.fill
                            color: "transparent"
                            border.color: defaultpalette.border
                            border.width: 2*pix
                        }
                    }
                    Frame {
                        id: featuresFrame
                        height: 432*pix
                        width: buttonWidth + 0.5*margin
                        backgroundColor: "white"
                        ScrollView {
                            clip: true
                            anchors.fill: parent
                            padding: 0
                            spacing: 0
                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                            Flickable {
                                boundsBehavior: Flickable.StopAtBounds
                                contentHeight: featureView.height+buttonHeight-2*pix
                                Item {
                                    TreeButton {
                                        id: updatemodelButton
                                        anchors.top: featureView.bottom
                                        width: buttonWidth + 0.5*margin - 24*pix
                                        height: buttonHeight - 2*pix
                                        hoverEnabled: true
                                        visible: false
                                        Label {
                                            topPadding: 0.15*margin
                                            leftPadding: 105*pix
                                            text: "Update model"
                                        }
                                        onClicked: {
                                            Julia.save_model("models/" + nameTextField.text + ".model")
                                        }
                                    }
                                    ListView {
                                        id: featureView
                                        height: childrenRect.height
                                        spacing: 0
                                        boundsBehavior: Flickable.StopAtBounds
                                        model: ListModel {id: featureModel}
                                        delegate: TreeButton {
                                            id: control
                                            hoverEnabled: true
                                            width: buttonWidth + 0.5*margin - 24*pix
                                            height: buttonHeight - 2*pix
                                            onClicked: {
                                                if (featuredialogLoader.sourceComponent === null) {
                                                    indTree = index
                                                    featuredialogLoader.source = "FeatureDialog.qml"
                                                }
                                            }
                                            RowLayout {
                                                anchors.fill: parent.fill
                                                Rectangle {
                                                    id: colorRectangle
                                                    Layout.leftMargin: 0.2*margin
                                                    Layout.bottomMargin: 6*pix
                                                    Layout.alignment: Qt.AlignBottom
                                                    height: 30*pix
                                                    width: 30*pix
                                                    border.width: 2*pix
                                                    radius: colorRectangle.width
                                                    color: rgbtohtml([colorR,colorG,colorB])
                                                }
                                                Label {
                                                    topPadding: 0.15*margin
                                                    leftPadding: 0.10*margin
                                                    text: name
                                                    Layout.alignment: Qt.AlignBottom
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        Repeater {
                            id: progressRepeater
                            model: 3
                            property var offsets: [-30*pix,0,30*pix]
                            Rectangle {
                                id: progress1Rectangle
                                x: featuresFrame.width/2 - width/2 - progressRepeater.offsets[index]
                                y: buttonHeight/2 - height/2
                                color: defaultcolors.dark
                                visible: false
                                width: 15*pix
                                height: width
                                radius: width
                            }
                        }
                    }
                }
                Column {
                    id: buttonsColumn
                    spacing: 0.3*margin
                    topPadding: (featuresColumn.height - buttonsColumn.height)/2
                    leftPadding: (dataColumn.width - featuresColumn.width -
                        buttonWidth)/2
                    Button {
                        id: previewdataButton
                        visible: false
                        text: "Preview imported data"
                        width: buttonWidth
                        height: buttonHeight
                        onClicked: {
                            if (down) {
                                return
                            }
                        }
                    }
                    Button {
                        id: optionsButton
                        text: "Options"
                        width: buttonWidth
                        height: buttonHeight
                        onClicked: {
                        }
                    }
                    Button {
                        id: validateButton
                        text: "Validate"
                        width: buttonWidth
                        height: buttonHeight
                        onClicked: {
                            if (down) {
                                return
                            }
                            if (imagesTextField.length===0 ||
                                    (uselabelsCheckBox.checkState===Qt.checked &&
                                     labelsTextField.length===0)) {
                                return
                            }
                            if (validateButton.text==="Validate") {
                                validateButton.text = "Stop validation"
                                Julia.get_urls_validation()
                                Julia.empty_progress_channel("Validation data preparation modifiers")
                                Julia.empty_progress_channel("Validation")
                                Julia.empty_results_channel("Validation")
                                Julia.empty_progress_channel("Validation modifiers")
                                validationplotLoader.source = "ValidationPlot.qml"
                                Julia.validate()
                            }
                            else {
                                validateButton.text = "Validate"
                                validationTimer.running = false
                                progressbar.value = 0
                                Julia.put_channel("Validation",["stop"])
                            }
                        }
                    }
                    ProgressBar {
                        id: progressbar
                        visible: false
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                        width: buttonWidth
                    }
                }
            }
        }
        function disableButtons(currentIndex,ind) {
            if (problemtypeComboBox.currentIndex===1 && inputtypeComboBox.currentIndex===0) {
                optionsButton.down = undefined
                validateButton.down = undefined
                previewdataButton.down = undefined
            }
            else{
                optionsButton.down = true
                validateButton.down = true
                previewdataButton.down = true
            }
        }
    }
}
