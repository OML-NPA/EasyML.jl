
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.impl 2.12
import QtQuick.Templates 2.12 as T

T.Button {
    id: control

    property double tabmargin: 0.5*margin
    property bool buttonfocus: false
    property bool horizontal: false

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: 6*pix
    horizontalPadding: padding + 2*pix
    spacing: 6*pix

    icon.width: 24*pix
    icon.height: 24*pix
    icon.color: control.checked || control.highlighted ? control.palette.brightText :
                control.flat && !control.down ? (control.visualFocus ? control.palette.highlight : control.palette.windowText) : control.palette.buttonText

    FontMetrics {
        id: fontMetrics
        font.family: "Proxima Nova"
    }

    contentItem: IconLabel {
        spacing: control.spacing
        mirrored: control.mirrored
        display: control.display

        icon: control.icon
        Label {
            id: textText
            text: control.text
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            leftPadding: horizontal ? 0 : tabmargin
            font.pixelSize: defaultPixelSize
            Component.onCompleted: {
                if (horizontal) {
                    var text_width = fontMetrics.advanceWidth(text)*pix
                    control.width = text_width + 150*pix
                    x = (control.width - text_width)/2 - 0.23*text_width
                }
                else {
                    anchors.fill = parent
                }
            }
        }


        color: control.checked || control.highlighted ? control.palette.brightText :
               control.flat && !control.down ? (control.visualFocus ? control.palette.highlight : control.palette.windowText) : control.palette.buttonText
    }

    background: Rectangle {
        anchors.fill: parent.fill
        visible: !control.flat || control.down || control.checked || control.highlighted
        color: control.pressed ? defaultpalette.buttonpressed :
               control.hovered && !control.buttonfocus ? defaultcolors.midlight2:
               control.buttonfocus ? defaultpalette.window: defaultpalette.window2
        border.color: control.palette.dark
        border.width: 0
        Rectangle {
                y: horizontal ? 0 : -1*pix
                x: horizontal ? -1*pix : 0
                color: defaultcolors.dark2
                border.color: defaultcolors.dark2
                border.width: 4*pix
                width: horizontal ? 3*pix : control.width
                height: horizontal ? control.height : 3*pix
        }
        Rectangle {
                y: horizontal ? 0 : control.height
                x: horizontal ? control.width : 0
                color: defaultcolors.dark2
                border.color: defaultcolors.dark2
                border.width: 4*pix
                width: horizontal ? 3*pix : control.width
                height: horizontal ? control.height : 3*pix
        }
    }
}
