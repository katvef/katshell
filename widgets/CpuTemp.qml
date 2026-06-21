import QtQuick
import Quickshell.Io
import "../modules"

Text {
	id: root
	property var package0: new Object({
		temp1_input: 0,
		temp1_max: 0,
		temp1_crit: 0
	})
	property real max: package0.temp1_max
	property real crit: package0.temp1_crit
	property real temp: package0.temp1_input
	property real high: 0
	property real low: 0

	Timer {
		interval: 1000
		repeat: true
		running: true
		onTriggered: {
			sensors.running = true;
		}
	}

	Process {
		id: sensors
		command: ["sensors", "-j"]
		running: true
		stdout: StdioCollector {
			onStreamFinished: {
				package0 = Object.values(JSON.parse(text))[0]["Package id 0"];
				high = temp > high ? temp : high
				low = temp < low ? temp : low
			}
		}
	}

	color: Style.text
	text: temp + " °C"
}
