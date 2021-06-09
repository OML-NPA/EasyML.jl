
import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Controls.impl 2.14
import QtQuick.Templates 2.14 as T

T.ComboBox {
    id: control
    property double defaultWidth: 384*pix
    property double defaultHeight: buttonHeight
    property bool wasDown: false
    implicitWidth: defaultWidth
    implicitHeight: defaultHeight
    leftPadding: padding + (!control.mirrored || !indicator || !indicator.visible ? 0 : indicator.width + spacing)
    rightPadding: padding + (control.mirrored || !indicator || !indicator.visible ? 0 : indicator.width + spacing)
    delegate: ItemDelegate {
        width: control.width
        text: control.textRole ? (Array.isArray(control.model) ? modelData[control.textRole] : model[control.textRole]) : modelData
        palette.text: control.palette.text
        palette.highlightedText: control.palette.text
        font.weight: control.currentIndex === index ? Font.DemiBold : Font.Normal
        font.pixelSize: defaultPixelSize
        highlighted: control.highlightedIndex === index
        hoverEnabled: control.hoverEnabled
    }
    onFocusReasonChanged: if (down) {wasDown = true}

    contentItem: T.TextField {
        leftPadding: !control.mirrored ? 12*pix : control.editable && activeFocus ? 3*pix : 1*pix
        rightPadding: control.mirrored ? 12*pix : control.editable && activeFocus ? 3*pix : 1*pix
        topPadding: 6*pix - control.padding
        bottomPadding: 6*pix - control.padding

        text: control.editable ? control.editText : control.displayText

        enabled: control.editable
        autoScroll: control.editable
        readOnly: control.down
        inputMethodHints: control.inputMethodHints
        validator: control.validator

        font.family: "Proxima Nova"//control.font.family
        font.pixelSize: defaultPixelSize
        color: control.editable ? control.palette.text : control.palette.buttonText
        selectionColor: control.palette.highlight
        selectedTextColor: control.palette.highlightedText
        verticalAlignment: Text.AlignVCenter

        background: Rectangle {
            visible: control.enabled && control.editable && !control.flat
            border.width: 2*pix
            border.color: parent && parent.activeFocus ? control.palette.highlight : control.palette.dark
            color: defaultpalette.button
        }
    }

    indicator: ColorImage {
        x: control.mirrored ? control.padding : control.width - width - control.padding
        y: control.topPadding + (control.availableHeight - height) / 2
        width: 40*pix
        height: 28*pix
        color: control.palette.dark
        defaultColor: "#353637"
        source: "qrc:/qt-project.org/imports/QtQuick/Controls.2/images/double-arrow.png"
        opacity: enabled ? 1 : 0.3
    }

    background: Rectangle {
        implicitWidth: 140*pix
        implicitHeight: 40*pix

        color: control.down ? defaultpalette.buttonpressed : defaultpalette.button
        border.color: defaultpalette.controlborder
        border.width: 2*pix
        visible: !control.flat || control.down
    }

    popup: T.Popup {
        y: control.height
        width: control.width
        height: Math.min(contentItem.implicitHeight)
        topMargin: 6*pix
        bottomMargin: 6*pix
        onOpened: {
            if (wasDown) {
                close()
                wasDown = false
            }
        }

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.delegateModel
            currentIndex: control.highlightedIndex
            highlightMoveDuration: 0

            Rectangle {
                z: 10*pix
                width: parent.width
                height: parent.height
                color: "transparent"
                border.color: defaultpalette.border
            }

            T.ScrollIndicator.vertical: ScrollIndicator { }
        }

        background: Rectangle {
            color: defaultpalette.button
        }
    }
}
