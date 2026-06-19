import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../modules"

PopupWindow {
	id: root
	visible: false
	required property var item
	required property Component content
	property point offset: Qt.point(0, 0)
	property real offsetX: offset.x
	property real offsetY: offset.y

	property var grab: HyprlandFocusGrab {
		windows: [root]
		onActiveChanged: if (!active) root.visible = false
	}
	onVisibleChanged: grab.active = visible

	anchor.item: item
	anchor.rect.x: item.width / 2 - width / 2 + offsetX
	anchor.rect.y: item.height + offsetY

	implicitWidth: bg.implicitWidth
	implicitHeight: bg.implicitHeight

	color: "transparent"

	Background {
		id: bg
		implicitWidth: loader.implicitWidth + 12
		implicitHeight: loader.implicitHeight + 12

		Loader {
			id: loader
			anchors.centerIn: parent
			sourceComponent: root.content
		}
	}
}
