import QtQuick

Item {
	property var owner: parent

	anchors.centerIn: owner

	Rectangle {
		anchors.centerIn: parent
		height: 1
		width: parent.owner.width
	}

	Rectangle {
		anchors.centerIn: parent
		height: parent.owner.height
		width: 1
	}
}
