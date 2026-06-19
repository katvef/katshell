pragma Singleton
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import Quickshell.Wayland
import "../widgets"

PanelWindow {
	id: root
	WlrLayershell.layer: WlrLayer.Overlay
	WlrLayershell.exclusiveZone: 0

	anchors {
		right: true
		top: true
	}

	margins {
		right: 2
		top: 2
	}

	implicitWidth: notifWidth
	implicitHeight: Math.min(notifCards.contentHeight, screen.height / 3)
	color: "transparent"
	screen: Quickshell.screens.find(x => x.name == Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

	property list<Notification> notifications
	property real notifWidth: 300
	property real notifHeight: 80
	property bool expire: true

	ListView {
		id: notifCards
		anchors.fill: parent
		model: server.trackedNotifications.values
		spacing: 6

		onModelChanged: if (model.length == 0) {
			root.expire = true;
		}

		delegate: Background {
			id: card
			required property var modelData
			width: root.notifWidth
			height: childrenRect.height + 8

			Text {
				id: cardSummary
				anchors.left: parent.left
				anchors.top: parent.top
				anchors.topMargin: 3
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

			GridLayout {
				id: buttons
				anchors.top: cardBody.bottom
				anchors.left: card.left
				anchors.right: card.right
				anchors.margins: 6
				columns: 2
				uniformCellWidths: true

				Repeater {
					id: button
					model: modelData.actions.filter(x => x.identifier != "default")
					delegate: Button {
						required property var modelData
						text: modelData.text ?? ""
						Layout.preferredWidth: buttons.width / 2 - 3

						background: Background {}
						contentItem: Text {
							text: parent.modelData.text ?? parent.modelData.identifier
							color: Style.text
							anchors.centerIn: parent
							// Layout.preferredWidth: parent.width / 2 - 3
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

			property Timer expirationTimer: Timer {
				interval: (parent.modelData.expireTimeout > 0 ? parent.modelData.expireTimeout * 1000 : 4000)
				running: root.expire
				repeat: false

				onTriggered: parent.modelData.expire()
			}
		}

		MouseArea {
			anchors.fill: parent
			acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
			hoverEnabled: true

			onEntered: notifCards.children[0].children.forEach(x => {
				const v = x?.expirationTimer;
				if (v != undefined)
					v.running = false;
			})

			onExited: notifCards.children[0].children.forEach(x => {
				const v = x?.expirationTimer;
				if (v != undefined)
					v.running = root.expire;
			})

			onClicked: mouse => {
				const item = notifCards.itemAt(mouse.x, mouse.y);
				const notification = item.modelData;
				switch (mouse.button) {
				case Qt.LeftButton:
					if (item != null) {
						const defaultAction = notification.actions.find(x => x.identifier == "default");
						if (defaultAction == undefined) {
							notification.dismiss();
						} else {
							defaultAction.invoke();
						}
					}
					break;
				case Qt.MiddleButton:
					root.expire = !root.expire;
					break;
				case Qt.RightButton:
					notification.dismiss();
				}
			}
		}
	}

	NotificationServer {
		id: server
		actionsSupported: true
		persistenceSupported: true

		onNotification: notification => {
			notification.tracked = true;
			if (!notification.transient) {
				notification.retained = true;
			}
			root.notifications.push(notification);
		}
	}
}
