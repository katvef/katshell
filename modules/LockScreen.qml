import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import "../widgets"

Scope {
	id: root
	property bool passwordBoxVisible: false
	property string currentText: ""
	property string promptText: "Enter password"
	readonly property string failureText: "Incorrect password"
	property bool unlockInProgress: false

	function unlocked() {
		lock.locked = false;
	}

	function showPasswordBox() {
		root.passwordBoxVisible = true;
		hidePasswordBox.running = true;
	}

	Timer {
		id: hidePasswordBox
		interval: 10000
		repeat: false
		onTriggered: root.passwordBoxVisible = false
	}

	signal failed

	function tryUnlock() {
		if (currentText === "")
			return;

		root.unlockInProgress = true;
		pam.start();
	}

	PamContext {
		id: pam

		configDirectory: Quickshell.shellDir + "/pam"
		config: "password.conf"

		onPamMessage: {
			if (this.responseRequired) {
				this.respond(root.currentText);
			}
		}

		onCompleted: result => {
			if (result == PamResult.Success) {
				root.unlocked();
			} else {
				root.currentText = "";
				root.failed();
			}

			root.unlockInProgress = false;
		}
	}

	WlSessionLock {
		id: lock

		WlSessionLockSurface {
			id: surface
			color: "transparent"

			Rectangle {
				anchors.fill: parent
				anchors.horizontalCenter: parent.horizontalCenter
				color: Style.shade(Qt.alpha(Style.background, 1), -0.5)
			}

			MouseArea {
				anchors.fill: parent
				hoverEnabled: true
				acceptedButtons: Qt.NoButton
				onPositionChanged: root.showPasswordBox()
			}

			Text {
				id: time
				anchors.topMargin: surface.height / 5
				anchors.horizontalCenter: parent.horizontalCenter
				anchors.top: parent.top
				text: Qt.formatDateTime(Clock.date, "hh:mm:ss")
				color: "white"
				font.pointSize: 60
			}

			Text { // Date
				anchors.horizontalCenter: parent.horizontalCenter
				anchors.top: time.bottom
				text: Qt.formatDateTime(Clock.date, "MMMM d yyyy")
				color: Qt.alpha("white", 0.5)
				font.pointSize: 30
			}

			Text {
				id: uptime
				anchors.bottom: parent.bottom
				anchors.right: parent.right
				anchors.margins: 10

				text: ""
				color: "white"
				font.pointSize: 25

				Timer {
					interval: 1000
					running: true
					triggeredOnStart: true
					onTriggered: uptimeProc.running = true
				}

				Process {
					id: uptimeProc
					command: ["uptime", "-p"]
					stdout: StdioCollector {
						onStreamFinished: uptime.text = this.text
					}
				}
			}

			TextField {
				id: passwordBox
				visible: root.passwordBoxVisible
				anchors.bottomMargin: surface.height / 7 * 2
				anchors.bottom: parent.bottom
				anchors.horizontalCenter: parent.horizontalCenter

				implicitWidth: 400
				padding: 10
				focus: true
				enabled: !root.unlockInProgress
				echoMode: TextInput.Password
				inputMethodHints: Qt.ImhSensitiveData
				placeholderText: root.promptText
				placeholderTextColor: Style.bright

				background: Background {
					anchors.fill: parent
				}

				onTextChanged: {
					root.currentText = this.text;
					root.showPasswordBox();
					passwordBox.placeholderText = root.promptText;
					passwordBox.placeholderTextColor = Style.bright;
				}

				onAccepted: root.tryUnlock()

				Connections {
					target: root

					function onCurrentTextChanged() {
						passwordBox.text = root.currentText;
					}

					function onFailed() {
						passwordBox.placeholderText = root.failureText;
						passwordBox.placeholderTextColor = Style.red;
					}
				}
			}
		}
	}

	IpcHandler {
		target: "lockscreen"
		function lock(): void {
			lock.locked = true;
		}
	}
}
