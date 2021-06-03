
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.impl 2.12
import QtQuick.Templates 2.12 as T
import QtQuick.Window 2.2

T.Button {
    id: control

    SystemPalette { id: systempalette; colorGroup: SystemPalette.Active }

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    property color backgroundColor: "#000000"
    property color borderColor: "#000000"

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
        font.pixelSize: 33*pix
        color: control.checked || control.highlighted ? control.palette.brightText :
               control.flat && !control.down ? (control.visualFocus ? control.palette.highlight : control.palette.windowText) : control.palette.buttonText
    }

    background: Rectangle {
        implicitWidth: 100*pix
        implicitHeight: 40*pix
        radius: 8*pix
        color: backgroundColor

        border.color: visualFocus ? "#66666" : systempalette.mid
        border.width: 3*pix
    }
}
