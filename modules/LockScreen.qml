import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import "../widgets"

Scope {
	id: root
	property string currentText: ""
	property string promptText: "Enter password"
	readonly property string failureText: "Incorrect password"
	property bool unlockInProgress: false

	function unlocked() {
		lock.locked = false;
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
				color: Style.shade(Qt.alpha(Style.background, 1), -0.5)
			}

			TextField {
				id: passwordBox
				anchors.centerIn: parent

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
