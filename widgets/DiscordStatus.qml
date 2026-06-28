import QtQuick
import Quickshell
import Quickshell.Io
import "../modules"

Item {
	id: root
	anchors.top: parent.top
	anchors.bottom: parent.bottom
	width: icon.width
	property string status: "waiting"
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

	function setStatus(status) {
		proc.write(`set ${status}\n`);
	}

	Image {
		id: icon
		source: switch (root.status) {
		default:
			return "https://i.imgur.com/QU35DxI.png";
			break;
		case "dnd":
			return "https://i.imgur.com/JlXjK4S.png";
			break;
		case "invisible":
			return "https://i.imgur.com/w3EYDuS.png";
			break;
		case "idle":
			return "https://i.imgur.com/eHW8KmV.png";
			break;
		}

		sourceSize: Qt.size(12, 12)
		anchors.verticalCenter: parent.verticalCenter
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
