pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../modules"

PopupWindow {
	id: root
	required property var item
	required property var menu
	anchor.item: item
	visible: false
	grabFocus: true

	property var selectedItem: undefined
	property var items: new Array()
	property bool isSubmenu: false
	property var owningPopup
	property var submenuRefs: new Map()
	property point offset: Qt.point(0, 0)
	property real offsetX: offset.x
	property real offsetY: offset.y

	property var grab: HyprlandFocusGrab {
		windows: [root]
	}

	Item {
		property list<int> acceptedKeys: [Qt.Key_Up, Qt.Key_Down, Qt.Key_Right, Qt.Key_Left]
		focus: true
		// Keys.onPressed: event => {
		// 	switch (event.key) {
		// 	case Qt.Key_Down:
		// 		break;
		// 	}
		// 	if (!acceptedKeys.find(x => x == event.key)) {
		// 		root.visible = false;
		// 	}
		// }
	}

	anchor.rect.x: offsetX
	anchor.rect.y: offsetY

	color: "transparent"

	implicitWidth: background.implicitWidth
	implicitHeight: background.implicitHeight

	property var opener: QsMenuOpener {
		menu: root.menu
	}

	property var entries: opener.children.values

	onVisibleChanged: {
		if (visible == false && owningPopup) {
			owningPopup.submenuRefs.delete(root);
		}
		grab.active = visible;
	}

	Background {
		id: background
		anchors.fill: parent
		implicitWidth: column.implicitWidth + 12
		implicitHeight: column.implicitHeight + 12

		Loader {
			id: highlight
			active: root.selectedItem !== undefined
			sourceComponent: Rectangle {
				radius: 3
				visible: true
				color: Style.highlight
				property point position: mapFromItem(root.selectedItem.area, root.selectedItem.area.x, root.selectedItem.area.y)
				x: position.x
				y: position.y
				width: root.selectedItem.area.width
				height: root.selectedItem.area.height
			}
		}

		MouseArea {
			anchors.fill: parent

			hoverEnabled: true

			onExited: if (root.isSubmenu) {
				root.visible = false;
			}

			Column {
				id: column
				anchors.fill: parent
				anchors.margins: 6
				spacing: 4
				property bool hasIcons: false
				property bool hasCheckboxes: false

				Repeater {
					model: root.entries

					delegate: Item {
						id: entry
						required property var modelData

						implicitWidth: text.x + text.implicitWidth + (modelData.isSeparator ? 1 : 0) + 3
						height: (modelData.isSeparator ? 4 : 16)

						property var submenu: entry.modelData.hasChildren ? Qt.createQmlObject(`
						import Quickshell
						import "."

						MenuPopup {
							item: text
							menu: entry.modelData
							isSubmenu: true
							offsetY: 20
							owningPopup: root
						}
						`, entry) : null

						Loader {
							active: entry.modelData.icon != ""
							sourceComponent: Image {
								id: icon
								source: entry.modelData.icon
								sourceSize: Qt.size(16, 16)
								Component.onCompleted: column.hasIcons = true
							}
						}

						Component {
							id: checkbox

							CheckBox {
								id: control
								anchors.left: background.anchorLeft
								anchors.leftMargin: icon.width
								x: 2 + (column.hasIcons ? 16 : 0)

								checkState: entry.modelData.checkState

								onToggled: entry.modelData.triggered()

								indicator: Background {
									implicitHeight: 16
									implicitWidth: 16

									Text {
										anchors.centerIn: parent
										visible: control.checkState === Qt.Checked
										color: Style.border
										text: ""
										font.pixelSize: 10
									}
									Text {
										anchors.centerIn: parent
										visible: control.checkState === Qt.PartiallyChecked
										color: Style.border
										text: "━"
										font.pixelSize: 10
									}
								}

								Component.onCompleted: column.hasCheckboxes = true
							}
						}

						Component {
							id: empty
							Rectangle {
								x: 18
								color: "transparent"
								height: 16
								width: 16
							}
						}

						Loader {
							id: maybeCheckbox
							sourceComponent: entry.modelData.buttonType == QsMenuButtonType.CheckBox ? checkbox : empty
						}

						Text {
							id: text
							x: 2 + (column.hasIcons ? 18 : 0) + (column.hasCheckboxes ? 18 : 0)
							text: entry.modelData.text
							color: Style.text
							verticalAlignment: Text.AlignVCenter

							property var area: children[0]

							MouseArea {
								hoverEnabled: true
								height: 18
								property real pad: 1
								x: -pad
								width: column.width - text.x + pad 

								onEntered: {
									if (!entry.modelData.isSeparator) {
										text.color = Style.background;
										root.selectedItem = text;
									}
									if (entry.submenu != null && entry.submenu.opener.children.values.length > 0) {
										if (root.submenuRefs.size > 0) {
											for (let ref of root.submenuRefs) {
												if (ref[0] !== entry.submenu) {
													ref[0].visible = false;
													root.submenuRefs.delete(ref[0]);
												}
											}
										}
										entry.submenu.visible = true;
										root.submenuRefs.set(entry.submenu, true);
									}
								}

								onExited: {
									text.color = Style.text;
									if (!entry.modelData.isSeparator) {
										root.selectedItem = undefined;
									}
									console.log(text.area);
								}

								onClicked: root.handleClick(entry.modelData)
							}
						}
					}
				}
			}
		}
	}

	function handleClick(modelData) {
		modelData.triggered();
		root.visible = false;
		for (let child of column.children) {
			if (child.submenu) {
				child.submenu.visible = false;
			}
		}
		if (owningPopup) {
			owningPopup.visible = false;
		}
	}
}
