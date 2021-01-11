

import QtQuick 2.12
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.Layouts 1.2
import Qt.labs.platform 1.1
import QtQml.Models 2.15
import QtCharts 2.15
import "Templates"
import org.julialang 1.0

ApplicationWindow {
    id: validationWindow
    visible: true
    minimumHeight: 1024*pix + margin
    minimumWidth: informationPane.width + 1024*pix + margin
    title: qsTr("  Julia Machine Learning GUI")
    color: defaultpalette.window

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

    onClosing: {
        Julia.put_channel("Validation",["stop"])
    }

    Timer {
        id: yieldTimer
        running: true
        repeat: true
        interval: 1
        onTriggered: {Julia.yield()}
    }

    JuliaCanvas {
        id: imagetransferCanvas
        visible: false
        paintFunction: display_image
        width: 1024
        height: 1024
    }

    Timer {
        id: validationTimer
        interval: 200
        running: true
        repeat: true
        property int iteration: 0
        property int max_iterations: -1
        property var accuracy: []
        property var loss: []
        property double mean_accuracy
        property double mean_loss
        property double accuracy_std
        property double loss_std
        property bool grabDone: false
        onTriggered: {
            var data = iteration!==max_iterations ? Julia.get_progress("Validation") :
                                                    Julia.get_results("Validation")
            if (data===false) {return}
            if (max_iterations===-1) {
                max_iterations = data[0]
            }
            else if (iteration<(max_iterations/2)) {
                var accuracy_temp = data[0]
                var loss_temp = data[1]
                var accuracy_std_temp = data[2]
                var loss_std_temp = data[3]
                iteration += 1
                accuracyLabel.text = accuracy_temp.toFixed(2) + " ± " + accuracy_std_temp.toFixed(2)
                lossLabel.text = loss_temp.toFixed(2) + " ± " + loss_std_temp.toFixed(2)
                validationProgressBar.value = iteration/max_iterations
            }
            else if (iteration>=(max_iterations/2) && iteration!==max_iterations) {
                iteration += 1
                validationProgressBar.value = iteration/max_iterations
            }
            else if (iteration===max_iterations) {
                running = false
                accuracy = data[0]
                loss = data[1]
                mean_accuracy = data[2]
                mean_loss = data[3]
                accuracy_std = data[4]
                loss_std = data[5]
                sampleSpinBox.value = 1
                featureComboBox.currentIndex = 0
                var ind1 = 1
                var ind2 = 1
                var size = get_image(originalDisplay,"data_input_orig",[ind1])
                var ratio = size[1]/size[0]
                if (ratio>1) {
                    displayItem.height = displayItem.width/ratio
                }
                else {
                    displayItem.width = displayItem.height*ratio
                }
                imagetransferCanvas.height = size[0]
                imagetransferCanvas.width = size[1]
                imagetransferCanvas.update()
                imagetransferCanvas.grabToImage(function(result) {
                                           originalDisplay.source = result.url
                                           validationTimer.grabDone = true;
                                       });
                function upd() {
                    get_image(resultDisplay,typeComboBox.type,[ind1,ind2])
                    imagetransferCanvas.update()
                    imagetransferCanvas.grabToImage(function(result) {
                                               resultDisplay.source = result.url;
                                           });
                }
                delay(10, upd)
                var cond = 1024*pix-margin
                if (displayItem.width>=cond) {
                    displayPane.horizontalPadding = 0.5*margin
                }
                else {
                    displayPane.horizontalPadding = (1024*pix+margin -
                                       displayItem.width - informationPane.width)/2
                }
                if (displayItem.height>=cond) {
                    displayPane.verticalPadding = 0.5*margin
                }
                else {
                    displayPane.verticalPadding = (1024*pix+margin - displayItem.height)/2
                }
                displayPane.height = displayItem.height + 2*displayPane.verticalPadding
                displayPane.width = displayItem.width + 2*displayPane.horizontalPadding
                displayScrollableItem.width = displayPane.width - 2*displayPane.horizontalPadding
                displayScrollableItem.height = displayPane.height - 2*displayPane.verticalPadding
                sizechangeTimer.prevWidth = displayPane.height
                sizechangeTimer.running = true
                controlsLabel.visible = true
                sampleRow.visible = true
                featureRow.visible = true
                typeRow.visible = true
                opacityRow.visible = true
                zoomRow.visible = true
            }
        }
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
            if (prevWidth!==validationWindow.width) {
                prevWidth = validationWindow.width
                check = 0
                prevWidthChanged = true
            }
            else if (prevWidthChanged) {
                check = check + 1
                prevWidthChanged = false
            }
            if (check>0 || (displayPane.width + 2*displayPane.x)!==(validationWindow.width - 580*pix) ||
                    displayPane.height!==(validationWindow.height)) {
                var ind1 = sampleSpinBox.value
                var ind2 = featureComboBox.currentIndex+1
                var new_width = validationWindow.width - 580*pix
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
                if (validationWindow.width===Screen.width) {
                    displayPane.height = validationWindow.height
                    displayPane.width = displayScrollableItem.width
                            + 2*displayPane.horizontalPadding
                }
                else {
                    displayPane.height = Math.floor(displayScrollableItem.height
                                                    + 2*displayPane.verticalPadding)
                    displayPane.width = Math.floor(displayScrollableItem.width
                                                   + 2*displayPane.horizontalPadding)
                    validationWindow.height = displayPane.height
                }
                displayPane.x = (validationWindow.width - displayPane.width - informationPane.width)/2
                check = 0
            }
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
            x: validationWindow.width - 580*pix
            height: Math.max(1024*pix+margin,displayPane.height)
            width: 580*pix
            padding: 0.75*margin
            backgroundColor: defaultpalette.window2
            Column {
                id: informationColumn
                spacing: 0.4*margin
                Row {
                    spacing: 0.3*margin
                    ProgressBar {
                        id: validationProgressBar
                        width: buttonWidth
                        height: buttonHeight
                    }
                    StopButton {
                        id: stoptraining
                        width: buttonHeight
                        height: buttonHeight
                        onClicked: Julia.put_channel("Validation",["stop"])
                    }
                }
                Label {
                    topPadding: 0.2*margin
                    text: "Validation information"
                    font.bold: true
                }
                Row {
                    spacing: 0.3*margin
                    Label {
                        id: accuracytextLabel
                        text: "Accuracy:"
                    }
                    Label {
                        id: accuracyLabel
                    }
                }
                Row {
                    spacing: 0.3*margin
                    Label {
                        text: "Loss:"
                        width: accuracytextLabel.width
                    }
                    Label {
                        id: lossLabel
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
                    id: sampleRow
                    visible: false
                    spacing: 0.3*margin
                    Label {
                        text: "Sample:"
                        width: accuracytextLabel.width
                    }
                    SpinBox {
                        id: sampleSpinBox
                        from: 1
                        value: 1
                        to: validationTimer.accuracy.length
                        stepSize: 1
                        editable: false
                        onValueModified: {
                            var ind1 = sampleSpinBox.value
                            var ind2 = featureComboBox.currentIndex+1
                            accuracyLabel.text = validationTimer.mean_accuracy.toFixed(2) + " ± " +
                                validationTimer.accuracy_std.toFixed(2) +
                                " (" + validationTimer.accuracy[ind1-1].toFixed(2) + ")"
                            lossLabel.text = validationTimer.mean_loss.toFixed(2) + " ± " +
                                 validationTimer.loss_std.toFixed(2) +
                                 " (" + validationTimer.loss[ind1-1].toFixed(2)+")"
                            get_image(originalDisplay,"data_input_orig",[ind1])
                            imagetransferCanvas.update()
                            imagetransferCanvas.grabToImage(function(result) {
                                                       resultDisplay.visible = false
                                                       originalDisplay.source = result.url
                                                   });
                            function upd() {
                                get_image(resultDisplay,typeComboBox.type,[ind1,ind2])
                                imagetransferCanvas.update()
                                imagetransferCanvas.grabToImage(function(result) {
                                                           resultDisplay.source = result.url;
                                                           resultDisplay.visible = true
                                                       });
                            }
                            delay(10, upd)
                        }
                    }
                }
                Row {
                    id: featureRow
                    visible: false
                    spacing: 0.3*margin
                    Label {
                        text: "Feature:"
                        width: accuracytextLabel.width
                        topPadding: 10*pix
                    }
                    ComboBox {
                        id: featureComboBox
                        editable: false
                        width: 0.76*buttonWidth
                        model: ListModel {
                            id: featureselectModel
                        }
                        ListModel {id: featureModel}
                        onActivated: {
                            var ind1 = sampleSpinBox.value
                            var ind2 = featureComboBox.currentIndex+1
                            get_image(resultDisplay,typeComboBox.type,[ind1,ind2])
                            imagetransferCanvas.update()
                            imagetransferCanvas.grabToImage(function(result) {
                                                       resultDisplay.source = result.url
                                                   });
                        }
                        Component.onCompleted: {
                            load_model_features()
                            for (var i=0;i<featureModel.count;i++) {
                                featureselectModel.append(
                                    {"name": featureModel.get(i).name})
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
                    id: typeRow
                    visible: false
                    spacing: 0.3*margin
                    Label {
                        text: "Show:"
                        width: accuracytextLabel.width
                        topPadding: 10*pix
                    }
                    ComboBox {
                        id: typeComboBox
                        property string type: "data_predicted"
                        editable: false
                        currentIndex: 0
                        width: 0.76*buttonWidth
                        model: ListModel {
                            id: typeModel
                            ListElement {name: "Result"}
                            ListElement {name: "Error"}
                            ListElement {name: "Target"}
                        }
                        onActivated: {
                            if (typeComboBox.currentIndex==0) {
                                type = "data_predicted"
                            }
                            else if  (typeComboBox.currentIndex==1) {
                                type = "data_error"
                            }
                            else {
                                type = "data_target"
                            }
                            get_image(resultDisplay,type,
                                [sampleSpinBox.value,featureComboBox.currentIndex+1])
                            imagetransferCanvas.update()
                            imagetransferCanvas.grabToImage(function(result) {
                                                       resultDisplay.source = result.url
                                                   });
                        }
                    }
                }
                Row {
                    id: opacityRow
                    visible: false
                    topPadding: 34*pix
                    spacing: 0.3*margin
                    Label {
                        text: "Opacity:"
                        width: accuracytextLabel.width
                        topPadding: -24*pix
                    }
                    Slider {
                        width: 0.76*buttonWidth
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
                    visible: false
                    topPadding: 34*pix
                    spacing: 0.3*margin
                    Label {
                        text: "Zoom:"
                        width: accuracytextLabel.width
                        topPadding: -24*pix
                    }
                    Slider {
                        width: 0.76*buttonWidth
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
        width: validationWindow.width
        height: validationWindow.height
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
        var size = Julia.get_image(["Validation_data","Validation_plot_data",type],
            [0,0],inds)
        return size
    }

    function load_model_features() {
        var num_features = Julia.num_features()
        if (num_features!==0 && featureModel.count==0) {
            for (var i=0;i<num_features;i++) {
                var color = Julia.get_feature_field(i+1,"color")
                var feature = {
                    "name": Julia.get_feature_field(i+1,"name"),
                    "colorR": color[0],
                    "colorG": color[1],
                    "colorB": color[2],
                    "border": Julia.get_feature_field(i+1,"border"),
                    "parent": Julia.get_feature_field(i+1,"parent")}
                featureModel.append(feature)
            }
        }
    }

    function rgbtohtml(colorRGB) {
            return(Qt.rgba(colorRGB[0]/255,colorRGB[1]/255,colorRGB[2]/255))
    }

    function delay(delayTime, cb) {
        function Timer() {
            return Qt.createQmlObject("import QtQuick 2.0; Timer {}", validationWindow);
        }
        var timer = new Timer();
        timer.interval = delayTime;
        timer.repeat = false;
        timer.triggered.connect(cb);
        timer.start();
    }
}
