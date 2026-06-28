import "dotenv/config";
import * as readline from "node:readline";
import { setInterval } from "node:timers";
import { PreloadedUserSettings } from "discord-protos";
import https from "https";

const TOKEN = process.env.DISCORD_TOKEN;
const apiv = 10;
let status = null;
let s = null;
let timer;
let ack_received = true;

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

async function setStatus(status) {
	const data = JSON.stringify({
		settings: PreloadedUserSettings.toBase64({
			status: {
				status: { value: status },
				statusExpiresAtMs: 0n, // Having this unset causes errors due to it being parsed as undefined
			},
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
	}).then((data) => JSON.parse(data).url)}?v=${apiv}`,
);

const rl = readline.createInterface({ input: process.stdin });
const validStatuses = new Set(["online", "idle", "dnd", "invisible"]);

rl.on("line", async (input) => {
	const args = input.split(" ");
	switch (args[0]) {
		case "set":
			if (validStatuses.has(args[1])) {
				setStatus(...args.slice(1));
			}
			break;
		case "close":
			socket.close();
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

function heartbeatCallback() {
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
	}
}

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
				console.log(status);
			} else if (data.t == "READY") {
				const settings = PreloadedUserSettings.fromBase64(data.d.user_settings_proto);
				status = settings.status.status.value;
				console.log(status);
			}
			break;
	}
});
