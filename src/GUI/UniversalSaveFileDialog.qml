import QtQuick 2.15
import Qt.labs.platform 1.1
import org.julialang 1.0

FileDialog {
    id: fileDialog
    currentFile: "file:///"+filename
    fileMode: FileDialog.SaveFile
    onAccepted: {
        var url = file.toString().replace("file:///","")
        Julia.observe(url)
        Qt.quit()
    }
    onRejected: {
        Qt.quit()
    }
    Component.onCompleted: {
        fileDialog.open()
    }
}
