pragma Singleton
import QtQuick

QtObject {
	function inspectObject(obj) {
		for (let key in obj) {
			console.log(key, obj[key]);
		}
	}
	function inspectMap(map) {
		for (let entry of map) {
			console.log(entry);
		}
	}
}
