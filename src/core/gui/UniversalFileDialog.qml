import QtQuick 2.15
import Qt.labs.platform 1.1
import org.julialang 1.0

FileDialog {
    id: fileDialog
    nameFilters: name_filters
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
        if (Julia.unit_test()) {
            fileDialog.close()
            function Timer() {
                return Qt.createQmlObject("import QtQuick 2.0; Timer {}", fileDialog);
            }
            function delay(delayTime, cb) {
                var timer = new Timer();
                timer.interval = delayTime;
                timer.repeat = false;
                timer.triggered.connect(cb);
                timer.start();
            }
            delay(1000, Qt.quit)
        }
    }
}
