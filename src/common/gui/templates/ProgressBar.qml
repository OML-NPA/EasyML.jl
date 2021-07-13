
import QtQuick 2.12
import QtQuick.Controls 2.12

Rectangle {
    id: control
    property double value: 0
    height: 6*pix
    width: 100*pix
    radius: 8*pix
    color: defaultcolors.mid
    Rectangle {
        radius: 8*pix
        height: control.height
        width: control.value*control.width
        color: "#3498db"
    }
}
