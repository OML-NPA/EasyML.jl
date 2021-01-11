
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.impl 2.12
import QtQuick.Templates 2.12 as T
import QtQuick.Window 2.2

T.Button {
    id: control

    property double margin: 0.02*Screen.width
    property double pix: Screen.width/3840
    property double tabmargin: 0.5*margin
    property double font_size: 9
    property string heading: ""
    property string body: ""

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: 6
    horizontalPadding: padding + 2
    spacing: 6

    icon.width: 24
    icon.height: 24
    icon.color: control.checked || control.highlighted ? control.palette.brightText :
                control.flat && !control.down ? (control.visualFocus ? control.palette.highlight : control.palette.windowText) : control.palette.buttonText

    background: Rectangle {
        anchors.fill: parent.fill
        visible: !control.flat || control.down || control.checked || control.highlighted
        color: defaultcolors.light
        border.color: control.palette.dark
        border.width: 0
        Label {
            id: headinglabel
            x: 20*pix
            y: 20*pix
            width: control.width - 30*pix
            font.pointSize: 10
            font.family: "Proxima Nova"
            font.bold: true
            text: control.heading
        }
        TextArea {
            id: bodyTextArea
            x: 15*pix
            y: 80*pix
            width: control.width - 30*pix
            font.pointSize: 10
            font.family: "Proxima Nova"
            readOnly: true
            wrapMode: TextEdit.WordWrap
            horizontalAlignment: TextEdit.AlignJustify
            text: body
        }
        Rectangle {
                y: 1*pix
                color: defaultcolors.dark2
                border.color: defaultcolors.dark2
                border.width: 4*pix
                width: control.width
                height: 2*pix
        }
        Rectangle {
                y: control.height
                color: defaultcolors.dark2
                border.color: defaultcolors.dark2
                border.width: 4*pix
                width: control.width
                height: 2*pix
        }
    }
}
