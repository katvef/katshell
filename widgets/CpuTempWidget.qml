import QtQuick
import "../modules"

Column {
	anchors.top: parent.top
	anchors.bottom: parent.bottom

	CpuTemp {
		id: cpuTemp
		font.pixelSize: 12
		anchors.horizontalCenter: parent.horizontalCenter
	}

	Rectangle {
		property real value: cpuTemp.temp
		property real from: 20
		property real to: 100
		property var colors: new Object({
			ok: Style.shade(Style.green, 0.15),
			high: Style.yellow,
			max: Style.orange,
			crit: Style.red
		})
		property var steps: new Object({
			high: cpuTemp.max - 20,
			max: cpuTemp.max,
			crit: cpuTemp.crit - 10
		})
		function normalizeValue(value) {
			return 1 - ((value - from) / (to - from));
		}

		implicitWidth: cpuTemp.implicitWidth + 2
		implicitHeight: 9

		color: {
			if (value < steps.high) {
				return colors.ok;
			} else if (value < steps.max) {
				return colors.high;
			} else if (value < steps.crit) {
				return colors.max;
			} else {
				return colors.crit;
			}
		}

		// Cpu critical indicator
		Text {
			visible: parent.value >= cpuTemp.crit
			anchors.horizontalCenter: parent.horizontalCenter
			verticalAlignment: Text.AlignVCenter
			height: parent.height
			y: -1
			text: ""
			color: parent.colors.crit
			font.pixelSize: 18
		}

		// Inactive color
		Rectangle {
			visible: parent.value >= parent.from
			anchors.right: parent.right
			implicitWidth: parent.width * parent.normalizeValue(parent.value)
			implicitHeight: parent.implicitHeight
			color: Style.shade(Style.bright, -0.3)
		}

		// Step indicators
		Rectangle {
			visible: parent.value < parent.steps.high
			height: parent.height
			width: 1
			x: parent.width * (1 - parent.normalizeValue(parent.steps.high))
			color: parent.colors.high
		}

		Rectangle {
			visible: parent.value < parent.steps.max
			height: parent.height
			width: 1
			x: parent.width * (1 - parent.normalizeValue(parent.steps.max))
			color: parent.colors.max
		}

		Rectangle {
			visible: parent.value < parent.steps.crit
			height: parent.height
			width: 1
			x: parent.width * (1 - parent.normalizeValue(parent.steps.crit))
			color: parent.colors.crit
		}
	}
}
