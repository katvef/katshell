pragma Singleton
import QtQml
import QtQuick
import Quickshell.Io

QtObject {
	id: root

	property string unit: "B"
	property int precision: 3

	readonly property var units: ({
			"B": 1,
			"KB": 1024,
			"MB": 1024 ** 2,
			"GB": 1024 ** 3,
			"TB": 1024 ** 4
		})

	function sizeToBits(sizestr) {
		if (typeof (sizestr) != "string") {
			throw new Error("Invalid size string " + sizestr);
		}
		const match = sizestr.trim().match(/^([\d.]+)\s*(b|Kb|Mb|Gb|Tb)$/i);
		if (!match || !match[2]) {
			throw new Error("Invalid size format " + sizestr);
		}

		const value = parseFloat(match[1]);
		const unit = match[2].toUpperCase();

		return value * units[unit];
	}

	function sizeToUnit(sizestr, unit, precision) {
		const size = sizeToBits(sizestr);
		let value = (size / units[unit]);
		if (precision) {
			value = value.toPrecision(precision);
		}
		return value + " " + unit;
	}

	property Timer timer: Timer {
		interval: 1000
		running: true
		repeat: true

		onTriggered: memProcess.running = true
	}

	property var memInfo: new Object({
		memTotal: "0 B",
		memFree: "0 B",
		memAvailable: "0 B",
		memUsed: "0 B",
		swapCached: "0 B",
		swapTotal: "0 B",
		swapFree: "0 B",
		swapUsed: "0 B",
		zswap: "0 B",
		zswapped: "0 B",
	})

	property Process process: Process {
		id: memProcess
		running: true

		command: ["cat", "/proc/meminfo"]

		stdout: StdioCollector {
			onStreamFinished: {
				const memInfoMap = new Map(text.split('\n').filter(x => x.match(/Swap|Mem|Zswap/)).map(x => x.split(/:\s+/)));
				const memInfoObj = new Object();
				memInfoMap.forEach((v, k) => {
					v = root.sizeToUnit(v, root.unit);
					memInfoMap.set(k, v);
				});
				memInfoMap.set("MemUsed", ((root.sizeToBits(memInfoMap.get('MemTotal')) - root.sizeToBits(memInfoMap.get('MemAvailable'))) / root.units[root.unit]) + " " + root.unit);
				memInfoMap.set("SwapUsed", ((root.sizeToBits(memInfoMap.get('SwapTotal')) - root.sizeToBits(memInfoMap.get('SwapFree'))) / root.units[root.unit]) + " " + root.unit);
				for (const [k, v] of memInfoMap.entries()) {
					const name = k[0].toLowerCase() + k.slice(1);
					memInfoObj[name] = v;
				}
				memInfo = memInfoObj;
			}
		}
	}

	Component.onCompleted: process.running = true
}
