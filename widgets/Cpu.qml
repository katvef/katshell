import QtQuick
import "../modules"

Text {
	color: Style.text
	text: `${Cpu.cpuUsage}%`
}
