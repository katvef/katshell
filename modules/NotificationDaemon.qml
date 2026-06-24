pragma Singleton
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
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

	property var notifications: new Map()
	property list<Notification> notificationsList
	property list<Notification> respawned
	property real notifWidth: 300
	property real notifHeight: 80
	property bool expire: true

	function notificationsWasModified() {
		notificationsList = [...notifications.keys()].sort((a, b) => b.time - a.time);
	}

	function getNotification(id: int): Notification {
		let n;
		if (typeof id == "number") {
			if (root.getIds().find(x => x == id) == undefined) {
				throw new Error("Id not found");
			}
			n = notificationsList.find(x => x.id == id);
			Util.inspect(n);
		}
		n = notificationsList[0];
		return n;
	}

	function getIds(): var {
		return notificationsList.map(x => x.id) ?? new Array();
	}

	IpcHandler {
		target: "notifications"

		function respawn(id: int): void {
			const n = root.getNotification(id);
			if (n !== undefined) {
				n.closed.connect(function () {
					const idx = root.respawned.findIndex(x => x == n);
					if (idx != -1) {
						root.respawn.pop(idx);
					}
					n.Retainable.unlock();
				});
				n.Retainable.lock();
				root.respawned.push(n);
			}
		}

		function dismiss(id: int): void {
			const n = root.getNotification(id);
			if (n !== undefined) {
				if (n.tracked == true) {
					n.dismiss();
				} else {
					n.closed(NotificationCloseReason.Dismissed);
				}
			}
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
				if (notification.tracked == true) {
					notification.dismiss();
				} else {
					notification.closed(NotificationCloseReason.Dismissed);
				}
			}
		}

		ListView {
			id: notifCards
			anchors.fill: parent
			model: server.trackedNotifications.values.concat(root.respawned)
			spacing: 6

			onModelChanged: if (model.length == 0) {
				root.expire = true;
			}

			delegate: Background { // Keep in sync with NotificationHistory.qml
				id: card
				required property var modelData
				width: root.notifWidth
				height: childrenRect.height + 6

				Text {
					id: cardTime
					property int daysAgo: Math.round((modelData.time - Clock.time) / (24 * 60 * 60 * 1000))
					anchors.top: parent.top
					anchors.right: parent.right
					anchors.topMargin: 2
					anchors.rightMargin: 5
					horizontalAlignment: Text.AlignRight
					text: {
						let days;
						switch (daysAgo) {
						case 0:
							days = "today\n";
							break;
						case 1:
							days = "yesterday\n";
						default:
							days = daysAgo + " days ago\n";
						}
						return days + Qt.formatDateTime(modelData.time, "hh:mm:ss");
					}
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
					font.pixelSize: 14
				}

				Text {
					id: cardBody
					anchors.left: parent.left
					anchors.top: cardSummary.bottom
					anchors.topMargin: 5
					anchors.leftMargin: 6

					width: root.notifWidth - 6
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
								if (card.modelData.resident) {
									card.modelData.expirationTimer.running = false;
								} else {
									card.modelData.dismiss();
									card.modelData.tracked = false;
								}
							}
						}
					}
				}

				property Timer expirationTimer: Timer {
					interval: parent.modelData.expireTimeout > 0 ? parent.modelData.expireTimeout * 1000 : 4000
					running: root.expire
					repeat: false

					onTriggered: parent.modelData.expire()
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
			notification.time = new Date();
			if (!notification.transient) {
				notification.Retainable.lock();
				root.notifications.set(notification, true);
				root.notificationsWasModified();
			}
		}
	}
}
