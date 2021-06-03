
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.Layouts 1.2
import Qt.labs.platform 1.1
import "Templates"
import org.julialang 1.0


ApplicationWindow {
    id: classdialogWindow
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
    function load_model_classes(classModel) {
        problemComboBox.currentIndex = Julia.get_problem_type()
        var num_classes = Julia.num_classes()
            if (num_classes<3) {
            parent2Row.visible = false
            if (Julia.num_classes()<2) {
                parentComboBox.visible = false
                parentLabel.visible = false
            }
        }
        if (classModel.count!==0) {
            classModel.clear()
        }
        for (var i=0;i<num_classes;i++) {
            var ind = i+1
            if (i+1<max_id) {
                var id = ids[i]
            }
            else {
                max_id += 1
                id = max_id
            }
            if (problemComboBox.currentIndex==0) {
                console.log(id)
                console.log(Julia.get_class_field(ind,"name"))
                var class_var = {
                    "id": id,
                    "name": Julia.get_class_field(ind,"name")
                }
                classModel.append(class_var)
            }
            else if (problemComboBox.currentIndex==1) {
                var color = Julia.get_class_field(ind,"color")
                var parents = Julia.get_class_field(ind,"parents")
                class_var = {
                    "id": id,
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
                    "notClass": Julia.get_class_field(ind,"not_class")
                }
            }
            classModel.append(class_var)
        }
    }

    function update_visibility() {
        nameTextField.visible = false
        colorLabel.visible = false
        colorRow.visible = false
        minareaRow.visible = false
        parentRow.visible = false
        notclassRow.visible = false
        borderRow.visible = false
        bordernumpixelsRow.visible = false
        borderremoveobjsRow.visible = false
    }

    function update_fields() {
        
        nameTextField.visible = true
        if (problemComboBox.currentIndex==0) {

        }
        else if (problemComboBox.currentIndex==1) {
            colorLabel.visible = true
            colorRow.visible = true
            minareaRow.visible = true
            parentRow.visible = true
            notclassRow.visible = true
            borderRow.visible = true
            bordernumpixelsRow.visible = true
            borderremoveobjsRow.visible = true
        }
        
        if (indTree<0) {
            parametersColumn.opacity = 0
            return
        }
        else {
            parametersColumn.opacity = 1
        }
        classView.itemAtIndex(indTree).borderForceVisible = true

        nameTextField.text = classModel.get(indTree).name
        
        if (problemComboBox.currentIndex==0) {

        }
        else if (problemComboBox.currentIndex==1) {
            colorLabel.visible = true
            colorRow.visible = true
            minareaRow.visible = true
            parentRow.visible = true
            notclassRow.visible = true
            borderRow.visible = true
            bordernumpixelsRow.visible = true
            borderremoveobjsRow.visible = true

            redTextField.text = classModel.get(indTree).colorR
            greenTextField.text = classModel.get(indTree).colorG
            blueTextField.text = classModel.get(indTree).colorB

            minareaTextField.text = classModel.get(indTree).min_area

            // parentComboBox 1
            nameModel.clear()
            var name = classModel.get(indTree).parent
            nameModel.append({"name": ""})
            for (var i=0;i<classModel.count;i++) {
                if (i===indTree) continue
                nameModel.append({"name": classModel.get(i).name})
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
            for (i=0;i<classModel.count;i++) {
                name = classModel.get(i).name
                if (i===indTree || name1===name) continue
                name2Model.append({"name": name})
            }
            var parentName = classModel.get(indTree).parent2
            if (parentName!=="") {
                for (i=0;i<name2Model.count;i++) {
                    if (name2Model.get(i).name===parentName) {
                        parent2ComboBox.currentIndex = i
                    }
                }
            }

            // notclassCheckBox
            notclassCheckBox.checkState = classModel.get(indTree).notClass ?
                            Qt.Checked : Qt.Unchecked

            // borderCheckBox
            borderCheckBox.checkState = classModel.get(indTree).border ?
                            Qt.Checked : Qt.Unchecked

            // bordernumpixelsSpinBox
            bordernumpixelsSpinBox.value = classModel.get(indTree).border_thickness

            // borderremoveobjsLabel
            borderremoveobjsCheckBox.checkState = classModel.get(indTree).borderRemoveObjs ?
                            Qt.Checked : Qt.Unchecked
        }
    }

    ListModel {
        id: classModel
        Component.onCompleted: {
            load_model_classes(classModel)
            classView.forceLayout()
            update_fields()
        }
    }

    //-------------------------------------------------------------------------

    color: defaultpalette.window

    // onClosing: {classdialogLoader.sourceComponent = null}

    RowLayout {
        id: rowLayout
        spacing: 0.75*margin
        Column {
            id: classesColumn
            Layout.alignment: Qt.AlignTop
            Layout.margins: 0.75*margin
            Layout.rightMargin: 0*margin
            spacing: -2
            Row {
                id: problemRow
                spacing: 0.3*margin
                bottomPadding: 0.5*margin
                Label {
                    id: problemtypeLabel
                    text: "Problem:"
                    anchors.verticalCenter: problemComboBox.verticalCenter
                }
                ComboBox {
                    id: problemComboBox
                    editable: false
                    width: 0.69*buttonWidth-1*pix
                    model: ListModel {
                        id: problemtypeModel
                        ListElement {text: "Classification"}
                        ListElement {text: "Segmentation"}
                        ListElement {text: "Regression"}
                    }
                    onActivated: {
                        classModel.clear()
                        indTree = -1
                        update_fields()
                    }
                }
            }
            Label {
                id: classesLabel
                width: buttonWidth + 0.5*margin - 5*pix
                text: "Classes:"
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
                id: classesFrame
                height: Math.max(parametersColumn.height - problemRow.height - classesLabel.height,300*pix)
                width: buttonWidth + 0.5*margin - 5*pix
                backgroundColor: "white"
                ScrollView {
                    clip: true
                    anchors.fill: parent
                    padding: 0
                    spacing: 0
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    Flickable {
                        boundsBehavior: Flickable.StopAtBounds
                        contentHeight: classView.height+buttonHeight-2*pix
                        Item {
                            ListView {
                                id: classView
                                height: childrenRect.height
                                spacing: -2*pix
                                boundsBehavior: Flickable.StopAtBounds
                                model: classModel
                                delegate: TreeButton {
                                    id: treeButton
                                    x: 1
                                    hoverEnabled: true
                                    width: classesFrame.width - 25*pix
                                    height: buttonHeight - 2*pix
                                    onClicked: {
                                        for (var i=0;i<classModel.count;i++) {
                                            classView.itemAtIndex(i).borderForceVisible = false
                                        }
                                        borderForceVisible = true
                                        indTree = index
                                        update_fields()
                                    }
                                    Rectangle {
                                        id: colorRectangle
                                        visible: problemComboBox.currentIndex==1
                                        anchors.left: treeButton.left
                                        anchors.verticalCenter: treeButton.verticalCenter
                                        anchors.leftMargin: 15*pix
                                        height: 30*pix
                                        width: 30*pix
                                        border.width: 2*pix
                                        radius: colorRectangle.width
                                        color: problemComboBox.currentIndex==1 ? 
                                            rgbtohtml([colorR,colorG,colorB]) :
                                            "transparent"
                                    }
                                    Label {
                                        anchors.left: colorRectangle.left
                                        anchors.leftMargin: problemComboBox.currentIndex==1 ? 
                                            50*pix : 10*pix
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
                                                if (indTree<0 && classModel.count!=1) {
                                                    indTree = 0
                                                }
                                            }
                                            if (indTree==(classModel.count-1)) {
                                                indTree -= 1
                                            }
                                            classModel.remove(index)
                                            update_fields()
                                        }
                                    }
                                }
                            }
                            Button {
                                id: addButton
                                hoverEnabled: true
                                anchors.top: classView.bottom
                                x: 1
                                width: classesFrame.width - 25*pix
                                height: buttonHeight - 2*pix
                                background: Rectangle {
                                    color: "transparent"
                                    border.color: defaultpalette.border
                                    border.width: addButton.hovered ? 2*pix : 0
                                }
                                onClicked: {
                                    var cnt = classModel.count+1
                                    var name = "Class "+cnt.toString()
                                    while (true) {
                                        for (var i=0;i<classModel.count;i++) {
                                            if (classModel.get(i).name==name) {
                                                cnt += 1
                                                name = "Class "+cnt.toString()
                                                break
                                            }
                                        }
                                        if(i==(classModel.count)) {
                                            break
                                        }
                                    }
                                    max_id += 1
                                    var id = max_id
                                    if (problemComboBox.currentIndex==0) {
                                        var class_var = {
                                            "name": name,
                                            "id": id
                                        }
                                    }
                                    else if (problemComboBox.currentIndex==1) {
                                        var class_var = {
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
                                            "notClass": false
                                        }
                                    }
                                    
                                    classModel.append(class_var)
                                    if (indTree<0) {
                                        indTree = 0
                                    }
                                    classView.forceLayout()
                                    update_visibility()
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
                id: nameRow
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
                        var prev_name = classModel.get(indTree).name
                        var new_name = nameTextField.text
                        if (prev_name!==new_name) {
                            for (var i=0;i<classModel.count;i++) {
                                var element = classModel.get(i)
                                if (element.parent===prev_name) {
                                    element.parent = new_name
                                }
                            }
                        }
                        classModel.setProperty(indTree, "name", text)
                    }
                    
                }
            }
            Row {
                id: parentRow
                visible: false
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
                        if (index!==0 && classModel.count>2) {
                            parent2Row.visible = true
                        }
                        else {
                            parent2Row.visible = false
                        }
                        classModel.setProperty(indTree, "parent", currentValue)
                    }
                }
            }
            Row {
                id: parent2Row
                visible: false
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
                        classModel.setProperty(indTree, "parent2", currentValue)
                    }
                }
            }
            Label {
                id: colorLabel
                visible: false
                text: "Color (RGB):"
            }
            Row {
                id: colorRow
                visible: false
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
                        classModel.setProperty(indTree, "colorR", val)
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
                        classModel.setProperty(indTree, "colorR", val)
                        classModel.get(indTree).colorR = val
                    }
                    onAccepted: {
                        var val = parseFloat(greenTextField.text)
                        if (val>255) {
                            val = 255
                            greenTextField.text = "255"
                        }
                        classModel.setProperty(indTree, "colorR", val)
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
                        classModel.setProperty(indTree, "colorR", val)
                        classModel.get(indTree).colorR = val
                    }
                    onAccepted: {
                        var val = parseFloat(blueTextField.text)
                        if (val>255) {
                            val = 255
                            blueTextField.text = "255"
                        }
                        classModel.setProperty(indTree, "colorR", val)
                        backgroundMouseArea.focus = true
                    }
                }
            }
            Row {
                id: notclassRow
                visible: false
                Label {
                    id: notclassLabel
                    width: 350*pix
                    text: "Not a class_var:"
                }
                CheckBox {
                    id: notclassCheckBox
                    onClicked: {
                        if (checkState==Qt.Checked) {
                            classModel.get(indTree).notClass = true
                        }
                        if (checkState==Qt.Unchecked) {
                            classModel.get(indTree).notClass = false
                        }
                    }
                }
            }
            Row {
                id: borderRow
                visible: false
                Label {
                    id: borderLabel
                    width: 350*pix
                    text: "Border is important:"
                }
                CheckBox {
                    id: borderCheckBox
                    onClicked: {
                        if (checkState==Qt.Checked) {
                            classModel.get(indTree).border = true
                        }
                        if (checkState==Qt.Unchecked) {
                            classModel.get(indTree).border = false
                        }
                    }
                }
            }
            Row {
                id: bordernumpixelsRow
                visible: false
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
                        classModel.get(indTree).border_thickness = value
                    }
                }
            }
            Row {
                id: borderremoveobjsRow
                visible: false
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
                            classModel.get(indTree).borderRemoveObjs = true
                        }
                        if (checkState==Qt.Unchecked) {
                            classModel.get(indTree).borderRemoveObjs = false
                        }
                    }
                }
            }
            Row {
                id: minareaRow
                visible: false
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
                        classModel.get(indTree).min_area = parseInt(text)
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
            Julia.reset_classes()
            Julia.reset_output_options()
            for (var i=0;i<classModel.count;i++) {
                var class_var = classModel.get(i)
                Julia.append_classes(class_var.id,
                    [class_var.name,
                    class_var.colorR,
                    class_var.colorG,
                    class_var.colorB,
                    class_var.border,
                    class_var.border_thickness,
                    class_var.borderRemoveObjs,
                    class_var.min_area,
                    [class_var.parent,class_var.parent2],
                    class_var.notClass])
            }
            // classdialogLoader.sourceComponent = null
            classdialogWindow.close()
        }
    }

    MouseArea {
        id: backgroundMouseArea
        width: classdialogWindow.width
        height: classdialogWindow.height
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










