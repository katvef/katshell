import QtQuick
import "../modules"

Background { // Keep in sync with NotificationHistory.qml
	id: card
	required property var modelData
	required property real notifWidth
	required property bool expire

	width: notifWidth
	height: childrenRect.height + 6

	property var cardTime: cardTime
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

	property var image: image
	Image {
		id: image
		anchors.top: parent.top
		anchors.left: parent.left
		anchors.leftMargin: 4
		source: modelData.image
		anchors.verticalCenter: cardSummary.verticalCenter
		height: 24
		width: source == "" ? 0 : 24
		fillMode: Image.PreserveAspectFit
	}

	property var cardSummary: cardSummary
	Text {
		id: cardSummary
		anchors.left: image.right
		anchors.top: parent.top
		anchors.right: cardTime.left
		anchors.leftMargin: 6
		anchors.topMargin: 6

		width: card.notifWidth - 6
		wrapMode: Text.Wrap
		color: Style.text
		textFormat: Text.PlainText
		text: modelData.summary
		font.pixelSize: 14
	}

	property var cardBody: cardBody
	Text {
		id: cardBody
		anchors.left: parent.left
		anchors.top: image.bottom
		anchors.topMargin: 5
		anchors.leftMargin: 6

		width: card.notifWidth - 6
		wrapMode: Text.Wrap
		color: Style.text
		textFormat: Text.StyledText
		text: modelData.body
	}

	property Timer expirationTimer: Timer {
		interval: parent.modelData.expireTimeout > 0 ? parent.modelData.expireTimeout * 1000 : 4000
		running: card.expire
		repeat: false

		onTriggered: parent.modelData.expire()
	}
}
