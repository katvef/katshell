pragma Singleton

import QtQuick
import Quickshell.Services.Mpris

QtObject {
	id: root
	property var players: Mpris.players.values
	property int playerIndex: 0
	property MprisPlayer activePlayer: players.length > 0 ? players[playerIndex] : null;
	property string defaultPlayer
	onDefaultPlayerChanged: playerIndex = players.findIndex(x => x.dbusName.match(defaultPlayer) != null)
	onPlayerIndexChanged: activePlayer = players.length > 0 ? players[playerIndex] : null;

	readonly property Timer timer: Timer {
		interval: 3000
		running: true
		repeat: true

		onTriggered: root.updatePlayers()
	}

	function updatePlayers() {
		if (playerIndex >= players.length) {
			playerIndex = 0;
		}
	}

	function nextPlayer() {
		playerIndex = (playerIndex + 1) % players.length;
	}
}
