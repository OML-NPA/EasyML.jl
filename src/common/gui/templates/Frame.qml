
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.impl 2.12
import QtQuick.Templates 2.12 as T

T.Frame {
    id: control
    property color backgroundColor: "transparent"
    property double borderWidth: pix*2
    property color borderColor: defaultpalette.border
    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            contentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             contentHeight + topPadding + bottomPadding)

    padding: 12*pix

    background: Rectangle {
        anchors.fill: parent.fill

        color: backgroundColor
        border.width: borderWidth
        border.color: borderColor
    }
}
