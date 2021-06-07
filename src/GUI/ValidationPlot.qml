
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.Layouts 1.2
import Qt.labs.platform 1.1
import QtQml.Models 2.15
import "Templates"
import org.julialang 1.0

ApplicationWindow {
    id: validationWindow
    visible: true
    title: qsTr("  Julia Machine Learning GUI")
    
    //---Universal property block-----------------------------------------------
    property double pix: Screen.width/3840
    //property double defaultPixelSize: 33*pix
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
    //-------------------------------------------------------------------------
    //---Yield timer block-----------------------------------------------------
    
    Timer {
        id: yieldTimer
        running: true
        repeat: true
        interval: 1
        onTriggered: {Julia.yield()}
    }
    //-------------------------------------------------------------------------
    //-Other-------------------------------------------------------------------
    
    JuliaCanvas {
        id: imagetransferCanvas
        visible: false
        paintFunction: display_image
        width: 1024
        height: 1024
    }
    
    ListModel {
        id: classModel
        Component.onCompleted: {
            if (problem_type==0) {
            }
            else if (problem_type==1) {
                load_model_classes(classModel)
                for (var i=0;i<classModel.count;i++) {
                    var class_var = classModel.get(i)
                    if (!class_var.notClass) {
                        classeselectModel.append(
                            {"name": class_var.name})
                    }
                }
                var num = classeselectModel.count
                for (i=0;i<num;i++) {
                    if (classModel.get(i).border) {
                        classeselectModel.append(
                            {"name": classModel.get(i).name+" (border)"})
                    }
                }
                for (i=0;i<num;i++) {
                    if (classModel.get(i).border) {
                        classeselectModel.append(
                            {"name": classModel.get(i).name+" (applied border)"})
                    }
                }
                classComboBox.currentIndex = 0
            }
        }
    }
    
    function load_model_classes(classModel) {
        var num_classes = Julia.num_classes()
        if (problem_type==0) {
                var class_var = {
                    "id": id,
                    "name": Julia.get_class_field(ind,"name")
                }
            }
        else if (problem_type==1) {
            if (classModel.count!==0) {
                classModel.clear()
            }
            for (var i=0;i<num_classes;i++) {
                var ind = i+1
                var color = Julia.get_class_field(ind,"color")
                var parents = Julia.get_class_field(ind,"parents")
                var class_var = {
                    "name": Julia.get_class_field(ind,"name"),
                    "colorR": color[0],
                    "colorG": color[1],
                    "colorB": color[2],
                    "border": Julia.get_class_field(ind,"border"),
                    "border_thickness": Julia.get_class_field(ind,"border_thickness"),
                    "borderRemoveObjs": Julia.get_class_field(ind,"border_remove_objs"),
                    "min_area": Julia.get_class_field(ind,"min_area"),
                    "parent": parents[0],
                    "parent2": parents[1],
                    "notClass": Julia.get_class_field(ind,"not_class")}
                classModel.append(class_var)
            }
        }
    }

    function delay(delayTime, cb) {
        function Timer() {
            return Qt.createQmlObject("import QtQuick 2.15; Timer {}", validationWindow);
        }
        var timer = new Timer();
        timer.interval = delayTime;
        timer.repeat = false;
        timer.triggered.connect(cb);
        timer.start();
    }
    //-------------------------------------------------------------------------
    
    minimumHeight: 1024*pix + classLabel.height + margin
    minimumWidth: informationPane.width + 1024*pix + margin
    color: defaultpalette.window
    property int input_type: Julia.get_settings(["input_type"])=="Image" ? 0 : 1
    property int problem_type: Julia.get_settings(["problem_type"])=="Classification" ? 0 : 1

    property var accuracy: []
    property var loss: []
    property double mean_accuracy
    property double mean_loss
    property double accuracy_std
    property double loss_std
    property var predicted_labels: []
    property var target_labels: []
    property string fieldname

    onClosing: {
        Julia.put_channel("Validation",["stop"])
        //validateButton.text = "Validate"
        //progressbar.value = 0
        //validationplotLoader.sourceComponent = undefined
    }

    Timer {
        id: validationTimer
        interval: 200
        running: true
        repeat: true
        property int iteration: 0
        property int max_iterations: -1
        
        property bool grabDone: false
        onTriggered: {
            var state = Julia.get_progress("Validation")
            if (state===false) {
                return
            }
            else {
                var data = Julia.get_results("Validation")
            }
            if (max_iterations===-1) {
                max_iterations = state
            }
            else if (iteration<max_iterations) {
                iteration += 1
                validationProgressBar.value = iteration/max_iterations
                var accuracy_temp = data[0]
                var loss_temp = data[1]
                accuracy.push(accuracy_temp)
                loss.push(loss_temp)
                if (iteration==1) {
                    sampleSpinBox.value = 1
                    classComboBox.currentIndex = 0
                    var ind1 = 1
                    var size = get_image(originalDisplay,"original",[ind1])
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
                    if (problem_type==0) {
                        var predicted_label = Julia.get_data(["Validation_data","Image_classification_results","predicted_labels"],[iteration])
                        var target_label = Julia.get_data(["Validation_data","Image_classification_results","target_labels"],[iteration])
                        predicted_labels.push(predicted_label)
                        target_labels.push(target_label)
                        classLabel.text = "Predicted: " + predicted_label + "; Real: " + target_label
                        classLabel.visible = true
                    }
                    else if (problem_type==1) {
                        var ind2 = 1
                        resultDisplay.visible = true
                        function upd() {
                            get_image(resultDisplay,typeComboBox.type,[ind1,ind2])
                            imagetransferCanvas.update()
                            imagetransferCanvas.grabToImage(function(result) {
                                resultDisplay.source = result.url;
                            });
                        }
                        delay(50, upd)
                        classRow.visible = true
                        typeRow.visible = true
                        opacityRow.visible = true
                        zoomRow.visible = true
                    }
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
                }
                else {
                    mean_accuracy = mean(accuracy)
                    mean_loss = mean(loss)
                    if (problem_type==0) {
                        var predicted_label = Julia.get_data(["Validation_data","Image_classification_results","predicted_labels"],[iteration])
                        var target_label = Julia.get_data(["Validation_data","Image_classification_results","target_labels"],[iteration])
                        predicted_labels.push(predicted_label)
                        target_labels.push(target_label)
                    }
                    sampleSpinBox.to = iteration
                }
            }
            else if (iteration===max_iterations) {
                running = false
            }
        }
        Component.onCompleted: {
            if (problem_type==0) {
                fieldname = "Image_classification_results"
            }
            else if (problem_type==1) {
                fieldname = "Image_segmentation_results"
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
                var ind2 = classComboBox.currentIndex+1
                var new_width = validationWindow.width - 580*pix
                var modif1 = new_width/displayPane.width
                var new_heigth = Math.min(Screen.height-1.75*margin,(displayScrollableItem.height)*modif1)
                var modif2 = new_heigth/(displayScrollableItem.height)
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
                    (cond - (displayScrollableItem.height))/2)
                if (validationWindow.width===Screen.width) {
                    displayPane.height = validationWindow.height
                    displayPane.width = displayScrollableItem.width
                            + 2*displayPane.horizontalPadding
                }
                else {
                    displayPane.height = Math.floor(displayScrollableItem.height + classLabel.height
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
            Column {
                id: resultColumn
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
                            visible: false
                            opacity: 0.5
                            width: displayItem.width
                            height: displayItem.height
                            autoTransform: true
                            fillMode: Image.PreserveAspectFit
                            smooth: false
                        }
                    }
                }
                Label {
                    id: classLabel
                    anchors.horizontalCenter: resultColumn.horizontalCenter
                    topPadding: 0.5*margin
                    visible: false
                }
            }
        }
        Pane {
            id: informationPane
            x: validationWindow.width - 580*pix
            height: Math.max(1024*pix + margin + classLabel.height,displayPane.height)
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
                    visible: Julia.get_settings(["Validation","use_labels"])
                    topPadding: 0.2*margin
                    text: "Validation information"
                    font.bold: true
                }
                Row {
                    visible: Julia.get_settings(["Validation","use_labels"])
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
                    visible: Julia.get_settings(["Validation","use_labels"])
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
                        to: 1
                        stepSize: 1
                        editable: false
                        onValueModified: {
                            var ind1 = sampleSpinBox.value
                            accuracyLabel.text = mean_accuracy.toFixed(2)+
                                " (" + accuracy[ind1-1].toFixed(2) + ")"
                            lossLabel.text = mean_loss.toFixed(2)+
                                 " (" + loss[ind1-1].toFixed(2)+")"
                            
                            get_image(originalDisplay,"original",[ind1])
                            imagetransferCanvas.update()
                            imagetransferCanvas.grabToImage(function(result) {
                                                       resultDisplay.visible = false
                                                       originalDisplay.source = result.url
                                                   });
                            if (problem_type==0) {
                                 classLabel.text = "Predicted: " + predicted_labels[ind1] + "; Real: " + target_labels[ind1]
                             }
                            else if (problem_type==1) {
                                var ind2 = classComboBox.currentIndex+1
                                function upd() {
                                    get_image(resultDisplay,typeComboBox.type,[ind1,ind2])
                                    imagetransferCanvas.update()
                                    imagetransferCanvas.grabToImage(function(result) {
                                                            resultDisplay.source = result.url;
                                                            resultDisplay.visible = true
                                    });
                                }
                                delay(50, upd)
                            }
                        }
                    }
                }
                Row {
                    id: classRow
                    visible: false
                    spacing: 0.3*margin
                    Label {
                        text: "Class:"
                        width: accuracytextLabel.width
                        topPadding: 10*pix
                    }
                    ComboBox {
                        id: classComboBox
                        editable: false
                        width: 0.76*buttonWidth
                        model: ListModel {
                            id: classeselectModel
                        }
                        onActivated: {
                            var ind1 = sampleSpinBox.value
                            var ind2 = classComboBox.currentIndex+1
                            get_image(resultDisplay,typeComboBox.type,[ind1,ind2])
                            imagetransferCanvas.update()
                            imagetransferCanvas.grabToImage(function(result) {
                                                       resultDisplay.source = result.url
                                                   });
                        }
                        Component.onCompleted: {
                            for (var i=0;i<classModel.count;i++) {
                                var class_var = classModel.get(i)
                                if (!class_var.notClass) {
                                    classeselectModel.append(
                                        {"name": class_var.name})
                                }
                            }
                            var num = classeselectModel.count
                            for (i=0;i<num;i++) {
                                if (classModel.get(i).border) {
                                    classeselectModel.append(
                                        {"name": classModel.get(i).name+" (border)"})
                                }
                            }
                            for (i=0;i<num;i++) {
                                if (classModel.get(i).border) {
                                    classeselectModel.append(
                                        {"name": classModel.get(i).name+" (applied border)"})
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
                        visible: Julia.get_settings(["Validation","use_labels"])
                        text: "Show:"
                        width: accuracytextLabel.width
                        topPadding: 10*pix
                    }
                    ComboBox {
                        id: typeComboBox
                        visible: Julia.get_settings(["Validation","use_labels"])
                        property string type: "predicted_data"
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
                                type = "predicted_data"
                            }
                            else if  (typeComboBox.currentIndex==1) {
                                type = "target_data"
                            }
                            else {
                                type = "error_data"
                            }
                            get_image(resultDisplay,type,
                                [sampleSpinBox.value,classComboBox.currentIndex+1])
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
        var size = Julia.get_image(["Validation_data",fieldname,type],
            [0,0],inds)
        return size
    }

    function mean(array) {
        var total = 0
        for(var i = 0;i<array.length;i++) {
            total += array[i]
        }
        return(total/array.length)
    }
}
