pragma Singleton
import QtQuick

QtObject {
	// Style colors
	property color background: "#E6192330"
	property color foreground: "#1f3955"
	property color highlight: "#6295DE"
	property color bright: "#71839b"
	property color border: "#E633ccff"

	// text colors
	property color text: "#7aa2f7"
	property color textBright: "#0db9d7"
	property int rounding: 3

	// Basic colors
	property color red: "#c94f6d"
	property color yellow: "#dbc074"
	property color orange: "#f4a261"
	property color green: "#81b29a"
	property color cyan: "#63cdcf"
	property color blue: "#719cd6"

	function shade(color, l) {
		return l < 0 ? Qt.darker(color, 1 - l) : Qt.lighter(color, 1 + l);
	}
}
