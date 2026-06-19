import Quickshell.Services.Pipewire
import QtQuick
import "../modules"

Text {
	id: root
	required property PwNode node
	property int precision: 3
	property bool muted: node?.audio ? node.audio.muted : false
	property list<string> icons: [] // 4 states: muted, volume 0-33%, volume 34-66%, volume 67+%. Indexed in listed order
	property string activeIcon: ""
	property real volume: node?.audio ? node.audio.volume : 0
	property bool padInteger: true
	property string volumePercentage: (volume * 100).toPrecision(precision)
	property string volumeFloat: volume.toPrecision(precision)
	property string volumeInteger: _formatVolumeInteger(volume)

	PwObjectTracker {
		objects: [root.node]
	}

	color: Style.text

	function _formatVolumeInteger() {
		const vol = Math.round(volume * 100);
		let ret = vol.toString();
		if (padInteger) {
			const padding = precision - vol.toString().length;
			if (padding > 0) {
				ret = " ".repeat(padding) + ret;
			}
		}
		return ret;
	}

	function updateIcon() {
		if (muted == true) {
			activeIcon = icons[0];
		} else if (volume <= 1 / 3) {
			activeIcon = icons[1];
		} else if (volume <= 2 / 3) {
			activeIcon = icons[2];
		} else {
			activeIcon = icons[3];
		}
	}

	onVolumeChanged: updateIcon()
	onMutedChanged: updateIcon()
}
