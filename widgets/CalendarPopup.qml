pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import "../modules"

PopupWindow {
	required property var item
	property point offset: Qt.point(0, 0)
	property real offsetX: offset.x
	property real offsetY: offset.y

	anchor.item: item
	anchor.rect.x: item.width / 2 - width / 2 + offsetX
	anchor.rect.y: item.height + 7 + offsetY
	implicitWidth: grid.implicitWidth + 24
	implicitHeight: grid.implicitHeight + dateString.implicitHeight + 24
	visible: false

	color: "transparent"

	Background {
		id: root
		anchors.fill: parent

		Text {
			id: dateString
			anchors.horizontalCenter: parent.horizontalCenter
			anchors.bottom: grid.top
			// anchors.top: parent.top
			anchors.bottomMargin: 6
			horizontalAlignment: Text.AlignHCenter
			verticalAlignment: Text.AlignBottom

			text: Qt.formatDateTime(Clock.date, "MMMM d yyyy")
			color: Style.text
			font.bold: true
		}

		Grid {
			id: grid
			anchors.bottom: parent.bottom
			anchors.horizontalCenter: parent.horizontalCenter
			anchors.bottomMargin: 12

			horizontalItemAlignment: Grid.AlignHCenter
			verticalItemAlignment: Grid.AlignVCenter

			columns: 7
			spacing: 2

			property int days: Clock.date.getDate()

			Component.onCompleted: {
				const d = Clock.date;
				days = new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate();
			}

			// Weekday names
			Repeater {
				id: weekdays
				property list<string> days: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
				property int day: Clock.date.getDate() % 7
				property int firstDay: Clock.date.getDay()

				model: 7

				delegate: Text {
					required property int index
					text: weekdays.days[(index + weekdays.firstDay - weekdays.day) % 7]
					color: Style.text
					font.bold: true
					font.pixelSize: 10
				}
			}

			// Dates
			Repeater {
				model: parent.days

				delegate: Rectangle {
					required property int index
					property bool today: Clock.date.getDate() == index + 1

					width: 24
					height: 24
					color: today ? Style.highlight : Style.foreground
					radius: 3

					Text {
						anchors.centerIn: parent
						text: parent.index + 1
						color: parent.today ? Style.foreground : Style.text
						font.bold: parent.today
					}
				}
			}
		}
	}
}
