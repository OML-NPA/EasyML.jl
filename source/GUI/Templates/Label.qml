
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.impl 2.12
import QtQuick.Templates 2.12 as T

T.Label {
    id: control

    color: control.palette.windowText
    linkColor: control.palette.link
    font.family: "Proxima Nova"//control.font.family
    font.pointSize: 10
    wrapMode: Text.WordWrap
}
