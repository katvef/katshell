import "dotenv/config";
import * as readline from "node:readline";
import { clearInterval, setInterval } from "node:timers";
import { PreloadedUserSettings } from "discord-protos";
import https from "https";

const TOKEN = process.env.DISCORD_TOKEN;
const apiv = 10;
let status = null;
let game_activity = null;
let s = null;
let timer;
let ack_received = true;
let session_id;
let resume_gateway_url;

function httpsRequest(options, write) {
	return new Promise((resolve) => {
		let data = "";
		const req = https.request(options, (res) => {
			res.on("data", (chunk) => (data += chunk));
			res.on("end", () => resolve(data));
		});
		if (write != undefined) req.write(write);

		req.end();
	});
}

async function getSettings() {
	let settings;
	await httpsRequest({
		hostname: "discord.com",
		path: "/api/v10/users/@me/settings-proto/1",
		method: "GET",
		headers: {
			Authorization: TOKEN,
			"Content-Type": "application/json",
		},
	}).then((data) => {
		settings = PreloadedUserSettings.fromBase64(JSON.parse(data).settings);
	});
	return settings;
}

async function setStatus(status) {
	const status_settings = (await getSettings()).status;
	status_settings.status = { value: status };
	const data = JSON.stringify({
		settings: PreloadedUserSettings.toBase64({
			status: status_settings,
		}),
	});
	const req = await httpsRequest(
		{
			hostname: "discord.com",
			path: `/api/v${apiv}/users/@me/settings-proto/1`,
			method: "PATCH",
			headers: {
				Authorization: TOKEN,
				"Content-Type": "application/json",
			},
		},
		data,
	);
	return req;
}

async function setShowCurrentGame(show) {
	const status_settings = (await getSettings()).status;
	status_settings.showCurrentGame = { value: show };
	const data = JSON.stringify({
		settings: PreloadedUserSettings.toBase64({
			status: status_settings,
		}),
	});
	const req = await httpsRequest(
		{
			hostname: "discord.com",
			path: `/api/v${apiv}/users/@me/settings-proto/1`,
			method: "PATCH",
			headers: {
				Authorization: TOKEN,
				"Content-Type": "application/json",
			},
		},
		data,
	);
	return req;
}

const socket = new WebSocket(
	`${await httpsRequest({
		hostname: "discord.com",
		path: `/api/v${apiv}/gateway`,
		method: "GET",
		headers: {
			Authorization: TOKEN,
		},
	}).then((data) => JSON.parse(data).url)}?v=${apiv}`,
);

const rl = readline.createInterface({ input: process.stdin });
const validStatuses = new Set(["online", "idle", "dnd", "invisible"]);

rl.on("line", async (input) => {
	const args = input.split(" ");
	switch (args[0]) {
		case "status":
			if (validStatuses.has(args[1])) {
				setStatus(args[1]);
			}
			break;
		case "game": {
			if (args[1] == "show" || args[1] == "true") {
				setShowCurrentGame(true);
			} else if (args[1] == "hide" || args[1] == "false") {
				setShowCurrentGame(false);
			}
			break;
		}
		case "close":
			socket.close();
			rl.close();
			process.exit(0);
	}
});

socket.addEventListener("open", () => {
	socket.send(
		JSON.stringify({
			op: 2, // Identify
			d: {
				token: TOKEN,
				properties: {
					os: "Linux",
					browser: "node",
					device: "null",
				},
				intents: 0,
				capabilities: 1 << 9,
			},
		}),
	);
});

async function heartbeatCallback() {
	if (ack_received) {
		ack_received = false;
		socket.send(
			JSON.stringify({
				op: 1,
				d: s,
			}),
		);
	} else {
		socket.close();
		resume();
		console.error("connection lost");
	}
}

async function resume() {
	console.error("resuming connection");
	socket = new WebSocket(`${resume_gateway_url}?v=${apiv}`);

	socket.addEventListener("open", () => {
		socket.send(
			JSON.stringify({
				op: 6, // Resume
				d: {
					token: TOKEN,
					session_id: session_id,
					seq: s,
				},
			}),
		);
	});

	addListeners();
}

function addListeners() {
	socket.addEventListener("message", (event) => {
		const data = JSON.parse(event.data);
		switch (data.op) {
			case 10: // Hello
				timer = setInterval(heartbeatCallback, data.d.heartbeat_interval);
				s = data.s;
				break;
			case 11: // Heratbeat ACK
				s = data.s;
				ack_received = true;
				break;
			case 0: // Dispatch events
				if (data.t == "USER_SETTINGS_PROTO_UPDATE") {
					const settings = PreloadedUserSettings.fromBase64(data.d.settings.proto);
					status = settings.status.status.value;
					game_activity = settings.status.showCurrentGame.value;
					console.log(status + " " + game_activity);
				} else if (data.t == "READY") {
					const settings = PreloadedUserSettings.fromBase64(data.d.user_settings_proto);
					status = settings.status.status.value;
					game_activity = settings.status.showCurrentGame.value;
					resume_gateway_url = data.d.resume_gateway_url;
					session_id = data.d.session_id;
					console.log(status + " " + game_activity);
				} else if (data.t == "RESUMED") {
					console.error("Connection resumed");
				}
				s = data.s;
				break;
		}
	});
}

addListeners();
