//@ pragma UseQApplication
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Wayland
import "./modules"
import "./widgets"

// qmllint disable unresolved-type import
ShellRoot {
	Variants {
		model: Quickshell.screens

		// Panels
		delegate: PanelWindow { // qmllint disable uncreatable-type
			id: panel

			required property var modelData

			WlrLayershell.layer: WlrLayer.Top
			screen: modelData
			visible: true
			anchors.top: true
			anchors.left: true
			anchors.right: true
			margins.top: 2
			margins.left: 2
			margins.right: 2
			implicitHeight: 32
			color: "transparent"

			GlobalShortcut {
				appid: "bar"
				name: "toggle panel on monitor " + panel.modelData.name

				onPressed: panel.visible = !panel.visible
			}

			// Background
			Background {
				anchors.fill: parent
			}

			// Alignment {}

			// Status bar main container
			Item {
				anchors.fill: parent

				// Left
				Row {
					anchors.left: parent.left
					anchors.verticalCenter: parent.verticalCenter
					leftPadding: 6
					spacing: 6

					Workspaces {}

					// Volume
					Item {
						implicitWidth: volume.implicitWidth
						implicitHeight: volume.implicitHeight

						MouseArea {
							anchors.fill: parent

							hoverEnabled: true
							onEntered: volumePopup.visible = true

							PopupToolTip {
								id: volumePopup
								item: volume
								grabFocus: true
								// lockSize: true
								offsetY: 3

								content: MouseArea {
									hoverEnabled: true
									implicitWidth: children[0].implicitWidth
									implicitHeight: children[0].implicitHeight
									onExited: volumePopup.visible = false

									Column {
										spacing: 6

										Row {
											Text {
												text: " "
												color: Style.text
											}

											KSlider {
												anchors.verticalCenter: parent.verticalCenter
												property var audio: sink.node?.audio
												handleSize: 12
												sliderHeight: 4
												sliderWidth: 150

												from: 0
												value: audio ? audio.volume * 100 : 0
												onValueChanged: audio.volume = value / 100
												snapSize: 1
												to: 100
											}
										}

										Row {
											Text {
												text: "󰋋 "
												color: Style.text
											}
											KSlider {
												anchors.verticalCenter: parent.verticalCenter
												property var audio: source.node?.audio
												handleSize: 12
												sliderHeight: 4
												sliderWidth: 150

												from: 0
												value: audio ? audio.volume * 100 : 0
												onValueChanged: audio.volume = value / 100
												snapSize: 1
												to: 150
											}
										}
									}
								}
							}
						}

						Column {
							id: volume
							spacing: -4

							VolumeText {
								id: sink
								icons: [" ", " ", " ", " "]
								node: Pipewire.defaultAudioSource
								text: volumePercentage + "% " + (activeIcon || "")
							}

							VolumeText {
								id: source
								icons: [" ", " ", " ", " "]
								node: Pipewire.defaultAudioSink
								text: volumePercentage + "% " + (activeIcon || "")
							}
						}
					}

					// Performance
					Item {
						implicitWidth: perf.implicitWidth
						implicitHeight: perf.implicitHeight

						MouseArea {
							anchors.fill: parent
							hoverEnabled: true
							onEntered: perfTooltip.visible = true

							PopupToolTip {
								id: perfTooltip
								item: perf
								offsetY: 3
								content: MouseArea {

									hoverEnabled: true
									implicitWidth: children[0].implicitWidth
									implicitHeight: children[0].implicitHeight
									onExited: perfTooltip.visible = false

									Row {
										spacing: 12

										Grid {
											columns: 4
											columnSpacing: 4
											Repeater {
												model: Object.keys(Cpu.usage).slice(1)

												delegate: Repeater {
													id: repeater
													required property string modelData
													model: 2

													delegate: Loader {
														required property int index
														property var modelData: repeater.modelData
														sourceComponent: index == 0 ? coreText : usageText
													}
												}
											}
										}

										Column {
											Repeater {
												model: ["memTotal", "memFree", "memAvailable", "memUsed", "swapCached", "swapTotal", "swapFree", "swapUsed", "zswap", "zswapped",]

												delegate: MemText {
													required property string modelData
													color: Style.text
													text: modelData.replace(/([A-Z])/g, ' $1').toLowerCase() + ": " + Mem.sizeToUnit(Mem.memInfo[modelData], unit, precision)
												}
											}
										}
									}

									Component {
										id: coreText
										Text {
											property string core: parent.modelData
											color: Style.text
											text: `${core}:`
										}
									}

									Component {
										id: usageText
										Text {
											property string core: parent.modelData
											color: Style.text
											text: `${Cpu.usage[core]}%`
										}
									}
								}
							}
						}

						Column {
							id: perf
							spacing: -4

							CpuText {
								verticalAlignment: Text.AlignVCenter
							}
							MemText {
								verticalAlignment: Text.AlignVCenter
								text: ((Mem.sizeToBits(Mem.memInfo.memUsed) / Mem.sizeToBits(Mem.memInfo.memTotal)) * 100).toPrecision(3) + "%"
							}
						}
					}

					// CPU temperature
					Column {
						anchors.top: parent.top
						anchors.bottom: parent.bottom

						CpuTemp {
							id: cpuTemp
							font.pixelSize: 12
							anchors.horizontalCenter: parent.horizontalCenter
						}

						Rectangle {
							property int value: cpuTemp.temp
							implicitWidth: cpuTemp.implicitWidth + 2
							implicitHeight: 9

							color: {
								if (cpuTemp.temp < cpuTemp.max - 20) {
									return Style.shade(Style.green, 0.15);
								} else if (cpuTemp.temp < cpuTemp.max) {
									return Style.yellow;
								} else if (cpuTemp.temp < cpuTemp.crit) {
									return Style.orange;
								} else {
									return Style.red;
								}
							}

							Rectangle {
								anchors.right: parent.right
								implicitWidth: parent.width * (1 - parent.value / 100)
								implicitHeight: parent.implicitHeight
								color: Style.bright
							}
						}
					}
				}

				// Middle
				Row {
					id: middle

					anchors.centerIn: parent
					spacing: 20

					MediaPlayer {}

					// Clock
					Text {
						id: clock
						property bool showDate: false

						text: showDate ? Qt.formatDateTime(Clock.date, "yyyy-MM-dd") : Qt.formatDateTime(Clock.date, "hh:mm:ss")
						color: Style.text
						font.pixelSize: 14

						// Calendar popup
						CalendarPopup {
							id: calendarPopup
							item: clock
						}

						MouseArea {
							anchors.fill: parent
							cursorShape: Qt.PointingHandCursor
							hoverEnabled: true

							onClicked: parent.showDate = !parent.showDate
							onEntered: calendarPopup.visible = true
							onExited: calendarPopup.visible = false
						}
					}
				}

				// Right
				Row {
					id: right

					anchors.right: parent.right
					anchors.verticalCenter: parent.verticalCenter
					anchors.margins: 8
					spacing: 2
					layoutDirection: Qt.RightToLeft

					Tray {}
				}
			}
		}
	}
}
