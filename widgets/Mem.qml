import QtQuick
import "../modules"

Text {
	property string unit: "GB"
	property int precision: 3
	property var value: Mem.memInfo.memUsed

	color: Style.text
	text: Mem.sizeToUnit(value, unit, precision)
}
