import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.2
import Qt.labs.platform 1.1
import org.julialang 1.0


ApplicationWindow {
    id: window
    Component.onCompleted: {
        folderDialog.open()
    }

    FolderDialog {
        id: folderDialog
        currentFolder: currentfolder
        options: FolderDialog.ShowDirsOnly
        onAccepted: {
            var dir = folder.toString().replace("file:///","")
            Julia.set_settings([target,type],dir)
            Qt.quit()
        }
        onRejected: {
            Julia.set_settings([target,type],"")
        }
    }
}


