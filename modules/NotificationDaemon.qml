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
	property var respawned: new Array()
	property real notifWidth: 300
	property real notifHeight: 80
	property bool expire: true

	function notificationsWasModified() {
		notificationsList = [...notifications.keys()].sort((a, b) => b.time - a.time);
	}

	onNotificationsListChanged: notificationsList = notificationsList.filter(x => x != null)

	function getNotification(id: int): Notification {
		let n;
		id = id || undefined;
		if (typeof id == "number") {
			n = notificationsList.find(x => x.id == id);
		} else {
			n = notificationsList.find(x => !respawned.includes(x));
		}
		return n;
	}

	function getIds(): var {
		return notificationsList.map(x => x.id) ?? new Array();
	}

	IpcHandler {
		target: "notifications"

		function test(): void {
			Util.inspect(root.respawned);
		}

		function respawn(id: int): string {
			const n = root.getNotification(id);
			if (n != undefined) {
				if (root.respawned.find(x => x == n)) {
					return "Notification already respawned";
				}
				n.despawn = function () {
					root.respawned = root.respawned.filter(x => x != n);
					n.Retainable.unlock();
				};
				n.Retainable.lock();
				root.respawned = [...root.respawned, n];
				return "Success";
			} else {
				return "Notification not found";
			}
		}

		function activate(id: int, identifier: string): string {
			const n = root.getNotification(id);
			if (n != undefined) {
				identifier = indentifier ?? "default";
				const action = n.actions.find(x => x.identifier == identifier);
				if (action != undefined) {
					action.invoke();
					return "Success";
				}
				return "Action not found";
			} else {
				return "Notification not found";
			}
		}

		function dismiss(id: int): string {
			const n = root.getNotification(id);
			if (n != undefined) {
				if (n.tracked == true) {
					n.dismiss();
				} else {
					n.despawn();
				}
				return "Success";
			} else {
				return "Notification not found";
			}
		}
	}

	MouseArea {
		anchors.fill: parent
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

		ListView {
			id: notifCards
			anchors.fill: parent
			model: server.trackedNotifications.values.concat(root.respawned)
			spacing: 6

			onModelChanged: if (model.length == 0) {
				root.expire = true;
			}

			delegate: NotificationCard {
				id: card
				notifWidth: root.notifWidth
				expire: root.expire

				MouseArea {
					anchors.fill: parent
					acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
					onClicked: mouse => {
						const notification = card.modelData;
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
								notification.despawn();
							}
						}
					}
				}

				GridLayout {
					id: buttons
					property var actions: card.modelData.actions.filter(x => x.identifier != "default")
					anchors.top: parent.cardBody.bottom
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
