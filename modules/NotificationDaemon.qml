pragma Singleton
import QtQuick
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
	property bool noExpire: false

	// onDestroyed:

	ListView {
		id: notifCards
		anchors.fill: parent
		model: server.trackedNotifications.values
		spacing: 6

		delegate: Background {
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

			property Timer expirationTimer: Timer {
				interval: (parent.modelData.expireTimeout > 0 ? parent.modelData.expireTimeout * 1000 : 4000)
				running: true
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
					root.noExpire = true;
					break;
				case Qt.LeftButton:
					notification.dismiss();
					notification.tracked = false;
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
