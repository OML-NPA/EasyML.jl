
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.Layouts 1.2
import Qt.labs.platform 1.1
import QtQml.Models 2.15
import QtCharts 2.15
import org.julialang 1.0
import "templates"


ApplicationWindow {
    id: trainingWindow
    visible: true
    title: qsTr("EasyML")
    minimumWidth: gridLayout.width
    minimumHeight: gridLayout.height
    maximumWidth: gridLayout.width
    maximumHeight: gridLayout.height
    
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
    //---Jield timer block-----------------------------------------------------
    Timer {
        id: yieldTimer
        running: true
        repeat: true
        interval: 1
        onTriggered: {Julia.yield()}
    }
    //-------------------------------------------------------------------------
    
    color: defaultpalette.window

    onClosing: {
        Julia.put_channel("training_modifiers",[0.0,0.0])
    }

    function show_warnings() {
        var warnings = Julia.get_data(["TrainingData","warnings"])
        if (warnings.length>0) {
            for (var i=0;i<warnings.length;i++) {
                warningPopup.warnings.push(warnings[i])
            }
            warningPopup.visible = true
            Julia.set_data(["TrainingData","warnings"],[])
        }
    }

    function show_errors() {
        var errors = Julia.get_data(["TrainingData","errors"])
        if (errors.length>0) {
            for (var i=0;i<errors.length;i++) {
                errorPopup.errors.push(errors[i])
            }
            errorPopup.visible = true
            Julia.set_data(["TrainingData","errors"],[])
            return true
        }
        return false
    }

    Popup {
        id: warningPopup
        modal: true
        visible: false
        closePolicy: Popup.NoAutoClose
        x: trainingWindow.width/2 - width/2
        y: trainingWindow.height/2 - height/2
        width: Math.max(warningtitleLabel.width,warningtextLabel.width) + 0.8*margin
        height: warningtitleLabel.height + warningtextLabel.height 
            + okButton.height + 0.4*margin + okButton.height
        property var warnings: []
        onVisibleChanged: {
            if (visible) {
                if (warnings.length!==0) {
                    warningtextLabel.text = warnings[0]
                    warnings.shift()
                }
            }
            if (Julia.unit_test()) {
                trainingWindow.close()
            }
        }
        Label {
            id: warningtitleLabel
            x: warningPopup.width/2 - width/2 - 12*pix
            leftPadding: 0
            topPadding: 0.25*margin
            text: "WARNING"
        }
        Label {
            id: warningtextLabel
            x:warningPopup.width/2 - width/2 - 12*pix
            leftPadding: 0
            anchors.top: warningtitleLabel.bottom
            topPadding: 0.4*margin
        }
        Button {
            id: okButton
            width: buttonWidth/2
            x: warningPopup.width/2 - width/2 - 12*pix
            anchors.top: warningtextLabel.bottom
            anchors.topMargin: 0.4*margin
            text: "OK"
            onClicked: {
                if (warningPopup.warnings.length!==0) {
                    warningtextLabel.text = warningPopup.warnings[0]
                    warningPopup.warnings.shift()
                }
                else {
                    warningPopup.visible = false
                }
            }
        }
    }
    
    Popup {
        id: errorPopup
        modal: true
        visible: false
        closePolicy: Popup.NoAutoClose
        x: trainingWindow.width/2 - width/2
        y: trainingWindow.height/2 - height/2
        width: Math.max(errortitleLabel.width,errortextLabel.width) + 0.8*margin
        height: errortitleLabel.height + errortextLabel.height 
            + okButton.height + 0.4*margin + okButton.height
        property var errors: []
        onVisibleChanged: {
            if (visible) {
                if (errors.length!==0) {
                    errortextLabel.text = errors[0]
                    errors.shift()
                }
            }
            if (Julia.unit_test()) {
                trainingWindow.close()
            }
        }
        Label {
            id: errortitleLabel
            x: errorPopup.width/2 - width/2 - 12*pix
            leftPadding: 0
            topPadding: 0.25*margin
            text: "ERROR"
        }
        Label {
            id: errortextLabel
            x:errorPopup.width/2 - width/2 - 12*pix
            leftPadding: 0
            anchors.top: errortitleLabel.bottom
            topPadding: 0.4*margin
        }
        Button {
            id: errorokButton
            width: buttonWidth/2
            x: errorPopup.width/2 - width/2 - 12*pix
            anchors.top: errortextLabel.bottom
            anchors.topMargin: 0.4*margin
            text: "OK"
            onClicked: {
                if (errorPopup.errors.length!==0) {
                    errortextLabel.text = errorPopup.errors[0]
                    errorPopup.errors.shift()
                }
                else {
                    errorPopup.visible = false
                    trainingWindow.close()
                }
            }
        }
    }

    Timer {
        id: warningerrorTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            show_warnings()
            var state = show_errors()
            if (state==true) {
                trainingTimer.running = false
            }
        }
    }

    Popup {
        id: initialisationPopup
        modal: true
        visible: true
        closePolicy: Popup.NoAutoClose
        x: trainingWindow.width/2 - width/2
        y: trainingWindow.height/2 - height/2
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
        id: trainingTimer
        property int iteration: 0
        property int epochs: 0
        property int epoch: 0
        property int iterations_per_epoch: 0
        property int max_iterations: 0
        property bool done: false
        property string channel_name: "training_start_progress"
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            while (true) {
                var data = Julia.get_progress(channel_name)
                if (data===false) {return}
                if (epoch===0) {
                    channel_name = "training_progress"
                    Julia.set_training_starting_time()
                    epoch = 1
                    epochs = data[0]
                    iterations_per_epoch = data[1]
                    max_iterations = data[2]
                    epochLabel.text = 1
                    iterationsperepochLabel.text = iterations_per_epoch
                    currentiterationLabel.text = 1
                    maxiterationsLabel.text = max_iterations
                    titleLabel.text = "COMPILATION"
                    if (Julia.unit_test()) {
                        Julia.put_channel("training_modifiers",[1.0,0.0001])
                        Julia.put_channel("training_modifiers",[2.0,1])
                        Julia.put_channel("training_modifiers",[3.0,2])
                    }
                }
                else if (data[0]==="Training") {
                    var accuracy = data[1]
                    var loss = data[2]
                    iteration += 1
                    accuracyLine.append(iteration,100*accuracy)
                    lossLine.append(iteration,loss)
                    if (loss>lossLine.axisY.max) {
                        lossLine.axisY.max = loss
                    }
                    accuracyAxisX.max = iteration+1
                    accuracyAxisX.tickInterval = Math.round(iteration/10)+1
                    lossAxisX.max = iteration + 1
                    lossAxisX.tickInterval = Math.round(iteration/10)+1
                }
                else if (data[0]==="Testing") {
                    var test_accuracy = data[1]
                    var test_loss = data[2]
                    var test_iteration = data[3]
                    accuracytestLine.append(test_iteration,100*test_accuracy)
                    losstestLine.append(test_iteration,test_loss)
                    if (test_loss>lossLine.axisY.max) {
                        lossLine.axisY.max = test_loss
                    }
                }
                if ((iteration===max_iterations && max_iterations!==0) || trainingTimer.done) {
                    running = false
                    if (Julia.unit_test()) {
                        stopButton.clicked(null)
                        trainingWindow.close()
                    }
                }
                if ((iteration/iterations_per_epoch)>epoch && max_iterations!==0) {
                    addEpochLine()
                    epoch += 1
                    epochLabel.text = epoch
                }
                if (iteration==1) {
                    initialisationPopup.visible = false
                }
                currentiterationLabel.text = iteration
                trainingProgressBar.value = iteration/max_iterations
                elapsedtimelabel.text = Julia.training_elapsed_time()
            }
        }
    }
    GridLayout {
        id: gridLayout
        Row {
            Column {
                id: plotsColumn
                Label {
                    topPadding: 0.5*margin
                    text: "Training progress"
                    anchors.horizontalCenter: plotsColumn.horizontalCenter
                    font.bold: true
                }
                Row {
                    spacing: 0
                    Label {
                        text: "Accuracy (%)"
                        rotation : 270
                        anchors.verticalCenter: accuracyChartColumn.verticalCenter
                        topPadding: -1.1*margin
                    }
                    Column {
                        id: accuracyChartColumn
                        leftPadding: -1.21*margin
                        ChartView {
                            id: accuracyChartView
                            height: 10*margin
                            width: 15*margin
                            backgroundColor : defaultpalette.window
                            plotAreaColor : defaultpalette.listview
                            antialiasing: true
                            legend.visible: false
                            margins { right: 0.3*margin; bottom: 0; left: 0; top: 0 }
                            ValueAxis {
                                    id: accuracyAxisX
                                    min: 1
                                    max: 2
                                    labelsFont.pixelSize: defaultPixelSize*11/12
                                    tickType: ValueAxis.TicksDynamic
                                    tickInterval: 1
                                    labelFormat: "%i"
                                }
                            ValueAxis {
                                    id: accuracyAxisY
                                    labelsFont.pixelSize: defaultPixelSize*11/12
                                    tickInterval: 10
                                    tickType: ValueAxis.TicksDynamic
                                    min: 0
                                    max: 100
                                    labelFormat: "%i"
                            }
                            LineSeries {
                                id: accuracyLine
                                axisX: accuracyAxisX
                                axisY: accuracyAxisY
                                width: 4*pix
                                color: "#3498db"
                            }
                            LineSeries {
                                id: accuracytestLine
                                axisX: accuracyAxisX
                                axisY: accuracyAxisY
                                width: 4*pix
                                color: "#163E5A"
                                style: Qt.DashLine
                            }
                        }
                        Label {
                            text: "Iteration"
                            topPadding: -0.3*margin
                            leftPadding: -2.75*margin
                            anchors.horizontalCenter: accuracyChartView.horizontalCenter
                        }
                    }
                }
                Row {
                    spacing: 0
                    Label {
                        text: "Loss"
                        rotation : 270
                        leftPadding: 0.9*margin
                        anchors.verticalCenter: lossChartColumn.verticalCenter
                        topPadding: -0.2*margin
                    }
                    Column {
                        id: lossChartColumn
                        leftPadding: -0.69*margin
                        ChartView {
                            id: lossChartView
                            height: 6*margin
                            width: 15.3*margin
                            backgroundColor : defaultpalette.window
                            plotAreaColor : defaultpalette.listview
                            antialiasing: true
                            legend.visible: false
                            margins { right: 0.3*margin; bottom: 0; left: 0*margin; top: 0 }
                            ValueAxis {
                                    id: lossAxisX
                                    min: 1
                                    max: 2
                                    labelsFont.pixelSize: defaultPixelSize*11/12
                                    tickType: ValueAxis.TicksDynamic
                                    tickInterval: 1
                                    labelFormat: "%i"
                            }
                            ValueAxis {
                                    id: lossAxisY
                                    labelsFont.pixelSize: defaultPixelSize*11/12
                                    tickType: ValueAxis.TicksFixed
                                    tickCount: 6
                                    min: 0
                                    max: 0.01
                                    labelFormat: "%.3f"
                            }
                            LineSeries {
                                id: lossLine
                                axisX: lossAxisX
                                axisY: lossAxisY
                                width: 4*pix
                                color: "#e67e22"
                            }
                            LineSeries {
                                id: losstestLine
                                axisX: lossAxisX
                                axisY: lossAxisY
                                width: 4*pix
                                color: "#5E340E"
                                style: Qt.DashLine
                            }
                        }
                        Label {
                            text: "Iteration"
                            topPadding: -0.3*margin
                            leftPadding: -1*margin
                            bottomPadding: 0.5*margin
                            anchors.horizontalCenter: lossChartView.horizontalCenter
                        }
                    }
                }
            }
            Pane {
                height: plotsColumn.height
                backgroundColor: defaultpalette.window2
                Column {
                    padding: 0.5*margin
                    Row {
                        id: progressbarheader
                        spacing: 0
                        Label {
                            text: "Training iteration  "
                        }
                        Label {
                            id: currentiterationLabel
                            text: ""
                        }
                        Label {
                            text: "  of  "
                        }
                        Label {
                            id: maxiterationsLabel
                            text: ""
                        }
                    }
                    Row {
                        topPadding: 0.25*margin
                        spacing: 0.3*margin
                        ProgressBar {
                            id: trainingProgressBar
                            width: 1.2*buttonWidth
                            height: buttonHeight
                        }
                        StopButton {
                            id: stopButton
                            width: buttonHeight
                            height: buttonHeight
                            anchors.verticalCenter: trainingProgressBar.verticalCenter
                            onClicked: {
                                Julia.put_channel("training_modifiers",[0.0,0.0])
                            }
                        }
                    }
                    Column {
                        spacing: 0.4*margin
                        Label {
                            topPadding: 0.5*margin
                            text: "Training time"
                            font.bold: true
                        }
                        Row {
                            spacing: 0.3*margin
                            Label {
                                text: "Start time:"
                                width: elapsedtimeLabel.width
                            }
                            Label {
                                id: starttimeLabel
                                text: Julia.time()
                            }
                        }
                        Row {
                            spacing: 0.3*margin
                            Label {
                                id: elapsedtimeLabel
                                text: "Elapsed time:"
                            }
                            Label {
                                id: elapsedtimelabel
                                Layout.topMargin: 0.2*margin
                                text: ""
                            }
                        }
                        Label {
                            topPadding: 0.5*margin
                            text: "Training cycle"
                            font.bold: true
                        }
                        Row {
                            spacing: 0.3*margin
                            Label {
                                text: "Epoch:"
                                width: iterationsperepochtextLabel.width
                            }
                            Label {
                                id: epochLabel
                                text: ""
                            }
                        }
                        Row {
                            spacing: 0.3*margin
                            Label {
                                id: iterationsperepochtextLabel
                                text: "Iterations per epoch:"
                            }
                            Label {
                                id: iterationsperepochLabel
                                Layout.topMargin: 0.2*margin
                                text: ""
                            }
                        }
                        Label {
                            topPadding: 0.5*margin
                            text: "Other information:"
                            font.bold: true
                        }
                        Row {
                            spacing: 0.3*margin
                            Label {
                                text: "Hardware resource:"
                            }
                            Label {
                                id: hardwareresource
                                Layout.topMargin: 0.2*margin
                                text: Julia.get_options(["GlobalOptions",
                                    "HardwareResources","allow_GPU"]) ? "GPU" : "CPU"
                            }
                        }
                        Label {
                            topPadding: 0.5*margin
                            text: "Controls:"
                            font.bold: true
                        }
                        Row {
                            spacing: 0.3*margin
                            Label {
                                id: numepochsLabel
                                text: "Number of epochs:"
                            }
                            SpinBox {
                                anchors.verticalCenter: numepochsLabel.verticalCenter
                                from: trainingTimer.epoch
                                value: Julia.get_options(
                                            ["TrainingOptions","Hyperparameters","epochs"])
                                to: 10000
                                stepSize: 1
                                editable: false
                                onValueModified: {
                                    Julia.put_channel("training_modifiers",[2.0,value])
                                    trainingTimer.epochs = value
                                    trainingTimer.max_iterations =
                                            value*trainingTimer.iterations_per_epoch
                                    maxiterationsLabel.text = trainingTimer.max_iterations
                                }
                            }
                        }
                        Row {
                            spacing: 0.3*margin
                            Label {
                                id: learningrateLabel
                                text: "Learning rate:"
                                width: numepochsLabel.width
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
                                    return Number(realValue).toLocaleString(locale,'e',0)
                                }
                                onValueModified: {
                                    Julia.put_channel("training_modifiers",[1.0,realValue])
                                }
                                Component.onCompleted: {
                                    var optimisers = ["Descent","Momentum",
                                        "Nesterov","RMSProp","ADAM","RADAM","AdaMax",
                                        "ADAGrad","ADADelta","AMSGrad","NADAM","ADAMW"]
                                    var allow_lr = [true,true,true,true,true,true,true,
                                        true,false,true,true,true]
                                    var name = Julia.get_options(
                                        ["TrainingOptions","Hyperparameters","optimiser"])
                                    for (var i=0;i<optimisers.length;i++) {
                                        if (name==optimisers[i]) {
                                            var visibility = allow_lr[i]
                                            learningrateSpinBox.visible = visibility
                                            learningrateLabel.visible = visibility
                                        }
                                    }
                                }
                            }
                        }
                        Row {
                            id: numtestsRow
                            visible: Julia.get_data(["TrainingData","OptionsData","run_test"])
                            spacing: 0.3*margin
                            Label {
                                id: numtestsLabel
                                text: "Number of tests:"
                                width: numepochsLabel.width
                            }
                            SpinBox {
                                anchors.verticalCenter: numtestsLabel.verticalCenter
                                from: 0
                                value: Julia.get_options(["TrainingOptions","Testing","num_tests"])
                                to: 10000
                                stepSize: 1
                                editable: true
                                onValueModified: {
                                    Julia.put_channel("training_modifiers",[3.0,value])
                                }
                                Component.onCompleted: {
                                    if (value==0) {
                                        numtestsRow.visible = false
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        MouseArea {
            width: trainingWindow.width
            height: trainingWindow.height
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

    function addEpochLine() {
        var accuracyEpochLine = accuracyChartView.createSeries(ChartView.SeriesTypeLine, "Epoch line", accuracyAxisX, accuracyAxisY);
        var lossEpochLine = lossChartView.createSeries(ChartView.SeriesTypeLine, "Epoch line", lossAxisX, lossAxisY);
        accuracyEpochLine.append(trainingTimer.iteration,0)
        accuracyEpochLine.append(trainingTimer.iteration,200)
        lossEpochLine.append(trainingTimer.iteration,0)
        lossEpochLine.append(trainingTimer.iteration,100000000)
        accuracyEpochLine.color = "black"
        lossEpochLine.color = "black"
        accuracyEpochLine.opacity = 0.25
        lossEpochLine.opacity = 0.25
    }

}
