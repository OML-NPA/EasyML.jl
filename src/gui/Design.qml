
import QtQuick 2.15
import Qt.labs.platform 1.1
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.Layouts 1.1
import QtQml.Models 2.15
import QtQuick.Shapes 1.15
import Qt.labs.folderlistmodel 2.15
import org.julialang 1.0
import "templates"


ApplicationWindow {
    id: designWindow
    visible: true
    title: qsTr("  EasyML")
    minimumWidth: 2500*pix
    minimumHeight: 1500*pix

    color: defaultpalette.window

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
//-------------------------------------------------------------------------

    property double paneHeight: designWindow.height - 4*pix
    property double paneWidth: designWindow.width-leftFrame.width-rightFrame.width-4*pix

    property bool optionsOpen: false
    property bool localtrainingOpen: false
    property double iconSize: 70*pix

    Loader { id: designoptionsLoader}

//---Julia package block--------------------------------------------------
    property var model: []
    Component.onCompleted: {
        importmodel(model)
        if (Julia.unit_test()) {
            function test_func() {
                saveButton.clicked(null)
                arrangeButton.clicked(null)
                optionsButton.clicked(null)
                designWindow.close()
            }
            function Timer() {
                return Qt.createQmlObject("import QtQuick 2.0; Timer {}", designWindow);
            }
            function delay(delayTime, cb) {
                var timer = new Timer();
                timer.interval = delayTime;
                timer.repeat = false;
                timer.triggered.connect(cb);
                timer.start();
            }
            delay(1000, test_func)
        }
    }

//------------------------------------------------------------------------

    property int idCounter: 0

    onWidthChanged: {
        if (layers.children.length>0) {
            mainFrame.width = designWindow.width-leftFrame.width-rightFrame.width
            mainFrame.height = designWindow.height
            updateMainPane(layers.children[0])
        }
    }

    Item {
        id: cache
        visible: false
    }
    QtObject {
        id: copycache
        property var objectsdata: []
        property var connections: []
        property var ids: []
    }

    Item {
        id: customizationItem
        focus: true
        Keys.onPressed: {
            if (event.key===Qt.Key_Backspace || event.key===Qt.Key_Delete) {
                var inds = mainPane.selectioninds
                for (var k=0;k<inds.length;k++) {
                    var unit = layers.children[inds[k]]
                    var upNodes = getUpNodes(unit)
                    var downNodes = getDownNodes(unit) 
                    for (var i=0;i<upNodes.children.length;i++) {
                        var upNode = upNodes.children[i].children[0]
                        if (upNode.connectedNode!==null) {
                            if (upNode.connectedNode.parent.children.length<4) {
                                upNode.connectedNode.visible = false
                            }
                            upNode.connectedItem.connectedNode = null
                            upNode.connectedItem.connection.destroy()
                            upNode.connectedItem.destroy()
                        }
                    }
                    for (i=0;i<downNodes.children.length;i++) {
                        for (var j=1;j<downNodes.children[i].children.length;j++) {
                            var downNode = downNodes.children[i].children[j]
                            if (downNode.connectedNode!==null) {
                                downNode.connectedNode.visible = false
                                downNode.connectedNode.connectedNode = null
                                downNode.connectedNode.connectedItem = null
                                downNode.connection.destroy()
                            }
                        }
                    }
                    unit.destroy()
                }
                mainPane.selectioninds = []
                updateOverview()
                propertiesStackView.push(generalpropertiesComponent)
            }
            else if ((event.key===Qt.Key_A) && (event.modifiers && Qt.ControlModifier)) {
                for (i=0;i<layers.children.length;i++){
                    selectunit(layers.children[i])
                    mainPane.selectioninds.push(i)
                }
            }
            else if ((event.key===Qt.Key_C) && (event.modifiers && Qt.ControlModifier)) {
                copycache.objectsdata = []
                copycache.connections = []
                copycache.ids = []
                for (i=0;i<mainPane.selectioninds.length;i++) {
                    var ind = mainPane.selectioninds[i]
                    unit = layers.children[ind]
                    var data = {"color": unit.color,
                                "name": unit.name,
                                "type": unit.type,
                                "group": unit.group,
                                "label_color": unit.label_color,
                                "inputnum": unit.inputnum,
                                "outputnum": unit.outputnum,
                                "x": unit.x,
                                "y": unit.y,
                                "datastore": copy(unit.datastore)}
                    copycache.objectsdata.push(data)
                    copycache.ids.push(ind)
                    copycache.connections.push(getconnections(unit,0))
                }
            }
            else if ((event.key===Qt.Key_V) && (event.modifiers && Qt.ControlModifier)) {
                var startInd = layers.children.length
                var selectioninds = mainPane.selectioninds
                for (i=0;i<copycache.objectsdata.length;i++) {
                    data = copycache.objectsdata[i]
                    idCounter += 1
                    var id = idCounter
                    unit = layerComponent.createObject(layers,{
                       "color" : data.color,
                       "id": id,
                       "name": data.name,
                       "type": data.type,
                       "group": data.group,
                       "label_color": data.label_color,
                       "inputnum": copycache.connections[i].up.length,
                       "outputnum": copycache.connections[i].down.length,
                       "x": data.x+20*pix,
                       "y": data.y+20*pix,
                       "datastore": data.datastore})
                }
                for (i=0;i<copycache.objectsdata.length;i++) {
                    data = copycache.objectsdata[i]
                    var ids = copycache.ids[i]
                    var conns_all = copycache.connections[i]
                    var connections_down = conns_all.down
                    for (j=0;j<connections_down.length;j++) {
                        var conns = connections_down[j]
                        for (var l=0;l<conns.length;l++) {
                            var conn = conns[l]
                            if (copycache.ids.includes(conn)) {
                                var conn_real = startInd + copycache.ids.indexOf(conn)
                                unit = layers.children[startInd+i]

                                var unit_connected = layers.children[conn]
                                var new_unit_connected = layers.children[conn_real]

                                downNode = getDownNode(unit,j)
                                var downNodeRectangle = getDownNodeRec(unit,j,l+1)
                                ind = -1
                                var connections_up = getconnections(unit_connected,0).up
                                for (var a=0;a<connections_up.length;a++) {
                                    if ((connections_up[a])===copycache.ids[i]) {
                                        ind = a
                                    }
                                }
                                if (ind===-1) {
                                    continue
                                }
                                upNode = getUpNode(new_unit_connected,ind)
                                makeConnection(unit,downNode,downNodeRectangle,upNode)
                            }
                        }
                    }
                }
                propertiesStackView.push(generalpropertiesComponent)
                mainPane.selectioninds = range(startInd, layers.children.length-1, 1)
                for (i=0;i<mainPane.selectioninds.length;i++) {
                    unit = layers.children[mainPane.selectioninds[i]]
                    if (unit!==undefined) {
                        selectunit(unit)
                    }
                }
                updateOverview()
            }
        }
        Frame {
            id: leftFrame
            z: 1
            height: designWindow.height + 1*pix
            width: 530*pix + 1*pix
            padding:0
            Item {
                id: layersItem
                Label {
                    id: layersLabel
                    width: leftFrame.width
                    text: "Layers:"
                    font.pixelSize: 33*1.1*pix
                    padding: 0.2*margin
                    leftPadding: 0.2*margin
                    background: Rectangle {
                        anchors.fill: parent.fill
                        color: "transparent"
                        border.color: defaultpalette.border
                        border.width: 2*pix
                    }
                }
                Frame {
                    id: layersFrame
                    y: layersLabel.height - 2*pix
                    height: 1*(designWindow.height - 1*layersLabel.height) + 1*pix
                    width: leftFrame.width
                    padding: 0
                    backgroundColor: defaultpalette.listview
                    ScrollableItem {
                        y: 2*pix
                        id: layersFlickable
                        height: layersFrame.height-4*pix
                        width: leftFrame.width-3*pix
                        contentHeight: 1.25*buttonHeight*(inoutlayerView.count + linearlayerView.count +
                            normlayerView.count + activationlayerView.count + poolinglayerView.count +
                            resizinglayerView.count) + 6*0.9*buttonHeight
                        ScrollBar.horizontal.visible: false
                        Item {
                            id: listItem

                            Label {
                                id: inoutLabel
                                width: leftFrame.width-4*pix
                                height: 0.9*buttonHeight
                                
                                font.pixelSize: defaultPixelSize*1.1
                                color: "#777777"
                                topPadding: 0.10*linearLabel.height
                                text: "Input and output layers"
                                leftPadding: 0.25*margin
                                background: Rectangle {
                                    anchors.fill: parent.fill
                                    x: 2*pix
                                    color: defaultpalette.window
                                    width: leftFrame.width-4*pix
                                    height: 0.9*buttonHeight
                                }
                            }
                            ListView {
                                    id: inoutlayerView
                                    height: childrenRect.height
                                    anchors.top: inoutLabel.bottom
                                    spacing: 0
                                    boundsBehavior: Flickable.StopAtBounds
                                    model: ListModel {id: inoutlayerModel
                                                        ListElement{
                                                            name: "input"
                                                            type: "Input"
                                                            group: "inout"
                                                            colorR: 0
                                                            colorG: 0
                                                            colorB: 250
                                                            inputnum: 0
                                                            outputnum: 1}
                                                        ListElement{
                                                            name: "output"
                                                            type: "Output"
                                                            group: "inout"
                                                            colorR: 0
                                                            colorG: 0
                                                            colorB: 250
                                                            inputnum: 1
                                                            outputnum: 0}
                                                    }
                                    delegate: buttonComponent
                                }
                            Label {
                                id: linearLabel
                                width: leftFrame.width-4*pix
                                height: 0.9*buttonHeight
                                anchors.top: inoutlayerView.bottom
                                font.pixelSize: defaultPixelSize*1.1
                                color: "#777777"
                                topPadding: 0.10*linearLabel.height
                                text: "Linear layers"
                                leftPadding: 0.25*margin
                                background: Rectangle {
                                    anchors.fill: parent.fill
                                    x: 2*pix
                                    color: defaultpalette.window
                                    width: leftFrame.width-4*pix
                                    height: 0.9*buttonHeight
                                }
                            }
                            ListView {
                                    id: linearlayerView
                                    height: childrenRect.height
                                    anchors.top: linearLabel.bottom
                                    spacing: 0
                                    boundsBehavior: Flickable.StopAtBounds
                                    model: ListModel {id: linearlayerModel
                                                        ListElement{
                                                            name: "conv"
                                                            type: "Convolution"
                                                            group: "linear"
                                                            colorR: 250
                                                            colorG: 250
                                                            colorB: 0
                                                            inputnum: 1
                                                            outputnum: 1}
                                                        ListElement{
                                                            name: "tconv"
                                                            type: "Transposed convolution"
                                                            group: "linear"
                                                            colorR: 250
                                                            colorG: 250
                                                            colorB: 0
                                                            inputnum: 1
                                                            outputnum: 1}
                                                        ListElement{
                                                            name: "dense"
                                                            type: "Dense"
                                                            group: "linear"
                                                            colorR: 250
                                                            colorG: 250
                                                            colorB: 0
                                                            inputnum: 1
                                                            outputnum: 1}
                                                    }
                                    delegate: buttonComponent
                                }
                            Label {
                                id: normLabel
                                anchors.top: linearlayerView.bottom
                                width: leftFrame.width-4*pix
                                height: 0.9*buttonHeight
                                font.pixelSize: defaultPixelSize*1.1
                                color: "#777777"
                                topPadding: 0.10*activationLabel.height
                                text: "Normalisation layers"
                                leftPadding: 0.25*margin
                                background: Rectangle {
                                    anchors.fill: parent.fill
                                    x: 2*pix
                                    color: defaultpalette.window
                                    width: leftFrame.width-4*pix
                                    height: 0.9*buttonHeight
                                }
                            }
                            ListView {
                                id: normlayerView
                                anchors.top: normLabel.bottom
                                height: childrenRect.height
                                spacing: 0
                                boundsBehavior: Flickable.StopAtBounds
                                model: ListModel {id: normlayerModel
                                                    ListElement{
                                                        name: "dropout"
                                                        type: "Drop-out"
                                                        group: "norm"
                                                        colorR: 0
                                                        colorG: 250
                                                        colorB: 0
                                                        inputnum: 1
                                                        outputnum: 1}
                                                    ListElement{
                                                        name: "batchnorm"
                                                        type: "Batch normalisation"
                                                        group: "norm"
                                                        colorR: 0
                                                        colorG: 250
                                                        colorB: 0
                                                        inputnum: 1
                                                        outputnum: 1}
                                                }
                                delegate: buttonComponent
                            }
                            Label {
                                id: activationLabel
                                anchors.top: normlayerView.bottom
                                width: leftFrame.width-4*pix
                                height: 0.9*buttonHeight
                                font.pixelSize: defaultPixelSize*1.1
                                color: "#777777"
                                topPadding: 0.10*activationLabel.height
                                text: "Activation layers"
                                leftPadding: 0.25*margin
                                background: Rectangle {
                                    anchors.fill: parent.fill
                                    x: 2*pix
                                    color: defaultpalette.window
                                    width: leftFrame.width-4*pix
                                    height: 0.9*buttonHeight
                                }
                            }
                            ListView {
                                id: activationlayerView
                                anchors.top: activationLabel.bottom
                                height: childrenRect.height
                                spacing: 0
                                boundsBehavior: Flickable.StopAtBounds
                                model: ListModel {id: activationlayerModel
                                                    ListElement{
                                                        name: "relu"
                                                        type: "ReLU"
                                                        group: "activation"
                                                        colorR: 250
                                                        colorG: 0
                                                        colorB: 0
                                                        inputnum: 1
                                                        outputnum: 1}
                                                    ListElement{
                                                        name: "leakyrelu"
                                                        type: "Leaky ReLU"
                                                        group: "activation"
                                                        colorR: 250
                                                        colorG: 0
                                                        colorB: 0
                                                        inputnum: 1
                                                        outputnum: 1}
                                                    ListElement{
                                                        name: "elu"
                                                        type: "ELU"
                                                        group: "activation"
                                                        colorR: 250
                                                        colorG: 0
                                                        colorB: 0
                                                        inputnum: 1
                                                        outputnum: 1}
                                                    ListElement{
                                                        name: "tanh"
                                                        type: "Tanh"
                                                        group: "activation"
                                                        colorR: 250
                                                        colorG: 0
                                                        colorB: 0
                                                        inputnum: 1
                                                        outputnum: 1}
                                                    ListElement{
                                                        name: "sigmoid"
                                                        type: "Sigmoid"
                                                        group: "activation"
                                                        colorR: 250
                                                        colorG: 0
                                                        colorB: 0
                                                        inputnum: 1
                                                        outputnum: 1}
                                                }
                                delegate: buttonComponent
                            }
                            Label {
                                id: poolingLabel
                                anchors.top: activationlayerView.bottom
                                width: leftFrame.width-4*pix
                                height: 0.9*buttonHeight
                                font.pixelSize: defaultPixelSize*1.1
                                color: "#777777"
                                topPadding: 0.10*poolingLabel.height
                                text: "Pooling layers"
                                leftPadding: 0.25*margin
                                background: Rectangle {
                                    anchors.fill: parent.fill
                                    x: 2*pix
                                    color: defaultpalette.window
                                    width: leftFrame.width-4*pix
                                    height: 0.9*buttonHeight
                                }
                            }
                            ListView {
                                id: poolinglayerView
                                anchors.top: poolingLabel.bottom
                                height: childrenRect.height
                                spacing: 0
                                boundsBehavior: Flickable.StopAtBounds
                                model: ListModel {id: poolinglayerModel
                                                    ListElement{
                                                        name: "maxpool"
                                                        type: "Max pooling"
                                                        group: "pooling"
                                                        colorR: 150
                                                        colorG: 0
                                                        colorB: 255
                                                        inputnum: 1
                                                        outputnum: 1}
                                                    ListElement{
                                                        name: "avgpool"
                                                        type: "Average pooling"
                                                        group: "pooling"
                                                        colorR: 150
                                                        colorG: 0
                                                        colorB: 255
                                                        inputnum: 1
                                                        outputnum: 1}
                                                }
                                delegate: buttonComponent
                            }

                            Label {
                                id: resizingLabel
                                anchors.top: poolinglayerView.bottom
                                width: leftFrame.width-4*pix
                                height: 0.9*buttonHeight
                                font.pixelSize: defaultPixelSize*1.1
                                color: "#777777"
                                topPadding: 0.10*activationLabel.height
                                text: "Resizing layers"
                                leftPadding: 0.25*margin
                                background: Rectangle {
                                    anchors.fill: parent.fill
                                    x: 2*pix
                                    color: defaultpalette.window
                                    width: leftFrame.width-4*pix
                                    height: 0.9*buttonHeight
                                }
                            }
                            ListView {
                                id: resizinglayerView
                                anchors.top: resizingLabel.bottom
                                height: childrenRect.height
                                spacing: 0
                                boundsBehavior: Flickable.StopAtBounds
                                model: ListModel {id: resizinglayerModel
                                                ListElement{
                                                    name: "addition"
                                                    type: "Addition"
                                                    group: "resizing"
                                                    colorR: 180
                                                    colorG: 180
                                                    colorB: 180
                                                    inputnum: 2
                                                    outputnum: 1}
                                                ListElement{
                                                    name: "join"
                                                    type: "Join"
                                                    group: "resizing"
                                                    colorR: 180
                                                    colorG: 180
                                                    colorB: 180
                                                    inputnum: 2
                                                    outputnum: 1}
                                                ListElement{
                                                    name: "split"
                                                    type: "Split"
                                                    group: "resizing"
                                                    colorR: 180
                                                    colorG: 180
                                                    colorB: 180
                                                    inputnum: 1
                                                    outputnum: 2}
                                                ListElement{
                                                    name: "upsample"
                                                    type: "Upsample"
                                                    group: "resizing"
                                                    colorR: 180
                                                    colorG: 180
                                                    colorB: 180
                                                    inputnum: 1
                                                    outputnum: 1}
                                                ListElement{
                                                    name: "flatten"
                                                    type: "Flatten"
                                                    group: "resizing"
                                                    colorR: 180
                                                    colorG: 180
                                                    colorB: 180
                                                    inputnum: 1
                                                    outputnum: 1}
                                                }
                                delegate: buttonComponent
                            }
                        }
                    }
                }
            }
            /*Item {
                id: layergroupsItem
                visible: false
                y: layersLabel.height + layersFrame.height - 2*pix
                Label {
                    id: layergroupsLabel
                    width: leftFrame.width
                    text: "Layer groups:"
                    font.pixelSize: defaultPixelSize*1.1
                    padding: 0.2*margin
                    leftPadding: 0.2*margin
                    background: Rectangle {
                        anchors.fill: parent.fill
                        color: defaultpalette.window
                        border.color: defaultpalette.border
                        border.width: 2*pix
                    }
                }
                Frame {
                    y: layergroupsLabel.height - 2*pix
                    height: 0.4*(designWindow.height - 2*layergroupsLabel.height)+4*pix
                    width: leftFrame.width
                    padding: 0
                    backgroundColor: defaultpalette.listview

                    ScrollableItem {
                        clip: true
                        y: 2*pix
                        height: 0.4*(designWindow.height - 2*layergroupsLabel.height)
                        width: leftFrame.width-2*pix
                        contentHeight: 1.25*buttonHeight*(defaultgroupsView.count)
                                        +0.75*buttonHeight
                        ScrollBar.horizontal.visible: false
                        Item {
                            id: groupsRow
                            Label {
                                id: defaultLabel
                                width: leftFrame.width-4*pix
                                height: 0.9*buttonHeight
                                font.pixelSize: defaultPixelSize*1.1
                                color: "#777777"
                                topPadding: 0.10*defaultLabel.height
                                text: "Default layer groups"
                                leftPadding: 0.25*margin
                                background: Rectangle {
                                    anchors.fill: parent.fill
                                    x: 2*pix
                                    color: defaultpalette.window
                                    width: leftFrame.width-4*pix
                                    height: 0.9*buttonHeight
                                }
                            }
                            ListView {
                                    id: defaultgroupsView
                                    height: childrenRect.height
                                    anchors.top: defaultLabel.bottom
                                    spacing: 0
                                    boundsBehavior: Flickable.StopAtBounds
                                    model: ListModel {id: deafultmodulesModel
                                                    }
                                    delegate: ButtonNN {
                                        x: +2
                                        width: leftFrame.width-23*pix
                                        height: 1.25*buttonHeight
                                        RowLayout {
                                            anchors.fill: parent.fill
                                            ColorBox {
                                                Layout.leftMargin: 0.2*margin
                                                Layout.bottomMargin: 0.03*margin
                                                Layout.preferredWidth: 0.4*margin
                                                Layout.preferredHeight: 0.4*margin
                                                height: 20*margin
                                                Layout.alignment: Qt.AlignBottom
                                                colorRGB: [colorR,colorG,colorB]
                                            }
                                            Label {
                                                topPadding: 0.28*margin
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
            }*/

        }
        Frame {
            id: mainFrame
            anchors.left: leftFrame.right
            anchors.leftMargin: -1
            z: 0
            width : designWindow.width-leftFrame.width-rightFrame.width + 3*pix
            height : designWindow.height
            backgroundColor: defaultpalette.listview
            padding: 0
            antialiasing: true
            layer.enabled: true
            layer.samples: 8
            onWidthChanged: {
                flickableMainPane.width = mainFrame.width - 4*pix
                mainPane.width = flickableMainPane.width
            }
            onHeightChanged: {
                flickableMainPane.height = mainFrame.height - 4*pix
                mainPane.height = flickableMainPane.height
            }
            ScrollableItem {
                id: flickableMainPane
                width : mainFrame.width - 4*pix
                height : mainFrame.height - 4*pix
                contentWidth: flickableMainPane.width
                contentHeight: flickableMainPane.height
                showBackground: false
                clip: false
                Pane {
                    id: mainPane
                    width: flickableMainPane.width
                    height: flickableMainPane.height-2*pix
                    padding: 0
                    backgroundColor: defaultpalette.listview
                    Component.onCompleted: {
                        flickableMainPane.ScrollBar.vertical.visible = false
                        flickableMainPane.ScrollBar.horizontal.visible = false
                        for (var i=0;i<model.length;i++) {
                            var data = model[i]
                            var datastore = copy(data)
                            var names = ["connections_down","connections_up",
                                "label_color","x","y"]
                            for (var j=0;j<names.length;j++) {
                                delete datastore[names[j]]
                            }
                            layerComponent.createObject(layers,{"color" : adjustcolor(data.label_color),
                                "id": data.id,
                                "name": data.name,
                                "type": data.type,
                                "group": data.group,
                                "label_color": data.label_color,
                                "inputnum": data.connections_up.length,
                                "outputnum": data.connections_down.length,
                                "x": data.x,
                                "y": data.y,
                                "datastore": datastore});
                        }

                        for (i=0;i<model.length;i++) {
                            data = model[i]
                            var connections_down = data.connections_down
                            for (j=0;j<connections_down.length;j++) {
                                var conns = connections_down[j]
                                for (var l=0;l<conns.length;l++) {
                                    var conn = conns[l]-1
                                    var unit = layers.children[i]
                                    var unit_connected = layers.children[conn]
                                    var downNode = getDownNode(unit,j)
                                    var downNodeRectangle = getDownNodeRec(unit,j,l+1)
                                    var ind = -1
                                    var connections_up = model[conn].connections_up
                                    for (var a=0;a<connections_up.length;a++) {
                                        if ((connections_up[a]-1)===i) {
                                            ind = a
                                        }
                                    }
                                    var upNode = getUpNode(unit_connected,ind)
                                    makeConnection(unit,downNode,downNodeRectangle,upNode)
                                }
                            }
                        }
                        deselectunits()
                        if (layers.children.length!==0) {
                            updateMainPane(layers.children[0])
                        }
                        propertiesStackView.push(generalpropertiesComponent)
                        updateOverview()
                    }
                    property var selectioninds: []
                    property var justselected: false
                    Timer {
                        id: mainframeTimer
                        running: true
                        repeat: true
                        interval: 50
                        property double prevY: 0
                        property double prevX: 0
                        property double prevMouseY: 0
                        property double prevMouseX: 0
                        property double prevValY: 0.5
                        property double prevValX: 0.5
                        property double prevAdjY: 0
                        property double prevAdjX: 0
                        property double mouseY: 0
                        property double mouseX: 0
                        property bool pressed: false
                        property var object: null
                        property var object_data: null
                        onTriggered: {
                            // During scrolling
                            if (flickableMainPane.contentY!==prevY) {
                                var startY = flickableMainPane.ScrollBar.vertical.height/
                                    mainPane.height
                                var valY = (flickableMainPane.contentY +
                                    flickableMainPane.ScrollBar.vertical.height)/
                                    mainPane.height
                                var maxheightchildren = getbottomchild(layers)
                                var minheightchildren = gettopchild(layers)
                                var adjY = 50*pix
                                if (valY>0.99) {
                                    mainPane.height = mainPane.height + adjY
                                    flickableMainPane.contentHeight = mainPane.height
                                }
                                else if (valY<0.98 && valY>maxheightchildren/mainPane.height) {
                                    mainPane.height = mainPane.height - adjY
                                    flickableMainPane.contentHeight = mainPane.height
                                }
                                prevY = flickableMainPane.contentY
                            }
                            if (flickableMainPane.contentX!==prevX) {
                                var valX = (flickableMainPane.contentX +
                                    flickableMainPane.ScrollBar.horizontal.width)/
                                    mainPane.width
                                var maxwidthchildren = getrightchild(layers)
                                var adjX = 50*pix
                                if (valX>0.99) {
                                    mainPane.width = mainPane.width + adjX
                                    flickableMainPane.contentWidth = mainPane.width
                                }
                                else if (valX>maxwidthchildren/mainPane.width && valX<0.98) {
                                    mainPane.width = mainPane.width - adjX
                                    flickableMainPane.contentWidth = mainPane.width
                                }
                                prevX = flickableMainPane.contentX
                            }
                            // Object moving
                            if (pressed) {
                                adjY = 0
                                valY = (mouseY-
                                    flickableMainPane.contentY)/flickableMainPane.height
                                if (valY>0.95 && ((prevAdjY===0) || (mouseY!==prevMouseY))) {
                                    adjY = 30*pix*(valY-0.95)/0.05
                                    prevAdjY = adjY
                                    prevValY = valY
                                }
                                else if ((mouseY==prevMouseY) && (prevValY>=0.95)) {
                                    adjY = prevAdjY
                                    mouseY = mouseY + adjY
                                    prevMouseY = mouseY
                                }
                                else if (valY<0.05 && ((prevAdjY===0) || (mouseY!==prevMouseY))) {
                                    adjY = 30*pix*(valY-0.05)/0.05
                                    prevAdjY = adjY
                                    prevValY = valY
                                }
                                else if ((mouseY==prevMouseY) && (prevValY<=0.05)) {
                                    adjY = prevAdjY
                                    mouseY = mouseY + adjY
                                    prevMouseY = mouseY
                                }
                                else {
                                    prevAdjY = 0
                                }
                                if (adjY!==0) {
                                    var newY = flickableMainPane.contentY + adjY
                                    if (newY>0) {
                                        flickableMainPane.contentY = newY
                                    }
                                    else if (newY<0) {
                                        flickableMainPane.contentY = 0
                                    }
                                }
                                adjX = 0
                                valX = (mouseX-
                                    flickableMainPane.contentX)/flickableMainPane.width
                                if (valX>0.95 && ((prevAdjX===0) || (mouseX!==prevMouseX))) {
                                    adjX = 30*pix*(valX-0.95)/0.05
                                    prevAdjX = adjX
                                    prevValX = valX
                                }
                                else if ((mouseX==prevMouseX) && (prevValX>=0.95)) {
                                    adjX = prevAdjX
                                    mouseX = mouseX + adjX
                                    prevMouseX = mouseX
                                }
                                else if (valX<0.05 && ((prevAdjX===0) || (mouseX!==prevMouseX))) {
                                    adjX = 30*pix*(valX-0.05)/0.05
                                    prevAdjX = adjX
                                    prevValX = valX
                                }
                                else if ((mouseX==prevMouseX) && (prevValX<=0.05)) {
                                    adjX = prevAdjX
                                    mouseX = mouseX + adjX
                                    prevMouseX = mouseX
                                }
                                else {
                                    prevAdjX = 0
                                }
                                if (adjX!==0) {
                                    var newX = flickableMainPane.contentX + adjX
                                    if (newX>0) {
                                        flickableMainPane.contentX = newX
                                    }
                                    else if (newX<0) {
                                        flickableMainPane.contentX = 0
                                    }
                                }
                                prevMouseY = mouseY
                                prevMouseX = mouseX
                                if (mouseX>mainPane.width) {
                                    mouseX = mainPane.width
                                }
                                else if (flickableMainPane.contentX==0) {
                                    adjX = 0
                                }
                                if (mouseY>mainPane.height) {
                                    mouseY = mainPane.height
                                }
                                else if (flickableMainPane.contentY==0) {
                                    adjY = 0
                                }
                                // Update object position
                                if (adjX!==0 || adjY!==0) {
                                    if (object==="mainMouseArea") {
                                        var mouse = {x: mouseX, y: mouseY}
                                        updatePosSelectRect(mouse,object_data[0],object_data[1])
                                    }
                                    else if (object==="unit") {
                                        var unit = object_data[0]
                                        unit.x = unit.x + adjX
                                        unit.y = unit.y + adjY
                                        updatePosUnit(unit)
                                    }
                                    else if (object==="upnode") {
                                        var upNodeRectangle = object_data[1]
                                        upNodeRectangle.x = upNodeRectangle.x + adjX
                                        upNodeRectangle.y = upNodeRectangle.y + adjY
                                        updatePosUpNode(object_data[0],upNodeRectangle,object_data[2])
                                    }
                                    else if (object==="downnode") {
                                        var downNodeRectangle = object_data[2]
                                        if (downNodeRectangle===undefined) {
                                            return
                                        }
                                        downNodeRectangle.x = downNodeRectangle.x + adjX
                                        downNodeRectangle.y = downNodeRectangle.y + adjY
                                        updatePosDownNode(object_data[0],
                                            object_data[1],downNodeRectangle,object_data[3])
                                    }
                                }
                            }
                        }
                    }
                    MouseArea {
                        id: mainMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        property int initialXPos
                        property int initialYPos
                        onClicked: {
                            propertiesStackView.push(generalpropertiesComponent)
                            if (mainPane.justselected===true) {
                                mainPane.justselected = false
                            }
                            else {
                                mainPane.selectioninds = []
                            }
                        }
                        onPressed: {
                            deselectunits()
                            if (mouse.button == Qt.LeftButton) {
                                // initialize local variables to determine the selection orientation
                                initialXPos = mouse.x
                                initialYPos = mouse.y

                                flickableMainPane.interactive = false // in case the event started over a Flickable element
                                selectionRect.x = mouse.x
                                selectionRect.y = mouse.y
                                selectionRect.width = 0
                                selectionRect.height = 0
                                selectionRect.visible = true
                                mainframeTimer.pressed = true
                                mainframeTimer.object = "mainMouseArea"
                            }
                        }
                        onPositionChanged: {
                            updatePosSelectRect(mouse,initialXPos,initialYPos)
                            mainframeTimer.object_data = [initialXPos,initialYPos]
                            var mapped_point = mapToItem(mainMouseArea,mouse.x,mouse.y)
                            mainframeTimer.mouseY = mapped_point.y
                            mainframeTimer.mouseX = mapped_point.x
                        }

                        onReleased: {
                            selectionRect.visible = false
                            flickableMainPane.interactive = true
                            var finishX = mouse.x
                            var finishY = mouse.y
                            var maxX = Math.max(initialXPos,finishX)
                            var minX = Math.min(initialXPos,finishX)
                            var maxY = Math.max(initialYPos,finishY)
                            var minY = Math.min(initialYPos,finishY)
                            for (var i=0;i<layers.children.length;i++) {
                                if (layers.children[i].x >minX && layers.children[i].x <maxX &&
                                        layers.children[i].y >minY && layers.children[i].y <maxY &&
                                        (layers.children[i].x + layers.children[i].width)>minX &&
                                        (layers.children[i].x + layers.children[i].width)<maxX &&
                                        (layers.children[i].y + layers.children[i].height) >minY &&
                                        (layers.children[i].y + layers.children[i].height) <maxY) {
                                    mainPane.selectioninds.push(i)
                                    layers.children[i].border.color = defaultcolors.dark
                                    layers.children[i].border.width = 4*pix
                                }
                            }
                            mainPane.justselected = true
                            mainframeTimer.pressed = false
                            mainframeTimer.object = null
                        }
                    }

                    Item {
                        id: layers
                        
                    }
                    Item {
                        id: connections
                    }
                    Rectangle {
                        id: selectionRect
                        visible: false
                        x: 0
                        y: 0
                        z: 99
                        width: 0
                        height: 0
                        rotation: 0
                        transformOrigin: Item.TopLeft
                        border.width: 2*pix
                        border.color: Qt.rgba(0.2,0.5,0.8,0.8)
                        color: Qt.rgba(0.2,0.5,0.8,0.05)
                    }
                }
            }
            Button {
                id: saveButton
                x: mainFrame.width-iconSize*1.5
                y: iconSize*0.5
                width: iconSize
                height: iconSize
                background: Image {
                    source: gui_dir+"icons/saveIcon.png"
                    fillMode: Image.PreserveAspectFit
                }
                Component.onCompleted: {
                    customToolTip.createObject(saveButton,
                        {"parent": saveButton,
                        text: "Save"})
                }
                onPressed: {opacity = 0.5}
                onClicked: {
                    if (layers.children.length>3) {
                        getarchitecture()
                        customizationItem.forceActiveFocus()
                        var name = Julia.get_data(["Urls","model_name"])
                        var url = Julia.get_data(["Urls","model_url"])
                        var state = Julia.make_model()
                        if (state) {
                            state = Julia.check_model()
                        }
                        if (state==false) {
                            show_warnings()
                        }
                        else {
                            Julia.move_model()
                            Julia.save_model(url)
                        }
                    }
                    opacity = 1
                }
            }
            Button {
                id: optionsButton
                x: mainFrame.width-iconSize*1.5
                y: iconSize*0.5 + 1.25*iconSize
                width: iconSize
                height: iconSize
                Component.onCompleted: {
                    customToolTip.createObject(optionsButton,
                        {"parent": optionsButton,
                        text: "Options"})
                }
                background: Image {
                    source: gui_dir+"icons/optionsIcon.png"
                    fillMode: Image.PreserveAspectFit
                }
                onPressed: {opacity = 0.5}
                onClicked: {
                    opacity = 1
                    if (designoptionsLoader.sourceComponent === null) {
                        designoptionsLoader.source = gui_dir+"DesignOptions.qml"
                    }
                }
            }
            Button {
                id: arrangeButton
                x: mainFrame.width-iconSize*1.5
                y: iconSize*0.5 + 2*1.25*iconSize
                width: iconSize
                height: iconSize
                Component.onCompleted: {
                    customToolTip.createObject(arrangeButton,
                        {"parent": arrangeButton,
                        text: "Arrange"})
                }
                background: Image {
                    source: gui_dir+"icons/arrangeIcon.png"
                    fillMode: Image.PreserveAspectFit
                }
                onPressed: {opacity = 0.5}
                onClicked: {
                    if (layers.children.length>3) {
                        getarchitecture()
                        var data = Julia.arrange()
                        var coordinates = data[0]
                        var inds = data[1]
                        for (var i=0;i<inds.length;i++) {
                            var layer = layers.children[inds[i]]
                            layer.x = coordinates[i][0]*pix
                            layer.y = coordinates[i][1]*pix
                            layer.oldpos = [layer.x,layer.y]
                        }
                        updateMainPane(layers.children[0])
                        for (i=0;i<layers.children.length;i++) {
                            updatePosition(layers.children[i],layers.children[i])
                        }
                        updateConnections()
                        updateConnections()
                        customizationItem.forceActiveFocus()
                    }
                    opacity = 1
                }
            }
            Rectangle {
                color: "transparent"
                anchors.fill: parent
                border.width: 2*pix
                border.color: defaultpalette.border
            }
        }
        Frame {
            id: rightFrame
            anchors.left: mainFrame.right
            anchors.leftMargin: -1
            z: 3
            height: designWindow.height
            width: 530*pix + 1*pix
            padding:0
            Item {
                id: propertiesColumn
                Label {
                    id: propertiesLabel
                    width: rightFrame.width
                    text: "Properties:"
                    font.pixelSize: defaultPixelSize*1.1
                    padding: 0.2*margin
                    leftPadding: 0.2*margin
                    background: Rectangle {
                        anchors.fill: parent.fill
                        color: defaultpalette.window
                        border.color: defaultpalette.border
                        border.width: 2*pix
                    }
                }
                Frame {
                    id: propertiesFrame
                    y: propertiesLabel.height -4*pix
                    height: 0.6*(designWindow.height - 2*layersLabel.height)
                    width: rightFrame.width
                    padding: 0
                    backgroundColor: defaultpalette.window
                    ScrollableItem {
                        id: propertiesFlickable
                        y: 2*pix
                        height: 0.6*(designWindow.height - 2*layersLabel.height) - 4*pix
                        width: rightFrame.width-2*pix
                        contentHeight: 0.6*(designWindow.height - 2*layersLabel.height) - 4*pix
                        ScrollBar.horizontal.visible: false
                        Item {
                            MouseArea {
                                width: propertiesFrame.width
                                height: propertiesFrame.height
                                onClicked: {
                                    focus = true
                                    mouse.accepted = false
                                }
                            }
                            StackView {
                                id: propertiesStackView
                                initialItem: generalpropertiesComponent
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
                        }
                    }
                }
            }
            Item {
                id: overviewItem
                y: propertiesLabel.height + propertiesFrame.height - 6*pix
                Label {
                    id: overviewLabel
                    width: rightFrame.width
                    text: "Overview:"
                    font.pixelSize: defaultPixelSize*1.1
                    padding: 0.2*margin
                    leftPadding: 0.2*margin
                    background: Rectangle {
                        anchors.fill: parent.fill
                        color: defaultpalette.window
                        border.color: defaultpalette.border
                        border.width: 2*pix
                    }
                }
                Frame {
                    id: overviewFrame
                    y: overviewLabel.height - 2*pix
                    height: 0.4*(designWindow.height - 2*layersLabel.height) + 8*pix
                    width: rightFrame.width
                    padding: 0
                    backgroundColor: defaultpalette.listview
                    Image {
                        id: overviewImage
                        x: 2*pix
                        y: 2*pix
                        height: overviewFrame.height - 4*pix
                        width: overviewFrame.width - 4*pix
                        fillMode: Image.PreserveAspectFit
                    }
                }
            }
        }

        MouseArea {
            width: designWindow.width
            height: designWindow.height
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


//--FUNCTIONS--------------------------------------------------------------------

//---Universal function block-------------------------------------------------
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

    function importmodel(model) {
        idCounter = Julia.get_max_id()
        model.length = 0
        var skipStringing = ["x","y"]
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
                        unit[prop_name] = {"text": prop[0],"ind": parseInt(prop[1])}
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

    function stripURL(url) {
        return url.toString().replace("file:///","")
    }
//----------------------------------------------------------------------------


    function show_warnings() {
        var warnings = Julia.get_data(["DesignData","warnings"])
        for (var i=0;i<warnings.length;i++) {
            warningPopup.warnings.push(warnings[i])
        }
        warningPopup.visible = true
        Julia.set_data(["DesignData","warnings"],[])
    }

    function updatePosDownNode(unit,downNode,downNodeRectangle,mouseAdjust) {
        var outputnum = downNodeRectangle.outputnum
        var index = downNodeRectangle.index
        var connection = downNodeRectangle.connection
        var beginX = unit.x + unit.width*index/(outputnum+1)
        var beginY = unit.y + unit.height - 2*pix
        var finishX = unit.x + downNodeRectangle.x + downNode.radius +
                mouseAdjust[0]
        var finishY = unit.y + downNodeRectangle.y + downNode.radius +
                mouseAdjust[1] + 2*pix
        if (connection===null) {
            connection = connectionShapeComponent.createObject(connections, {
                 "beginX": beginX,
                 "beginY": beginY,
                 "finishX": finishX,
                 "finishY": finishY,
                 "origin": downNodeRectangle});
            downNodeRectangle.connection = connection
        }
        else {
            updateConnection(connection,beginX,beginY,finishX,finishY)
        }
    }

    function updatePosUpNode(upNode,upNodeRectangle,mouseAdjust) {
        var point = upNodeRectangle.mapToItem(layers,0,0)
        var connection = upNode.connectedItem.connection
        var beginX = upNode.connectedItem.unit.x + upNode.connectedItem.unit.width*
                upNode.connectedItem.index/(upNode.connectedItem.outputnum+1)
        var beginY = upNode.connectedItem.unit.y +
                upNode.connectedItem.unit.height - 2*pix
        var finishX = point.x +
                upNode.connectedNode.radius + mouseAdjust[0]
        var finishY = point.y +
                upNode.connectedNode.radius + mouseAdjust[1] + 2*pix
        updateConnection(connection,beginX,beginY,finishX,finishY)

    }

    function updatePosUnit(unit) {
        var inds = -1
        var currentind = -1
        for (var i=0;i<layers.children.length;i++) {
            if (layers.children[i]===unit) {
                currentind = i
                break
            }
        }
        if (mainPane.selectioninds.length===0) {
            inds = [currentind]
        }
        else {
            inds = mainPane.selectioninds
        }
        var devX = unit.x - unit.oldpos[0]
        var devY = unit.y - unit.oldpos[1]
        for (var k=0;k<inds.length;k++) {
            var other_unit = layers.children[inds[k]]
            if (inds[k]!==currentind) {
                other_unit.x = other_unit.x + devX
                other_unit.y = other_unit.y + devY
            }
            other_unit.oldpos = [other_unit.x,other_unit.y]
            updatePosition(other_unit)
        }
        unit.oldpos = [unit.x,unit.y]
    }

    function updatePosSelectRect(mouse,initialXPos,initialYPos) {
        if (selectionRect.visible==true) {
            if ((mouse.x!==initialXPos || mouse.y!==initialYPos)) {
                if (mouse.x>=initialXPos) {
                    if (mouse.y>=initialYPos)
                       selectionRect.rotation = 0
                    else
                       selectionRect.rotation = -90

                }
                else {
                    if (mouse.y>=initialYPos)
                        selectionRect.rotation = 90
                    else
                        selectionRect.rotation = -180
                }
            }

            if (selectionRect.rotation==0 || selectionRect.rotation==-180) {
                selectionRect.width = Math.abs(mouse.x - selectionRect.x)
                selectionRect.height = Math.abs(mouse.y - selectionRect.y)
            }
            else {
                selectionRect.width = Math.abs(mouse.y - selectionRect.y)
                selectionRect.height = Math.abs(mouse.x - selectionRect.x)
            }
            mainframeTimer.mouseY = mouse.y
            mainframeTimer.mouseX = mouse.x
        }
    }

    function add(array,num) {
        var array2 = [...array]
        for (var i=0;i<array2.length;i++) {
            array2[i] = array2[i] + num
        }
        return array2
    }

    function copy(obj) {
        return Object.assign({}, obj)
    }

    function range(start,end,step) {
        var numiter = Math.floor((end-start)/step)+1
        var array = []
        for (var i=0;i<numiter;i++) {
            array.push(start+i*step)
        }
        return array
    }

    function dif(ar,x) {
        function dif_subfunc(value,x) {
            return value - x;
        }
        return ar.map(value => dif_subfunc(value,x));
    }

    function findindex(array,value) {
        var array2 = []
        for (var i=0;i<array.length;i++){
            if (array[i]===value){
                array2.push(i)
            }
        }
        return(array2)
    }

    function indexOfMax(array) {
        if (array.length === 0) {
            return -1;
        }
        var max = array[0];
        var maxIndex = 0;
        for (var i=1;i<array.length;i++) {
            if (array[i] > max) {
                maxIndex = i;
                max = array[i];
            }
        }
        return maxIndex;
    }

    function indexOfMin(array) {
        if (array.length === 0) {
            return -1;
        }
        var min = array[0];
        var minIndex = 0;
        for (var i=1;i<array.length;i++) {
            if (array[i] < min) {
                minIndex = i;
                min = array[i];
            }
        }
        return minIndex;
    }

    function getleft(item) {
        return(item.x)
    }

    function getright(item) {
        return(item.x+item.width)
    }

    function gettop(item) {
        return(item.y)
    }

    function getbottom(item) {
        return(item.y+item.height)
    }

    function getrightchild(item) {
        var max = -10000000
        if (item.children.length===0) {
            return(0)
        }
        for (var i = 0; i < item.children.length; i++) {
            var temp = getright(item.children[i])
            temp = item.mapToItem(mainPane,temp,0).x
            if (temp>max) {
                max = temp;
            }
        }
        return(max)
    }

    function getleftchild(item) {
        var min = 10000000
        if (item.children.length===0) {
            return(0)
        }
        for (var i = 0; i < item.children.length; i++) {
            var temp = getleft(item.children[i])
            temp = item.mapToItem(mainPane,temp,0).x
            if (temp<min) {
                min = temp;
            }
        }
        return(min)
    }

    function getbottomchild(item) {
        var max = -10000000
        if (item.children.length===0) {
            return(0)
        }
        for (var i = 0; i < item.children.length; i++) {
            var temp = getbottom(item.children[i])
            temp = item.mapToItem(mainPane,0,temp).y
            if (temp>max) {
                max = temp;
            }
        }
        return(max)
    }

    function gettopchild(item) {
        var min = 10000000
        if (item.children.length===0) {
            return(0)
        }
        for (var i = 0; i < item.children.length; i++) {
            var temp = gettop(item.children[i])
            temp = item.mapToItem(mainPane,0,temp).y
            if (temp<min) {
                min = temp;
            }
        }
        return(min)
    }

    function adjustcolor(colorRGB) {
        var tempRGB = copy(colorRGB)
        tempRGB[0] = 225 + tempRGB[0]/255*30
        tempRGB[1] = 225 + tempRGB[1]/255*30
        tempRGB[2] = 225 + tempRGB[2]/255*30
        return(Qt.rgba(tempRGB[0]/255,tempRGB[1]/255,tempRGB[2]/255))
    }

    function comparelocations(item1,mouseX,mouseY,item2,item) {
        var coor1 = item1.mapToItem(item, mouseX, mouseY)
        var coor2 = item2.mapToItem(item, 10*pix, 10*pix)
        if (Math.abs(coor2.x-coor1.x)<30*pix && Math.abs(coor2.y-coor1.y)<30*pix) {
            return(true)
        }
        else {
            return(false)
        }
    }

    function getlayersnum() {
        var layersnum = layers.children.length
        for (var i=0;i<layers.children.length;i++) {
            if (layers.children[i].group==="inout") {
                layersnum -= 1
            }
        }
        
        return(layersnum)
    }

    function getconnectionsnum() {
        var connnum = connections.children.length
        for (var i=0;i<layers.children.length;i++) {
            if (layers.children[i].group==="inout") {
                if (layers.children[i].name=="input") {
                    connnum -= layers.children[i].children[2].children[1].children[0].children.length - 2
                }
                else {
                    connnum -= 1
                }
            }
        }
        return(connnum)
    }

    function getirregularitiesnum() {
        var out = 0;
        if (layers.children.length>1) {
            for (var i=1;i<layers.children.length;i++) {
                if (layers.children[i].group==="activation") {
                    out = out + 1
                }
            }
        }
        return(out)
    }

    function datacmp(data,type) {
        if (data===undefined) {
            if (type==="str") {
                return("")
            }
            else if (type==="num") {
                return(-1)
            }
            else {
                return("")
            }
        }
        else {
            return(data)
        }
    }

    function updateOverview() {
        function Timer() {
            return Qt.createQmlObject("import QtQuick 2.0; Timer {}", designWindow);
        }
        function delay(delayTime, cb) {
            var timer = new Timer();
            timer.interval = delayTime;
            timer.repeat = false;
            timer.triggered.connect(cb);
            timer.start();
        }
        function upd() {
            mainPane.grabToImage(function(result) {
                overviewImage.source = result.url;
            })
        }
        delay(50, upd)
    }

    function deselectunits() {
        for (var i=0;i<layers.children.length;i++) {
            mainPane.selectioninds = []
            layers.children[i].border.color = defaultpalette.controlborder
            layers.children[i].border.width = 3*pix
        }
    }

    function deselectunit(unit) {
        unit.border.color = defaultpalette.controlborder
        unit.border.width = 3*pix
    }

    function selectunit(unit) {
        unit.border.color = defaultcolors.dark
        unit.border.width = 4*pix
    }

    function getarchitecture() {
        Julia.reset_layers()
        for (var i=0;i<layers.children.length;i++) {
            var datastore = layers.children[i].datastore
            var keys = Object.keys(datastore)
            var values = Object.values(datastore)
            for (var j=0;j<keys.length;j++) {
                if (typeof values[j] === typeof {}) {
                    values[j] = Object.values(values[j])
                }
            }
            var unit = layers.children[i]
            var connections = getconnections(unit,1)
            var x = layers.children[i].x/pix
            var y = layers.children[i].y/pix
            keys = ["connections_up","connections_down","x","y","label_color",...keys]
            values = [connections["up"],connections["down"],x,y,
                layers.children[i].label_color,...values]
            Julia.update_layers(keys,values)
        }
    }

    function getconnections(unit,indmod) {
        var upNodes = unit.children[2].children[0]
        var connections_up = Array(upNodes.children.length).fill(-1+indmod)
        var connections_up_item = Array(upNodes.children.length).fill(-1+indmod)
        for (var j=0;j<upNodes.children.length;j++) {
            var node = upNodes.children[j].children[0].connectedNode
            var item = upNodes.children[j].children[0].connectedItem
            if (node!==null) {
                connections_up[j] = unitindex(nodetolayer(node))+indmod
            }
        }
        var downNodes = unit.children[2].children[1]
        var connections_down = Array(downNodes.children.length).fill([])
        for (j=0;j<downNodes.children.length;j++) {
            connections_down[j] = Array(downNodes.children[j].children.length-2).fill(-1+indmod)
            for (var v=0; v<downNodes.children[j].children.length-1;v++) {
                node = downNodes.children[j].children[1+v].connectedNode
                if (node!==null) {
                    connections_down[j][v] = unitindex(nodetolayer(node))+indmod
                }
            }
        }
        return {"up": connections_up,"down": connections_down}
    }

    function indexofmin(a) {
        var lowest = 0;
        for (var i = 1; i < a.length; i++) {
            if (a[i] < a[lowest]) lowest = i;
        }
        return lowest;
    }

    function indexofmax(a) {
        var highest = 0;
        for (var i = 1; i < a.length; i++) {
            if (a[i] > a[highest]) highest = i;
        }
        return highest;
    }

    function pushstack(comp,id,name,type,group,label_color,unit) {
        propertiesStackView.push(comp, {"id": id, "name": name, "type": type, 
            "group": group, "label_color": label_color, "unit": unit})
    }

    function getstack(label_color,id,group,type,name,unit) {
        var properties = [id,name,type,group,label_color]
        switch(type) {
            case "Input":
                return pushstack(inputpropertiesComponent,...properties,unit)
            case "Output":
                return pushstack(outputpropertiesComponent,...properties,unit)
            case "Convolution":
                return pushstack(convpropertiesComponent,...properties,unit)
            case "Transposed convolution":
                return pushstack(tconvpropertiesComponent,...properties,unit)
            case "Dense":
                return pushstack(densepropertiesComponent,...properties,unit)
            case "Drop-out":
                return pushstack(dropoutpropertiesComponent,...properties,unit)
            case "Batch normalisation":
                return pushstack(batchnormpropertiesComponent,...properties,unit)
            case "Leaky ReLU":
                return pushstack(leakyrelupropertiesComponent,...properties,unit)
            case "ELU":
                return pushstack(elupropertiesComponent,...properties,unit)
            case "Max pooling":
                return pushstack(poolpropertiesComponent,...properties,unit)
            case "Average pooling":
                return pushstack(poolpropertiesComponent,...properties,unit)
            case "Addition":
                return pushstack(additionpropertiesComponent,...properties,unit)
            case "Join":
                return pushstack(catpropertiesComponent,...properties,unit)
            case "Split":
                return pushstack(splitpropertiesComponent,...properties,unit)
            case "Upsample":
                return pushstack(upsamplepropertiesComponent,...properties,unit)
            default:
                pushstack(emptypropertiesComponent,...properties,unit)
        }
    }

    function updateConnections() {
        for (var k=0;k<layers.children.length;k++) {
            var unit = layers.children[k]
            var upNodes = unit.children[2].children[0]
            var downNodes = unit.children[2].children[1]
            for (var i=0;i<upNodes.children.length;i++) {
                var upNodeRectangle = upNodes.children[i].children[0]
                if (upNodeRectangle.connectedNode!==null) {
                    var connection = upNodeRectangle.connectedItem.connection
                    var beginX = connection.data[0].startX
                    var beginY = connection.data[0].startY
                    var finishX = unit.x + unit.width*upNodes.children[i].index/(unit.inputnum+1)
                    var finishY = unit.y + 2*pix
                    updateConnection(connection,beginX,beginY,finishX,finishY)
                    var nodePoint = upNodeRectangle.mapToItem(upNodeRectangle.connectedItem.parent,0,0)
                    upNodeRectangle.connectedItem.x = nodePoint.x - upNodeRectangle.radius/2
                    upNodeRectangle.connectedItem.y = nodePoint.y - upNodeRectangle.radius/2
                }
            }
            for (i=0;i<downNodes.children.length;i++) {
                for (var j=1;j<downNodes.children[i].children.length;j++) {
                    var downNodeRectangle = downNodes.children[i].children[j]
                    if (downNodeRectangle.connectedNode!==null) {
                        connection = downNodeRectangle.connection
                        beginX = unit.x + unit.width*downNodes.children[i].index/(unit.outputnum+1)
                        beginY = unit.y + unit.height - 2*pix
                        finishX = connection.data[0].pathElements[0].x
                        finishY = connection.data[0].pathElements[0].y
                        nodePoint = downNodeRectangle.connectedNode.
                            mapToItem(downNodes.children[i],0,0)
                        downNodeRectangle.x = nodePoint.x - downNodeRectangle.radius/2
                        downNodeRectangle.y = nodePoint.y - downNodeRectangle.radius/2 + 2*pix
                    }
                }
            }
        }
    }


    function updateConnection(connection,beginX,beginY,finishX,finishY) {
        connection.beginX = beginX
        connection.beginY = beginY
        connection.finishX = finishX
        connection.finishY = finishY
        var connection_data = connection.data[0]
        connection_data.startX = beginX
        connection_data.startY = beginY
        var pathElement = connection_data.pathElements[0]
        pathElement.x = finishX
        pathElement.y = finishY
    }

    function makeConnection(unit,downNode,downNodeRectangle,upNode) {
        var connection = downNodeRectangle.connection
        downNodeRectangle.connectedNode = upNode
        upNode.connectedNode = downNode
        upNode.connectedItem = downNodeRectangle
        upNode.visible = true
        var upNodePoint = upNode.mapToItem(layers,0,0)
        var downNodePoint = downNode.mapToItem(layers,0,0)
        downNodeRectangle.x = downNodeRectangle.x - 10*pix +
            (upNodePoint.x - downNodeRectangle.mapToItem(layers,0,0).x)
        downNodeRectangle.y = downNodeRectangle.y - 10*pix +
                (upNodePoint.y - downNodeRectangle.mapToItem(layers,0,0).y)
        if (connection===null) {
            downNodeRectangle.connection = connectionShapeComponent.createObject(connections, {
                 "beginX": unit.x + unit.width*downNode.parent.index/(unit.outputnum+1),
                 "beginY": unit.y + unit.height - 2*pix,
                 "finishX": upNodePoint.x + downNode.radius/2,
                 "finishY": upNodePoint.y + downNode.radius/2,
                 "origin": downNodeRectangle});
        }
        else {
            var beginX = unit.x + unit.width*downNode.parent.index/(unit.outputnum+1)
            var beginY = unit.y + unit.height - 2*pix
            var finishX = upNodePoint.x + downNode.radius/2
            var finishY = upNodePoint.y + downNode.radius/2
            updateConnection(connection,beginX,beginY,finishX,finishY)
        }
        var downNodeItem = downNode.parent
        var num = downNodeItem.children.length
        if (downNodeItem.children[num-1].connection!==null) {
            downNodeRectangleComponent.createObject(downNode.parent, {
                            "unit": unit,
                            "upNodes": getUpNodes(unit),
                            "downNodes": getDownNodes(unit),
                            "downNodeItem": downNode.parent,
                            "downNode": downNode,
                            "outputnum": unit.outputnum,
                            "index": downNode.parent.index});
        }
        downNode.visible = true
    }

    function updateMainPane(unit) {
        var paneHeight = mainPane.height
        var paneWidth = mainPane.width
        var minheight = Math.min(0,gettop(unit))
        var minwidth = Math.min(0,getleft(unit))
        var maxheight = Math.max(paneHeight,getbottom(unit))
        var maxwidth = Math.max(paneWidth,getright(unit))
        var minheightchildren = gettopchild(layers)
        var minwidthchildren = getleftchild(layers)
        var maxheightchildren = getbottomchild(layers)
        var maxwidthchildren = getrightchild(layers)
        var padding = 100*pix
        var limit = [mainFrame.width/4,mainFrame.height]

        var adjX = 0
        var adjY = 0
        if (minwidth<0) {
            adjX = -minwidth + padding
        }
        else {
            adjX = -minwidthchildren + padding
        }
        if (minheight<0) {
            adjY = -minheight + padding
        }
        else {
            adjY = -minheightchildren + padding
        }
        if (adjX===padding && minwidthchildren===0*pix) {
            adjX = 0
        }
        if (adjY===padding && minheightchildren===0*pix) {
            adjY = 0
        }

        var devX = (minwidthchildren+maxwidthchildren)/2-paneWidth/2
        if (adjX<0) {
            if (Math.abs(devX)>limit[0] && minwidthchildren>devX && layers.children.length!==1) {
                adjX = -devX
            }
            else {
                adjX = 0
            }
        }
        var devY = (minheightchildren+maxheightchildren)/2-paneHeight/2

        if (adjY<0) {
            if (Math.abs(devY)>limit[1] && minheightchildren>devY && layers.children.length!==1) {
                adjY = -devY
            }
            else {
                adjY = 0
            }
        }
        if (layers.children.length===1) {
            if (adjX<0 ) { adjX = 0}
            if (adjY<0 ) { adjY = 0}
        }
        if (adjX!==0 || adjY!==0) {
            for (var i = 0; i < layers.children.length; i++) {
                layers.children[i].x = layers.children[i].x + adjX
                layers.children[i].y = layers.children[i].y + adjY
                mainPane.width = mainPane.width
                mainPane.height = mainPane.height
            }
            if (adjX!==0) {
                flickableMainPane.contentX = 0
            }
            if (adjY!==0) {
                flickableMainPane.contentY = 0
            }

            var num = connections.children.length
            for (i=0; i<num; i++) {
                var connection = connections.children[i]
                var beginX = connection.beginX + adjX
                var beginY = connection.beginY + adjY
                var finishX = connection.finishX + adjX
                var finishY = connection.finishY + adjY
                updateConnection(connection,beginX,beginY,finishX,finishY)
            }
        }

        paneHeight = mainPane.height
        paneWidth = mainPane.width
        maxheight = Math.max(paneHeight,getbottom(unit))
        maxwidth = Math.max(paneWidth,getright(unit))
        maxheightchildren = Math.max(getbottomchild(layers))
        maxwidthchildren = Math.max(getrightchild(layers))

        if (maxheight>paneHeight) {
            mainPane.height = maxheight + padding
            flickableMainPane.contentHeight = mainPane.height
            flickableMainPane.contentY = maxheight - flickableMainPane.height + padding
        }
        if (maxwidth>paneWidth) {
            mainPane.width = maxwidth + padding
            flickableMainPane.contentWidth = mainPane.width
            flickableMainPane.contentX = maxwidth - flickableMainPane.width + padding
        }
        if (maxheightchildren>paneHeight) {
            mainPane.height = maxheightchildren + padding
            flickableMainPane.contentHeight = mainPane.height
        }
        else if (maxheightchildren>(mainFrame.height - 4*pix)) {
            mainPane.height = maxheightchildren + padding
            flickableMainPane.contentHeight = mainPane.height
        }
        else {
            mainPane.height = mainFrame.height - 4*pix
            flickableMainPane.contentHeight = mainPane.height
        }

        if (maxwidthchildren>paneWidth) {
            mainPane.width = maxwidthchildren + padding
            flickableMainPane.contentWidth = mainPane.width
        }
        else if (maxwidthchildren>(mainFrame.width - 4*pix)) {
            mainPane.width = maxwidthchildren + padding
            flickableMainPane.contentWidth = mainPane.width
        }
        else {
            mainPane.width = mainFrame.width - 4*pix
            flickableMainPane.contentWidth = mainPane.width
        }

        if (flickableMainPane.contentHeight>flickableMainPane.height) {
            flickableMainPane.ScrollBar.vertical.visible = true
        }
        else {
            flickableMainPane.ScrollBar.vertical.visible = false
        }
        if (flickableMainPane.contentWidth>flickableMainPane.width) {
            flickableMainPane.ScrollBar.horizontal.visible = true
        }
        else {
            flickableMainPane.ScrollBar.horizontal.visible = false
        }
        updateOverview()
    }

    function unitindex(layer) {
        for (var i=0;i<layers.children.length;i++) {
            if (layer===layers.children[i]) {
                return(i)
            }
        }
    }

    function nodetolayer(node) {
        return(node.parent.parent.parent.parent)
    }

    function itemindex(item) {
        var nodeItem = item.parent
        for (var i=1;i<nodeItem.children.length;i++) {
            if (item===nodeItem.children[i]) {
                return i
            }
        }
    }

    function nodeindex(nodes,node) {
        for (var i=0;i<nodes.children.length;i++) {
            if (nodes.children[i].children[0]===node) {
                return i
            }
        }
    }

    function getUpNode(unit,ind) {
        return unit.children[2].children[0].children[ind].children[0]
    }
    function getUpNodes(unit) {
        return unit.children[2].children[0]
    }
    function getUpNodeRec(unit,ind1,ind2) {
        return unit.children[2].children[0].children[ind1].children[ind2]
    }
    function getDownNodes(unit) {
        return unit.children[2].children[1]
    }
    function getDownNode(unit,ind) {
        return unit.children[2].children[1].children[ind].children[0]
    }
    function getDownNodeRec(unit,ind1,ind2) {
        return unit.children[2].children[1].children[ind1].children[ind2]
    }

    function updatePosition(unit) {
        var devX = unit.x - unit.oldpos[0]
        var devY = unit.y - unit.oldpos[1]
        var upNodes = unit.children[2].children[0]
        var downNodes = unit.children[2].children[1]
        for (var i=0;i<upNodes.children.length;i++) {
            var upNodeRectangle = upNodes.children[i].children[0]
            if (upNodeRectangle.connectedNode!==null) {
                var startX = upNodeRectangle.connectedItem.connection.data[0].startX;
                var startY = upNodeRectangle.connectedItem.connection.data[0].startY;
                var connection = upNodeRectangle.connectedItem.connection
                var beginX = startX
                var beginY = startY
                var finishX = unit.x +unit.width*upNodes.children[i].index/
                        (unit.inputnum+1) + devX
                var finishY = unit.y + 2*pix + devY
                updateConnection(connection,beginX,beginY,finishX,finishY)
                var nodePoint = upNodeRectangle.mapToItem(upNodeRectangle.connectedItem.parent,0,0)
                upNodeRectangle.connectedItem.x = nodePoint.x - upNodeRectangle.radius/2
                upNodeRectangle.connectedItem.y = nodePoint.y - upNodeRectangle.radius/2
            }
        }
        for (i=0;i<downNodes.children.length;i++) {
            for (var j=1;j<downNodes.children[i].children.length;j++) {
                var downNodeRectangle = downNodes.children[i].children[j]
                if (downNodeRectangle.connectedNode!==null) {
                    connection = downNodeRectangle.connection
                    beginX = unit.x + unit.width*downNodes.children[i].index/
                            (unit.outputnum+1) + devX
                    beginY = unit.y + unit.height - 2*pix + devY
                    finishX = connection.data[0].pathElements[0].x
                    finishY = connection.data[0].pathElements[0].y
                    updateConnection(connection,beginX,beginY,finishX,finishY)
                    nodePoint = downNodeRectangle.connectedNode.
                        mapToItem(downNodes.children[i],0,0)
                    downNodeRectangle.x = nodePoint.x - 10*pix
                    downNodeRectangle.y = nodePoint.y - 10*pix
                }
            }
        }
    }


//--COMPONENTS--------------------------------------------------------------------

    Component {
        id: layerComponent
        Rectangle {
            id: unit
            height: 95*pix
            width: 340*pix
            radius: 8*pix
            border.color: defaultpalette.controlborder
            border.width: 3*pix
            property int id
            property string name
            property string type
            property string group
            property var label_color: null
            property double inputnum
            property double outputnum
            property var datastore
            property var oldpos: [x,y]
            Column {
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: 14*pix
                spacing: 5*pix
                Label {
                    id: nameLabel
                    text: name
                    font.pixelSize: defaultPixelSize*1.1
                }
                Label {
                    id: typeLabel
                    text: type
                    font.pixelSize: defaultPixelSize*0.9
                    color: "#777777"
                }
            }
            MouseArea {
                id: unitMouseArea
                anchors.fill: parent
                drag.target: parent
                hoverEnabled: true
                Component.onCompleted: {
                    deselectunits()
                    selectunit(unit)
                    idCounter  = idCounter + 1
                    id = idCounter
                    getstack(label_color,id,group,type,name,unit)
                }
                onEntered: {
                    selectunit(unit)
                    for (var i=0;i<upNodes.children.length;i++) {
                        upNodes.children[i].children[0].visible = true
                    }
                    for (i=0;i<downNodes.children.length;i++) {
                        downNodes.children[i].children[0].visible = true
                    }
                }
                onExited: {
                    if (!mainPane.selectioninds.includes(unitindex(unit))){
                        deselectunit(unit)
                    }
                    for (var i=0;i<upNodes.children.length;i++) {
                        if (upNodes.children[i].children[0].connectedNode===null) {
                            upNodes.children[i].children[0].visible = false
                        }
                    }

                    for (i=0;i<downNodes.children.length;i++) {
                        var downNode = downNodes.children[i]
                        if (downNode.children[1].connectedNode===null) {
                            downNode.children[0].visible = false
                        }
                    }
                }
                onPressed: {
                    unit.oldpos = [unit.x,unit.y]
                    if (!mainPane.selectioninds.includes(unitindex(unit))) {
                        deselectunits()
                        selectunit(unit)
                    }
                    mainframeTimer.pressed = true
                    mainframeTimer.object = "unit"
                    mainframeTimer.object_data = [unit]
                }
                onClicked: {
                    deselectunits()
                    selectunit(unit)
                    mainPane.selectioninds = [unitindex(unit)]
                    getstack(label_color,id,group,type,name,unit)
                }
                onPositionChanged: {
                    if (pressed) {
                        updatePosUnit(unit)
                        var mapped_point = mapToItem(mainMouseArea,mouse.x,mouse.y)
                        mainframeTimer.mouseY = mapped_point.y
                        mainframeTimer.mouseX = mapped_point.x
                    }
                }
                onReleased: {
                    updateMainPane(unit)
                    mainframeTimer.pressed = false
                    mainframeTimer.object = null
                }
            }

            Item {
            id: nodes
                Item {
                    id: upNodes
                    Component.onCompleted: {
                        for (var i=0;i<inputnum;i++) {
                            upNodeComponent.createObject(upNodes, {
                                "unit": unit,
                                "upNodes": upNodes,
                                "downNodes": downNodes,
                                "inputnum": inputnum,
                                "index": i+1});
                        }
                    }
                }
                Item {
                    id: downNodes
                    Component.onCompleted: {
                        for (var i=0;i<outputnum;i++) {
                            downNodeComponent.createObject(downNodes, {
                                "unit": unit,
                                "upNodes": upNodes,
                                "downNodes": downNodes,
                                "outputnum": outputnum,
                                "index": i+1});
                        }
                    }
                }
            }
        }
    }

    Component {
        id: downNodeComponent
        Item {
            id: downNodeItem
            property var unit: null
            property var upNodes: null
            property var downNodes: null
            property double outputnum
            property double index
            Rectangle {
                id: downNode
                width: 20*pix
                height: 20*pix
                radius: 20*pix
                border.color: defaultpalette.controlborder
                border.width: 3*pix
                visible: false
                x: unit.width*index/(outputnum+1) - downNode.radius/2
                y: unit.height - downNode.radius/2 - 2*pix
            }
            Component.onCompleted: downNodeRectangleComponent.createObject(downNodeItem, {
                "unit": unit,
                "upNodes": upNodes,
                "downNodes": downNodes,
                "downNodeItem": downNodeItem,
                "downNode": downNode,
                "outputnum": outputnum,
                "index": index});
        }
    }

    Component {
        id: downNodeRectangleComponent
        Rectangle {
            id: downNodeRectangle
            property var unit: null
            property var upNodes: null
            property var downNodes: null
            property var downNode: null
            property var downNodeItem: null
            property var connectedNode: null
            property var connection: null
            property double outputnum
            property double index
            width: 2*downNode.radius
            height: 2*downNode.radius
            //opacity: 0.2
            color: "transparent"
            x: unit.width*index/(outputnum+1) - downNode.radius
            y: unit.height - downNode.radius - 2*pix
            MouseArea {
                id: downnodeMouseArea
                anchors.fill: parent
                hoverEnabled: true
                drag.target: downNodeRectangle
                drag.smoothed: false
                property var mouseAdjust: [0,0]
                onEntered: {
                    downNode.border.color = defaultcolors.dark
                    downNode.border.width = 4*pix
                    for (var i=0;i<upNodes.children.length;i++) {
                        upNodes.children[i].children[0].visible = true
                    }
                    for (i=0;i<downNodes.children.length;i++) {
                        downNodes.children[i].children[0].visible = true
                    }
                }
                onExited: {
                    downNode.border.color = defaultpalette.controlborder
                    downNode.border.width = 3*pix
                    for (var i=0;i<upNodes.children.length;i++) {
                        if (upNodes.children[i].children[0].connectedNode===null) {
                            upNodes.children[i].children[0].visible = false
                        }
                    }
                    for (i=0;i<downNodes.children.length;i++) {
                        if (downNodes.children[i].children[1].connectedNode===null) {
                            downNodes.children[i].children[0].visible = false
                        }
                    }
                }
                onPressed: {
                    deselectunits()
                    mainPane.selectioninds = []
                    mouseAdjust[0] = 0//mouse.x - downNodeRectangle.width/2;
                    mouseAdjust[1] = 0//mouse.y - downNodeRectangle.height/2;
                    for (var i=0;i<layers.children.length;i++) {
                        var unit_other = layers.children[i]
                        var upNodes_other = getUpNodes(unit_other)
                        for (var j=0;j<upNodes_other.children.length;j++) {
                            if (!getconnections(unit_other,0).up.includes(unitindex(unit))) {
                                getUpNode(unit_other,j).visible = true
                            }
                        }
                    }
                    mainframeTimer.pressed = true
                    mainframeTimer.object = "downnode"
                    mainframeTimer.object_data = [unit,downNode,downNodeRectangle,mouseAdjust]
                }
                onPositionChanged: {
                    if (pressed) {
                        updatePosDownNode(unit,downNode,downNodeRectangle,mouseAdjust)
                        var mapped_point = mapToItem(mainMouseArea,mouse.x,mouse.y)
                        mainframeTimer.mouseY = mapped_point.y
                        mainframeTimer.mouseX = mapped_point.x
                    }
                }
                onReleased: {
                    mainframeTimer.pressed = false
                    mainframeTimer.object = null
                    updateOverview()
                    for (var i=0;i<layers.children.length;i++) {
                        var unit_other = layers.children[i]
                        var upNodes_other = getUpNodes(unit_other)
                        for (var j=0;j<upNodes_other.children.length;j++) {
                            var upNode_other = getUpNode(unit_other,j)
                            if (upNode_other.connectedNode===null) {
                                upNode_other.visible = false
                            }
                        }
                    }
                    for (i=0;i<layers.children.length;i++) {
                        unit_other = layers.children[i]
                        upNodes_other = getUpNodes(unit_other)
                        for (j=0;j<upNodes_other.children.length;j++) {
                            upNode_other = getUpNode(unit_other,j)
                            if (comparelocations(downNodeRectangle,mouse.x,mouse.y,
                                    upNode_other,layers) && (upNode_other.connectedNode===null ||
                                    (upNode_other.connectedNode===downNode &&
                                    upNode_other.connectedItem===downNodeRectangle)) &&
                                    nodetolayer(upNode_other)!==nodetolayer(downNodeRectangle)) {
                                if (!getconnections(unit_other,0).up.includes(unitindex(unit))) {
                                    makeConnection(unit,downNode,downNodeRectangle,upNode_other)
                                    return
                                }
                            }
                        }
                    }
                    var connectedNode = downNodeRectangle.connectedNode
                    if (connectedNode!==null) {
                        connectedNode.connectedItem = null
                        connectedNode.connectedNode = null
                        connectedNode.visible = false
                        downNodeRectangle.destroy()
                    }
                    else {
                        downNodeRectangle.x = unit.width*index/(outputnum+1) - downNode.radius
                        downNodeRectangle.y = unit.height - downNode.radius - 2*pix
                    }
                    downNodeRectangle.connection.destroy()

                    downNode.border.color = defaultpalette.controlborder
                    downNode.border.width = 3*pix
                    if (downNodeItem.children.length===2) {
                        downNode.visible = false
                    }
                }
            }
        }
    }

    Component {
        id: upNodeComponent
        Item {
            id: upNodeItem
            property var unit: null
            property var upNodes: null
            property var downNodes: null
            property double inputnum
            property double index
            Rectangle {
                id: upNode
                width: 20*pix
                height: 20*pix
                radius: 20*pix
                border.color: defaultpalette.controlborder
                border.width: 3*pix
                visible: false
                property var connectedNode: null
                property var connectedItem: null
                x: unit.width*index/(inputnum+1)-upNode.radius/2
                y: -upNode.radius/2 + 2*pix
            }
            Rectangle {
                id: upNodeRectangle
                width: 2*upNode.radius
                height: 2*upNode.radius
                //opacity: 0.2
                color: "transparent"
                border.width: 0
                x: unit.width*index/(inputnum+1)-upNode.radius
                y: -upNode.radius + 2*pix
                MouseArea {
                    anchors.fill: parent
                    drag.target: parent
                    hoverEnabled: true
                    property var mouseAdjust: [0,0]
                    onEntered: {
                        upNode.border.color = defaultcolors.dark
                        upNode.border.width = 4*pix
                        for (var i=0;i<upNodes.children.length;i++) {
                            upNodes.children[i].children[0].visible = true
                        }
                        for (i=0;i<downNodes.children.length;i++) {
                            downNodes.children[i].children[0].visible = true
                        }

                    }
                    onExited: {
                        upNode.border.color = defaultpalette.controlborder
                        upNode.border.width = 3*pix
                        for (var i=0;i<upNodes.children.length;i++) {
                            if (upNodes.children[i].children[0].connectedNode===null) {
                                upNodes.children[i].children[0].visible = false
                            }
                        }
                        for (i=0;i<downNodes.children.length;i++) {
                            if (downNodes.children[i].children[1].connectedNode===null) {
                                downNodes.children[i].children[0].visible = false
                            }
                        }
                    }
                    onPressed: {
                        deselectunits()
                        mainPane.selectioninds = []
                        if (upNode.connectedNode==null) {
                            return
                        }
                        mouseAdjust[0] = 0//mouse.x - upNode.connectedItem.width/2;
                        mouseAdjust[1] = 0//mouse.y - upNode.connectedItem.height/2;
                        for (var i=0;i<layers.children.length;i++) {
                            var unit_other = layers.children[i]
                            var upNodes_other = getUpNodes(unit_other)
                            for (var j=0;j<upNodes_other.children.length;j++) {
                                getUpNode(unit_other,j).visible = true
                            }
                        }
                        mainframeTimer.pressed = true
                        mainframeTimer.object = "upnode"
                        mainframeTimer.object_data = [upNode,upNodeRectangle,mouseAdjust]
                    }
                    onPositionChanged: {
                        if (upNode.connectedNode==null) {
                            return
                        }
                        if (pressed) {
                            updatePosUpNode(upNode,upNodeRectangle,mouseAdjust)
                            var mapped_point = mapToItem(mainMouseArea,mouse.x,mouse.y)
                            mainframeTimer.mouseY = mapped_point.y
                            mainframeTimer.mouseX = mapped_point.x
                        }
                    }
                    onReleased: {
                        mainframeTimer.pressed = false
                        mainframeTimer.object = null
                        if (upNode.connectedNode==null) {
                            upNodeRectangle.x = unit.width*index/(inputnum+1)-upNode.radius
                            upNodeRectangle.y = -upNode.radius + 2*pix
                            return
                        }
                        for (var i=0;i<layers.children.length;i++) {
                            var unit_other = layers.children[i]
                            var upNodes_other = getUpNodes(unit_other)
                            for (var j=0;j<upNodes_other.children.length;j++) {
                                var upNode_other = getUpNode(unit_other,j)
                                if (upNode_other.connectedNode===null) {
                                    upNode_other.visible = false
                                }
                            }
                        }
                        for (i=0;i<layers.children.length;i++) {
                            unit_other = layers.children[i]
                            upNodes_other = getUpNodes(unit_other)
                            for (j=0;j<upNodes_other.children.length;j++) {
                                upNode_other = getUpNode(unit_other,j)
                                var upNodeRec_other = getUpNodeRec(unit_other,j,1)
                                if (comparelocations(upNodeRectangle,mouse.x,mouse.y,
                                        upNode_other,layers) && (upNode_other.connectedNode===null ||
                                        upNode_other.connectedNode===upNode.connectedNode) &&
                                        upNodeRec_other!==
                                        upNode.connectedNode.parent.parent.parent.children[j].children[1]) {
                                    if (upNode==upNode_other) {
                                        var connectedItem = upNode.connectedItem
                                        var connectedNode = upNode.connectedNode
                                        connectedItem.connectedNode = upNode_other
                                        upNode_other.connectedNode = upNode.connectedNode
                                        upNode_other.connectedItem = upNode.connectedItem
                                        upNode_other.visible = true
                                        var upNodePoint = upNodeRec_other.mapToItem(layers,0,0)
                                        var downNodePoint = connectedItem.mapToItem(layers,0,0)
                                        var adjX = downNodePoint.x - upNodePoint.x
                                        var adjY = downNodePoint.y - upNodePoint.y
                                        upNodeRectangle.x = unit.width*index/(inputnum+1)-upNode.radius
                                        upNodeRectangle.y = -upNode.radius + 2*pix
                                        connectedItem.x = connectedItem.x - adjX
                                        connectedItem.y = connectedItem.y - adjY
                                        var connection = connectedItem.connection
                                        var connection_data = connection.data[0]
                                        var pathElement = connection_data.pathElements[0]
                                        var beginX = connectedItem.unit.x + connectedItem.unit.width*
                                                connectedItem.index/(connectedItem.outputnum+1)
                                        var beginY = connectedItem.unit.y + connectedItem.unit.height - 2*pix
                                        var finishX = pathElement.x + adjX
                                        var finishY = pathElement.y + adjY - 2*pix
                                        updateConnection(connection,beginX,beginY,finishX,finishY)
                                    }
                                    else {
                                        // Initialize
                                        var unit_source = nodetolayer(upNode.connectedNode)
                                        var downNode_source = upNode.connectedNode
                                        var downNodeRectangle_source = upNode.connectedItem
                                        // Clean up
                                        connectedNode = upNode.connectedNode
                                        connectedItem = upNode.connectedItem
                                        connectedItem.connectedNode = null
                                        connectedItem.connection.destroy()
                                        connectedItem.connection = null
                                        if (connectedNode.parent.children.length===2) {
                                            connectedNode.visible = false
                                        }
                                        upNode.connectedNode = null
                                        upNode.connectedItem = null
                                        upNodeRectangle.x = unit.width*index/(inputnum+1)-upNode.radius
                                        upNodeRectangle.y = -upNode.radius + 2*pix
                                        upNode.visible = false
                                        // Connect
                                        makeConnection(unit_source,downNode_source,downNodeRectangle_source,upNode_other)
                                    }
                                    return
                                }
                            }
                        }
                        connectedNode = upNode.connectedNode
                        connectedItem = upNode.connectedItem
                        connectedItem.connectedNode = null
                        connectedItem.connection.destroy()
                        connectedItem.destroy()
                        if (connectedNode.parent.children.length===2) {
                            connectedNode.visible = false
                        }
                        upNode.connectedNode = null
                        upNode.connectedItem = null
                        upNodeRectangle.x = unit.width*index/(inputnum+1)-upNode.radius
                        upNodeRectangle.y = -upNode.radius + 2*pix
                        upNode.visible = false
                    }
                }
            }

        }
    }

    Component {
        id: connectionShapeComponent
        Shape {
            id: pathShape
            property double beginX: 0
            property double beginY: 0
            property double finishX: 0
            property double finishY: 0
            property var origin: null
            antialiasing: true
            vendorExtensionsEnabled: false
            ShapePath {
                id: pathShapePath
                strokeColor: defaultcolors.middark2
                strokeWidth: 4*pix
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap

                property int joinStyleIndex: 0

                property variant styles: [
                    ShapePath.BevelJoin,
                    ShapePath.MiterJoin,
                    ShapePath.RoundJoin
                ]

                joinStyle: styles[joinStyleIndex]

                startX: beginX
                startY: beginY
                PathLine {
                    x: finishX
                    y: finishY
                }
            }
        }
    }

    Component {
        id: connectionShapePathComponent
        ShapePath {
            id: pathShapePath
            property double beginX: 0
            property double beginY: 0
            property double finishX: 0
            property double finishY: 0
            strokeColor: defaultcolors.middark2
            strokeWidth: 4*pix
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            property int joinStyleIndex: 0

            property variant styles: [
                ShapePath.BevelJoin,
                ShapePath.MiterJoin,
                ShapePath.RoundJoin
            ]

            joinStyle: styles[joinStyleIndex]

            startX: beginX
            startY: beginY
            PathLine {
                x: finishX
                y: finishY
            }
        }
    }

    Component {
        id: buttonComponent
        ButtonNN {
            x: +2*pix
            width: leftFrame.width-24*pix
            height: 1.25*buttonHeight
            onPressed: {
                var object = layerComponent.createObject(layers,{"color" : adjustcolor([colorR,colorG,colorB]),
                                           "name": name,
                                           "type": type,
                                           "group": group,
                                           "label_color": [colorR,colorG,colorB],
                                           "inputnum": inputnum,
                                           "outputnum": outputnum,
                                           "x": flickableMainPane.contentX + 20*pix,
                                           "y": flickableMainPane.contentY + 20*pix});
                mainPane.selectioninds = [layers.children.length-1]
            }
            RowLayout {
                anchors.fill: parent.fill
                Rectangle {
                    id: colorRectangle
                    Layout.leftMargin: 0.2*margin
                    Layout.bottomMargin: 0.03*margin
                    Layout.preferredWidth: 0.4*margin
                    Layout.preferredHeight: 0.4*margin
                    height: 20*pix
                    width: 20*pix
                    radius: colorRectangle.height
                    Layout.alignment: Qt.AlignBottom
                    color: rgbtohtml([colorR,colorG,colorB])
                    border.width: 2*pix
                }
                Label {
                    topPadding: 0.28*margin
                    leftPadding: 0.10*margin
                    text: type
                    Layout.alignment: Qt.AlignBottom
                    Component.onCompleted: {
                        
                    }
                }
            }
        }
    }

    Component {
        id: customToolTip
        ToolTip {
            x: -1.1*width
            y: Math.round((parent.height - height)/2)
            delay: 200
            font.family: "Proxima Nova"
            font.pixelSize: defaultPixelSize*0.8
            visible: parent.hovered
            background: Rectangle {color: "white"; border.width: 2*pix}
        }
    }

    Popup {
        id: warningPopup
        modal: true
        visible: false
        closePolicy: Popup.NoAutoClose
        x: designWindow.width/2 - width/2
        y: designWindow.height/2 - height/2
        width: Math.max(titleLabel.width,textLabel.width) + 0.8*margin
        height: titleLabel.height + textLabel.height 
            + okButton.height + 0.4*margin + okButton.height
        property var warnings: []
        onVisibleChanged: {
            if (visible) {
                if (warnings.length!==0) {
                    textLabel.text = warnings[0]
                    warnings.shift()
                }
            }
        }
        Label {
            id: titleLabel
            x: warningPopup.width/2 - width/2 - 12*pix
            leftPadding: 0
            topPadding: 0.25*margin
            text: "WARNING"
        }
        Label {
            id: textLabel
            x:warningPopup.width/2 - width/2 - 12*pix
            leftPadding: 0
            anchors.top: titleLabel.bottom
            topPadding: 0.4*margin
        }
        Button {
            id: okButton
            width: buttonWidth/2
            x: warningPopup.width/2 - width/2 - 12*pix
            anchors.top: textLabel.bottom
            anchors.topMargin: 0.4*margin
            text: "OK"
            onClicked: {
                if (warningPopup.warnings.length!==0) {
                    textLabel.text = warningPopup.warnings[0]
                    warningPopup.warnings.shift()
                }
                else {
                    warningPopup.visible = false
                }
            }
        }
    }
//----Properties components----------------------------------------
    Component {
        id: generalpropertiesComponent
        Column {
            leftPadding: 0.4*margin
            topPadding: 0.4*margin
            spacing: 0.3*margin
            Row {
                spacing: 0.3*margin
                Label {
                    id: nameLabel
                    width: problemtypeLabel.width
                    text: "Name: "
                }
                TextField {
                    id: nameTextField
                    anchors.verticalCenter: nameLabel.verticalCenter
                    height: buttonHeight
                    width: rightFrame.width - 220*pix
                    onEditingFinished: {
                        Julia.set_data(["Urls","model_name"],displayText)
                        var model_url = Julia.get_data(["Urls","model_url"])
                        var model_url_split = model_url.split(/[\/\\]/g)
                        model_url_split.pop()
                        var model_url_new = model_url_split.join("/")
                        model_url_new = model_url_new+"/"+displayText+".model"
                        Julia.set_data(["model_url"],model_url_new)
                    }
                    Component.onCompleted: {
                        var name = Julia.get_data(["Urls","model_name"])
                        if (name.length===0) {
                            text = "new_model"
                            var model_url = "models/new_model.model"
                            Julia.set_data(["Urls","model_name"],text)
                            Julia.set_data(["Urls","model_url"],model_url)
                        }
                        else {
                            text = name
                        }
                    }
                }
            }
            Row {
                id: problemRow
                spacing: 0.3*margin
                Label {
                    id: problemtypeLabel
                    text: "Problem:"
                }
                ComboBox {
                    id: problemComboBox
                    anchors.verticalCenter: problemtypeLabel.verticalCenter
                    editable: false
                    width: 0.69*buttonWidth-1*pix
                    model: ListModel {
                        id: problemtypeModel
                        ListElement {text: "Classification"}
                        ListElement {text: "Regression"}
                        ListElement {text: "Segmentation"}
                    }
                    Component.onCompleted: {
                        problemComboBox.currentIndex = Julia.get_problem_type()
                    }
                    onActivated: {
                        Julia.set_problem_type(currentIndex)
                    }
                }
            }
            Row {
                spacing: 0.3*margin
                Label {
                    id: numlayersLabel
                    text: "Number of layers:"
                    width: numnonlinearLabel.width
                }
                Label {
                    text: getlayersnum()
                }
            }
            Row {
                spacing: 0.3*margin
                Label {
                    id: numconnectionsLabel
                    text: "Number of connections:"
                    width: numnonlinearLabel.width
                }
                Label {
                    text: getconnectionsnum()
                }
            }
            Row {
                spacing: 0.3*margin
                Label {
                    id: numnonlinearLabel
                    text: "Number of nonlinearities:"
                }
                Label {
                    text: getirregularitiesnum()
                }
            }
        }
    }

    Component {
        id: inputpropertiesComponent
        Column {
            id: column
            property int id
            property var unit: null
            property var name: null
            property string type
            property var group: null
            property var label_color: null
            property var datastore: {"id": id,"name": name, "type": type, "group": group,
                "size": [160,160],"normalisation": {"text": "[0,1]", "ind": 0}}
            Component.onCompleted: {
                if (unit.datastore===undefined) {
                    unit.datastore = datastore
                }
                else {
                    datastore = unit.datastore
                }
            }

            Row {
                leftPadding: 20*pix
                bottomPadding: 20*pix
                ColorBox {
                    topPadding: 0.39*margin
                    leftPadding: 0.1*margin
                    rightPadding: 0.2*margin
                    colorRGB: label_color
                }
                Label {
                    id: typeLabel
                    topPadding: 0.28*margin
                    leftPadding: 0.10*margin
                    text: type
                    font.pixelSize: defaultPixelSize*1.1
                    color: "#777777"
                    wrapMode: Text.NoWrap
                }
            }
            Row {
                Column{
                    id: labelColumn
                    leftPadding: 0.4*margin
                    topPadding: 0.2*margin
                    spacing: 20*pix
                    Repeater {
                        model: ["Name","Size","Normalisation"]
                        Label {
                            height: buttonHeight
                            topPadding: 14*pix
                            bottomPadding: topPadding
                            text: modelData+": "
                        }
                    }
                }
                Column {
                    topPadding: 0.2*margin
                    spacing: 20*pix
                    TextField {
                        text: datastore.name
                        height: buttonHeight
                        width: rightFrame.width - labelColumn.width - 70*pix
                        onEditingFinished: {
                            unit.datastore.name = displayText
                            unit.children[0].children[0].text = displayText
                        }
                    }
                    TextField {
                        height: buttonHeight
                        width: rightFrame.width - labelColumn.width - 70*pix
                        validator: RegExpValidator { regExp: /(([1-9]\d{0,3})|([1-9]\d{0,3},[1-9]\d{0,3})|([1-9]\d{0,3},[1-9]\d{0,3},[1-9]\d{0,3}))/ }
                        Component.onCompleted: {
                            var str = ""
                            for (var i=0;i<datastore.size.length;i++) {
                                str = str + datastore.size[i].toString()
                                if (i!==(datastore.size.length-1)) {
                                    str = str + ","
                                }
                            }
                            text = str
                        }
                        onEditingFinished: {
                            var splitString = displayText.split(",")
                            var ar = []
                            for (var i=0;i<splitString.length;i++) {
                                ar.push(parseInt(splitString[i],10))
                            }
                            unit.datastore.size = ar
                        }
                    }
                    ComboBox {
                        height: buttonHeight
                        width: rightFrame.width - labelColumn.width - 70*pix
                        currentIndex: datastore.normalisation.ind
                        model: ListModel {
                           id: optionsModel
                           ListElement { text: "[0,1]" }
                           ListElement { text: "[-1,1]" }
                           ListElement { text: "zero center" }
                        }
                        onActivated: {
                            unit.datastore.normalisation.text = currentText
                            unit.datastore.normalisation.ind = currentIndex
                        }
                    }
                }
            }
        }
    }

    Component {
        id: outputpropertiesComponent
        Column {
            property int id
            property var unit: null
            property var name: null
            property string type
            property var group: null
            property var label_color: null
            property var datastore: { "id": id,"name": name, "type": type, "group": group,"loss": {"text": "Dice coefficient", "ind": 12}}
            Component.onCompleted: {
                if (unit.datastore===undefined) {
                    unit.datastore = datastore
                }
                else {
                    datastore = unit.datastore
                }
            }
            Row {
                leftPadding: 20*pix
                bottomPadding: 20*pix
                ColorBox {
                    topPadding: 0.39*margin
                    leftPadding: 0.1*margin
                    rightPadding: 0.2*margin
                    colorRGB: label_color
                }
                Label {
                    id: typeLabel
                    topPadding: 0.28*margin
                    leftPadding: 0.10*margin
                    text: type
                    font.pixelSize: defaultPixelSize*1.1
                    color: "#777777"
                    wrapMode: Text.NoWrap
                }
            }
            Row {
                Column {
                    id: labelColumn
                    leftPadding: 0.4*margin
                    topPadding: 0.2*margin
                    spacing: 20*pix
                    Repeater {
                        model: ["Name","Loss"]
                        Label {
                            height: buttonHeight
                            topPadding: 14*pix
                            bottomPadding: topPadding
                            text: modelData+": "
                        }
                    }
                }
                Column {
                    topPadding: 0.2*margin
                    spacing: 20*pix
                    TextField {
                        text: datastore.name
                        height: buttonHeight
                        width: rightFrame.width - labelColumn.width - 70*pix
                        onEditingFinished: {
                            unit.datastore.name = displayText
                            unit.children[0].children[0].text = displayText
                        }
                    }
                    ComboBox {
                        height: buttonHeight
                        width: rightFrame.width - labelColumn.width - 70*pix
                        currentIndex: datastore.loss.ind
                        model: ListModel {
                           id: optionsModel
                           ListElement { text: "MAE" }
                           ListElement { text: "MSE" }
                           ListElement { text: "MSLE" }
                           ListElement { text: "Huber" }
                           ListElement { text: "Crossentropy" }
                           ListElement { text: "Logit crossentropy" }
                           ListElement { text: "Binary crossentropy" }
                           ListElement { text: "Logit binary crossentropy" }
                           ListElement { text: "Kullback-Leibler divergence" }
                           ListElement { text: "Poisson" }
                           ListElement { text: "Hinge" }
                           ListElement { text: "Squared hinge" }
                           ListElement { text: "Dice coefficient" }
                           ListElement { text: "Tversky" }
                        }
                        onActivated: {
                            unit.datastore.loss.text = currentText
                            unit.datastore.loss.ind = currentIndex
                        }
                    }
                }
            }
        }
    }

    Component {
        id: convpropertiesComponent
        Column {
            property int id
            property var unit: null
            property var name: null
            property string type
            property var group: null
            property var label_color: null
            property var datastore: { "id": id,"name": name, "type": type, "group": group,
                "filters": 32, "filter_size": 3,"stride": 1, "dilation_factor": 1}
            Component.onCompleted: {
                if (unit.datastore===undefined) {
                    unit.datastore = datastore
                }
                else {
                    datastore = unit.datastore
                }
            }
            Row {
                leftPadding: 20*pix
                bottomPadding: 20*pix
                ColorBox {
                    topPadding: 0.39*margin
                    leftPadding: 0.1*margin
                    rightPadding: 0.2*margin
                    colorRGB: label_color
                }
                Label {
                    id: typeLabel
                    topPadding: 0.28*margin
                    leftPadding: 0.10*margin
                    text: type
                    font.pixelSize: defaultPixelSize*1.1
                    color: "#777777"
                    wrapMode: Text.NoWrap
                }
            }
            Row {
                Column {
                    id: labelColumn
                    leftPadding: 0.4*margin
                    topPadding: 0.2*margin
                    spacing: 20*pix
                    Repeater {
                        model: ["Name","Filters","Filter size",
                            "Stride","Dilation factor"]
                        Label {
                            height: buttonHeight
                            topPadding: 14*pix
                            bottomPadding: topPadding
                            text: modelData+": "
                        }
                    }
                }
                Column {
                    topPadding: 0.2*margin
                    spacing: 20*pix
                    TextField {
                        text: datastore.name
                        height: buttonHeight
                        width: rightFrame.width - labelColumn.width - 70*pix
                        onEditingFinished: {
                            unit.datastore.name = displayText
                            unit.children[0].children[0].text = displayText
                        }
                    }
                    TextField {
                        text: datastore.filters.toString()
                        height: buttonHeight
                        width: rightFrame.width - labelColumn.width - 70*pix
                        validator: RegExpValidator { regExp: /[1-9]\d{0,5}/ }
                        onEditingFinished: {
                            unit.datastore.filters = parseInt(displayText,10)
                        }
                    }
                    TextField {
                        height: buttonHeight
                        width: rightFrame.width - labelColumn.width - 70*pix
                        validator: RegExpValidator { regExp: /(([1-9]\d{0,1})|([1-9]\d{0,1},[1-9]\d{0,1})|([1-9]\d{0,1},[1-9]\d{0,1},[1-9]\d{0,1}))/ }
                        Component.onCompleted: {
                            if (Array.isArray(datastore.filter_size)) {
                                if (datastore.filter_size[0]==datastore.filter_size[1]) {
                                    text = datastore.filter_size[0].toString()
                                }
                                else {
                                    text = datastore.filter_size[0].toString() + 
                                        "," + datastore.filter_size[1].toString()
                                }
                            }
                            else {
                                text = datastore.filter_size.toString()
                            }
                        }
                        onEditingFinished: {
                            unit.datastore.filter_size = parseInt(displayText,10)
                        }
                    }
                    TextField {
                        text: datastore.stride.toString()
                        height: buttonHeight
                        width: rightFrame.width - labelColumn.width - 70*pix
                        validator: RegExpValidator { regExp: /(([1-9]\d{0,1})|([1-9]\d{0,1},[1-9]\d{0,1})|([1-9]\d{0,1},[1-9]\d{0,1},[1-9]\d{0,1}))/ }
                        onEditingFinished: {
                            unit.datastore.stride = parseInt(displayText,10)
                        }
                    }
                    TextField {
                        text: datastore.dilation_factor.toString()
                        height: buttonHeight
                        width: rightFrame.width - labelColumn.width - 70*pix
                        validator: RegExpValidator { regExp: /(([1-9]\d{0,1})|([1-9]\d{0,1},[1-9]\d{0,1})|([1-9]\d{0,1},[1-9]\d{0,1},[1-9]\d{0,1}))/ }
                        onEditingFinished: {
                            unit.datastore.dilation_factor = parseInt(displayText,10)
                        }
                    }
                }
            }
        }
    }

    Component {
        id: tconvpropertiesComponent
        Column {
            property int id
            property var unit: null
            property var name: null
            property string type
            property var group: null
            property var label_color: null
            property var datastore: { "id": id,"name": name, "type": type, 
                "group": group,"filters": 32, "filter_size": 3,"stride": 1}
            Component.onCompleted: {
                if (unit.datastore===undefined) {
                    unit.datastore = datastore
                }
                else {
                    datastore = unit.datastore
                }
            }
            Row {
                leftPadding: 20*pix
                bottomPadding: 20*pix
                ColorBox {
                    topPadding: 0.39*margin
                    leftPadding: 0.1*margin
                    rightPadding: 0.2*margin
                    colorRGB: label_color
                }
                Label {
                    id: typeLabel
                    topPadding: 0.28*margin
                    leftPadding: 0.10*margin
                    text: type
                    font.pixelSize: defaultPixelSize*1.1
                    color: "#777777"
                    wrapMode: Text.NoWrap
                }
            }
            Row {
                Column {
                    id: labelColumn
                    leftPadding: 0.4*margin
                    topPadding: 0.2*margin
                    spacing: 20*pix
                    Repeater {
                        model: ["Name","Filters","Filter size",
                            "Stride"]
                        Label {
                            height: buttonHeight
                            topPadding: 14*pix
                            bottomPadding: topPadding
                            text: modelData+": "
                        }
                    }
                }
                Column {
                    topPadding: 0.2*margin
                    spacing: 20*pix
                    TextField {
                        text: datastore.name
                        height: buttonHeight
                        width: rightFrame.width - labelColumn.width - 70*pix
                        onEditingFinished: {
                            unit.datastore.name = displayText
                            unit.children[0].children[0].text = displayText
                        }
                    }
                    TextField {
                        text: datastore.filters.toString()
                        height: buttonHeight
                        width: rightFrame.width - labelColumn.width - 70*pix
                        validator: RegExpValidator { regExp: /[1-9]\d{0,5}/ }
                        onEditingFinished: {
                            unit.datastore.filters = parseInt(displayText,10)
                        }
                    }
                    TextField {
                        height: buttonHeight
                        width: rightFrame.width - labelColumn.width - 70*pix
                        validator: RegExpValidator { regExp: /(([1-9]\d{0,1})|([1-9]\d{0,1},[1-9]\d{0,1})|([1-9]\d{0,1},[1-9]\d{0,1},[1-9]\d{0,1}))/ }
                        Component.onCompleted: {
                            if (Array.isArray(datastore.filter_size)) {
                                if (datastore.filter_size[0]==datastore.filter_size[1]) {
                                    text = datastore.filter_size[0].toString()
                                }
                                else {
                                    text = datastore.filter_size[0].toString() + 
                                        "," + datastore.filter_size[1].toString()
                                }
                            }
                            else {
                                text = datastore.filter_size.toString()
                            }
                        }
                        onEditingFinished: {
                            unit.datastore.filter_size = parseInt(displayText,10)
                        }
                    }
                    TextField {
                        text: datastore.stride.toString()
                        height: buttonHeight
                        width: rightFrame.width - labelColumn.width - 70*pix
                        validator: RegExpValidator { regExp: /(([1-9]\d{0,1})|([1-9]\d{0,1},[1-9]\d{0,1})|([1-9]\d{0,1},[1-9]\d{0,1},[1-9]\d{0,1}))/ }
                        onEditingFinished: {
                            unit.datastore.stride = parseInt(displayText,10)
                        }
                    }
                }
            }
        }
    }

    Component {
        id: densepropertiesComponent
        Column {
            property int id
            property var unit: null
            property var name: null
            property string type
            property var group: null
            property var label_color: null
            property var datastore: { "id": id,"name": name, "type": type, 
                "group": group, "filters": 32}
            Component.onCompleted: {
                if (unit.datastore===undefined) {
                    unit.datastore = datastore
                }
                else {
                    datastore = unit.datastore
                }
            }
            Row {
                leftPadding: 20*pix
                bottomPadding: 20*pix
                ColorBox {
                    topPadding: 0.39*margin
                    leftPadding: 0.1*margin
                    rightPadding: 0.2*margin
                    colorRGB: label_color
                }
                Label {
                    id: typeLabel
                    topPadding: 0.28*margin
                    leftPadding: 0.10*margin
                    text: type
                    font.pixelSize: defaultPixelSize*1.1
                    color: "#777777"
                    wrapMode: Text.NoWrap
                }
            }
            Row {
                Column {
                    id: labelColumn
                    leftPadding: 0.4*margin
                    topPadding: 0.2*margin
                    spacing: 20*pix
                    Repeater {
                        model: ["Name","Filters"]
                        Label {
                            height: buttonHeight
                            topPadding: 14*pix
                            bottomPadding: topPadding
                            text: modelData+": "
                        }
                    }
                }
                Column {
                    topPadding: 0.2*margin
                    spacing: 20*pix
                    TextField {
                        text: datastore.name
                        height: buttonHeight
                        width: rightFrame.width - labelColumn.width - 70*pix
                        onEditingFinished: {
                            unit.datastore.name = displayText
                            unit.children[0].children[0].text = displayText
                        }
                    }
                    TextField {
                        text: datastore.filters.toString()
                        height: buttonHeight
                        width: rightFrame.width - labelColumn.width - 70*pix
                        validator: RegExpValidator { regExp: /[1-9]\d{0,5}/ }
                        onEditingFinished: {
                            unit.datastore.filters = parseInt(displayText,10)
                        }
                    }
                }
            }
        }
    }

    Component {
        id: batchnormpropertiesComponent
        Column {
            property int id
            property var unit: null
            property var name: null
            property string type
            property var group: null
            property var label_color: null
            property var datastore: { "id": id,"name": name, "type": type, 
                "group": group,"epsilon": 0.00001}
            Component.onCompleted: {
                if (unit.datastore===undefined) {
                    unit.datastore = datastore
                }
                else {
                    datastore = unit.datastore
                }
            }
            Row {
                leftPadding: 20*pix
                bottomPadding: 20*pix
                ColorBox {
                    topPadding: 0.39*margin
                    leftPadding: 0.1*margin
                    rightPadding: 0.2*margin
                    colorRGB: label_color
                }
                Label {
                    id: typeLabel
                    topPadding: 0.28*margin
                    leftPadding: 0.10*margin
                    text: type
                    font.pixelSize: defaultPixelSize*1.1
                    color: "#777777"
                    wrapMode: Text.NoWrap
                }
            }
            Row {
                Column {
                    id: labelColumn
                    leftPadding: 0.4*margin
                    topPadding: 0.2*margin
                    spacing: 20*pix
                    Repeater {
                        model: ["Name","Epsilon"]
                        Label {
                            height: buttonHeight
                            topPadding: 14*pix
                            bottomPadding: topPadding
                            text: modelData+": "
                        }
                    }
                }
                Column {
                    topPadding: 0.2*margin
                    spacing: 20*pix
                    TextField {
                        text: datastore.name
                        height: buttonHeight
                        width: rightFrame.width - labelColumn.width - 70*pix
                        onEditingFinished: {
                            unit.datastore.name = displayText
                            unit.children[0].children[0].text = displayText
                        }
                    }
                    TextField {
                        text: datastore.epsilon.toString()
                        height: buttonHeight
                        width: rightFrame.width - labelColumn.width - 70*pix
                        validator: RegExpValidator { regExp: /0.\d{1,10}/ }
                        onEditingFinished: {
                            unit.datastore.epsilon = parseFloat(displayText)
                        }
                    }
                }
            }
        }
    }

    Component {
        id: dropoutpropertiesComponent
        Column {
            property int id
            property var unit: null
            property var name: null
            property string type
            property var group: null
            property var label_color: null
            property var datastore: { "id": id,"name": name, "type": type, 
                "group": group,"probability": 0.5}
            Component.onCompleted: {
                if (unit.datastore===undefined) {
                    unit.datastore = datastore
                }
                else {
                    datastore = unit.datastore
                }
            }
            Row {
                leftPadding: 20*pix
                bottomPadding: 20*pix
                ColorBox {
                    topPadding: 0.39*margin
                    leftPadding: 0.1*margin
                    rightPadding: 0.2*margin
                    colorRGB: label_color
                }
                Label {
                    id: typeLabel
                    topPadding: 0.28*margin
                    leftPadding: 0.10*margin
                    text: type
                    font.pixelSize: defaultPixelSize*1.1
                    color: "#777777"
                    wrapMode: Text.NoWrap
                }
            }
            Row {
                Column {
                    id: labelColumn
                    leftPadding: 0.4*margin
                    topPadding: 0.2*margin
                    spacing: 20*pix
                    Repeater {
                        model: ["Name","Probability"]
                        Label {
                            height: buttonHeight
                            topPadding: 14*pix
                            bottomPadding: topPadding
                            text: modelData+": "
                        }
                    }
                }
                Column {
                    topPadding: 0.2*margin
                    spacing: 20*pix
                    TextField {
                        text: datastore.name
                        height: buttonHeight
                        width: rightFrame.width - labelColumn.width - 70*pix
                        onEditingFinished: {
                            unit.datastore.name = displayText
                            unit.children[0].children[0].text = displayText
                        }
                    }
                    TextField {
                        text: datastore.probability.toString()
                        height: buttonHeight
                        width: rightFrame.width - labelColumn.width - 70*pix
                        validator: RegExpValidator { regExp: /0.\d{1,2}/ }
                        onEditingFinished: {
                            unit.datastore.probability = parseFloat(displayText)
                        }
                    }
                }
            }
        }
    }

    Component {
        id: leakyrelupropertiesComponent
        Column {
            property int id
            property var unit: null
            property var name: null
            property string type
            property var group: null
            property var label_color: null
            property var datastore: { "id": id,"name": name, "type": type, 
                "group": group,"scale": 0.01}
            Component.onCompleted: {
                if (unit.datastore===undefined) {
                    unit.datastore = datastore
                }
                else {
                    datastore = unit.datastore
                }
            }
            Row {
                leftPadding: 20*pix
                bottomPadding: 20*pix
                ColorBox {
                    topPadding: 0.39*margin
                    leftPadding: 0.1*margin
                    rightPadding: 0.2*margin
                    colorRGB: label_color
                }
                Label {
                    id: typeLabel
                    topPadding: 0.28*margin
                    leftPadding: 0.10*margin
                    text: type
                    font.pixelSize: defaultPixelSize*1.1
                    color: "#777777"
                    wrapMode: Text.NoWrap
                }
            }
            Row {
                Column {
                    id: labelColumn
                    leftPadding: 0.4*margin
                    topPadding: 0.2*margin
                    spacing: 20*pix
                    Repeater {
                        model: ["Name","Scale"]
                        Label {
                            height: buttonHeight
                            topPadding: 14*pix
                            bottomPadding: topPadding
                            text: modelData+": "
                        }
                    }
                }
                Column {
                    topPadding: 0.2*margin
                    spacing: 20*pix
                    TextField {
                        text: datastore.name
                        height: buttonHeight
                        width: rightFrame.width - labelColumn.width - 70*pix
                        onEditingFinished: {
                            unit.datastore.name = displayText
                            unit.children[0].children[0].text = displayText
                        }
                    }
                    TextField {
                        text: datastore.scale.toString()
                        height: buttonHeight
                        width: rightFrame.width - labelColumn.width - 70*pix
                        validator: RegExpValidator { regExp: /0.\d{1,2}/ }
                        onEditingFinished: {
                            unit.datastore.scale = parseFloat(displayText)
                        }
                    }
                }
            }
        }
    }

    Component {
        id: elupropertiesComponent
        Column {
            property int id
            property var unit: null
            property var name: null
            property string type
            property var group: null
            property var label_color: null
            property var datastore: { "id": id,"name": name, "type": type, 
                "group": group,"alpha": 1}
            Component.onCompleted: {
                if (unit.datastore===undefined) {
                    unit.datastore = datastore
                }
                else {
                    datastore = unit.datastore
                }
            }
            Row {
                leftPadding: 20*pix
                bottomPadding: 20*pix
                ColorBox {
                    topPadding: 0.39*margin
                    leftPadding: 0.1*margin
                    rightPadding: 0.2*margin
                    colorRGB: label_color
                }
                Label {
                    id: typeLabel
                    topPadding: 0.28*margin
                    leftPadding: 0.10*margin
                    text: type
                    font.pixelSize: defaultPixelSize*1.1
                    color: "#777777"
                    wrapMode: Text.NoWrap
                }
            }
            Row {
                Column {
                    id: labelColumn
                    leftPadding: 0.4*margin
                    topPadding: 0.2*margin
                    spacing: 20*pix
                    Repeater {
                        model: ["Name","Alpha"]
                        Label {
                            height: buttonHeight
                            topPadding: 14*pix
                            bottomPadding: topPadding
                            text: modelData+": "
                        }
                    }
                }
                Column {
                    topPadding: 0.2*margin
                    spacing: 20*pix
                    TextField {
                        text: datastore.name
                        height: buttonHeight
                        width: rightFrame.width - labelColumn.width - 70*pix
                        onEditingFinished: {
                            unit.datastore.name = displayText
                            unit.children[0].children[0].text = displayText
                        }
                    }
                    TextField {
                        text: datastore.alpha.toString()
                        height: buttonHeight
                        width: rightFrame.width - labelColumn.width - 70*pix
                        validator: RegExpValidator { regExp: /0.\d{1,4}|[1-9]d{1,2}/ }
                        onEditingFinished: {
                            unit.datastore.alpha = parseFloat(displayText)
                        }
                    }
                }
            }
        }
    }

    Component {
        id: poolpropertiesComponent
        Column {
            property int id
            property var unit: null
            property var name: null
            property string type
            property var group: null
            property var label_color: null
            property var datastore: { "id": id,"name": name, "type": type, 
                "group": group, "poolsize": 2, "stride": 2}
            Component.onCompleted: {
                if (unit.datastore===undefined) {
                    unit.datastore = datastore
                }
                else {
                    datastore = unit.datastore
                }
            }
            Row {
                leftPadding: 20*pix
                bottomPadding: 20*pix
                ColorBox {
                    topPadding: 0.39*margin
                    leftPadding: 0.1*margin
                    rightPadding: 0.2*margin
                    colorRGB: label_color
                }
                Label {
                    id: typeLabel
                    topPadding: 0.28*margin
                    leftPadding: 0.10*margin
                    text: type
                    font.pixelSize: defaultPixelSize*1.1
                    color: "#777777"
                    wrapMode: Text.NoWrap
                }
            }
            Row {
                Column {
                    id: labelColumn
                    leftPadding: 0.4*margin
                    topPadding: 0.2*margin
                    spacing: 20*pix
                    Repeater {
                        model: ["Name","Pool size","Stride"]
                        Label {
                            height: buttonHeight
                            topPadding: 14*pix
                            bottomPadding: topPadding
                            text: modelData+": "
                        }
                    }
                }
                Column {
                    topPadding: 0.2*margin
                    spacing: 20*pix
                    TextField {
                        text: datastore.name
                        height: buttonHeight
                        width: rightFrame.width - labelColumn.width - 70*pix
                        onEditingFinished: {
                            unit.datastore.name = displayText
                            unit.children[0].children[0].text = displayText
                        }
                    }
                    TextField {
                        text: datastore.poolsize.toString()
                        height: buttonHeight
                        width: rightFrame.width - labelColumn.width - 70*pix
                        validator: RegExpValidator { regExp: /(([1-9]\d{0,1})|([1-9]\d{0,1},[1-9]\d{0,1})|([1-9]\d{0,1},[1-9]\d{0,1},[1-9]\d{0,1}))/ }
                        onEditingFinished: {
                            unit.datastore.poolsize = parseInt(displayText,10)
                        }
                    }
                    TextField {
                        text: datastore.stride.toString()
                        height: buttonHeight
                        width: rightFrame.width - labelColumn.width - 70*pix
                        validator: RegExpValidator { regExp: /(([1-9]\d{0,1})|([1-9]\d{0,1},[1-9]\d{0,1})|([1-9]\d{0,1},[1-9]\d{0,1},[1-9]\d{0,1}))/ }
                        onEditingFinished: {
                            unit.datastore.stride = parseInt(displayText,10)
                        }
                    }
                }
            }
        }
    }

    Component {
        id: additionpropertiesComponent
        Column {
            property int id
            property var unit: null
            property var name: null
            property string type
            property var group: null
            property var label_color: null
            property var datastore: { "id": id,"name": name, "type": type, 
                "group": group,"inputs": 2}
            Component.onCompleted: {
                if (unit.datastore===undefined) {
                    unit.datastore = datastore
                }
                else {
                    datastore = unit.datastore
                }
            }
            Row {
                leftPadding: 20*pix
                bottomPadding: 20*pix
                ColorBox {
                    topPadding: 0.39*margin
                    leftPadding: 0.1*margin
                    rightPadding: 0.2*margin
                    colorRGB: label_color
                }
                Label {
                    id: typeLabel
                    topPadding: 0.28*margin
                    leftPadding: 0.10*margin
                    text: type
                    font.pixelSize: defaultPixelSize*1.1
                    color: "#777777"
                    wrapMode: Text.NoWrap
                }
            }
            Row {
                Column {
                    id: labelColumn
                    leftPadding: 0.4*margin
                    topPadding: 0.2*margin
                    spacing: 20*pix
                    Repeater {
                        model: ["Name","Inputs"]
                        Label {
                            height: buttonHeight
                            topPadding: 14*pix
                            bottomPadding: topPadding
                            text: modelData+": "
                        }
                    }
                }
                Column {
                    topPadding: 0.2*margin
                    spacing: 20*pix
                    TextField {
                        text: datastore.name
                        height: buttonHeight
                        width: rightFrame.width - labelColumn.width - 70*pix
                        onEditingFinished: {
                            unit.datastore.name = displayText
                            unit.children[0].children[0].text = displayText
                        }
                    }
                    TextField {
                        text: datastore.inputs.toString()
                        height: buttonHeight
                        width: rightFrame.width - labelColumn.width - 70*pix
                        validator: RegExpValidator { regExp: /[1-9]|10/ }
                        onEditingFinished: {
                            var inputnum = parseFloat(unit.datastore.inputs)
                            var newinputnum = parseFloat(displayText)
                            if (inputnum===newinputnum) {return}
                            if (inputnum<newinputnum) {
                                for (var i=0;i<inputnum;i++) {
                                    var upNodeItem = unit.children[2].children[0].children[i]
                                    var upNode = upNodeItem.children[0]
                                    var upRec = upNodeItem.children[1]
                                    upNodeItem.inputnum = newinputnum
                                    upNode.x = unit.width*upNodeItem.index/(newinputnum+1)-10*pix
                                    upRec.x = unit.width*upNodeItem.index/(newinputnum+1)-20*pix
                                    var downRecCon = upNode.connectedItem
                                    if (downRecCon!==null) {
                                        var downNodeCon = upNode.connectedNode
                                        downRecCon.x = upRec.x
                                        downRecCon.connection.destroy()
                                        makeConnection(downNodeCon.parent.unit,downNodeCon,downRecCon,upNode)
                                    }
                                }
                                for (i=0;i<(newinputnum-inputnum);i++) {
                                    upNodeComponent.createObject(unit.children[2].children[0], {
                                        "unit": unit,
                                        "upNodes": unit.children[2].children[0],
                                        "downNodes": unit.children[2].children[1],
                                        "inputnum": newinputnum,
                                        "index": inputnum+i+1})
                                }
                            }
                            else {
                                for (i=inputnum-1;i>=0;i--) {
                                    upNodeItem = unit.children[2].children[0].children[i]
                                    if (i<newinputnum) {
                                        upNode = upNodeItem.children[0]
                                        upRec = upNodeItem.children[1]
                                        upNodeItem.inputnum = newinputnum
                                        var new_x = unit.width*upNodeItem.index/(newinputnum+1)
                                        var oldRec_x = upRec.x
                                        upNode.x = new_x - 10*pix
                                        upRec.x = new_x - 20*pix
                                        downRecCon = upNodeItem.children[0].connectedItem
                                        if (downRecCon!==null) {
                                            downNodeCon = upNode.connectedNode
                                            downRecCon.x = downRecCon.x + (oldRec_x - (new_x - 20*pix))
                                            downRecCon.connection.destroy()
                                            makeConnection(downNodeCon.parent.unit,downNodeCon,downRecCon,upNode)
                                        }
                                    }
                                    else {
                                        upNode = upNodeItem.children[0]
                                        if (upNode.connectedNode!==null) {
                                            upNode.connectedItem.connection.destroy()
                                            upNode.connectedItem.destroy()
                                        }
                                        upNodeItem.destroy()
                                    }
                                }
                            }
                            unit.inputnum = newinputnum
                            unit.datastore.inputs = parseInt(displayText,10)
                        }
                    }
                }
            }
        }
    }

    Component {
        id: catpropertiesComponent
        Column {
            property int id
            property var unit: null
            property var name: null
            property string type
            property var group: null
            property var label_color: null
            property var datastore: { "id": id,"name": name, "type": type, "group": group,
                "inputs": 2, "dimension": 3}
            Component.onCompleted: {
                if (unit.datastore===undefined) {
                    unit.datastore = datastore
                }
                else {
                    datastore = unit.datastore
                }
            }
            Row {
                leftPadding: 20*pix
                bottomPadding: 20*pix
                ColorBox {
                    topPadding: 0.39*margin
                    leftPadding: 0.1*margin
                    rightPadding: 0.2*margin
                    colorRGB: label_color
                }
                Label {
                    id: typeLabel
                    topPadding: 0.28*margin
                    leftPadding: 0.10*margin
                    text: type
                    font.pixelSize: defaultPixelSize*1.1
                    color: "#777777"
                    wrapMode: Text.NoWrap
                }
            }
            Row {
                Column {
                    id: labelColumn
                    leftPadding: 0.4*margin
                    topPadding: 0.2*margin
                    spacing: 20*pix
                    Repeater {
                        model: ["Name","Inputs","Dimension"]
                        Label {
                            height: buttonHeight
                            topPadding: 14*pix
                            bottomPadding: topPadding
                            text: modelData+": "
                        }
                    }
                }
                Column {
                    topPadding: 0.2*margin
                    spacing: 20*pix
                    TextField {
                        text: datastore.name
                        height: buttonHeight
                        width: rightFrame.width - labelColumn.width - 70*pix
                        onEditingFinished: {
                            unit.datastore.name = displayText
                            unit.children[0].children[0].text = displayText
                        }
                    }
                    TextField {
                        text: datastore.inputs.toString()
                        height: buttonHeight
                        width: rightFrame.width - labelColumn.width - 70*pix
                        validator: RegExpValidator { regExp: /[2-9]|10/ }
                        onEditingFinished: {
                            var inputnum = parseFloat(unit.datastore.inputs)
                            var newinputnum = parseFloat(displayText)
                            if (inputnum===newinputnum) {return}
                            if (inputnum<newinputnum) {
                                for (var i=0;i<inputnum;i++) {
                                    var upNodeItem = unit.children[2].children[0].children[i]
                                    var upNode = upNodeItem.children[0]
                                    var upRec = upNodeItem.children[1]
                                    upNodeItem.inputnum = newinputnum
                                    unit.inputnum = newinputnum
                                    upNode.x = unit.width*upNodeItem.index/(newinputnum+1)-10*pix
                                    upRec.x = unit.width*upNodeItem.index/(newinputnum+1)-20*pix
                                    var downRecCon = upNode.connectedItem
                                    if (downRecCon!==null) {
                                        var downNodeCon = upNode.connectedNode
                                        downRecCon.x = upRec.x
                                        makeConnection(downNodeCon.parent.unit,downNodeCon,downRecCon,upNode)
                                    }
                                }
                                for (i=0;i<(newinputnum-inputnum);i++) {
                                    upNodeComponent.createObject(unit.children[2].children[0], {
                                        "unit": unit,
                                        "upNodes": unit.children[2].children[0],
                                        "downNodes": unit.children[2].children[1],
                                        "inputnum": newinputnum,
                                        "index": inputnum+i+1})
                                }
                            }
                            else {
                                for (i=inputnum-1;i>=0;i--) {
                                    upNodeItem = unit.children[2].children[0].children[i]
                                    if (i<newinputnum) {
                                        upNode = upNodeItem.children[0]
                                        upRec = upNodeItem.children[1]
                                        upNodeItem.inputnum = newinputnum
                                        var new_x = unit.width*upNodeItem.index/(newinputnum+1)
                                        var oldRec_x = upRec.x
                                        upNode.x = new_x - 10*pix
                                        upRec.x = new_x - 20*pix
                                        downRecCon = upNodeItem.children[0].connectedItem
                                        if (downRecCon!==null) {
                                            downNodeCon = upNode.connectedNode
                                            downRecCon.x = downRecCon.x + (oldRec_x - (new_x - 20*pix))
                                            makeConnection(downNodeCon.parent.unit,downNodeCon,downRecCon,upNode)
                                        }
                                    }
                                    else {
                                        upNode = upNodeItem.children[0]
                                        if (upNode.connectedNode!==null) {
                                            upNode.connectedItem.connection.destroy()
                                            upNode.connectedItem.destroy()
                                        }
                                        upNodeItem.destroy()
                                    }
                                }
                            }
                            unit.inputnum = newinputnum
                            unit.datastore.inputs = parseInt(displayText,10)
                        }
                    }
                    TextField {
                        text: datastore.dimension.toString()
                        height: buttonHeight
                        width: rightFrame.width - labelColumn.width - 70*pix
                        validator: RegExpValidator { regExp: /[1-3]/ }
                        onEditingFinished: {
                            unit.datastore.dimension = parseInt(displayText,10)
                        }
                    }
                }
            }
        }
    }

    Component {
        id: splitpropertiesComponent
        Column {
            property int id
            property var unit: null
            property var name: null
            property string type
            property var group: null
            property var label_color: null
            property var datastore: { "id": id,"name": name, "type": type, "group": group,
                "outputs": 2,"dimension": 3}
            Component.onCompleted: {
                if (unit.datastore===undefined) {
                    unit.datastore = datastore
                }
                else {
                    datastore = unit.datastore
                }
            }
            Row {
                leftPadding: 20*pix
                bottomPadding: 20*pix
                ColorBox {
                    topPadding: 0.39*margin
                    leftPadding: 0.1*margin
                    rightPadding: 0.2*margin
                    colorRGB: label_color
                }
                Label {
                    id: typeLabel
                    topPadding: 0.28*margin
                    leftPadding: 0.10*margin
                    text: type
                    font.pixelSize: defaultPixelSize*1.1
                    color: "#777777"
                    wrapMode: Text.NoWrap
                }
            }
            Row {
                Column {
                    id: labelColumn
                    leftPadding: 0.4*margin
                    topPadding: 0.2*margin
                    spacing: 20*pix
                    Repeater {
                        model: ["Name","Outputs","Dimension"]
                        Label {
                            height: buttonHeight
                            topPadding: 14*pix
                            bottomPadding: topPadding
                            text: modelData+": "
                        }
                    }
                }
                Column {
                    topPadding: 0.2*margin
                    spacing: 20*pix
                    TextField {
                        text: datastore.name
                        height: buttonHeight
                        width: rightFrame.width - labelColumn.width - 70*pix
                        onEditingFinished: {
                            unit.datastore.name = displayText
                            unit.children[0].children[0].text = displayText
                        }
                    }
                    TextField {
                        text: datastore.outputs.toString()
                        height: buttonHeight
                        width: rightFrame.width - labelColumn.width - 70*pix
                        validator: RegExpValidator { regExp: /[1-9]|10/ }
                        onEditingFinished: {
                            var outputnum = parseFloat(unit.datastore.outputs)
                            var newoutputnum = parseFloat(displayText)
                            if (outputnum===newoutputnum) {return}
                            if (outputnum<newoutputnum) {
                                for (var i=0;i<outputnum;i++) {
                                    var downNodeItem = unit.children[2].children[1].children[i]
                                    var downNode = downNodeItem.children[0]
                                    unit.outputnum = newoutputnum
                                    downNodeItem.outputnum = newoutputnum
                                    downNode.x = unit.width*
                                        downNodeItem.index/(newoutputnum+1)-10*pix
                                    for (var j=1;j<downNodeItem.children.length;j++) {
                                        var downRecN = downNodeItem.children[j]
                                        downRecN.outputnum = newoutputnum
                                        downRecN.x = unit.width*
                                            downNodeItem.index/(newoutputnum+1)-20*pix
                                        var upNodeCon = downRecN.connectedNode
                                        if (upNodeCon!==null) {
                                            makeConnection(downNode.parent.unit,downNode,downRecN,upNodeCon)
                                        }
                                    }
                                }
                                for (i=0;i<(newoutputnum-outputnum);i++) {
                                    downNodeComponent.createObject(unit.children[2].children[1], {
                                        "unit": unit,
                                        "upNodes": unit.children[2].children[0],
                                        "downNodes": unit.children[2].children[1],
                                        "outputnum": newoutputnum,
                                        "index": outputnum+i+1})
                                }
                            }
                            else {
                                for (i=outputnum-1;i>=0;i--) {
                                    downNodeItem = unit.children[2].children[1].children[i]
                                    if (i<newoutputnum) {
                                        downNode = downNodeItem.children[0]
                                        unit.outputnum = newoutputnum
                                        downNodeItem.outputnum = newoutputnum
                                        downNode.x = unit.width*
                                            downNodeItem.index/(newoutputnum+1)-10*pix
                                        for (j=1;j<downNodeItem.children.length;j++) {
                                            downRecN = downNodeItem.children[j]
                                            downRecN.outputnum = newoutputnum
                                            downRecN.x = unit.width*
                                                downNodeItem.index/(newoutputnum+1)-20*pix
                                            upNodeCon = downRecN.connectedNode
                                            if (upNodeCon!==null) {
                                                makeConnection(downNode.parent.unit,downNode,downRecN,upNodeCon)
                                            }
                                        }
                                    }
                                    else {
                                        downNode = downNodeItem.children[1]
                                        if (downNode.connectedNode!==null) {
                                            upNodeCon = downNode.connectedNode
                                            upNodeCon.connectedItem = null
                                            upNodeCon.connectedNode = null
                                            downNode.connection.destroy()
                                        }
                                        downNodeItem.destroy()
                                    }
                                }

                            }
                            unit.outputnum = newoutputnum
                            unit.datastore.outputs = parseInt(displayText,10)
                        }
                    }
                    TextField {
                        text: datastore.dimension.toString()
                        height: buttonHeight
                        width: rightFrame.width - labelColumn.width - 70*pix
                        validator: RegExpValidator { regExp: /[1-3]/ }
                        onEditingFinished: {
                            unit.datastore.dimension = parseInt(displayText,10)
                        }
                    }
                }
            }
        }
    }

    Component {
        id: upsamplepropertiesComponent
        Column {
            property int id
            property var unit: null
            property var name: null
            property string type
            property var group: null
            property var label_color: null
            property var datastore: { "id": id,"name": name, "type": type, 
                "group": group,"multiplier": 2, "dimensions": [1,2]}
            Component.onCompleted: {
                if (unit.datastore===undefined) {
                    unit.datastore = datastore
                }
                else {
                    datastore = unit.datastore
                }
            }
            Row {
                leftPadding: 20*pix
                bottomPadding: 20*pix
                ColorBox {
                    topPadding: 0.39*margin
                    leftPadding: 0.1*margin
                    rightPadding: 0.2*margin
                    colorRGB: label_color
                }
                Label {
                    id: typeLabel
                    topPadding: 0.28*margin
                    leftPadding: 0.10*margin
                    text: type
                    font.pixelSize: defaultPixelSize*1.1
                    color: "#777777"
                    wrapMode: Text.NoWrap
                }
            }
            Row {
                Column {
                    id: labelColumn
                    leftPadding: 0.4*margin
                    topPadding: 0.2*margin
                    spacing: 20*pix
                    Repeater {
                        model: ["Name","Multiplier","Dimensions"]
                        Label {
                            height: buttonHeight
                            topPadding: 14*pix
                            bottomPadding: topPadding
                            text: modelData+": "
                        }
                    }
                }
                Column {
                    topPadding: 0.2*margin
                    spacing: 20*pix
                    TextField {
                        text: datastore.name
                        height: buttonHeight
                        width: rightFrame.width - labelColumn.width - 70*pix
                        onEditingFinished: {
                            unit.datastore.name = displayText
                            unit.children[0].children[0].text = displayText
                        }
                    }
                    TextField {
                        text: datastore.multiplier.toString()
                        height: buttonHeight
                        width: rightFrame.width - labelColumn.width - 70*pix
                        validator: RegExpValidator { regExp: /([2-5])/ }
                        onEditingFinished: {
                            unit.datastore.multiplier = parseInt(displayText,10)
                        }
                    }
                    TextField {
                        height: buttonHeight
                        width: rightFrame.width - labelColumn.width - 70*pix
                        validator: RegExpValidator {
                            regExp: /(1|2|3|1,2|1,2,3)/ }
                        Component.onCompleted: {
                            var str = ""
                            for (var i=0;i<datastore.dimensions.length;i++) {
                                str = str + datastore.dimensions[i].toString()
                                if (i!==(datastore.dimensions.length-1)) {
                                    str = str + ","
                                }
                            }
                            text = str
                        }
                        onEditingFinished: {
                            var splitString = displayText.split(",")
                            var ar = []
                            for (var i=0;i<splitString.length;i++) {
                                ar.push(parseInt(splitString[i],10))
                            }
                            unit.datastore.dimensions = ar
                        }
                    }
                }
            }
        }
    }

    Component {
        id: emptypropertiesComponent
        Column {
            property int id
            property var unit: null
            property var name: null
            property string type
            property var group: null
            property var label_color: null
            property var datastore: { "id": id,"name": name, "type": type, "group": group}
            Component.onCompleted: {
                if (unit.datastore===undefined) {
                    unit.datastore = datastore
                }
                else {
                    datastore = unit.datastore
                }
            }
            Row {
                leftPadding: 20*pix
                bottomPadding: 20*pix
                ColorBox {
                    topPadding: 0.39*margin
                    leftPadding: 0.1*margin
                    rightPadding: 0.2*margin
                    colorRGB: label_color
                }
                Label {
                    id: typeLabel
                    topPadding: 0.28*margin
                    leftPadding: 0.10*margin
                    text: type
                    font.pixelSize: defaultPixelSize*1.1
                    color: "#777777"
                    wrapMode: Text.NoWrap
                }
            }
            Row {
                Column {
                    id: labelColumn
                    leftPadding: 0.4*margin
                    topPadding: 0.2*margin
                    spacing: 20*pix
                    Repeater {
                        model: ["Name"]
                        Label {
                            height: buttonHeight
                            topPadding: 14*pix
                            bottomPadding: topPadding
                            text: modelData+": "
                        }
                    }
                }
                Column {
                    topPadding: 0.2*margin
                    spacing: 20*pix
                    TextField {
                        text: datastore.name
                        height: buttonHeight
                        width: rightFrame.width - labelColumn.width - 70*pix
                        onEditingFinished: {
                            unit.datastore.name = displayText
                            unit.children[0].children[0].text = displayText
                        }
                    }
                }
            }
        }
    }
}
