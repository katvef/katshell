pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Process {
	id: root
	signal statusChanged(status: string)
	signal gameChanged(show: bool)
	workingDirectory: Quickshell.shellDir + "/dc-status-control"
	command: ["node", "./index.js"]
	stdinEnabled: true
	running: true
	stdout: SplitParser {
		onRead: function (data) {
			if (data == "connection lost") {
				console.log("discord connection lost, restarting");
			}
			const [status, game] = data.split(" ");
			root.statusChanged(status);
			if (game == "true") {
				root.gameChanged(true);
			} else if (game == "false") {
				root.gameChanged(false);
			}
		}
	}
	stderr: SplitParser {
		onRead: function (data) {
			console.log("discord: " + data);
		}
	}
	onRunningChanged: running = true
	Component.onDestruction: this.write("close")
}
