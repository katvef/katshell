pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Hyprland
import "../modules"

Row {
	spacing: 2
	Repeater {
		id: repeater
		model: Hyprland.workspaces.values

		delegate: Loader {
			required property HyprlandWorkspace modelData

			active: modelData.id >= 0

			sourceComponent: Item {
				property var ws

				width: children[0].implicitWidth
				height: children[0].implicitHeight

				Column {
					property var ws: parent.ws
					property bool isActive: Hyprland.focusedWorkspace?.id === (ws.id)

					spacing: -4

					Text {
						text: parent.ws.name
						color: parent.isActive ? Style.textBright : Style.text
						font.bold: true
					}

					Text {
						text: parent.ws.toplevels.values.length < 10 ? parent.ws.toplevels.values.length : "+"
						color: parent.isActive ? Style.textBright : Style.text
						font.bold: true
					}
				}

				MouseArea {
					anchors.fill: parent

					onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + parent.ws.id + " })")
				}
			}

			onLoaded: item.ws = modelData
		}
	}
}
