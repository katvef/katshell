pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray
import "."

Repeater {
	id: root
	model: SystemTray.items

	x: parent.x
	y: parent.y

	delegate: Rectangle {
		id: trayItem

		required property SystemTrayItem modelData

		width: 16
		height: 16
		color: "transparent"

		Image {
			source: trayItem.modelData.icon
			sourceSize.width: 16
			sourceSize.height: 16
			fillMode: Image.PreserveAspectFit
			anchors.centerIn: parent
		}

		MenuPopup {
			id: pop
			item: trayItem
			menu: trayItem.modelData.menu //qmllint disable unresolved-type
		}

		MouseArea {
			id: mouseArea

			anchors.fill: parent
			acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
			cursorShape: Qt.PointingHandCursor
			hoverEnabled: true

			onClicked: function (mouse) {
				if (mouse.button === Qt.LeftButton) {
					trayItem.modelData.activate();
				} else if (mouse.button === Qt.MiddleButton) {
					// trayItem.modelData.secondaryActivate();
					trayItem.modelData.display(QsWindow.window, root.x + trayItem.x + mouse.x, root.y + trayItem.y + mouse.y);
				} else if (mouse.button === Qt.RightButton && trayItem.modelData.hasMenu) {
					pop.visible = true
				}
			}

			HoverToolTip {
				text: trayItem.modelData.tooltipTitle + (trayItem.modelData.tooltipDescription ? '\n' + trayItem.modelData.tooltipDescription : "")
				visible: mouseArea.containsMouse && text != ""
				popupType: Popup.Native
			}
		}
	}
}
