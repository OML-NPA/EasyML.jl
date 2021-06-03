
import QtQuick 2.12
import QtQuick.Templates 2.12 as T
import QtQuick.Controls 2.12
import QtQuick.Controls.impl 2.12
T.CheckBox {
    id: control
    implicitWidth: 1.5*Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorHeight + topPadding + bottomPadding)

    rightPadding: 6*pix
    spacing: 28*pix

    // keep in sync with CheckDelegate.qml (shared CheckIndicator.qml was removed for performance reasons)
    indicator: Rectangle {
        implicitWidth: 40*pix
        implicitHeight: 40*pix

        x: control.text ? (control.mirrored ? control.width - width - control.rightPadding : control.leftPadding) : control.leftPadding + (control.availableWidth - width) / 2
        y: control.topPadding + (control.availableHeight - height) / 2

        color: defaultpalette.controlbase
        border.width: 2*pix
        border.color: defaultpalette.controlborder

        ColorImage {
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2
            width: 40*pix
            height: 40*pix
            defaultColor: "#353637"
            color: control.palette.text
            source: "qrc:/qt-project.org/imports/QtQuick/Controls.2/images/check.png"
            visible: control.checkState === Qt.Checked
        }

        Rectangle {
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2
            width: 16*pix
            height: 3*pix
            color: control.palette.text
            visible: control.checkState === Qt.PartiallyChecked
        }
    }

    contentItem: CheckLabel {
        leftPadding: 0.9*(control.indicator && !control.mirrored ? control.indicator.width + control.spacing : 0)
        rightPadding: 0.9*(control.indicator && control.mirrored ? control.indicator.width + control.spacing : 0)

        text: control.text
        font.family: "Proxima Nova"
        font.pixelSize: 33*pix
        color: control.palette.windowText
    }
}
