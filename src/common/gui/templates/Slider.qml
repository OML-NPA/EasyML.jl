import QtQuick 2.12
import QtQuick.Controls 2.12

Slider {
    id: control
    value: 0.5
    property color backgroundColor: "#bdbebf"
    property color fillColor: "#3498db"
    property color handleColor: "#f6f6f6"
    property color handlePressedColor: "#f0f0f0"
    property color handleBorderColor: "#bdbebf"
    property double handleSize: 36*pix


    background: Rectangle {
        x: control.leftPadding
        y: control.topPadding + control.availableHeight/2 - height/2
        implicitWidth: 200*pix
        implicitHeight: 4*pix
        width: control.availableWidth
        height: control.height
        radius: control.height/2
        color: backgroundColor

        Rectangle {
            width: control.visualPosition * parent.width
            height: parent.height
            color: fillColor
            radius: control.height/2
        }
    }

    handle: Rectangle {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + control.availableHeight/2 - height/2
        implicitWidth: handleSize
        implicitHeight: handleSize
        radius: handleSize/2
        color: control.pressed ? handlePressedColor : handleColor
        border.color: handleBorderColor
    }
}
