import QtQuick 2.15
import Qt.labs.platform 1.1
import org.julialang 1.0

FolderDialog {
    id: folderDialog
    options: FolderDialog.ShowDirsOnly
    onAccepted: {
        var dir = folder.toString().replace("file:///","")
        Julia.observe(dir)
        Qt.quit()
    }
    onRejected: {
        Julia.set_settings([target,type],"")
        Qt.quit()
    }
    Component.onCompleted: {
        folderDialog.open()
    }
}


