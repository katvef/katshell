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

			property int days: new Date(Clock.date.getUTCFullYear(), Clock.date.getUTCMonth(), 0).getUTCDate()

			// Weekday names
			Repeater {
				id: weekdays
				property list<string> days: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
				model: 7
				delegate: Text {
					required property int index
					text: weekdays.days[index]
					color: Style.text
					font.bold: true
					font.pixelSize: 10
				}
			}

			// Previous dates
			Repeater {
				id: prevDates
				property int prevDays: new Date(Clock.date.getUTCFullYear(), Clock.date.getUTCMonth() - 1, 0).getUTCDate()
				model: new Date(Clock.date.getUTCFullYear(), Clock.date.getUTCMonth()).getUTCDay()


				delegate: Rectangle {
					required property int index

					width: 24
					height: 24
					color: Qt.alpha(Style.foreground, 0.5)
					radius: 3

					Text {
						anchors.centerIn: parent
						text: prevDates.prevDays - (prevDates.model - parent.index - 1)
						color: Qt.alpha(Style.text, 0.5)
						font.bold: parent.today
					}
				}
			}

			// Dates
			Repeater {
				model: parent.days

				delegate: Rectangle {
					required property int index
					property bool today: Clock.date.getUTCDate() == index + 1

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
