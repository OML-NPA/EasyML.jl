
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.impl 2.12
import QtQuick.Templates 2.12 as T
import QtQuick.Window 2.14

T.TextField {
    id: control

    property double defaultWidth: 384*pix
    property double defaultHeight: buttonHeight

    implicitWidth: defaultWidth
    implicitHeight: defaultHeight

    //implicitWidth: implicitBackgroundWidth + leftInset + rightInset
    //               || Math.max(contentWidth, placeholder.implicitWidth) + leftPadding + rightPadding
    //implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
    //                         contentHeight + topPadding + bottomPadding,
    //                         placeholder.implicitHeight + topPadding + bottomPadding)

    padding: 6*pix
    leftPadding: padding + 4*pix

    color: control.palette.text
    selectionColor: control.palette.highlight
    selectedTextColor: control.palette.highlightedText
    placeholderTextColor: Color.transparent(control.color, 0.5)
    verticalAlignment: TextInput.AlignVCenter

    font.family: control.font.family
    font.pointSize: 9


    PlaceholderText {
        id: placeholder
        x: control.leftPadding
        y: control.topPadding
        width: control.width - (control.leftPadding + control.rightPadding)
        height: control.height - (control.topPadding + control.bottomPadding)

        text: control.placeholderText
        font.family: "Proxima Nova"//control.font.family
        font.pointSize: 10
        color: control.placeholderTextColor
        verticalAlignment: control.verticalAlignment
        visible: !control.length && !control.preeditText && (!control.activeFocus || control.horizontalAlignment !== Qt.AlignHCenter)
        elide: Text.ElideRight
        renderType: control.renderType
    }

    background: Rectangle {
        implicitWidth: defaultWidth
        implicitHeight: defaultHeight
        border.width: control.activeFocus ? 2*pix : 1*pix
        color: control.palette.base
        border.color: control.activeFocus ? control.palette.highlight : control.palette.mid
    }
}
