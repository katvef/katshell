pragma Singleton

import QtQuick
import Quickshell.Services.Mpris

QtObject {
	id: root
	property var values: Mpris.players.values
	property int playerIndex: 0
	property MprisPlayer activePlayer: values.length > 0 ? values[0] : null

	readonly property Timer timer: Timer {
		interval: 3000
		running: true
		repeat: true

		onTriggered: root.updatePlayers()
	}

	function updatePlayers() {
		values = Mpris.players.values;

		if (playerIndex >= values.length) {
			playerIndex = 0;
		}

		activePlayer = values.length > 0 ? values[playerIndex] : null;
	}

	function nextPlayer() {
		playerIndex = (playerIndex + 1) % values.length;
		activePlayer = values.length > 0 ? values[playerIndex] : null;
	}
}
