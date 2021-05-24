
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.Layouts 1.2
import Qt.labs.platform 1.1
import QtQml.Models 2.15
import "Templates"
import org.julialang 1.0

ApplicationWindow {
    id: dataWindow
    visible: true
    minimumHeight: 1024*pix + margin
    minimumWidth: informationPane.width + 1024*pix + margin
    title: qsTr("  Open Machine Learning Software")
    color: defaultpalette.window
    property double margin: 0.02*Screen.width
    property double buttonWidth: 0.1*Screen.width
    property double buttonHeight: 0.03*Screen.height

    onClosing: {
        dataplotLoader.sourceComponent = undefined
    }

    Timer {
        id: sizechangeTimer
        interval: 300
        running: false
        repeat: true
        property double prevWidth: 0
        property bool prevWidthChanged: false
        property double check: 0
        onTriggered: {
            if (prevWidth!==dataWindow.width) {
                prevWidth = dataWindow.width
                check = 0
                prevWidthChanged = true
            }
            else if (prevWidthChanged) {
                check = check + 1
                prevWidthChanged = false
            }
            if (check>0 || (displayPane.width + 2*displayPane.x)!==(dataWindow.width - 580*pix) ||
                    displayPane.height!==(dataWindow.height)) {
                var new_width = dataWindow.width - 580*pix
                var modif1 = new_width/displayPane.width
                var new_heigth = Math.min(Screen.height-1.75*margin,displayScrollableItem.height*modif1)
                var modif2 = new_heigth/displayScrollableItem.height
                var modif = Math.min(modif1,modif2)
                displayItem.width = displayItem.width*modif
                displayItem.height = displayItem.height*modif
                displayScrollableItem.width = displayScrollableItem.width*modif
                displayScrollableItem.height = displayScrollableItem.height*modif
                displayScrollableItem.contentX = displayScrollableItem.contentX*modif
                displayScrollableItem.contentY = displayScrollableItem.contentY*modif
                var cond = 1024*pix + margin
                displayPane.horizontalPadding = Math.max(0.5*margin,
                    (cond - displayScrollableItem.width)/2)
                displayPane.verticalPadding = Math.max(0.5*margin,
                    (cond - displayScrollableItem.height)/2)
                if (dataWindow.width===Screen.width) {
                    displayPane.height = dataWindow.height
                    displayPane.width = displayScrollableItem.width
                            + 2*displayPane.horizontalPadding
                }
                else {
                    displayPane.height = Math.floor(displayScrollableItem.height
                                                    + 2*displayPane.verticalPadding)
                    displayPane.width = Math.floor(displayScrollableItem.width
                                                   + 2*displayPane.horizontalPadding)
                    dataWindow.height = displayPane.height
                }
                displayPane.x = (dataWindow.width - displayPane.width - informationPane.width)/2
                check = 0
            }
        }
    }

    Timer {
        id: dataprocessingTimer
        interval: 1000; running: false; repeat: true
        property double step: 0
        property double value: 0
        property double max_value: 0
        property bool done: false
        onTriggered: {
            dataProcessingTimerFunction(dataprocessingTimer,
                "Remove data","Training data preparation")
        }
    }

    Item {
        Pane {
            id: displayPane
            horizontalPadding: 0.5*margin
            verticalPadding: 0.5*margin
            height: 1024*pix + margin
            width: 1024*pix + margin
            ScrollableItem {
                id: displayScrollableItem
                width : 1024*pix
                height : 1024*pix
                contentWidth: displayItem.width
                contentHeight: displayItem.height
                showBackground: false
                backgroundColor: defaultpalette.window
                clip: true
                Item {
                    id: displayItem
                    width: 1024*pix
                    height: 1024*pix
                    Image {
                        id: originalDisplay
                        width: displayItem.width
                        height: displayItem.height
                        autoTransform: true
                        fillMode: Image.PreserveAspectFit
                        smooth: false
                    }
                    Image {
                        id: resultDisplay
                        opacity: 0.5
                        width: displayItem.width
                        height: displayItem.height
                        autoTransform: true
                        fillMode: Image.PreserveAspectFit
                        smooth: false
                    }
                }
            }
        }
        Pane {
            id: informationPane
            x: dataWindow.width - 580*pix
            height: Math.max(1024*pix+margin,displayPane.height)
            width: 580*pix
            padding: 0.75*margin
            backgroundColor: defaultpalette.window2
            Column {
                id: informationColumn
                spacing: 0.4*margin
                RowLayout {
                    ProgressBar {
                        id: preparationProgressBar
                        Layout.preferredWidth: 1*buttonWidth
                        Layout.preferredHeight: buttonHeight
                        Layout.alignment: Qt.AlignVCenter
                    }
                    StopButton {
                        id: startstopButton
                        Layout.preferredWidth: buttonHeight
                        Layout.preferredHeight: buttonHeight
                        Layout.leftMargin: 0.3*margin
                        running: true
                        onClicked: {
                            if (running) {
                                //Julia.put_channel("Training data preparation",["stop"])
                            }
                            else {
                                /*if (preparedataButton.text==="Prepare data") {
                                    preparedataButton.text = "Stop data preparation"
                                    Julia.get_urls_training()
                                    Julia.empty_progress_channel("Training data preparation")
                                    Julia.empty_results_channel("Training data preparation")
                                    Julia.empty_progress_channel("Training data preparation modifiers")
                                    Julia.empty_progress_channel("Training")
                                    Julia.empty_results_channel("Training")
                                    Julia.empty_progress_channel("Training modifiers")
                                    dataprocessingTimer.running = true
                                    Julia.prepare_training_data()
                                }
                                else if (preparedataButton.text==="Stop data preparation") {
                                    preparedataButton.text = "Prepare data"
                                    dataprocessingTimer.running = false
                                    dataprocessingTimer.value = 0
                                    dataprocessingTimer.max_value = 0
                                    dataprocessingTimer.done = false
                                    progressbar.value = 0
                                    Julia.put_channel("Training data preparation",["stop"])
                                }
                                else if (preparedataButton.text==="Remove data") {
                                    Julia.reset_data_field(["Training_data","Plot_data","data_input"])
                                    Julia.reset_data_field(["Training_data","Plot_data","data_labels"])
                                    preparedataButton.text = "Prepare data"
                                }*/
                            }
                            running = !running
                        }
                    }
                }
                Label {
                    id: controlsLabel
                    visible: false
                    topPadding: 0.2*margin
                    text: "Visualization controls"
                    font.bold: true
                }
                Row {
                    id: folderRow
                    spacing: 0.8*margin
                    Label {
                        text: "Folder:"
                        width: 100*pix
                        topPadding: 10*pix
                    }
                    ComboBox {
                        id: folderComboBox
                        editable: false
                        currentIndex: 0
                        width: 0.76*buttonWidth
                        model: ListModel {
                            id: folderselectModel
                        }
                        onActivated: {
                        }
                        Component.onCompleted: {
                            var folders = Julia.get_data(["Training_data","foldernames"])
                            if (folders[0]===""){
                                folderRow.visible = false
                            }
                            for (var i=0;i<folders.length;i++) {
                                folderselectModel.append(
                                    {"name": folders[i]})
                            }
                        }
                    }
                }
                Row {
                    id: fileRow
                    spacing: 0.8*margin
                    Label {
                        text: "Files:"
                        width: 100*pix
                        topPadding: 10*pix
                    }
                    ComboBox {
                        id: fileComboBox
                        editable: false
                        width: 0.85*buttonWidth
                        model: ListModel {
                            id: fileselectModel
                        }
                        onActivated: {
                            var folderInd = folderComboBox.currentIndex+1
                            var fileInd = fileComboBox.currentIndex+1
                            var ind = Julia.get_data(["Training_data","fileindices"],[folderInd,fileInd])
                            var url = Julia.get_data(["Training_data","url_input"],[ind])
                            var size = Julia.import_image(url)
                                imagetransferCanvas.height = size[0]
                                imagetransferCanvas.width = size[1]
                                imagetransferCanvas.update()
                                imagetransferCanvas.grabToImage(function(result) {
                                                           originalDisplay.source = result.url
                                                       });
                            function upd() {
                                url = Julia.get_data(["Training_data","url_label"],[ind])
                                Julia.import_image(url)
                                imagetransferCanvas.height = size[0]
                                imagetransferCanvas.width = size[1]
                                imagetransferCanvas.update()
                                imagetransferCanvas.grabToImage(function(result) {
                                                           resultDisplay.source = result.url;
                                                       });
                            }
                            delay(10, upd)
                            sizechangeTimer.running = true
                        }
                        Component.onCompleted: {
                            var files = Julia.get_data(["Training_data",
                                "filenames"])[folderComboBox.currentIndex]
                            for (var i=0;i<files.length;i++) {
                                fileselectModel.append(
                                    {"name": files[i]})
                            }
                        }
                    }
                }
                Row {
                    id: featureRow
                    visible: false
                    spacing: 0.8*margin
                    Label {
                        text: "Feature:"
                        width: 100*pix
                        topPadding: 10*pix
                    }
                    ComboBox {
                        id: featureComboBox
                        editable: false
                        width: 0.85*buttonWidth
                        model: ListModel {
                            id: featureselectModel
                        }
                        onActivated: {
                            /*var ind1 = sampleSpinBox.value
                            var ind2 = featureComboBox.currentIndex+1
                            get_image(resultDisplay,typeComboBox.type,[ind1,ind2])
                            imagetransferCanvas.update()
                            imagetransferCanvas.grabToImage(function(result) {
                                                       resultDisplay.source = result.url
                                                   });*/
                        }
                        Component.onCompleted: {
                            for (var i=0;i<featureModel.count;i++) {
                                var feature = featureModel.get(i)
                                if (!feature.notFeature) {
                                    featureselectModel.append(
                                        {"name": feature.name})
                                }
                            }
                            var num = featureselectModel.count
                            for (i=0;i<num;i++) {
                                if (featureModel.get(i).border) {
                                    featureselectModel.append(
                                        {"name": featureModel.get(i).name+" (border)"})
                                }
                            }
                            for (i=0;i<num;i++) {
                                if (featureModel.get(i).border) {
                                    featureselectModel.append(
                                        {"name": featureModel.get(i).name+" (applied border)"})
                                }
                            }
                            currentIndex = 0
                        }
                    }
                }
                Row {
                    id: opacityRow
                    topPadding: 34*pix
                    spacing: 0.8*margin
                    Label {
                        text: "Opacity:"
                        width: 100*pix
                        topPadding: -18*pix
                    }
                    Slider {
                        width: 0.85*buttonWidth
                        height: 12*pix
                        leftPadding: 0
                        from: 0
                        value: 0.5
                        to: 1
                        onMoved: {
                            resultDisplay.opacity = value
                        }
                    }
                }
                Row {
                    id: zoomRow
                    topPadding: 34*pix
                    spacing: 0.8*margin
                    Label {
                        text: "Zoom:"
                        width: 100*pix
                        topPadding: -18*pix
                    }
                    Slider {
                        width: 0.85*buttonWidth
                        height: 12*pix
                        leftPadding: 0
                        stepSize: 0.5
                        from: 1
                        value: 1
                        to: 10
                        property double last_value: 1
                        onMoved: {
                            if (value!==last_value) {
                                var ratio = value/last_value
                            }
                            else if(value===1) {
                                displayItem.width = displayScrollableItem.width
                                displayItem.height = displayScrollableItem.height
                                return
                            }
                            else {
                                return
                            }
                            displayItem.width = displayItem.width*ratio
                            displayItem.height = displayItem.height*ratio
                            displayScrollableItem.contentX =
                                    (displayItem.width-displayScrollableItem.width)/2
                            displayScrollableItem.contentY =
                                    (displayItem.height-displayScrollableItem.height)/2
                            last_value = value
                        }
                    }
                }
            }
        }
    }
    MouseArea {
        width: dataWindow.width
        height: dataWindow.height
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

    function get_image(display,type,inds) {
        var size = Julia.get_image(["Training_data","Results",type],
            [0,0],inds)
        return size
    }

    function dataProcessingTimerFunction(timer,finish,
        action) {
        if (timer.max_value!==0 && !timer.done) {
            var value = Julia.get_progress(action)
            if (timer.value===timer.max_value) {
                var state = Julia.get_results(action)
                if (state===true) {
                    timer.done = true
                    timer.running = false
                    timer.value = 0
                    timer.max_value = 0
                    timer.done = false
                    startstopButton.running = false
                    trainButton.visible = true
                    progressbar.value = 0
                }
            }
            else {
                if (value!==false) {
                    timer.value += value
                }
            }
            progressbar.value = timer.value/timer.max_value
        }
        else {
            value = Julia.get_progress(action)
            if (value===false) { return }
            if (value!==0) {
                timer.max_value = value
            }
            else {
                timer.running = false
                timer.value = 0
                timer.max_value = 0
                timer.done = false
            }
        }
    }
}
