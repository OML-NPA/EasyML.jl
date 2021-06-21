
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.Layouts 1.2
import Qt.labs.platform 1.1
import "Templates"
import org.julialang 1.0


ApplicationWindow {
    id: window
    visible: true
    title: qsTr("  EasyML")
    minimumWidth: rowLayout.width
    minimumHeight: rowLayout.height
    maximumWidth: rowLayout.width
    maximumHeight: rowLayout.height

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

    //--------------------------------------------------------------------------

    function load_model_classes(classModel) {
        var problemType = Julia.get_problem_type()
        var num_classes = Julia.num_classes()
        for (var i=0;i<num_classes;i++) {
            var ind = i+1
            if (problemType==0) {
                var class_var = {
                    "name": Julia.get_class_field(ind,"name")
                }
                classModel.append(class_var)
            }
            else if (problemType==1) {
                var class_var = {
                    "name": Julia.get_class_field(ind,"name")
                }
                classModel.append(class_var)
            }
            else if (problemType==2) {
                var color = Julia.get_class_field(ind,"color")
                class_var = {
                    "name": Julia.get_class_field(ind,"name"),
                    "colorR": color[0],
                    "colorG": color[1],
                    "colorB": color[2]
                }
            classModel.append(class_var)
            }
        }
    }

    ListModel {
        id: classModel
        Component.onCompleted: {
            load_model_classes(classModel)
            classView.forceLayout()
            classView.itemAtIndex(indTree).borderForceVisible = true
        }
    }

    color: defaultpalette.window
    property double indTree: 0
    property double currentViewIndex: 0
    property var viewModel: [{"name": "Mask", "stackview": maskView},
                            {"name": "Area", "stackview": areaView},
                            {"name": "Volume", "stackview": volumeView}]

    onClosing: {
        var url = Julia.get_settings(["Application","model_url"])
        Julia.save_model(url)
        // applicationclassdialogLoader.sourceComponent = null
    }

    RowLayout {
        id: rowLayout
        spacing: 0
        RowLayout {
            id: parametersRow
            Layout.alignment: Qt.AlignTop
            Pane {
                id: menuPane
                spacing: 0
                padding: -1
                width: 0.5*buttonWidth
                Layout.alignment: Qt.AlignTop
                Layout.preferredHeight: window.height
                topPadding: tabmargin/2
                bottomPadding: tabmargin/2
                backgroundColor: defaultpalette.window2
                Column {
                    id: menubuttonColumn
                    spacing: 0
                    Repeater {
                        id: menubuttonRepeater
                        Component.onCompleted: {menubuttonRepeater.itemAt(0).buttonfocus = true}
                        model: viewModel
                        delegate : MenuButton {
                            id: general
                            width: 1*buttonWidth
                            height: 1.25*buttonHeight
                            text: modelData.name
                            onClicked: {
                                stack.push(modelData.stackview);
                                for (var i=0;i<(menubuttonRepeater.count);i++) {
                                    menubuttonRepeater.itemAt(i).buttonfocus = false
                                }
                                buttonfocus = true
                                currentViewIndex = index
                            }
                        }
                    }
                }
            }
            Column {
                id: parametersColumn
                Layout.alignment: Qt.AlignTop
                Layout.margins: 0.5*margin
                width: 1.75*buttonWidth
                StackView {
                    id: stack
                    initialItem: maskView
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
                Component {
                    id: maskView
                    Column {
                        spacing: 0.2*margin
                        function update_mask_fields() {  
                            var problemType = Julia.get_problem_type()
                            if (problemType==0) {

                            }
                            else if (problemType==1) {

                            }
                            else if (problemType==2) {
                                outputmaskCheckBox.checkState = Julia.get_output(["Mask",
                                    "mask"],indTree+1) ? Qt.Checked : Qt.Unchecked
                                if (Julia.get_class_field(indTree+1,"border")) {
                                    bordermaskCheckBox.visible = true
                                    bordermaskCheckBox.checkState = Julia.get_output(["Mask",
                                        "mask_border"],indTree+1) ? Qt.Checked : Qt.Unchecked
                                }
                                if (Julia.get_class_field(indTree+1,"border")) {
                                    appliedbordermaskCheckbox.visible = true
                                    appliedbordermaskCheckbox.checkState = Julia.get_output(["Mask",
                                        "mask_applied_border"],indTree+1) ? Qt.Checked : Qt.Unchecked
                                }
                            }
                        }
                        Component.onCompleted: {
                            update_mask_fields()
                        }
                        Label {
                            text: "Save masks:"
                        }
                        CheckBox {
                            id: outputmaskCheckBox
                            text: "Output mask"
                            onClicked: {
                                var value = checkState===Qt.Checked ? true : false
                                Julia.set_output(["Mask","mask"],indTree+1,value)
                            }
                        }
                        CheckBox {
                            id: bordermaskCheckBox
                            visible: false
                            text: "Border mask"
                            onClicked: {
                                var value = checkState===Qt.Checked ? true : false
                                Julia.set_output(["Mask","mask_border"],indTree+1,value)
                            }
                        }
                        CheckBox {
                            id: appliedbordermaskCheckbox
                            visible: false
                            text: "Applied border mask"
                            onClicked: {
                                var value = checkState===Qt.Checked ? true : false
                                Julia.set_output(["Mask","mask_applied_border"],indTree+1,value)
                            }
                        }
                    }
                }
                Component {
                    id: areaView
                    Column {
                        spacing: 0.2*margin
                        function update_area_fields() {  
                            var problemType = Julia.get_problem_type()
                            if (problemType==0) {

                            }
                            else if (problemType==1) {

                            }
                            else if (problemType==2) {
                                areadistributionCheckBox.checkState = Julia.get_output(["Area",
                                    "area_distribution"], indTree+1) ? Qt.Checked : Qt.Unchecked
                                objareaCheckBox.checkState = Julia.get_output(["Area","obj_area"],
                                    indTree+1) ? Qt.Checked : Qt.Unchecked
                                objareasumCheckBox.checkState = Julia.get_output(["Area","obj_area_sum"],
                                    indTree+1) ? Qt.Checked : Qt.Unchecked
                                binningareaComboBox.currentIndex = Julia.get_output(["Area","binning"],indTree+1)
                                binningareaComboBox.changeLabel()
                                numvalueareaTextField.text = Julia.get_output(["Area","value"],indTree+1)
                                widthvalueareaTextField.text = Julia.get_output(["Area","value"],indTree+1)
                                normalisationareaComboBox.currentIndex = Julia.get_output(
                                    ["Area","normalisation"],indTree+1)
                            }
                        }
                        Component.onCompleted: {
                            update_area_fields()
                        }
                        Label {
                            text: "Outputs:"
                        }
                        CheckBox {
                            id: areadistributionCheckBox
                            text: "Area distribution"
                            onClicked: {
                                var value = checkState===Qt.Checked ? true : false
                                Julia.set_output(["Area","area_distribution"],indTree+1,value)
                            }
                        }
                        CheckBox {
                            id: objareaCheckBox
                            text: "Area of objects"
                            onClicked: {
                                var value = checkState===Qt.Checked ? true : false
                                Julia.set_output(["Area","obj_area"],indTree+1,value)
                            }
                        }
                        CheckBox {
                            id: objareasumCheckBox
                            text: "Sum of areas of objects"
                            onClicked: {
                                var value = checkState===Qt.Checked ? true : false
                                Julia.set_output(["Area","obj_area_sum"],indTree+1,value)
                            }
                        }
                        Rectangle {
                            height: 0.2*margin
                            width: 0.2*margin
                            color: defaultpalette.window
                        }
                        Label {
                            text: "Histogram options:"
                        }
                        RowLayout {
                            spacing: 0.3*margin
                            ColumnLayout {
                                spacing: 0.5*margin
                                Label {
                                    id: label
                                    text: "Binning method:"
                                }
                                Label {
                                    id: valueareaLabel
                                    text: "Value:"
                                }
                                Label {
                                    text: "Normalisation:"
                                }
                            }
                            ColumnLayout {
                                ComboBox {
                                    id: binningareaComboBox
                                    function changeLabel() {
                                        if (currentIndex===0) {
                                            valueareaLabel.visible = false
                                            widthvalueareaTextField.visible = false
                                            numvalueareaTextField.visible = false

                                        }
                                        else if (currentIndex===1) {
                                            valueareaLabel.visible = true
                                            widthvalueareaTextField.visible = true
                                            numvalueareaTextField.visible = false
                                        }
                                        else {
                                            valueareaLabel.visible = true
                                            widthvalueareaTextField.visible = false
                                            numvalueareaTextField.visible = true
                                        }
                                    }
                                    editable: false
                                    width: 0.69*buttonWidth-1*pix
                                    currentIndex: 0
                                    model: ListModel {
                                        id: binningModel
                                        ListElement {text: "Automatic"}
                                        ListElement {text: "Number of bins"}
                                        ListElement {text: "Bin width"}
                                    }
                                    onActivated: {
                                        Julia.set_output(["Area","binning"],indTree+1,currentIndex)
                                        changeLabel()
                                    }
                                }
                                TextField {
                                    id: numvalueareaTextField
                                    Layout.preferredWidth: 0.35*buttonWidth
                                    Layout.preferredHeight: buttonHeight
                                    text: "10"
                                    maximumLength: 5
                                    validator: IntValidator { bottom: 1; top: 99999}
                                    onEditingFinished: {
                                        var value = parseFloat(text)
                                        Julia.set_output(["Area","value"],indTree+1,value)
                                    }
                                }
                                TextField {
                                    id: widthvalueareaTextField
                                    Layout.preferredWidth: 0.35*buttonWidth
                                    Layout.preferredHeight: buttonHeight
                                    text: "1"
                                    maximumLength: 5
                                    validator: DoubleValidator { bottom: 0.001; top: 99999}
                                    onEditingFinished: {
                                        var value = parseFloat(text)
                                        Julia.set_output(["Area","value"],indTree+1,value)
                                    }
                                }
                                ComboBox {
                                    id: normalisationareaComboBox
                                    editable: false
                                    width: 0.69*buttonWidth-1*pix
                                    currentIndex: 0
                                    model: ListModel {
                                        id: normalisationModel
                                        ListElement {text: "pdf"}
                                        ListElement {text: "Density"}
                                        ListElement {text: "Probability"}
                                        ListElement {text: "None"}
                                    }
                                    onActivated: {
                                        Julia.set_output(["Area","normalisation"],indTree+1,currentIndex)
                                    }
                                }
                            }
                        }
                    }
                }
                Component {
                    id: volumeView
                    Column {
                        spacing: 0.2*margin
                        function update_volume_fields() {  
                            var problemType = Julia.get_problem_type()
                            if (problemType==0) {

                            }
                            else if (problemType==1) {

                            }
                            else if (problemType==2) {
                                volumedistributionCheckBox.checkState = Julia.get_output(["Volume",
                                    "volume_distribution"],indTree+1) ? Qt.Checked : Qt.Unchecked
                                objvolumeCheckBox.checkState = Julia.get_output(["Volume","obj_volume"],
                                    indTree+1) ? Qt.Checked : Qt.Unchecked
                                objvolumesumCheckBox.checkState = Julia.get_output(["Volume","obj_volume_sum"],
                                    indTree+1) ? Qt.Checked : Qt.Unchecked
                                binningvolumeComboBox.currentIndex = Julia.get_output(["Volume","binning"],indTree+1)
                                binningvolumeComboBox.changeLabel()
                                numvaluevolumeTextField.text = Julia.get_output(["Volume","value"],indTree+1)
                                widthvaluevolumeTextField.text = Julia.get_output(["Volume","value"],indTree+1)
                                normalisationvolumeComboBox.currentIndex = Julia.get_output(["Volume",
                                    "normalisation"],indTree+1)
                            }
                        }
                        Component.onCompleted: {
                            update_volume_fields()
                        }
                        Label {
                            text: "Outputs:"
                        }
                        CheckBox {
                            id: volumedistributionCheckBox
                            text: "Volume distribution"
                            onClicked: {
                                var value = checkState===Qt.Checked ? true : false
                                Julia.set_output(["Volume","volume_distribution"],indTree+1,value)
                            }
                        }
                        CheckBox {
                            id: objvolumeCheckBox
                            text: "Volume of objects"
                            onClicked: {
                                var value = checkState===Qt.Checked ? true : false
                                Julia.set_output(["Volume","obj_volume"],indTree+1,value)
                            }
                        }
                        CheckBox {
                            id: objvolumesumCheckBox
                            text: "Sum of volume of objects"
                            onClicked: {
                                var value = checkState===Qt.Checked ? true : false
                                Julia.set_output(["Volume","obj_volume_sum"],indTree+1,value)
                            }
                        }
                        Rectangle {
                            height: 0.2*margin
                            width: 0.2*margin
                            color: defaultpalette.window
                        }
                        Label {
                            text: "Histogram options:"
                        }
                        RowLayout {
                            spacing: 0.3*margin
                            ColumnLayout {
                                spacing: 0.5*margin
                                Label {
                                    id: label
                                    text: "Binning method:"
                                }
                                Label {
                                    id: valuevolumeLabel
                                    text: "Value:"
                                }
                                Label {
                                    text: "Normalisation:"
                                }
                            }
                            ColumnLayout {
                                ComboBox {
                                    id: binningvolumeComboBox
                                    function changeLabel() {
                                        if (currentIndex===0) {
                                            valuevolumeLabel.visible = false
                                            widthvaluevolumeTextField.visible = false
                                            numvaluevolumeTextField.visible = false
                                        }
                                        else if (currentIndex===1) {
                                            valuevolumeLabel.visible = true
                                            widthvaluevolumeTextField.visible = true
                                            numvaluevolumeTextField.visible = false
                                        }
                                        else {
                                            valuevolumeLabel.visible = true
                                            widthvaluevolumeTextField.visible = false
                                            numvaluevolumeTextField.visible = true
                                        }
                                    }
                                    editable: false
                                    width: 0.69*buttonWidth-1*pix
                                    currentIndex: 0
                                    model: ListModel {
                                        id: binningModel
                                        ListElement {text: "Automatic"}
                                        ListElement {text: "Number of bins"}
                                        ListElement {text: "Bin width"}
                                    }
                                    onActivated: {
                                        Julia.set_output(["Volume","binning"],indTree+1,currentIndex)
                                        changeLabel()
                                    }
                                }
                                TextField {
                                    id: numvaluevolumeTextField
                                    Layout.preferredWidth: 0.35*buttonWidth
                                    Layout.preferredHeight: buttonHeight
                                    text: "10"
                                    maximumLength: 5
                                    validator: IntValidator { bottom: 1; top: 99999}
                                    onEditingFinished: {
                                        var value = parseFloat(text)
                                        Julia.set_output(["Volume","value"],indTree+1,value)
                                    }
                                }
                                TextField {
                                    id: widthvaluevolumeTextField
                                    Layout.preferredWidth: 0.35*buttonWidth
                                    Layout.preferredHeight: buttonHeight
                                    text: "1"
                                    maximumLength: 5
                                    validator: DoubleValidator { bottom: 0.001; top: 99999}
                                    onEditingFinished: {
                                        var value = parseFloat(text)
                                        Julia.set_output(["Volume","value"],indTree+1,value)
                                    }
                                }
                                ComboBox {
                                    id: normalisationvolumeComboBox
                                    editable: false
                                    width: 0.69*buttonWidth-1*pix
                                    currentIndex: 0
                                    model: ListModel {
                                        id: normalisationModel
                                        ListElement {text: "pdf"}
                                        ListElement {text: "Density"}
                                        ListElement {text: "Probability"}
                                        ListElement {text: "None"}
                                    }
                                    onActivated: {
                                        Julia.set_output(["Volume","normalisation"],indTree+1,currentIndex)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Pane {
                id: classesPane
                spacing: 0
                padding: 0.5*margin
                width: 0.5*buttonWidth
                topPadding: tabmargin
                bottomPadding: tabmargin
                backgroundColor: defaultpalette.window2
                Column {
                    id: classesColumn
                    spacing: -2*pix
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
                        height: Math.max(Math.max(parametersColumn.height,menuPane.height) - 
                            classesLabel.height - 2*0.75*margin,600*pix)
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
                                                stack.push(viewModel[currentViewIndex].stackview)
                                            }
                                            Rectangle {
                                                id: colorRectangle
                                                visible: Julia.get_problem_type()==2
                                                anchors.left: treeButton.left
                                                anchors.verticalCenter: treeButton.verticalCenter
                                                anchors.leftMargin: 15*pix
                                                height: 30*pix
                                                width: 30*pix
                                                border.width: 2*pix
                                                radius: colorRectangle.width
                                                color: Julia.get_problem_type()==2 ? 
                                                    rgbtohtml([colorR,colorG,colorB]) :
                                                    "transparent"
                                            }
                                            Label {
                                                anchors.left: colorRectangle.left
                                                anchors.leftMargin: Julia.get_problem_type()==2 ? 
                                                    50*pix : 10*pix
                                                anchors.verticalCenter: treeButton.verticalCenter
                                                text: name
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        MouseArea {
            id: backgroundMouseArea
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

}
