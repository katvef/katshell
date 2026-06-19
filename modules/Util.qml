pragma Singleton
import QtQuick

QtObject {
	function inspect(obj) {
		if (obj instanceof Map) {
			for (let entry of obj) {
				console.log(entry);
			}
		} else {
			for (let key in obj) {
				console.log(key, obj[key]);
			}
		}
	}
}
