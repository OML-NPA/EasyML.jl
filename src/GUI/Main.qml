import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.Layouts 1.2
import Qt.labs.platform 1.1
import QtQml.Models 2.15
import Qt.labs.folderlistmodel 2.15
import "Templates"
import org.julialang 1.0


ApplicationWindow {
    id: window
    visible: true
    title: qsTr("  Open Machine Learning Software")
    minimumWidth: 1650*pix
    minimumHeight: 1240*pix
    color: defaultpalette.window
    property double pix: Screen.width/3840
    property double margin: 78*pix
    property double tabmargin: 0.5*margin
    property double buttonWidth: 384*pix
    property double buttonHeight: 65*pix
    property double panel_width: window.width - menuPane.width - 2*margin
    property color defaultcolor: palette.window

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

    property string currentfolder: Qt.resolvedUrl(".")

    onClosing: {
        Julia.save_settings()
    }

    header: Rectangle {
        width: window.width
        height: buttonHeight
        color: menuPane.backgroundColor

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

    GridLayout {
        id: gridLayout
        RowLayout {
            id: rowlayout
            Pane {
                id: menuPane
                spacing: 0
                padding: -1
                topPadding: 1
                width: 1.3*buttonWidth
                height: window.height
                backgroundColor: defaultpalette.window2
                Column {
                    id: menubuttonColumn
                    spacing: 0
                    Repeater {
                        id: menubuttonRepeater
                        Component.onCompleted: {menubuttonRepeater.itemAt(0).buttonfocus = true}
                        model: [{"name": "Main", "stackview": mainView},
                            {"name": "Options", "stackview": generalOptionsView},
                            {"name": "Training", "stackview": trainingView},
                            {"name": "Validation", "stackview": validationView},
                            {"name": "Application", "stackview": applicationView}]
                            //{"name": "Visualisation", "stackview": visualisationView}]
                        delegate : MenuButton {
                            id: general
                            width: 1.3*buttonWidth
                            height: 1.5*buttonHeight
                            font_size: 13
                            onClicked: {
                                if (window.header.children[0]!==undefined) {
                                    window.header.children[0].destroy()
                                }
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
                id: viewLayout
                Layout.margins: margin
                StackView {
                    id: stack
                    initialItem: mainView
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
                    MainView { id: mainView}
                    GeneralOptionsView { id: generalOptionsView}
                    TrainingView { id: trainingView}
                    ValidationView { id: validationView}
                    ApplicationView { id: applicationView}
                    VisualisationView { id: visualisationView}
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

//--Functions---------------------------------------------------------

    function delay(delayTime, cb) {
        function Timer() {
            return Qt.createQmlObject("import QtQuick 2.0; Timer {}", window);
        }
        var timer = new Timer();
        timer.interval = delayTime;
        timer.repeat = false;
        timer.triggered.connect(cb);
        timer.start();
    }

    function listProperty(item)
    {
        for (var p in item)
        {
            if( typeof item[p] != "function" )
                if(p !== "objectName")
                    console.log(p + ":" + item[p]);
        }

    }

    function debug(x) {
        console.log(x)
        return(x)
    }

    function abs(ar) {
        return array.map(Math.abs);
    }

    function mean(array) {
        var total = 0
        for(var i = 0;i<array.length;i++) {
            total += array[i]
        }
        return(total/array.length)
    }

    function sum(array) {
        var total = 0
        for(var i = 0;i<array.length;i++) {
            total += array[i]
        }
        return(total)
    }

    function rgbtohtml(colorRGB) {
        return(Qt.rgba(colorRGB[0]/255,colorRGB[1]/255,colorRGB[2]/255))
    }

    function importmodel(model,url) {
        model.length = 0
        var state = Julia.load_model(url)
        var skipStringing = ["x","y"]
        if (state!==null) {
            var count = Julia.model_count()
            for (var i=0;i<count;i++) {
                var indJ = i+1
                var unit = {}
                var properties = Julia.model_properties(indJ)
                for (var j=0;j<properties.length;j++) {
                    var prop_name = properties[j]
                    var prop = Julia.model_get_layer_property(indJ,prop_name)
                    if (typeof(prop)==='object' && prop.length===2) {
                        if (typeof(prop[0])==='string' && typeof(prop[1])==='number') {
                           unit[prop_name] = {"text": prop[0],"ind": prop[1]}
                        }
                        else {
                            unit[prop_name] = prop
                        }
                    }
                    else {
                        if (skipStringing.includes(prop_name) || typeof(prop)==='object') {
                            if (prop_name==="x" || prop_name==="y") {
                                prop = prop*pix
                            }
                            unit[prop_name] = prop
                        }
                        else {
                            unit[prop_name] = prop.toString()
                        }
                    }
                }
                model.push(unit)
            }
        }
        Julia.set_settings(["Training","model"],url)
    }

    function load_model_features(featureModel) {
        var num_features = Julia.num_features()
        if (featureModel.count!==0) {
            featureModel.clear()
        }
        for (var i=0;i<num_features;i++) {
            var ind = i+1
            var color = Julia.get_feature_field(ind,"color")
            var parents = Julia.get_feature_field(ind,"parents")
            var feature = {
                "name": Julia.get_feature_field(ind,"name"),
                "colorR": color[0],
                "colorG": color[1],
                "colorB": color[2],
                "border": Julia.get_feature_field(ind,"border"),
                "border_thickness": Julia.get_feature_field(ind,"border_thickness"),
                "borderRemoveObjs": Julia.get_feature_field(ind,"border_remove_objs"),
                "min_area": Julia.get_feature_field(ind,"min_area"),
                "parent": parents[0],
                "parent2": parents[1],
                "notFeature": Julia.get_feature_field(ind,"not_feature")}
            featureModel.append(feature)
        }
    }

    function stripURL(url) {
        return url.toString().replace("file:///","")
    }
}
