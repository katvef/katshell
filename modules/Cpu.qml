pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
	id: root

	property int precision: 3

	property var previous: ({})
	property var usage: ({})
	property string cpuUsage: usage["cpu"] || "?"

	property Timer timer: Timer {
		interval: 1000
		running: true
		repeat: true

		onTriggered: cpuProcess.running = true
	}

	property Process process: Process {
		id: cpuProcess

		command: ["rg", `^cpu`, "/proc/stat"]

		stdout: StdioCollector {
			onStreamFinished: {
				const usage = {};
				const previous = {};

				const data = text.split('\n');
				data.pop()

				for (const line of data) {
					const parts = line.trim().split(/\s+/);

					const key = parts[0];
					const user = Number(parts[1]);
					const nice = Number(parts[2]);
					const system = Number(parts[3]);
					const idle = Number(parts[4]);
					const iowait = Number(parts[5]);
					const irq = Number(parts[6]);
					const softirq = Number(parts[7]);
					const steal = Number(parts[8]);
					const guest = Number(parts[9]);
					const guest_nice = Number(parts[10]);

					const busy = user + nice + system + irq + softirq + steal + guest + nice;
					const idling = idle + iowait;

					if (root.previous[key] !== undefined) {
						const previousBusy = root.previous[key][0];
						const previousIdle = root.previous[key][1];
						const busyDiff = busy - previousBusy;
						const idleDiff = idling - previousIdle;
						const total = busyDiff + idleDiff;

						const use = ((busyDiff / total) * 100);
						usage[key] = use.toPrecision(root.precision - (use < 1));
					}

					previous[key] = [busy, idling];
				}

				root.usage = usage;
				root.previous = previous;
			}
		}
	}
}
