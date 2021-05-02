
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.impl 2.12
import QtQuick.Templates 2.12 as T
import QtQuick.Window 2.2

T.Pane {
    id: control
    background: Rectangle {anchors.fill: parent.fill; color: "transparent"}
    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            contentWidth + leftPadding + rightPadding + boxWidth)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             contentHeight + topPadding + bottomPadding + boxHeight)
    property double boxWidth: 30*pix
    property double boxHeight: 30*pix
    property double boxX: 0//(control.width-box.height)/2
    property double boxY: 0//(control.height-box.height)/2
    property var colorRGB: [1,1,1]
    Rectangle {
        id: box
        width: boxWidth
        height: boxHeight
        anchors.left: parent.left
        x: boxX
        y: boxY
        color: typeof(colorRGB)=="undefined" ? "white" :
              Qt.rgba(colorRGB[0]/255,colorRGB[1]/255,colorRGB[2]/255,1.0)
        border.width: 1*pix
    }
}
