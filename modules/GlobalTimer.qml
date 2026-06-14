pragma Singleton
import QtQuick

Timer {
	interval: 1000
	repeat: true
	running: true
	property var actions: []
	onTriggered: {
		for (let action of actions) {
			action()
		}
	}

	function addAction(fun) {
		if (typeof(fun) == "function") {
			actions.push(fun)
			return(actions)
		} else {
			throw new Error("Not a function: " + fun)
		}
	}
}
