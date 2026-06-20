import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import Quickshell.Wayland
import "../modules"

PanelWindow {
	id: root
	property var daemon: NotificationDaemon

	WlrLayershell.layer: WlrLayer.Overlay
	WlrLayershell.exclusiveZone: 0
	GlobalShortcut {
		appid: "katshell"
		description: "Toggle notification history panel"
		name: "toggle notification history"
		onPressed: root.visible = !root.visible
	}

	visible: false
	color: Qt.alpha(Style.background, 0.8)
	implicitWidth: 400

	anchors {
		right: true
		top: true
		bottom: true
	}

	margins {
		right: 2
		top: 2
	}

	property real notifWidth: 300
	property real notifHeight: 80
	property bool expire: true

	ListView {
		id: notifCards
		anchors.fill: parent
		model: daemon.notificationsList
		spacing: 6
		delegateModelAccess: DelegateModel.ReadWrite

		onModelChanged: if (model.length == 0) {
			root.expire = true;
		}

		delegate: Background {
			id: card
			required property var modelData
			width: root.notifWidth
			height: childrenRect.height + 6

			Text {
				id: cardSummary
				anchors.left: parent.left
				anchors.top: parent.top
				anchors.leftMargin: 6

				width: root.notifWidth - 6
				wrapMode: Text.Wrap
				color: Style.text
				text: parent.modelData.summary
				font.pixelSize: 16
			}

			Text {
				id: cardBody
				anchors.left: parent.left
				anchors.top: cardSummary.bottom
				anchors.topMargin: 3
				anchors.leftMargin: 6

				width: root.notifWidth - 6
				wrapMode: Text.Wrap
				color: Style.text
				text: parent.modelData.body
			}
		}

		MouseArea {
			anchors.fill: parent
			acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
			hoverEnabled: true

			onClicked: mouse => {
				if (mouse.button == Qt.RightButton) {
					const item = notifCards.itemAt(mouse.x, mouse.y);
					const notification = item.modelData;
					root.daemon.notifications.delete(notification);
					root.daemon.notificationsWasModified()
					notification.Retainable.unlock();
				}
			}
		}
	}
}
