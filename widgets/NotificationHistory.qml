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

	ListView {
		id: notifCards
		anchors.fill: parent
		anchors.margins: 6
		spacing: 6
		clip: true

		model: daemon.notificationsList

		delegate: NotificationCard { // Keep in sync with NotificationDaemon.qml
			notifWidth: root.width - 12
			expire: false
		}
	}
}
