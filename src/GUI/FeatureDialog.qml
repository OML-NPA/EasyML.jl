
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

    function update_fields() {

        nameTextField.text = featureModel.get(indTree).name
        
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
            update_fields()
        }
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
                height: 1.37*432*pix
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
                                spacing: 0
                                boundsBehavior: Flickable.StopAtBounds
                                model: featureModel
                                delegate: TreeButton {
                                    id: control
                                    hoverEnabled: true
                                    width: buttonWidth + 0.5*margin - 24*pix
                                    height: buttonHeight - 2*pix
                                    onClicked: {
                                        indTree = index
                                        update_fields()
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
            }
        }
        Column {
            Layout.alignment: Qt.AlignTop
            Layout.margins: 0.75*margin
            Layout.leftMargin: 0*margin
            spacing: 0.4*margin
            RowLayout {
                spacing: 0.34*margin
                ColumnLayout {
                    Layout.alignment : Qt.AlignHCenter
                    spacing: 0.40*margin
                    Label {
                        Layout.alignment : Qt.AlignLeft
                        text: "Name:"
                        bottomPadding: 0.06*margin
                    }
                    Label {
                        id: parentLabel
                        Layout.alignment : Qt.AlignLeft
                        Layout.row: 1
                        text: "Parent:"
                        bottomPadding: 0.06*margin
                    }
                    Label {
                        id: parent2Label
                        Layout.alignment : Qt.AlignLeft
                        Layout.row: 1
                        text: "Parent 2:"
                        bottomPadding: 0.06*margin
                    }

                }
                ColumnLayout {
                    TextField {
                        id: nameTextField
                        Layout.alignment : Qt.AlignLeft
                        Layout.preferredWidth: 400*pix
                        Layout.preferredHeight: buttonHeight
                    }
                    ComboBox {
                        id: parentComboBox
                        Layout.preferredWidth: 400*pix
                        editable: false
                        model: nameModel
                        ListModel {
                            id: nameModel
                        }
                        onActivated: {
                            if (index!==0) {
                                parent2Label.visible = true
                                parent2ComboBox.visible = true
                            }
                            else {
                                parent2Label.visible = false
                                parent2ComboBox.visible = false
                            }
                        }
                    }
                    ComboBox {
                        id: parent2ComboBox
                        Layout.preferredWidth: 400*pix
                        editable: false
                        model: name2Model
                        ListModel {
                            id: name2Model
                        }
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
                    text: "Ignore objects with broken border:"
                }
                CheckBox {
                    id: borderremoveobjsCheckBox
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
        MouseArea {
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
    }
    Button {
        id: applyButton
        text: "Apply"
        anchors.horizontalCenter: rowLayout.horizontalCenter
        anchors.top: rowLayout.bottom
        width: buttonWidth/2
        height: 1.2*buttonHeight
        onClicked: {
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
            var feature = featureModel.get(indTree)
            feature.name = new_name
            feature.parent = parentComboBox.currentText
            feature.parent2 = parent2ComboBox.currentText
            var parents = [feature.parent,feature.parent2]
            Julia.update_features(indTree+1,
                                    feature.name,
                                    feature.colorR,
                                    feature.colorG,
                                    feature.colorB,
                                    feature.border,
                                    feature.border_thickness,
                                    feature.borderRemoveObjs,
                                    feature.min_area,
                                    [feature.parent,feature.parent2],
                                    feature.notFeature)
            // featuredialogLoader.sourceComponent = null
            featuredialogWindow.close()
        }
    }
}










