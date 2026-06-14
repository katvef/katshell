import QtQuick
import QtQuick.Controls
import "../modules"

Slider {
	id: root
	property real handleSize
	property real sliderWidth
	property real sliderHeight
	property real snapSize
	snapMode: Slider.NoSnap

	background: Rectangle {
		x: root.leftPadding
		y: root.topPadding + root.availableHeight / 2 - height / 2
		implicitWidth: root.sliderWidth
		implicitHeight: root.sliderHeight
		height: implicitHeight
		radius: implicitHeight / 2

		Rectangle {
			width: root.visualPosition * parent.width
			height: parent.height
			color: Style.highlight
			radius: parent.radius
		}

		color: Style.bright
	}

	handle: Background {
		x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
		y: root.topPadding + root.availableHeight / 2 - height / 2
		implicitWidth: root.handleSize
		implicitHeight: implicitWidth
		radius: implicitWidth / 2

		color: root.pressed ? Style.background : Style.foreground
	}

	Keys.onPressed: (event) => {
		if (event.modifiers == Qt.ShiftModifier && root.stepSize != undefined) {
			root.snapMode = Slider.SnapAlways
			root.stepSize = root.snapSize
		}
	}

	Keys.onReleased: (event) => {
		if (event.modifiers != Qt.ShiftModifier) {
			root.snapMode = Slider.NoSnap
			root.stepSize = 0
		}
	}
}
