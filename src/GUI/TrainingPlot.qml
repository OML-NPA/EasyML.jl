
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.Layouts 1.2
import Qt.labs.platform 1.1
import QtQml.Models 2.15
import QtCharts 2.15
import "Templates"
import org.julialang 1.0


ApplicationWindow {
    id: trainingWindow
    visible: true
    title: qsTr("  EasyML")
    minimumWidth: gridLayout.width
    minimumHeight: gridLayout.height
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
        Julia.put_channel("Training",["stop"])
        //trainButton.text = "Train"
        //progressbar.value = 0
        //trainingplotLoader.sourceComponent = undefined
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
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            while (true) {
                var data = Julia.get_progress("Training")
                if (data===false) {return}
                if (epoch===0) {
                    Julia.set_training_starting_time()
                    epoch = 1
                    epochs = data[0]
                    iterations_per_epoch = data[1]
                    max_iterations = data[2]
                    epochLabel.text = 1
                    iterationsperepochLabel.text = iterations_per_epoch
                    currentiterationLabel.text = 1
                    maxiterationsLabel.text = max_iterations
                    titleLabel.text = "MODEL COMPILATION"
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
                    // var state = Julia.get_results("Training")
                    //if (state===true) {
                        running = false
                    //}
                }
                if ((iteration/iterations_per_epoch)>epoch && max_iterations!==0) {
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
            Layout.alignment : Qt.AlignTop
            ColumnLayout {
                id: plots
                Label {
                    Layout.topMargin: 0.5*margin
                    text: "Training progress"
                    Layout.alignment : Qt.AlignHCenter | Qt.AligTop
                    font.bold: true
                }
                RowLayout {
                    spacing: 0
                    Label {
                        text: "Accuracy (%)"
                        rotation : 270
                        Layout.alignment : Qt.AlignHCenter
                        topPadding: -1.25*margin
                        leftPadding: margin
                    }
                    ColumnLayout {
                        ChartView {
                            id: accuracyChartView
                            Layout.preferredHeight: 10*margin
                            Layout.preferredWidth: 15*margin
                            Layout.leftMargin: -2.25*margin
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
                            Layout.topMargin: -0.3*margin
                            Layout.leftMargin: -2.75*margin
                            Layout.alignment : Qt.AlignHCenter
                        }
                    }
                }
                RowLayout {
                    spacing: 0
                    Label {
                        text: "Loss"

                        rotation : 270
                        Layout.alignment : Qt.AlignHCenter
                        topPadding: -0.25*margin
                        leftPadding: margin
                    }
                    ColumnLayout {
                        ChartView {
                            id: lossChartView
                            Layout.preferredHeight: 6*margin
                            Layout.preferredWidth: 15.3*margin
                            Layout.leftMargin: -0.85*margin
                            backgroundColor : defaultpalette.window
                            plotAreaColor : defaultpalette.listview
                            antialiasing: true
                            legend.visible: false
                            margins { right: 0.3*margin; bottom: 0; left: 0; top: 0 }
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
                            Layout.topMargin: -0.3*margin
                            Layout.leftMargin: -1*margin
                            Layout.bottomMargin: 0.5*margin
                            Layout.alignment : Qt.AlignHCenter
                        }
                    }
                }
            }
            Pane {
                height: plots.height
                backgroundColor: defaultpalette.window2
                ColumnLayout {
                    ColumnLayout {
                        Layout.margins: 0.5*margin
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
                        RowLayout {
                            ProgressBar {
                                id: trainingProgressBar
                                Layout.preferredWidth: 1.34*buttonWidth
                                Layout.preferredHeight: buttonHeight
                                Layout.alignment: Qt.AlignVCenter
                            }
                            StopButton {
                                id: stoptraining
                                Layout.preferredWidth: buttonHeight
                                Layout.preferredHeight: buttonHeight
                                Layout.leftMargin: 0.3*margin
                                onClicked: {
                                    Julia.put_channel("Training",["stop"])
                                    //var stop = false
                                    //while (!stop) {
                                    //    stop = Julia.get_results("Training")
                                    //    Julia.sleep(0.1)
                                    //}
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
                                    width: iterationsperepochtextLabel.width
                                }
                                Label {
                                    id: starttimeLabel
                                    text: Julia.time()
                                }
                            }
                            Row {
                                spacing: 0.3*margin
                                Label {
                                    text: "Elapsed time:"
                                    width: iterationsperepochtextLabel.width
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
                                    width: iterationsperepochtextLabel.width
                                }
                                Label {
                                    id: hardwareresource
                                    Layout.topMargin: 0.2*margin
                                    text: Julia.get_settings(["Options",
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
                                    text: "Number of epochs:"
                                    width: iterationsperepochtextLabel.width
                                }
                                SpinBox {
                                    from: trainingTimer.epoch
                                    value: Julia.get_settings(
                                               ["Training","Options","Hyperparameters","epochs"])
                                    to: 10000
                                    stepSize: 1
                                    editable: false
                                    onValueModified: {
                                        Julia.put_channel("Training",["epochs",value])
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
                                    visible: Julia.get_settings(
                                                 ["Training","Options","Hyperparameters","allow_lr_change"])
                                    text: "Learning rate:"
                                    width: iterationsperepochtextLabel.width
                                }
                                SpinBox {
                                    visible: Julia.get_settings(
                                                 ["Training","Options","Hyperparameters","allow_lr_change"])
                                    from: 1
                                    value: 100000*Julia.get_settings(
                                               ["Training","Options","Hyperparameters","learning_rate"])
                                    to: 1000
                                    stepSize: value>100 ? 100 :
                                              value>10 ? 10 : 1
                                    editable: false
                                    property real realValue: value/100000
                                    textFromValue: function(value, locale) {
                                        return Number(value/100000).toLocaleString(locale,'e',0)
                                    }
                                    onValueModified: {
                                        Julia.put_channel("Training",["learning rate",value/100000])
                                    }
                                }
                            }
                            Row {
                                visible: Julia.get_settings(
                                    ["Training","Options","General","test_data_fraction"])!==0
                                spacing: 0.3*margin
                                Label {
                                    id: testingfrLabel
                                    text: "Testing frequency:"
                                    width: iterationsperepochtextLabel.width
                                }
                                SpinBox {
                                    from: 0
                                    value: Julia.get_settings(
                                               ["Training","Options","General","testing_frequency"])
                                    to: 10000
                                    stepSize: 1
                                    editable: true
                                    onValueModified: {
                                        Julia.put_channel("Training",["testing frequency",value])
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
}
