import QtQuick 2.15
import Qt.labs.platform 1.1
import org.julialang 1.0

FileDialog {
    id: fileDialog
    nameFilters: [ "*.model"]
    onAccepted: {
        var url = file.toString().replace("file:///","")
        Julia.load_model(url)
        Qt.quit()
    }
    onRejected: {
        Qt.quit()
    }
    Component.onCompleted: {
        fileDialog.open()
    }
}
