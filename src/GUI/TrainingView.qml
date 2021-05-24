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
        Loader { id: trainingoptionsLoader}
        Loader { id: customizationLoader}
        Loader { id: dataplotLoader}
        Loader { id: trainingplotLoader}

        FolderDialog {
            id: folderDialog
            currentFolder: currentfolder
            options: FolderDialog.ShowDirsOnly
            onAccepted: {
                var dir = folder.toString().replace("file:///","")
                /*updateButton.visible = true
                updatemodelButton.visible = false
                var count = featureModel.count
                for (var i=0;i<count;i++) {
                    featureModel.remove(0)
                }*/
                if (dialogtarget=="Images") {
                    imagesTextField.text = dir
                    Julia.set_settings(["Training","input"],dir)
                }
                else if (dialogtarget=="Labels") {
                    labelsTextField.text = dir
                    Julia.set_settings(["Training","labels"],dir)
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
                importmodel(model,url)
                load_model_features(featureModel)
                updatemodelButton.visible = true
                nameTextField.text = Julia.get_settings(["Training","name"])
                Julia.save_settings()
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
                                "parent2": "",
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
                                                  [feature.parent,feature.parent2],
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
                    spacing: margin
                    Row {
                        spacing: 0.3*margin
                        Label {
                            id: problemtypeLabel
                            text: "Problem type:"
                            topPadding: 10*pix
                        }
                        ComboBox {
                            id: problemtypeComboBox
                            function changeLabels() {
                                if (currentIndex===0) {
                                    labelsLabel.text = "Labels:"
                                    inputtypeModel.clear()
                                    inputtypeModel.append({text: "Images"})
                                    inputtypeModel.append({text: "Data series"})
                                    inputtypeComboBox.currentIndex = 0
                                    labelsRow.visible = false
                                }
                                else if (currentIndex===1) {
                                    labelsLabel.text = "Labels:"
                                    inputtypeModel.clear()
                                    inputtypeModel.append({text: "Images"})
                                    inputtypeComboBox.currentIndex = 0
                                    labelsRow.visible = true
                                }
                                else {
                                    labelsLabel.text = "Targets:"
                                    inputtypeModel.clear()
                                    inputtypeModel.append({text: "Images"})
                                    inputtypeModel.append({text: "Data series"})
                                    inputtypeComboBox.currentIndex = 0
                                    labelsRow.visible = true
                                }
                            }
                            editable: false
                            width: 0.69*buttonWidth-1*pix
                            model: ListModel {
                                id: problemtypeModel
                                ListElement {text: "Classification"}
                                ListElement {text: "Segmentation"}
                                ListElement {text: "Regression"}
                            }
                            onActivated: {
                                Julia.set_settings(["Training","problem_type"],
                                    [currentText,currentIndex],"make_tuple")
                                featureModel.clear()
                                neuralnetworkTextField.text = ""
                                changeLabels()
                                if (inputtypeComboBox.currentIndex===0) {
                                    inputLabel.text = "Images:"
                                    previewdataButton.visible = false
                                }
                                else {
                                    inputLabel.text = "Data:"
                                    previewdataButton.visible = true
                                }
                                disableButtons(currentIndex,1)
                            }
                            Component.onCompleted: {
                                currentIndex = Julia.get_settings(["Training","problem_type"],2)
                                if (neuralnetworkTextField.text!=="") {
                                    var type = Julia.get_model_type()
                                    var type_part = type[0]
                                    for (var i=0;i<inputtypeModel.length;i++) {
                                        var value = inputtypeModel.get(i)
                                        if (type_part===value) {
                                            currentIndex = i
                                            break
                                        }
                                    }
                                }
                                changeLabels()
                                disableButtons(currentIndex,1)
                            }
                        }
                    }
                    Row {
                        spacing: 0.3*margin
                        Label {
                            text: "Input type:"
                            topPadding: 10*pix
                        }
                        ComboBox {
                            id: inputtypeComboBox
                            function changeLabels() {
                                if (currentIndex===0) {
                                    inputLabel.text = "Images:"
                                    previewdataButton.visible = false
                                }
                                else {
                                    inputLabel.text = "Data:"
                                    previewdataButton.visible = true
                                }
                            }

                            editable: false
                            width: 0.59*buttonWidth-1*pix
                            model: ListModel {
                                id: inputtypeModel
                                ListElement {text: "Images"}
                                ListElement {text: "Data series"}
                            }
                            onActivated: {
                                Julia.set_settings(["Training","input_type"],
                                    [currentText,currentIndex],"make_tuple")
                                featureModel.clear()
                                neuralnetworkTextField.text = ""
                                changeLabels()
                                disableButtons(currentIndex,0)
                            }
                            Component.onCompleted: {
                                currentIndex = Julia.get_settings(["Training","input_type"],2)
                                if (neuralnetworkTextField.text!=="") {
                                    var type = Julia.get_model_type()
                                    var type_part = type[1]
                                    for (var i=0;i<inputtypeModel.length;i++) {
                                        var value = inputtypeModel.get(i)
                                        if (type_part===value) {
                                            currentIndex = i
                                            break
                                        }
                                    }
                                }
                                changeLabels()
                                if (currentIndex==1) {
                                    previewdataButton.visible = false
                                }
                                disableButtons(currentIndex,0)
                            }
                        }
                    }
                }
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
                            var url = Julia.get_settings(["Training","model_url"])
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
                        text: "Name:"
                        topPadding: 10*pix
                        width: 0.34*buttonWidth
                    }
                    TextField {
                        id: nameTextField
                        width: 1.55*buttonWidth
                        height: buttonHeight
                        onEditingFinished: Julia.set_settings(["Training","name"],text)
                        Component.onCompleted: {
                            text = Julia.get_settings(["Training","name"])
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
                            var url = Julia.get_settings(["Training","input"])
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
                            var url = Julia.get_settings(["Training","labels"])
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
                                        id: updateButton
                                        anchors.top: featureView.bottom
                                        width: buttonWidth + 0.5*margin - 24*pix
                                        height: buttonHeight - 2*pix
                                        hoverEnabled: true
                                        Label {
                                            topPadding: 0.15*margin
                                            leftPadding: 1.95*margin
                                            text: "Update"
                                        }
                                        onClicked: {
                                            if (imagesTextField.text!=="" && labelsTextField.text!=="") {
                                                var count = featureModel.count
                                                for (var i=0;i<count;i++) {
                                                    featureModel.remove(0)
                                                }
                                                Julia.empty_progress_channel("Labels colors")
                                                Julia.get_urls_training()
                                                Julia.reset_features()
                                                Julia.get_labels_colors()
                                                updateButton.visible = false
                                                updatemodelButton.visible = false
                                                labelscolorsTimer.running = true

                                            }
                                        }
                                    }
                                    TreeButton {
                                        id: updatemodelButton
                                        anchors.top: updateButton.bottom
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
                                            Julia.set_model_type(problemtypeComboBox.currentText,
                                                            inputtypeComboBox.currentText)
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
                    topPadding: (featuresColumn.height - buttonsColumn.height)/1.1
                    leftPadding: (dataColumn.width - featuresColumn.width -
                        buttonWidth)/2
                    Button {
                        id: previewdataButton
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
                            if (down) {
                                return
                            }
                            if (trainingoptionsLoader.sourceComponent === null) {
                                trainingoptionsLoader.source = "TrainingOptions.qml"
                            }
                        }
                    }
                    Button {
                        id: designButton
                        text: "Design"
                        width: buttonWidth
                        height: buttonHeight
                        onClicked: {
                            if (down) {
                                return
                            }
                            if (customizationLoader.sourceComponent === null) {
                                customizationLoader.source = "Design.qml"
                            }
                        }
                    }
                    Button {
                        id: databrowserButton
                        text: "Data browser"
                        width: buttonWidth
                        height: buttonHeight
                        onClicked: {
                            if (down) {
                                return
                            }
                            if (imagesTextField.length===0 || labelsTextField.length===0) {
                                return
                            }
                            Julia.get_urls_training()
                            dataplotLoader.source = "DataPlot.qml"
                        }
                    }
                    Button {
                        id: trainButton
                        visible: true
                        text: "Train"
                        width: buttonWidth
                        height: buttonHeight
                        onClicked: {
                            if (down) {
                                return
                            }
                            if (imagesTextField.length===0 || labelsTextField.length===0) {
                                return
                            }
                            if (trainButton.text==="Train") {
                                trainButton.text = "Stop Training"
                                Julia.train()
                                trainingplotLoader.source = "TrainingPlot.qml"
                            }
                            else {
                                trainButton.text = "Train"
                                progressbar.value = 0
                                Julia.put_channel("Training",["stop"])
                            }
                        }
                    }
                    ProgressBar {
                        id: progressbar
                        width: buttonWidth
                    }
                }
            }
        }

        function disableButtons(currentIndex,ind) {
            if (problemtypeComboBox.currentIndex===1 && inputtypeComboBox.currentIndex===0) {
                optionsButton.down = undefined
                designButton.down = undefined
                trainButton.down =  undefined
                previewdataButton.down = undefined
            }
            else{
                optionsButton.down = true
                designButton.down = true
                trainButton.down = true
                previewdataButton.down = true
            }
        }
    }
}
