
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.Layouts 1.2
import Qt.labs.platform 1.1
import "Templates"
import org.julialang 1.0


ApplicationWindow {
    id: featuredialogWindow
    visible: true
    title: qsTr("  Julia Machine Learning GUI")
    width: rowLayout.width
    height: rowLayout.height + applyButton.height + 0.75*margin
    property double indTree: JindTree
    property double max_id: Math.max(...ids)

    //---Universal property block-----------------------------------------------
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

    function rgbtohtml(colorRGB) {
        return(Qt.rgba(colorRGB[0]/255,colorRGB[1]/255,colorRGB[2]/255))
    }

    //--------------------------------------------------------------------------
    function load_model_features(featureModel) {
        var num_features = Julia.num_features()
            if (num_features<3) {
            parent2ComboBox.visible = false
            parent2Label.visible = false
            if (Julia.num_features()<2) {
                parentComboBox.visible = false
                parentLabel.visible = false
            }
        }
        if (featureModel.count!==0) {
            featureModel.clear()
        }
        for (var i=0;i<num_features;i++) {
            var ind = i+1
            var color = Julia.get_feature_field(ind,"color")
            var parents = Julia.get_feature_field(ind,"parents")
            if (i+1<max_id) {
                var id = ids[i]
            }
            else {
                max_id += 1
                id = max_id
            }
            var feature = {
                "name": Julia.get_feature_field(ind,"name"),
                "id": id,
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

    function update_fields() {
        if (indTree<0) {
            parametersColumn.opacity = 0
            return
        }
        else {
            parametersColumn.opacity = 1
        }

        featureView.itemAtIndex(indTree).borderForceVisible = true

        nameTextField.text = featureModel.get(indTree).name
        
        redTextField.text = featureModel.get(indTree).colorR
        greenTextField.text = featureModel.get(indTree).colorG
        blueTextField.text = featureModel.get(indTree).colorB

        minareaTextField.text = featureModel.get(indTree).min_area

        // parentComboBox
        // parentComboBox 1
        nameModel.clear()
        var name = featureModel.get(indTree).parent
        nameModel.append({"name": ""})
        for (var i=0;i<featureModel.count;i++) {
            if (i===indTree) continue
            nameModel.append({"name": featureModel.get(i).name})
        }
        if (name!=="") {
            for (var i=0;i<parentComboBox.model.count;i++) {
                if (parentComboBox.model.get(i).name===name) {
                    parentComboBox.currentIndex = i
                }
            }
        }
        // parentComboBox 2
        name2Model.clear()
        var name1 = parentComboBox.currentText
        name2Model.append({"name": ""})
        for (i=0;i<featureModel.count;i++) {
            name = featureModel.get(i).name
            if (i===indTree || name1===name) continue
            name2Model.append({"name": name})
        }
        var parentName = featureModel.get(indTree).parent2
        if (parentName!=="") {
            for (i=0;i<name2Model.count;i++) {
                if (name2Model.get(i).name===parentName) {
                    parent2ComboBox.currentIndex = i
                }
            }
        }

        // notfeatureCheckBox
        notfeatureCheckBox.checkState = featureModel.get(indTree).notFeature ?
                        Qt.Checked : Qt.Unchecked

        // borderCheckBox
        borderCheckBox.checkState = featureModel.get(indTree).border ?
                        Qt.Checked : Qt.Unchecked

        // bordernumpixelsSpinBox
        bordernumpixelsSpinBox.value = featureModel.get(indTree).border_thickness

        // borderremoveobjsLabel
        borderremoveobjsCheckBox.checkState = featureModel.get(indTree).borderRemoveObjs ?
                        Qt.Checked : Qt.Unchecked
    }

    ListModel {
        id: featureModel
        Component.onCompleted: {
            load_model_features(featureModel)
            featureView.forceLayout()
            update_fields()
        }
    }

    ListModel {
        id: dummyModel
    }


    //-------------------------------------------------------------------------

    color: defaultpalette.window

    // onClosing: {featuredialogLoader.sourceComponent = null}

    RowLayout {
        id: rowLayout
        spacing: 0.75*margin
        Column {
            id: featuresColumn
            Layout.alignment: Qt.AlignTop
            Layout.margins: 0.75*margin
            Layout.rightMargin: 0*margin
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
                height: 1.66*432*pix
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
                            ListView {
                                id: featureView
                                height: childrenRect.height
                                spacing: -2*pix
                                boundsBehavior: Flickable.StopAtBounds
                                model: featureModel
                                delegate: TreeButton {
                                    id: treeButton
                                    x: 1
                                    hoverEnabled: true
                                    width: buttonWidth + 0.5*margin - 24*pix
                                    height: buttonHeight - 2*pix
                                    onClicked: {
                                        for (var i=0;i<featureModel.count;i++) {
                                            featureView.itemAtIndex(i).borderForceVisible = false
                                        }
                                        borderForceVisible = true
                                        indTree = index
                                        update_fields()
                                    }
                                    Rectangle {
                                        id: colorRectangle
                                        anchors.left: treeButton.left
                                        anchors.verticalCenter: treeButton.verticalCenter
                                        anchors.leftMargin: 15*pix
                                        height: 30*pix
                                        width: 30*pix
                                        border.width: 2*pix
                                        radius: colorRectangle.width
                                        color: rgbtohtml([colorR,colorG,colorB])
                                    }
                                    Label {
                                        anchors.left: colorRectangle.left
                                        anchors.leftMargin: 50*pix
                                        anchors.verticalCenter: treeButton.verticalCenter
                                        text: name
                                    }
                                    Button {
                                        id: trashcanButton
                                        visible: treeButton.hovered
                                        hoverEnabled: true
                                        height: 55*pix
                                        width: 55*pix
                                        background: Rectangle {
                                            opacity: 0
                                        }
                                        anchors.verticalCenter: treeButton.verticalCenter
                                        anchors.right: treeButton.right
                                        anchors.rightMargin: 5*pix
                                        Image {
                                            opacity: trashcanButton.hovered ? 1 : 0.2
                                            source: "Icons/trash_can.png"
                                            height: 55*pix
                                            width: 55*pix
                                            fillMode: Image.PreserveAspectFit
                                        }
                                        onClicked: {
                                            if (indTree==index) {
                                                indTree = index - 1
                                                if (indTree<0 && featureModel.count!=1) {
                                                    indTree = 0
                                                }
                                            }
                                            if (indTree==(featureModel.count-1)) {
                                                indTree -= 1
                                            }
                                            featureModel.remove(index)
                                            update_fields()
                                        }
                                    }
                                }
                            }
                            Button {
                                id: addButton
                                hoverEnabled: true
                                anchors.top: featureView.bottom
                                x: 1
                                width: buttonWidth + 0.5*margin - 24*pix
                                height: buttonHeight - 2*pix
                                background: Rectangle {
                                    color: "transparent"
                                    border.color: defaultpalette.border
                                    border.width: addButton.hovered ? 2*pix : 0
                                }
                                onClicked: {
                                    var cnt = featureModel.count+1
                                    var name = "Feature "+cnt.toString()
                                    while (true) {
                                        for (var i=0;i<featureModel.count;i++) {
                                            console.log(featureModel.get(i).name,name)
                                            if (featureModel.get(i).name==name) {
                                                cnt += 1
                                                name = "Feature "+cnt.toString()
                                                break
                                            }
                                        }
                                        console.log(i,(featureModel.count))
                                        if(i==(featureModel.count)) {
                                            break
                                        }
                                    }
                                    max_id += 1
                                    var id = max_id
                                    var feature = {
                                        "name": name,
                                        "id": id,
                                        "colorR": Math.floor(Math.random()*255)+1,
                                        "colorG": Math.floor(Math.random()*255)+1,
                                        "colorB": Math.floor(Math.random()*255)+1,
                                        "border": false,
                                        "border_thickness": 3,
                                        "borderRemoveObjs": false,
                                        "min_area": 0,
                                        "parent": "",
                                        "parent2": "",
                                        "notFeature": false}
                                    featureModel.append(feature)
                                    if (indTree<0) {
                                        indTree = 0
                                    }
                                    update_fields()
                                }
                                Item {
                                    id: plusItem
                                    anchors.horizontalCenter: addButton.horizontalCenter
                                    anchors.top: addButton.top
                                    anchors.topMargin: 10*pix
                                    property color colorOuter1: defaultcolors.dark
                                    property color colorOuter2: defaultcolors.middark
                                    property color colorInner1: defaultcolors.midlight3
                                    property color colorInner2: defaultcolors.midlight
                                    Rectangle {
                                        id: plusotline1Rectangle
                                        color: addButton.hovered ? plusItem.colorOuter1 : plusItem.colorOuter2
                                        height: plus1Rectangle.height + 4*pix
                                        width: plus1Rectangle.width + 4*pix
                                        border.width: 0*pix
                                        radius: 5*pix
                                    }
                                    Rectangle {
                                        id: plusoutline2Rectangle
                                        anchors.horizontalCenter: plusotline1Rectangle.horizontalCenter
                                        anchors.verticalCenter: plusotline1Rectangle.verticalCenter
                                        color: addButton.hovered ? plusItem.colorOuter1 : plusItem.colorOuter2
                                        height: plus1Rectangle.width + 4*pix
                                        width: plus1Rectangle.height + 4*pix
                                        border.width: 0*pix
                                        radius: 5*pix
                                    }
                                    Rectangle {
                                        id: plus1Rectangle
                                        anchors.horizontalCenter: plusotline1Rectangle.horizontalCenter
                                        anchors.verticalCenter: plusotline1Rectangle.verticalCenter
                                        color: addButton.hovered ? plusItem.colorInner1 : plusItem.colorInner2
                                        height: 40*pix
                                        width: 6*pix
                                        border.width: 0*pix
                                        radius: 5*pix
                                    }
                                    Rectangle {
                                        id: plus2Rectangle
                                        anchors.horizontalCenter: plusotline1Rectangle.horizontalCenter
                                        anchors.verticalCenter: plusotline1Rectangle.verticalCenter
                                        color: addButton.hovered ? plusItem.colorInner1 : plusItem.colorInner2
                                        height: 6*pix
                                        width: 40*pix
                                        border.width: 0*pix
                                        radius: 5*pix
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        Column {
            id: parametersColumn
            Layout.alignment: Qt.AlignTop
            Layout.margins: 0.75*margin
            Layout.leftMargin: 0*margin
            spacing: 0.4*margin
            Row {
                Label {
                    id: nameLabel
                    text: "Name:"
                    width: 160*pix
                    topPadding: 0.14*margin
                }
                TextField {
                    id: nameTextField
                    width: 400*pix
                    height: buttonHeight
                    onEditingFinished: {
                        var prev_name = featureModel.get(indTree).name
                        var new_name = nameTextField.text
                        if (prev_name!==new_name) {
                            for (var i=0;i<featureModel.count;i++) {
                                var element = featureModel.get(i)
                                if (element.parent===prev_name) {
                                    element.parent = new_name
                                }
                            }
                        }
                        featureModel.setProperty(indTree, "name", text)
                    }
                    
                }
            }
            Row {
                Label {
                    id: parentLabel
                    width: nameLabel.width
                    text: "Parent:"
                    topPadding: 0.14*margin
                }
                ComboBox {
                    id: parentComboBox
                    width: 400*pix
                    editable: false
                    model: nameModel
                    ListModel {
                        id: nameModel
                    }
                    onActivated: {
                        if (index!==0 && featureModel.count>2) {
                            parent2Label.visible = true
                            parent2ComboBox.visible = true
                        }
                        else {
                            parent2Label.visible = false
                            parent2ComboBox.visible = false
                        }
                        featureModel.setProperty(indTree, "parent", currentValue)
                    }
                }
            }
            Row {
                Label {
                    id: parent2Label
                    width: nameLabel.width
                    text: "Parent 2:"
                    topPadding: 0.14*margin
                }
                ComboBox {
                    id: parent2ComboBox
                    width: 400*pix
                    editable: false
                    model: name2Model
                    ListModel {
                        id: name2Model
                    }
                    onActivated: {
                        featureModel.setProperty(indTree, "parent2", currentValue)
                    }
                }
            }
            Label {
                text: "Color (RGB):"
            }
            Row {
                spacing: 0.3*margin
                bottomPadding: 0.2*margin
                Label {
                    text: "Red:"
                    anchors.verticalCenter: redTextField.verticalCenter
                }
                TextField {
                    id: redTextField
                    text: "0"
                    width: 0.18*buttonWidth
                    height: buttonHeight
                    validator: IntValidator { bottom: 0; top: 999;}
                    onEditingFinished: {
                        var val = parseFloat(redTextField.text)
                        if (val>255) {
                            val = 255
                            redTextField.text = "255"
                        }
                        featureModel.setProperty(indTree, "colorR", val)
                    }
                    onAccepted: {
                        backgroundMouseArea.focus = true
                    }
                }
                Label {
                    text: "Green:"
                    anchors.verticalCenter: greenTextField.verticalCenter
                }
                TextField {
                    id: greenTextField
                    text: "0"
                    width: 0.18*buttonWidth
                    height: buttonHeight
                    validator: IntValidator { bottom: 0; top: 999;}
                    onEditingFinished: {
                        var val = parseFloat(greenTextField.text)
                        if (val>255) {
                            val = 255
                            greenTextField.text = "255"
                        }
                        featureModel.setProperty(indTree, "colorR", val)
                        featureModel.get(indTree).colorR = val
                    }
                    onAccepted: {
                        var val = parseFloat(greenTextField.text)
                        if (val>255) {
                            val = 255
                            greenTextField.text = "255"
                        }
                        featureModel.setProperty(indTree, "colorR", val)
                        backgroundMouseArea.focus = true
                    }
                }
                Label {
                    text: "Blue:"
                    anchors.verticalCenter: blueTextField.verticalCenter
                }
                TextField {
                    id: blueTextField
                    text: "0"
                    width: 0.18*buttonWidth
                    height: buttonHeight
                    maximumLength: 3
                    validator: IntValidator { bottom: 0; top: 999;}
                    onEditingFinished: {
                        var val = parseFloat(blueTextField.text)
                        if (val>255) {
                            val = 255
                            blueTextField.text = "255"
                        }
                        featureModel.setProperty(indTree, "colorR", val)
                        featureModel.get(indTree).colorR = val
                    }
                    onAccepted: {
                        var val = parseFloat(blueTextField.text)
                        if (val>255) {
                            val = 255
                            blueTextField.text = "255"
                        }
                        featureModel.setProperty(indTree, "colorR", val)
                        backgroundMouseArea.focus = true
                    }
                }
            }
            Row {
                Label {
                    id: notfeatureLabel
                    width: 350*pix
                    text: "Not a feature:"
                }
                CheckBox {
                    id: notfeatureCheckBox
                    onClicked: {
                        if (checkState==Qt.Checked) {
                            featureModel.get(indTree).notFeature = true
                        }
                        if (checkState==Qt.Unchecked) {
                            featureModel.get(indTree).notFeature = false
                        }
                    }
                }
            }
            Row {
                Label {
                    id: borderLabel
                    width: 350*pix
                    text: "Border is important:"
                }
                CheckBox {
                    id: borderCheckBox
                    onClicked: {
                        if (checkState==Qt.Checked) {
                            featureModel.get(indTree).border = true
                        }
                        if (checkState==Qt.Unchecked) {
                            featureModel.get(indTree).border = false
                        }
                    }
                }
            }
            Row {
                spacing: 0.3*margin
                Label {
                    visible: borderCheckBox.checkState==Qt.Checked
                    text: "Border thickness (pix):"
                    width: 350*pix
                }
                SpinBox {
                    id: bordernumpixelsSpinBox
                    visible: borderCheckBox.checkState==Qt.Checked
                    from: 0
                    to: 9
                    stepSize: 1
                    property double realValue
                    textFromValue: function(value, locale) {
                        realValue = (value)*2+1
                        return realValue.toLocaleString(locale,'f',0)
                    }
                    onValueModified: {
                        featureModel.get(indTree).border_thickness = value
                    }
                }
            }
            Row {
                Label {
                    id: borderremoveobjsLabel
                    visible: borderCheckBox.checkState==Qt.Checked
                    width: 350*pix
                    wrapMode: Label.WordWrap
                    text: "Ignore objects with a broken border:"
                }
                CheckBox {
                    id: borderremoveobjsCheckBox
                    anchors.verticalCenter: borderremoveobjsLabel.verticalCenter
                    visible: borderCheckBox.checkState==Qt.Checked
                    onClicked: {
                        if (checkState==Qt.Checked) {
                            featureModel.get(indTree).borderRemoveObjs = true
                        }
                        if (checkState==Qt.Unchecked) {
                            featureModel.get(indTree).borderRemoveObjs = false
                        }
                    }
                }
            }
            Row {
                spacing: 0.3*margin
                Label {
                    id: minareaLabel
                    text: "Minimum object area:"
                    width: 350*pix
                    topPadding: 10*pix
                }
                TextField {
                    id: minareaTextField
                    width: 140*pix
                    validator: RegExpValidator { regExp: /([1-9]\d{0,5})/ }
                    onEditingFinished: {
                        featureModel.get(indTree).min_area = parseInt(text)
                    }
                }
            }
            
        }
    }
    Button {
        id: applyButton
        text: "Apply"
        anchors.horizontalCenter: rowLayout.horizontalCenter
        anchors.top: rowLayout.bottom
        width: buttonWidth/2
        height: 1.2*buttonHeight
        onClicked: {
            Julia.backup_options()
            Julia.reset_features()
            Julia.reset_output_options()
            for (var i=0;i<featureModel.count;i++) {
                var feature = featureModel.get(i)
                Julia.append_features(feature.id,
                    [feature.name,
                    feature.colorR,
                    feature.colorG,
                    feature.colorB,
                    feature.border,
                    feature.border_thickness,
                    feature.borderRemoveObjs,
                    feature.min_area,
                    [feature.parent,feature.parent2],
                    feature.notFeature])
            }
            // featuredialogLoader.sourceComponent = null
            featuredialogWindow.close()
        }
    }

    MouseArea {
        id: backgroundMouseArea
        width: featuredialogWindow.width
        height: featuredialogWindow.height
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

    function debug(el) {
        console.log(el)
        return el
    }

}










