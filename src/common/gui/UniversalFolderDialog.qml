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
        Qt.quit()
    }
    Component.onCompleted: {
        folderDialog.open()
        if (Julia.unit_test()) {
            folderDialog.close
            function Timer() {
                return Qt.createQmlObject("import QtQuick 2.0; Timer {}", folderDialog);
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


