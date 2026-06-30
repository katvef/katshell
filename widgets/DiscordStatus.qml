import QtQuick
import Quickshell
import Quickshell.Io
import "../modules"

Item {
	id: root
	anchors.top: parent.top
	anchors.bottom: parent.bottom
	width: status_icon.width
	property string status: undefined
	property bool game: undefined
	readonly property var proc: Process {
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
				root.status = status;
				if (game == "true") {
					root.game = true;
				} else if (game == "false") {
					root.game = false;
				}
			}
		}
		stderr: SplitParser {
			onRead: function (data) {
				console.log(data);
			}
		}
		onRunningChanged: running = true
		Component.onDestruction: proc.write("close")
	}

	function setStatus(new_status) {
		console.log(`status ${new_status}\n`);
		proc.write(`status ${new_status}\n`);
	}

	function setGame(new_game) {
		console.log(`game ${new_game}\n`);
		proc.write(`game ${new_game}\n`);
	}

	onStatusChanged: {
		switch (status) {
		case "online":
			status_icon.text = " ";
			status_icon.color = Style.green;
			break;
		case "idle":
			status_icon.text = "󰤄 ";
			status_icon.color = Style.yellow;
			break;
		case "invisible":
			status_icon.text = " ";
			status_icon.color = Style.shade(Style.black, 0.5);
			break;
		case "dnd":
			status_icon.text = " ";
			status_icon.color = Style.red;
			break;
		}
	}

	Row {
		anchors.top: parent.top
		anchors.bottom: parent.bottom

		Text {
			id: status_icon
			text: " "
			color: Style.black
			anchors.verticalCenter: parent.verticalCenter
			verticalAlignment: Text.AlignVCenter
			horizontalAlignment: Text.AlignHCenter
			font.pixelSize: 16

			MouseArea {
				anchors.fill: parent
				acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
				onClicked: mouse => {
					if (mouse.button == Qt.LeftButton) {
						popup.visible = !popup.visible;
						popup.grab.active = true;
					} else if (mouse.button == Qt.RightButton) {
						if (root.status == "online") {
							root.setStatus("idle");
						} else {
							root.setStatus("online");
						}
					} else if (mouse.button == Qt.MiddleButton) {
						if (root.status == "online") {
							root.setStatus("invisible");
						} else {
							root.setStatus("online");
						}
					}
				}
			}
		}

		Text {
			id: game_icon
			text: "󰊗 "
			color: game ? Style.green : Style.red
			anchors.verticalCenter: parent.verticalCenter
			verticalAlignment: Text.AlignVCenter
			horizontalAlignment: Text.AlignHCenter
			font.pixelSize: 16

			MouseArea {
				anchors.fill: parent
				acceptedButtons: Qt.LeftButton
				onClicked: mouse => {
					root.setGame(!root.game);
				}
			}
		}
	}

	PopupToolTip {
		id: popup
		visible: false
		item: root

		MouseArea {
			anchors.fill: popup
			hoverEnabled: true
			onExited: parent.visible = false
		}

		content: Column {
			Repeater {
				model: ["online", "idle", "dnd", "invisible"]
				delegate: Text {
					required property string modelData
					text: modelData
					color: Style.text
					MouseArea {
						anchors.fill: parent
						onClicked: {
							popup.visible = false;
							root.setStatus(parent.modelData);
						}
					}
				}
			}
		}
	}
}
