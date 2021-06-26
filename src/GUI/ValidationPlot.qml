
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
    title: qsTr("  EasyML")
    
    //---Universal property block-----------------------------------------------
    property double pix: Screen.width/3840*Julia.get_settings(["Options","Graphics","scaling_factor"])
    //property double defaultPixelSize: defaultPixelSize
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

    ListModel {
        id: classModel
        Component.onCompleted: {
            if (problem_type==0) {
            }
            else if (problem_type==1) {
            }
            else if (problem_type==2) {
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
        else if (problem_type==2) {
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
    
    minimumHeight: 1024*pix + showclassLabel.height + margin
    minimumWidth: informationPane.width + 1024*pix + margin
    color: defaultpalette.window
    property int input_type
    property int problem_type
    property bool use_labels

    property var accuracy: []
    property var loss: []
    property double mean_accuracy
    property double mean_loss
    property double accuracy_std
    property double loss_std
    property int decimals: 4
    property var predicted_labels: []
    property var target_labels: []
    property string fieldname

    onClosing: {
        Julia.put_channel("Validation",[0.0,0.0])
        //validateButton.text = "Validate"
        //progressbar.value = 0
        //validationplotLoader.sourceComponent = undefined
    }

    Popup {
        id: initialisationPopup
        modal: true
        visible: true
        closePolicy: Popup.NoAutoClose
        x: validationWindow.width/2 - width/2
        y: validationWindow.height/2 - height/2
        width: titleLabel.width + 0.8*margin
        height: titleLabel.height + 0.4*margin + 15*pix + 0.2*margin
        Label {
            id: titleLabel
            x: initialisationPopup.width/2 - width/2 - 12*pix
            leftPadding: 0
            topPadding: 0.10*margin
            text: "INITIALISATION"
        }
        Repeater {
            id: progressRepeater
            model: 3
            property var offsets: [-30*pix,0,30*pix]
            Rectangle {
                id: progress1Rectangle
                anchors.top: titleLabel.bottom
                anchors.topMargin: 0.1*margin
                x: initialisationPopup.width/2 - width/2 - progressRepeater.offsets[index] - 12*pix
                color: defaultcolors.dark
                visible: false
                width: 15*pix
                height: width
                radius: width
            }
        }
        Timer {
            id: initialisationTimer
            running: initialisationPopup.visible
            repeat: true
            interval: 300
            property double max_value: 0
            property double value: 0
            property double loading_state: 1
            onTriggered: {
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
            }
        }
    }

    Timer {
        id: validationTimer
        interval: 100
        running: true
        repeat: true
        property int iteration: 0
        property int max_iterations: -1
        
        property bool grabDone: false
        onTriggered: {
            while (true) {
                var state = Julia.get_progress("Validation")
                if (state===false) {
                    return
                }
                else {
                    var data = Julia.get_results("Validation")
                }
                if (max_iterations===-1) {
                    max_iterations = state
                    titleLabel.text = "MODEL COMPILATION"
                }
                else if (iteration<max_iterations) {
                    iteration += 1
                    validationProgressBar.value = iteration/max_iterations
                    var accuracy_temp = data[0]
                    var loss_temp = data[1]
                    accuracy.push(accuracy_temp)
                    loss.push(loss_temp)
                    if (iteration==1) {
                        initialisationPopup.visible = false
                        sampleSpinBox.value = 1
                        classComboBox.currentIndex = 0
                        var ind1 = 1
                        var size = Julia.get_image_size(["ValidationData",fieldname,"original"],[ind1])
                        var s = 1024*pix
                        var r = Math.min(s/size[0],s/size[1])
                        displayItem.height = size[0]*r
                        displayItem.width = size[1]*r
                        displayItem.image_height = size[0]
                        displayItem.image_width = size[1]
                        displayItem.scale = r
                        if (problem_type==0) {
                            Julia.get_image(["ValidationData","ImageClassificationResults","original"],[0,0],[ind1])
                            var predicted_label = Julia.get_data(["ValidationData","ImageClassificationResults","predicted_labels"],[iteration])
                            predicted_labels.push(predicted_label)
                            showclassLabel.visible = true
                            if (use_labels) {
                                var target_label = Julia.get_data(["ValidationData","ImageClassificationResults","target_labels"],[iteration])
                                target_labels.push(target_label)
                                showclassLabel.text = "Predicted: " + predicted_label + "; Real: " + target_label
                            }
                            else {
                                showclassLabel.text = "Predicted: " + predicted_label
                            }
                        }
                        else if (problem_type==1) {
                            Julia.get_image(["ValidationData","ImageRegressionResults","original"],[0,0],[ind1])
                            var predicted_label = Julia.get_data(["ValidationData","ImageRegressionResults","predicted_labels"],[iteration])
                            predicted_labels.push(predicted_label)
                            showclassLabel.visible = true
                            if (use_labels) {
                                var target_label = Julia.get_data(["ValidationData","ImageRegressionResults","target_labels"],[iteration])
                                decimals = countDecimals(target_label)
                                target_labels.push(target_label)
                                showclassLabel.text = "Predicted: " + anyToFixed(predicted_label,decimals) + "; Real: " + target_label
                            }
                            else {
                                showclassLabel.text = "Predicted: " + anyToFixed(predicted_label,decimals)
                            }
                        }
                        else if (problem_type==2) {
                            var ind2 = 1
                            Julia.get_image(["ValidationData","ImageSegmentationResults","original"],[0,0],[ind1])
                            Julia.get_image(["ValidationData","ImageSegmentationResults","predicted_data"],[0,0],[ind1,ind2])
                            resultDisplay.visible = true
                            resultDisplay.update()
                            classRow.visible = true
                            typeRow.visible = true
                            opacityRow.visible = true
                            zoomRow.visible = true
                        }
                        originalDisplay.update()
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
                            var predicted_label = Julia.get_data(["ValidationData","ImageClassificationResults","predicted_labels"],[iteration])
                            predicted_labels.push(predicted_label)
                            if (use_labels) {
                                var target_label = Julia.get_data(["ValidationData","ImageClassificationResults","target_labels"],[iteration])
                                    target_labels.push(target_label)
                            }
                        }
                        else if (problem_type==1) {
                            var predicted_label = Julia.get_data(["ValidationData","ImageRegressionResults","predicted_labels"],[iteration])
                            predicted_labels.push(predicted_label)
                            if (use_labels) {
                                var target_label = Julia.get_data(["ValidationData","ImageRegressionResults","target_labels"],[iteration])
                                    target_labels.push(target_label)
                            }
                        }
                        sampleSpinBox.to = iteration
                    }
                }
                else if (iteration===max_iterations) {
                    running = false
                }
            }
        }
        Component.onCompleted: {
            use_labels = Julia.get_settings(["Validation","use_labels"])
            var temp = Julia.get_settings(["input_type"])
            if (temp=="Image") {
                input_type = 0
            }
            var temp = Julia.get_settings(["problem_type"])
            if (temp=="Classification") {
                problem_type = 0
                fieldname = "ImageClassificationResults"
            }
            else if (temp=="Regression") {
                problem_type = 1
                fieldname = "ImageRegressionResults"
            }
            else if (temp=="Segmentation") {
                problem_type = 2
                fieldname = "ImageSegmentationResults"
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
                    displayPane.height = Math.floor(displayScrollableItem.height + showclassLabel.height
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
                    currentX: 0
                    currentY: 0
                    clip: true
                    Item {
                        id: displayItem
                        width: 1024*pix
                        height: 1024*pix
                        property double image_width: 1024*pix
                        property double image_height: 1024*pix
                        property double scale: 1
                        transform: Scale { origin.x: 0; origin.y: 0; 
                            xScale: displayItem.scale; yScale: displayItem.scale}
                        JuliaCanvas {
                            id: originalDisplay
                            width: displayItem.image_width
                            height: displayItem.image_height
                            paintFunction: display_original_image
                            smooth: false
                        }
                        JuliaCanvas {
                            id: resultDisplay
                            visible: false
                            width: displayItem.image_width
                            height: displayItem.image_height
                            opacity: 0.5
                            paintFunction: display_result_image
                            smooth: false
                        }
                    }
                }
                Label {
                    id: showclassLabel
                    anchors.horizontalCenter: resultColumn.horizontalCenter
                    topPadding: 0.5*margin
                    visible: false
                }
            }
        }
        Pane {
            id: informationPane
            x: validationWindow.width - 580*pix
            height: Math.max(1024*pix + margin + showclassLabel.height,displayPane.height)
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
                        onClicked: Julia.put_channel("Validation",[0.0,0.0])
                    }
                }
                Label {
                    visible: use_labels
                    topPadding: 0.2*margin
                    text: "Validation information"
                    font.bold: true
                }
                Row {
                    visible: use_labels
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
                    visible: use_labels
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
                        id: sampleLabel
                        text: "Sample:"
                        width: accuracytextLabel.width
                    }
                    SpinBox {
                        id: sampleSpinBox
                        anchors.verticalCenter: sampleLabel.verticalCenter
                        from: 1
                        value: 1
                        to: 1
                        stepSize: 1
                        editable: false
                        onValueModified: {
                            var ind1 = value - 1
                            accuracyLabel.text = accuracy[ind1].toFixed(2) + " (" + mean_accuracy.toFixed(2) + ")"
                            lossLabel.text = loss[ind1].toFixed(2) + " (" + mean_loss.toFixed(2) + ")"
                            var size = Julia.get_image_size(["ValidationData",fieldname,"original"],[ind1+1])
                            var s = 1024*pix
                            var r = Math.min(s/size[0],s/size[1])
                            displayItem.height = size[0]*r
                            displayItem.width = size[1]*r
                            displayItem.image_height = size[0]
                            displayItem.image_width = size[1]
                            displayItem.scale = r
                            Julia.get_image(["ValidationData",fieldname,"original"],[0,0],[ind1+1])
                            originalDisplay.update()
                            if (problem_type==0) {
                                if (use_labels) {
                                    showclassLabel.text = "Predicted: " + predicted_labels[ind1] + "; Real: " + target_labels[ind1]
                                }
                                else {
                                    showclassLabel.text = "Predicted: " + predicted_labels[ind1]
                                }
                            }
                            if (problem_type==1) {
                                if (use_labels) {
                                    showclassLabel.text = "Predicted: " + anyToFixed(predicted_labels[ind1],decimals) + "; Real: " + target_labels[ind1]
                                }
                                else {
                                    showclassLabel.text = "Predicted: " + anyToFixed(predicted_labels[ind1],decimals)
                                }
                            }
                            else if (problem_type==2) {
                                var ind2 = classComboBox.currentIndex
                                Julia.get_image(["ValidationData","ImageSegmentationResults",typeComboBox.type],[0,0],[ind1+1,ind2+1])
                                resultDisplay.visible = true
                                resultDisplay.update()
                            }
                        }
                    }
                }
                Row {
                    id: classRow
                    visible: false
                    spacing: 0.3*margin
                    Label {
                        id: classLabel
                        text: "Class:"
                        width: accuracytextLabel.width
                    }
                    ComboBox {
                        id: classComboBox
                        anchors.verticalCenter: classLabel.verticalCenter
                        editable: false
                        width: 0.76*buttonWidth
                        model: ListModel {
                            id: classeselectModel
                        }
                        onActivated: {
                            var ind1 = sampleSpinBox.value
                            var ind2 = classComboBox.currentIndex
                            Julia.get_image(["ValidationData","ImageSegmentationResults",typeComboBox.type],[0,0],[ind1,ind2+1])
                            resultDisplay.update()
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
                        id: typeLabel
                        visible: use_labels
                        text: "Show:"
                        width: accuracytextLabel.width
                    }
                    ComboBox {
                        id: typeComboBox
                        anchors.verticalCenter: typeLabel.verticalCenter
                        visible: use_labels
                        property string type: "predicted_data"
                        editable: false
                        currentIndex: 0
                        width: 0.76*buttonWidth
                        model: ListModel {
                            id: typeModel
                            ListElement {name: "Result"}
                            ListElement {name: "Target"}
                            ListElement {name: "Error"}
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
                            var ind1 = sampleSpinBox.value
                            var ind2 = classComboBox.currentIndex
                            Julia.get_image(["ValidationData","ImageSegmentationResults",type],[0,0],[ind1,ind2+1])
                            resultDisplay.update()
                        }
                    }
                }
                Row {
                    id: opacityRow
                    visible: false
                    spacing: 0.3*margin
                    Label {
                        id: opacityLabel
                        text: "Opacity:"
                        width: accuracytextLabel.width
                    }
                    Slider {
                        anchors.verticalCenter: opacityLabel.verticalCenter
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
                    spacing: 0.3*margin
                    Label {
                        id: zoomLabel
                        text: "Zoom:"
                        width: accuracytextLabel.width
                    }
                    Slider {
                        anchors.verticalCenter: zoomLabel.verticalCenter
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
                            var midPointX = displayScrollableItem.contentX + 512*pix
                            var midPointY = displayScrollableItem.contentY + 512*pix
                            var newWidth = displayItem.width*ratio
                            var newHeight = displayItem.height*ratio
                            displayScrollableItem.contentX = midPointX/(displayItem.width)*newWidth - 512*pix
                            displayScrollableItem.contentY = midPointY/(displayItem.height)*newHeight - 512*pix
                            displayItem.width = newWidth
                            displayItem.height = newHeight
                            displayItem.scale = displayItem.scale*ratio
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

    function mean(array) {
        var total = 0
        for(var i = 0;i<array.length;i++) {
            total += array[i]
        }
        return(total/array.length)
    }

    function countDecimals(value) {
        if (Math.floor(value) == value) {
            return 0
        }
        else {
            return value.toString().split(".")[1].length
        }
    }

    function anyToFixed(input,decimals) {
        if (Array.isArray(input)) {
            var out = []
            for(var i = 0;i<input.length;i++) {
                out.push(input[i].toFixed(decimals))
            }
            return out
        }
        else {
            return input.toFixed(decimals)
        }
    }

}
