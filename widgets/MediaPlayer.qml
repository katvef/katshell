import QtQuick
import "../modules"

Text {
	property int maxLength
	property string overflowStr
	text: MediaManager.activePlayer.trackTitle ? trimString(MediaManager.activePlayer.trackTitle, maxLength ? maxLength : 30, overflowStr ? overflowStr : "...") : "No track name"

	Component.onCompleted: MediaManager.defaultPlayer = "spotify"

	color: Style.text
	font.pixelSize: 14

	MouseArea {
		anchors.fill: parent
		acceptedButtons: Qt.LeftButton | Qt.RightButton
		cursorShape: Qt.PointingHandCursor

		onClicked: function (mouse) {
			switch (mouse.button) {
			case Qt.LeftButton:
				MediaManager.activePlayer.togglePlaying();
				break;
			case Qt.RightButton:
				MediaManager.nextPlayer();
				break;
			}
		}
	}

	function trimString(str, length, overflowStr) {
		if (str.length > length) {
			str = str.substring(0, length).trim() + (typeof (overflowStr) == "string" ? overflowStr : "");
		}
		return str;
	}
}
