import QtQuick
import QtQuick.Controls
import "../modules"

ToolTip {
	id: root
	contentItem: Text {
		anchors.centerIn: bg
		text: root.text
		color: Style.text
		verticalAlignment: Text.AlignVCenter
	}
	background: Rectangle {
		id: bg
		color: Style.background
		border.color: Style.border
		border.width: 2
		radius: Style.rounding
	}
}
