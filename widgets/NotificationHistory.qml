import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
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
		onPressed: {
			daemon.visible = !daemon.visible;
			root.visible = !root.visible;
		}
	}

	visible: false
	color: "transparent"
	implicitWidth: 400 + notifCards.anchors.margins * 2

	anchors {
		right: true
		top: true
		bottom: true
	}

	margins {
		right: 2
		top: 2
		bottom: 2
	}

	Background {
		anchors.fill: parent
	}

	MouseArea {
		anchors.fill: parent
		acceptedButtons: Qt.LeftButton | Qt.RightButton
		hoverEnabled: true

		onClicked: mouse => {
			switch (mouse.button) {
			case Qt.RightButton:
				const item = notifCards.itemAt(mouse.x, mouse.y);
				const notification = item.modelData;
				notification.dismiss();
				root.daemon.notifications.delete(notification);
				root.daemon.notificationsWasModified();
				notification.Retainable.unlock();
				break;
			case Qt.LeftButton:
				if (notification.resident) {
					notification.actions.find(x => x.identifier == "default");
				} else {
					notification.dismiss();
				}
			}
		}

		ListView {
			id: notifCards
			anchors.fill: parent
			anchors.margins: 6
			spacing: 6

			model: daemon.notificationsList

			delegate: Background { // Keep in sync with NotificationDaemon.qml
				id: card
				required property var modelData
				width: root.width - 12
				height: childrenRect.height + 6

				Text {
					id: cardTime
					anchors.top: parent.top
					anchors.right: parent.right
					anchors.topMargin: 2
					anchors.rightMargin: 5
					text: Qt.formatDateTime(modelData.time, "yyyy-MM-dd hh:mm:ss")
					color: Qt.alpha(Style.text, 0.75)
					font.pixelSize: 11
				}

				Text {
					id: cardSummary
					anchors.left: parent.left
					anchors.top: parent.top
					anchors.right: cardTime.left
					anchors.leftMargin: 6

					width: root.width - 6
					wrapMode: Text.Wrap
					color: Style.text
					textFormat: Text.PlainText
					text: modelData.summary
					font.pixelSize: 16
				}

				Text {
					id: cardBody
					anchors.left: parent.left
					anchors.top: cardSummary.bottom
					anchors.topMargin: 3
					anchors.leftMargin: 6

					width: root.height - 6
					wrapMode: Text.Wrap
					color: Style.text
					textFormat: Text.StyledText
					text: modelData.body
				}

				GridLayout {
					id: buttons
					property var actions: card.modelData.actions.filter(x => x.identifier != "default")
					anchors.top: cardBody.bottom
					anchors.left: card.left
					anchors.right: card.right
					anchors.margins: actions.length > 0 ? 6 : 0
					columns: 2
					uniformCellWidths: true

					Repeater {
						id: button
						model: parent.actions
						delegate: Button {
							required property var modelData
							text: modelData.text ?? ""
							Layout.preferredWidth: buttons.width / 2 - 3

							background: Background {}
							contentItem: Text {
								text: parent.modelData.text ?? parent.modelData.identifier
								color: Style.text
								anchors.centerIn: parent
								horizontalAlignment: Text.AlignHCenter
								font.pixelSize: 11
								wrapMode: Text.Wrap
							}

							onClicked: {
								modelData.invoke();
								card.modelData.dismiss();
								card.modelData.tracked = false;
							}
						}
					}
				}
			}
		}
	}
}
