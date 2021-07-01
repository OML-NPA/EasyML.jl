
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.impl 2.12
import QtQuick.Templates 2.12 as T

T.Button {
    id: control

    property real size: 20*pix
    property double inner_size: 1.15*size
    property bool running: false

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

    background: Rectangle {
        implicitWidth: size
        implicitHeight: size
        radius: 2*size
        visible: !control.flat || control.down || control.checked || control.highlighted
        color: Color.blend(control.checked || control.highlighted ? control.palette.dark : "#fafafa",
                                                                    control.palette.mid, control.down ? 0.5 : 0.0)
        border.color: control.palette.dark
        border.width: control.visualFocus ? 4*pix : 2*pix
        Rectangle {
            x: 1.08*size
            y: 1.08*size
            width: inner_size
            height: inner_size
            radius: 0.1*size
            visible: !running
            color: control.checked || control.highlighted ? "#333333" : defaultcolors.dark
        }
        Canvas{
            id: triangle
            width:  1.2*inner_size
            height: 1.2*inner_size
            x: 1.08*size+2*pix
            y: 1.08*size
            visible: running
            onPaint:{
                var ctx = getContext("2d");
                ctx.lineWidth = 1;
                ctx.beginPath();
                ctx.arc(2*pix, 2*pix, 2*pix,
                               -1.1*Math.PI, -0.45*Math.PI)
                ctx.arc(22*pix, inner_size/2, 2*pix,
                               -Math.PI/4, Math.PI/4)
                ctx.lineTo(2*pix, inner_size);//start point
                ctx.arc(2*pix, inner_size-2*pix, 2*pix,
                               0.45*Math.PI,1.1*Math.PI)
                ctx.fillStyle = control.checked || control.highlighted ? "#333333" : defaultcolors.dark
                ctx.fill();
            }
        }
    }
}
