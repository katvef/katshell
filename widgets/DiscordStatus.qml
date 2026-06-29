import QtQuick
import Quickshell
import Quickshell.Io
import "../modules"

Item {
	id: root
	anchors.top: parent.top
	anchors.bottom: parent.bottom
	width: icon.width
	property string status
	readonly property var proc: Process {
		workingDirectory: Quickshell.shellDir + "/dc-status-control"
		command: ["node", "./index.js"]
		stdinEnabled: true
		running: true
		stdout: SplitParser {
			onRead: function (data) {
				root.status = data;
			}
		}
	}

	function setStatus(new_status) {
		proc.write(`set ${new_status}\n`);
	}

	onStatusChanged: {
		switch (status) {
		case "online":
			icon.text = " ";
			icon.color = Style.green;
			break;
		case "idle":
			icon.text = "󰤄 ";
			icon.color = Style.yellow;
			break;
		case "invisible":
			icon.text = " ";
			icon.color = Style.shade(Style.black, 0.5);
			break;
		case "dnd":
			icon.text = " ";
			icon.color = Style.red;
			break;
		}
	}

	Text {
		id: icon
		text: "?"
		color: Style.black
		verticalAlignment: Text.AlignVCenter
		horizontalAlignment: Text.AlignHCenter
		anchors.top: parent.top
		anchors.bottom: parent.bottom
	}

	MouseArea {
		anchors.fill: icon
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
