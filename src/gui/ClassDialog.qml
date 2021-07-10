
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.Layouts 1.2
import Qt.labs.platform 1.1
import "../common/gui/templates"
import org.julialang 1.0


ApplicationWindow {
    id: classdialogWindow
    visible: true
    title: qsTr("  EasyML")
    minimumHeight: Math.max(mainItem.height,800*pix)
    minimumWidth: Math.max(mainItem.width,865*pix)
    property double indTree: JindTree
    property double max_id: Math.max(...ids)

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

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (Julia.unit_test()) {
            function Timer() {
                return Qt.createQmlObject("import QtQuick 2.0; Timer {}", classdialogWindow);
            }
            function delay(delayTime, cb) {
                var timer = new Timer();
                timer.interval = delayTime;
                timer.repeat = false;
                timer.triggered.connect(cb);
                timer.start();
            }
            function click1() {applyButton.clicked(null)}
            delay(1000, click1)
        }
    }

    function load_model_classes(classModel) {
        problemComboBox.currentIndex = Julia.get_problem_type()
        var num_classes = Julia.num_classes()
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
            var class_var = {
                    "name": "",
                    "weight": 0,
                    "parent": "",
                    "parent2": "",
                    "colorR": 0,
                    "colorG": 0,
                    "colorB": 0,
                    "overlap": false,
                    "border": false,
                    "border_thickness": 0
            }
            if (problemComboBox.currentIndex==0) {
                class_var.name = Julia.get_class_field(ind,"name")
                class_var.weight = Julia.get_class_field(ind,"weight")
            }
            else if (problemComboBox.currentIndex==1) {
                class_var.name = Julia.get_class_field(ind,"name")
            }
            else if (problemComboBox.currentIndex==2) {
                var color = Julia.get_class_field(ind,"color")
                var parents = Julia.get_class_field(ind,"parents")
                class_var.name = Julia.get_class_field(ind,"name")
                class_var.weight = Julia.get_class_field(ind,"weight")
                class_var.parent = parents[0]
                class_var.parent2 = parents[1]
                class_var.colorR = color[0]
                class_var.colorG = color[1]
                class_var.colorB = color[2]
                class_var.overlap = Julia.get_class_field(ind,"overlap")
                class_var.border = Julia.get_class_field(ind,["BorderClass","enabled"])
                class_var.border_thickness = Julia.get_class_field(ind,["BorderClass","thickness"])
            }
            classModel.append(class_var)
        }
        if (classModel.count>0) {
            indTree = 0
        }
    }

    function reset_visibility() {
        nameTextField.visible = false
        colorLabel.visible = false
        colorRow.visible = false
        parentRow.visible = false
        overlapRow.visible = false
        borderRow.visible = false
    }

    function update_fields() {
        
        nameTextField.visible = true
        if (problemComboBox.currentIndex==0) {
            weightRow.visible = true
        }
        else if (problemComboBox.currentIndex==1) {

        }
        else if (problemComboBox.currentIndex==2) {
            if (indTree>0 && classModel.get(indTree).overlap) {
                weightRow.visible = false
            }
            else {
                weightRow.visible = true
            }
            if (classModel.count>1) {
                parentRow.visible = true
                if (classModel.count>2) {
                    parent2Row.visible = true
                }
                else {
                    parent2Row.visible = false
                }
            }
            else {
                parentRow.visible = false
            }
            colorLabel.visible = true
            colorRow.visible = true
            overlapRow.visible = true
            borderRow.visible = true
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
            weightTextField.text = classModel.get(indTree).weight.toFixed(2)
        }
        if (problemComboBox.currentIndex==1) {

        }
        else if (problemComboBox.currentIndex==2) {

            weightTextField.text = classModel.get(indTree).weight.toFixed(2)

            redTextField.text = classModel.get(indTree).colorR
            greenTextField.text = classModel.get(indTree).colorG
            blueTextField.text = classModel.get(indTree).colorB

            // parentComboBox 1
            nameModel.clear()
            nameModel.append({"name": ""})
            var parent2Name = parent2ComboBox.currentText
            for (var i=0;i<classModel.count;i++) {
                var currentName = classModel.get(i).name
                if (i===indTree || currentName===parent2Name) continue
                nameModel.append({"name": currentName})
            }
            var parentName = classModel.get(indTree).parent
            if (parentName!=="") {
                for (i=0;i<parentComboBox.model.count;i++) {
                    if (parentComboBox.model.get(i).name===parentName) {
                        parentComboBox.currentIndex = i
                    }
                }
            }
            // parentComboBox 2
            name2Model.clear()
            var parent1Name = parentComboBox.currentText
            name2Model.append({"name": ""})
            for (i=0;i<classModel.count;i++) {
                currentName = classModel.get(i).name
                if (i===indTree || currentName===parent1Name) continue
                name2Model.append({"name": currentName})
            }
            parentName = classModel.get(indTree).parent2
            if (parentName!=="") {
                for (i=0;i<name2Model.count;i++) {
                    if (name2Model.get(i).name===parentName) {
                        parent2ComboBox.currentIndex = i
                    }
                }
            }

            // overlapCheckBox
            overlapCheckBox.checkState = classModel.get(indTree).overlap ?
                            Qt.Checked : Qt.Unchecked

            // borderCheckBox
            borderCheckBox.checkState = classModel.get(indTree).border ?
                            Qt.Checked : Qt.Unchecked

            // borderthicknessSpinBox
            borderthicknessSpinBox.value = (classModel.get(indTree).border_thickness - 1)/2
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

    Item {
        id: mainItem
        width: classesparametersItem.width
        height: classesparametersItem.height + applyButton.height + 0.75*margin
        onHeightChanged: {
            if (classdialogWindow.height<mainItem.height) {
                classdialogWindow.height = Math.max(mainItem.height,800*pix)
                classdialogWindow.minimumHeight = Math.max(mainItem.height,800*pix)
            }
        }
        Item {
            id: classesparametersItem
            height: Math.max(classesColumn.height,parametersColumn.height)
            width: classesColumn.width + parametersColumn.width
            Column {
                id: classesColumn
                padding: 0.75*margin
                spacing: -2*pix
                Item {
                    width: classesFrame.width
                    height: problemRow.height + classesLabel.height + classesFrame.height - 2*pix
                    Row {
                        id: problemRow
                        spacing: 0.3*margin
                        bottomPadding: 0.5*margin
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
                            onCurrentIndexChanged: {
                                classModel.clear()
                                classView.forceLayout()
                                indTree = -1
                                update_fields()
                            }
                        }
                    }
                    Label {
                        id: classesLabel
                        anchors.top: problemRow.bottom
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
                        anchors.top: classesLabel.bottom
                        anchors.topMargin: -2*pix
                        height: classdialogWindow.height - problemRow.height - classesLabel.height - 3*0.75*margin - applyButton.height
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
                                            x: 1*pix
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
                                                visible: problemComboBox.currentIndex==2
                                                anchors.left: treeButton.left
                                                anchors.verticalCenter: treeButton.verticalCenter
                                                anchors.leftMargin: 15*pix
                                                height: 30*pix
                                                width: 30*pix
                                                border.width: 2*pix
                                                radius: colorRectangle.width
                                                color: problemComboBox.currentIndex==2 ? rgbtohtml([colorR,colorG,colorB]) : "transparent"
                                            }
                                            Label {
                                                anchors.left: colorRectangle.left
                                                anchors.leftMargin: problemComboBox.currentIndex==2 ? 
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
                                                    source: "../common/gui/templates/icons/trash_can.png"
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
                                        width: classesFrame.width - 26*pix
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
                                            var class_var = {
                                                "name": "",
                                                "weight": 0,
                                                "parent": "",
                                                "parent2": "",
                                                "colorR": 0,
                                                "colorG": 0,
                                                "colorB": 0,
                                                "overlap": false,
                                                "border": false,
                                                "border_thickness": 0
                                            }
                                            if (problemComboBox.currentIndex==0) {
                                                class_var.name = name
                                                class_var.weight = 1
                                            }
                                            else if (problemComboBox.currentIndex==1) {
                                                class_var.name = name
                                            }
                                            else if (problemComboBox.currentIndex==2) {
                                                    class_var.name = name
                                                    class_var.weight = 1
                                                    class_var.colorR = Math.floor(Math.random()*255)+1
                                                    class_var.colorG = Math.floor(Math.random()*255)+1
                                                    class_var.colorB = Math.floor(Math.random()*255)+1
                                                    class_var.border = false
                                                    class_var.border_thickness = 3
                                                    class_var.parent = ""
                                                    class_var.parent2 = ""
                                                    class_var.overlap = false
                                            }
                                            
                                            classModel.append(class_var)
                                            if (indTree<0) {
                                                indTree = 0
                                            }
                                            classView.forceLayout()
                                            reset_visibility()
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
                                                height: plus1Rectangle.height + 5*pix
                                                width: plus1Rectangle.width + 5*pix
                                                border.width: 0*pix
                                                radius: 5*pix
                                            }
                                            Rectangle {
                                                id: plusoutline2Rectangle
                                                anchors.horizontalCenter: plusotline1Rectangle.horizontalCenter
                                                anchors.verticalCenter: plusotline1Rectangle.verticalCenter
                                                color: addButton.hovered ? plusItem.colorOuter1 : plusItem.colorOuter2
                                                height: plus1Rectangle.width + 5*pix
                                                width: plus1Rectangle.height + 5*pix
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
            }
            Column {
                id: parametersColumn
                anchors.left: classesColumn.right
                width: 645*pix
                padding: 0.75*margin
                leftPadding: 0
                spacing: 0.4*margin
                Row {
                    id: nameRow
                    Label {
                        id: nameLabel
                        text: "Name:"
                        width: 160*pix
                    }
                    TextField {
                        id: nameTextField
                        anchors.verticalCenter: nameLabel.verticalCenter
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
                    id: weightRow
                    visible: false
                    Label {
                        id: weightLabel
                        text: "Weight:"
                        width: 160*pix
                    }
                    TextField {
                        id: weightTextField
                        anchors.verticalCenter: weightLabel.verticalCenter
                        width: 400*pix
                        height: buttonHeight
                        validator: DoubleValidator { bottom: 0; decimals : 2; top: 1;}
                        onEditingFinished: {
                            classModel.setProperty(indTree, "weight", parseFloat(text))
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
                    }
                    ComboBox {
                        id: parentComboBox
                        anchors.verticalCenter: parentLabel.verticalCenter
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
                            update_fields()
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
                    }
                    ComboBox {
                        id: parent2ComboBox
                        anchors.verticalCenter: parent2Label.verticalCenter
                        width: 400*pix
                        editable: false
                        model: name2Model
                        ListModel {
                            id: name2Model
                        }
                        onActivated: {
                            classModel.setProperty(indTree, "parent2", currentValue)
                            update_fields()
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
                    bottomPadding: -0.1*margin
                    Label {
                        id: redLabel
                        text: "Red:"
                    }
                    TextField {
                        id: redTextField
                        anchors.verticalCenter: redLabel.verticalCenter
                        text: "0"
                        width: 0.20*buttonWidth
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
                        id: greenLabel
                        text: "Green:"
                    }
                    TextField {
                        id: greenTextField
                        anchors.verticalCenter: greenLabel.verticalCenter
                        text: "0"
                        width: redTextField.width
                        height: buttonHeight
                        validator: IntValidator { bottom: 0; top: 999;}
                        onEditingFinished: {
                            var val = parseFloat(greenTextField.text)
                            if (val>255) {
                                val = 255
                                greenTextField.text = "255"
                            }
                            classModel.setProperty(indTree, "colorG", val)
                        }
                    }
                    Label {
                        id: blueTextLabel
                        text: "Blue:"
                    }
                    TextField {
                        id: blueTextField
                        anchors.verticalCenter: blueTextLabel.verticalCenter
                        text: "0"
                        width: redTextField.width
                        height: buttonHeight
                        maximumLength: 3
                        validator: IntValidator { bottom: 0; top: 999;}
                        onEditingFinished: {
                            var val = parseFloat(blueTextField.text)
                            if (val>255) {
                                val = 255
                                blueTextField.text = "255"
                            }
                            classModel.setProperty(indTree, "colorB", val)
                        }
                    }
                }
                Row {
                    id: overlapRow
                    visible: false
                    Label {
                        id: overlapLabel
                        width: borderthicknessLabel.width
                        text: "Overlap of classes:"
                    }
                    CheckBox {
                        id: overlapCheckBox
                        anchors.verticalCenter: overlapLabel.verticalCenter
                        onClicked: {
                            if (checkState==Qt.Checked) {
                                classModel.get(indTree).overlap = true
                                classModel.get(indTree).border = false
                                borderCheckBox.checkState = Qt.Unchecked
                                borderRow.visible = false
                            }
                            if (checkState==Qt.Unchecked) {
                                classModel.get(indTree).overlap = false
                                borderRow.visible = true
                            }
                        }
                    }
                }
                Row {
                    id: borderRow
                    visible: false
                    Label {
                        id: borderLabel
                        width: borderthicknessLabel.width
                        text: "Generate border class:"
                    }
                    CheckBox {
                        id: borderCheckBox
                        anchors.verticalCenter: borderLabel.verticalCenter
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
                    id: borderthicknessRow
                    visible: borderCheckBox.checkState==Qt.Checked
                    spacing: 0.3*margin
                    Label {
                        id: borderthicknessLabel
                        text: "    - Border thickness (pix):"
                    }
                    SpinBox {
                        id: borderthicknessSpinBox
                        anchors.verticalCenter: borderthicknessLabel.verticalCenter
                        from: 0
                        to: 9
                        stepSize: 1
                        property double realValue
                        textFromValue: function(value, locale) {
                            realValue = (value)*2+1
                            return realValue.toLocaleString(locale,'f',0)
                        }
                        onValueModified: {
                            classModel.get(indTree).border_thickness = realValue
                        }
                    }
                }
            }
        }
        Button {
            id: applyButton
            text: "Apply"
            anchors.horizontalCenter: classesparametersItem.horizontalCenter
            y: classdialogWindow.height - 0.75*margin - height
            width: buttonWidth/2
            height: 1.2*buttonHeight
            onClicked: {
                Julia.set_problem_type(problemComboBox.currentIndex)
                Julia.reset_classes()
                for (var i=0;i<classModel.count;i++) {
                    var class_var = classModel.get(i)
                    if (class_var.overlap) {
                        class_var.border = false
                    }
                    Julia.append_classes(
                        [class_var.name,
                        class_var.colorR,
                        class_var.colorG,
                        class_var.colorB,
                        [class_var.parent,class_var.parent2],
                        class_var.overlap,
                        class_var.border,
                        class_var.border_thickness])
                }
                classdialogWindow.close()
            }
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