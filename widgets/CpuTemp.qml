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
	property int max: package0.temp1_max
	property int crit: package0.temp1_crit
	property int temp: package0.temp1_input

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
			}
		}
	}

	color: Style.text
	text: temp + " °C"
}
