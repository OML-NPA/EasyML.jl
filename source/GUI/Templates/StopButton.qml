
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.impl 2.12
import QtQuick.Templates 2.12 as T

T.Button {
    id: control

    property real size: 20*pix

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

    contentItem: IconLabel {
        spacing: control.spacing
        mirrored: control.mirrored
        display: control.display

        icon: control.icon
        text: control.text
        font.family: "Proxima Nova"//control.font.family
        font.pointSize: 9
        color: control.checked || control.highlighted ? control.palette.brightText :
               control.flat && !control.down ? (control.visualFocus ? control.palette.highlight : control.palette.windowText) : control.palette.buttonText
    }

    background: Rectangle {
        implicitWidth: size
        implicitHeight: size
        radius: 2*size
        visible: !control.flat || control.down || control.checked || control.highlighted
        color: control.down ? defaultcolors.mid : defaultcolors.midlight
        border.color: control.down ? control.palette.dark : rgbtohtml([130,130,130])
        border.width: control.visualFocus ? 4*pix : 2*pix
        Rectangle {
            x: 1.08*size
            y: 1.08*size
            width: 1.15*size
            height: 1.15*size
            radius: 0.1*size
            color: control.down ? rgbtohtml([100,100,100]) : defaultcolors.dark
        }
    }
}
