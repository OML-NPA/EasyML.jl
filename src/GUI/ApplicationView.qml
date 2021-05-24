
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import QtQuick.Layouts 1.2
import Qt.labs.platform 1.1
import QtQml.Models 2.15
import Qt.labs.folderlistmodel 2.15
import "Templates"
import org.julialang 1.0

Component {
    ColumnLayout {
        id: mainLayout
        property int indTree: 0
        Component.onCompleted: {
            var temp_folder = Julia.get_settings(["Application","folder_url"])
            if (temp_folder==="") {
                folderModel.folder = "file:///"+Julia.fix_slashes(Julia.pwd())
            }
            else {
                folderModel.folder = "file:///"+temp_folder
            }
            folderDialog.currentFolder = temp_folder
        }

        FolderListModel {
            id: folderModel
            showFiles: false
        }
        FolderDialog {
            id: folderDialog
            onAccepted: {
                updateFolder(folderDialog.folder)
            }
        }
        FileDialog {
            id: modelFileDialog
            folder: Qt.resolvedUrl(".")
            onAccepted: {
                var url = stripURL(file)
                import_model_application(url)
            }
        }

        Loader { id: applicationoptionsLoader }
        Loader { id: applicationfeaturedialogLoader}
        Loader { id: selectneuralnetworkLoader }
        RowLayout {
            id: rowLayout
            Layout.alignment: Qt.AlignHCenter
            spacing: margin
            Column {
                spacing: 0.3*margin
                RowLayout {
                    spacing: 0.5*margin
                    Button {
                        id: up
                        Layout.row: 1
                        text: "Up"
                        Layout.preferredWidth: buttonWidth/2
                        Layout.preferredHeight: buttonHeight
                        onClicked: {
                            updateFolder(folderModel.parentFolder)
                        }
                    }
                    Button {
                        id: browse
                        Layout.row: 2
                        text: "Browse"
                        Layout.preferredWidth: buttonWidth/2
                        Layout.preferredHeight: buttonHeight
                        onClicked: {folderDialog.open()}
                    }
                    Button {
                        Layout.preferredWidth: buttonWidth + 0.5*margin
                        Layout.preferredHeight: buttonHeight
                        Layout.leftMargin: 0.5*margin
                        backgroundRadius: 0
                        Component.onCompleted: {
                            var url = Julia.get_settings(["Application","model_url"])
                            if (Julia.isfile(url)) {
                                import_model_application(url)
                            }
                        }
                        onClicked: {
                            modelFileDialog.open()
                            /*if (selectneuralnetworkLoader.sourceComponent === null) {
                                selectneuralnetworkLoader.source = "SelectNeuralNetwork.qml"
                            }*/
                        }
                        Label {
                            id: nnselectLabel
                            anchors.verticalCenter: parent.verticalCenter
                            leftPadding: 15*pix
                            text: "Select an ML model"
                        }
                        Image {
                            anchors.right: parent.right
                            height: parent.height
                            opacity: 0.3
                            source: "qrc:/qt-project.org/imports/QtQuick/Controls.2/images/double-arrow.png"
                            fillMode: Image.PreserveAspectFit
                        }
                    }
                }
                RowLayout {
                    spacing: margin
                    Column {
                        spacing: -2*pix
                        Label {
                            width: buttonWidth + 0.5*margin
                            text: "Folders:"
                            padding: 0.1*margin
                            leftPadding: 0.2*margin
                            background: Rectangle {
                                anchors.fill: parent.fill
                                color: defaultpalette.window
                                border.color: defaultcolors.dark
                                border.width: 2*pix
                            }
                        }
                        Frame {
                            height: 432*pix
                            width: buttonWidth + 0.5*margin
                            backgroundColor: "white"
                            ScrollView {
                                clip: true
                                anchors.fill: parent
                                spacing: 0
                                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                                ListView {
                                    id: folderView
                                    spacing: 0
                                    boundsBehavior: Flickable.StopAtBounds
                                    model: folderModel
                                    delegate: TreeButton {
                                        id: control
                                        width: buttonWidth + 0.5*margin - 24*pix
                                        height: buttonHeight - 2*pix
                                        onDoubleClicked: {
                                            var url = folderModel.folder+"/"+name.text
                                            updateFolder(url)
                                        }
                                        Row {
                                            spacing: 0
                                            leftPadding: - 20*pix
                                            CheckBox {
                                                topPadding: 11*pix
                                                leftPadding: 10*pix
                                                onClicked: {
                                                    var url = folderModel.folder+"/"+name.text
                                                    var checkedFolders = []
                                                    for (var i=0;i<folderModel.count;i++) {
                                                         var treeButton = folderView.itemAtIndex(i)
                                                         if (treeButton!==null) {
                                                             var checkBox = treeButton.children[0].children[0]
                                                             if (checkBox.checked) {
                                                                var fileName = folderModel.get(i, "fileName")
                                                                checkedFolders.push(fileName)
                                                             }
                                                         }
                                                    }
                                                    Julia.set_settings(["Application","checked_folders"],
                                                                       checkedFolders)
                                                }
                                            }
                                            Label {
                                                id: name
                                                topPadding: 0.12*margin
                                                leftPadding: -10*pix
                                                text: fileName
                                            }
                                        }
                                    }
                                    Component.onCompleted: {
                                        initialize_checked()
                                    }
                                }
                            }
                        }
                    }
                    Column {
                        spacing: -2*pix
                        Label {
                            width: buttonWidth + 0.5*margin
                            text: "Features:"
                            padding: 0.1*margin
                            leftPadding: 0.2*margin
                            background: Rectangle {
                                anchors.fill: parent.fill
                                color: defaultpalette.window
                                border.color: defaultcolors.dark
                                border.width: 2*pix
                            }
                        }
                        Frame {
                            height: 432*pix
                            width: buttonWidth + 0.5*margin
                            backgroundColor: "white"
                            ScrollView {
                                clip: true
                                anchors.fill: parent
                                padding: 0
                                spacing: 0
                                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                                ListView {
                                    id: featureView
                                    height: childrenRect.height
                                    spacing: 0
                                    boundsBehavior: Flickable.StopAtBounds
                                    model: ListModel {id: applicationfeatureModel}
                                    Component.onCompleted: {
                                        var url = Julia.get_settings(["Application","model_url"])
                                        if (url!=="") {
                                            load_model_features(applicationfeatureModel)
                                            var url_split = url.split('/')
                                            nnselectLabel.text = url_split[url_split.length-1]
                                        }
                                    }
                                    delegate: TreeButton {
                                        id: applicationfeatureButton
                                        hoverEnabled: true
                                        width: buttonWidth + 0.5*margin - 24*pix
                                        height: buttonHeight - 2*pix
                                        onClicked: {
                                            if (applicationfeaturedialogLoader.sourceComponent === null) {
                                                indTree = index
                                                applicationfeaturedialogLoader.source = "OutputDialog.qml"
                                            }
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
        }
        ColumnLayout {
            id: columnLayout
            spacing: 0.4*margin
            Layout.topMargin: margin
            Layout.alignment: Qt.AlignHCenter
            Button {
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                text: "Options"
                Layout.preferredWidth: buttonWidth
                Layout.preferredHeight: buttonHeight
                onClicked: {
                    if (applicationoptionsLoader.sourceComponent === null) {
                       applicationoptionsLoader.source = "ApplicationOptions.qml"
                    }
                }
            }
            Button {
                id: applicationButton
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                text: "Apply"
                Layout.preferredWidth: buttonWidth
                Layout.preferredHeight: buttonHeight
                onClicked: {
                    function reset() {
                        applicationButton.text = "Apply"
                        applicationTimer.running = false
                        applicationTimer.value = 0
                        applicationTimer.max_value = 0
                        applicationProgressbar.value = 0
                        applicationprogressLabel.visible = false
                        Julia.put_channel("Application",["stop"])
                    }
                    applicationProgressbar.value = 0
                    applicationprogressLabel.text = "0%"
                    if (applicationButton.text==="Apply") {
                        applicationButton.text = "Stop application"
                        Julia.get_urls_application()
                        var num_urls = Julia.get_data(["Application_data","url_input"]).length
                        if (num_urls===0) {
                            reset()
                            return
                        }
                        Julia.empty_progress_channel("Application")
                        Julia.empty_progress_channel("Application modifiers")
                        applicationTimer.running = true
                        applicationprogressLabel.visible = true
                        Julia.apply()
                    }
                    else {
                        reset()
                    }
                }
                Timer {
                    id: applicationTimer
                    interval: 1000; running: false; repeat: true
                    property double value: 0
                    property double max_value: 0
                    onTriggered: {
                        applicationTimerFunction(applicationButton,applicationTimer,
                            "Apply","Stop application")
                    }
                }
            }
            ColumnLayout {
                id: progressbarLayout
                spacing: 0.1*margin
                Layout.alignment: Qt.AlignHCenter
                ProgressBar {
                    id: applicationProgressbar
                    Layout.alignment: Qt.AlignHCenter
                    width: buttonWidth
                }
                Label {
                    id: applicationprogressLabel
                    Layout.alignment: Qt.AlignHCenter
                    visible: false
                    text: "0%"
                }
            }
        }

        function applicationTimerFunction(button,timer,start,stop) {
            if (timer.max_value!==0) {
                var value = Julia.get_progress("Application")
                if (timer.value===timer.max_value) {
                    timer.running = false
                    timer.value = 0
                    timer.max_value = 0
                    button.text = start
                }
                else {
                    if (value!==false) {
                        timer.value += value
                        var progressvalue = timer.value/timer.max_value
                        applicationProgressbar.value = progressvalue
                        applicationprogressLabel.text = Math.round(100*progressvalue)+"%"
                    }
                }
            }
            else {
                value = Julia.get_progress("Application")
                if (value===false) { return }
                timer.max_value = value
            }
        }

        function import_model_application(url) {
            Julia.set_settings(["Application","model_url"],url)
            Julia.load_model(url)
            applicationfeatureModel.clear()
            load_model_features(applicationfeatureModel)
            url = url.split('/')
            nnselectLabel.text = url[url.length-1]
        }

        function updateFolder(path) {
            folderModel.folder = path
            path = String(path).substring(8)
            Julia.set_settings(["Application","folder_url"],path)
        }

        function initialize_checked() {
            if (folderModel.status!==1) {
                delay(10, initialize_checked)
            }
            var folders = Julia.get_settings(["Application","checked_folders"])
            var num = folders.length
            if (num===0) {
                return
            }
            else {
                for (var i=0;i<num;i++) {
                    for (var j=0;j<folderModel.count;j++) {
                        var folderName = folderModel.get(j,"fileName")
                        if (folders[i]===folderName) {
                            var treeButton = folderView.itemAtIndex(j)
                            if (treeButton!==null) {
                                var checkBox = treeButton.children[0].children[0]
                                checkBox.checkState = Qt.Checked
                            }
                        }
                    }
                }
            }
        }

        function load_model_features(featureModel) {
            var num_features = Julia.num_features()
            if (featureModel.count!==0) {
                featureModel.clear()
            }
            for (var i=0;i<num_features;i++) {
                var ind = i+1
                if (Julia.get_feature_field(ind,"not_feature")===true) {
                    continue
                }
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

    }
}
