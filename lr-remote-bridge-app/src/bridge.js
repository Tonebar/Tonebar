'use strict';

/*
 * Same Wi-Fi bridge behavior as the standalone lr-remote-bridge/server.js,
 * adapted to run as a background service inside Electron instead of a
 * terminal script:
 *   - Status is reported via a callback instead of console.log, so the
 *     tray menu can reflect it live.
 *   - The pairing token is stored under Electron's app.getPath('userData')
 *     rather than next to the script, since a packaged app's own install
 *     directory isn't writable.
 */

const net = require('net');
const os = require('os');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const WebSocket = require('ws');
const { app } = require('electron');

const WS_PORT = 8765;
const LR_HOST = '127.0.0.1';
const LR_PORT = 41102;
const MIN_INTERVAL_MS = 16; // roughly 60 updates/sec per slider

const TOKEN_FILE = path.join(app.getPath('userData'), 'bridge-token.txt');

function loadOrCreateToken() {
  try {
    const existing = fs.readFileSync(TOKEN_FILE, 'utf8').trim();
    if (existing) return existing;
  } catch (e) {
    // no token file yet -- fall through and create one
  }
  const generated = crypto.randomBytes(4).toString('hex');
  try {
    fs.writeFileSync(TOKEN_FILE, generated, 'utf8');
  } catch (e) {
    // Not fatal -- the token just won't survive a restart this time.
  }
  return generated;
}

const TOKEN = loadOrCreateToken();

let lrSocket = null;
let lrConnected = false;
let lrRetryDelay = 500;
let wss = null;
let running = false;
let notify = () => {};
const clients = new Set();
const lastSentAt = new Map();

function getLanAddresses() {
  const nets = os.networkInterfaces();
  const addresses = [];
  for (const name of Object.keys(nets)) {
    for (const iface of nets[name] || []) {
      if (iface.family === 'IPv4' && !iface.internal) addresses.push(iface.address);
    }
  }
  return addresses;
}

function broadcastStatusToPhone() {
  const payload = JSON.stringify({ type: 'status', lightroomConnected: lrConnected });
  for (const client of clients) {
    if (client.readyState === WebSocket.OPEN) client.send(payload);
  }
}

function connectToLightroom() {
  const socket = net.createConnection({ host: LR_HOST, port: LR_PORT }, () => {
    lrConnected = true;
    lrRetryDelay = 500;
    broadcastStatusToPhone();
    notify();
  });

  socket.on('error', () => {
    // onclose follows; nothing extra to do here
  });

  socket.on('close', () => {
    lrConnected = false;
    lrSocket = null;
    broadcastStatusToPhone();
    notify();
    if (running) {
      setTimeout(connectToLightroom, lrRetryDelay);
      lrRetryDelay = Math.min(lrRetryDelay * 1.5, 5000);
    }
  });

  lrSocket = socket;
}

function sendToLightroom(line) {
  if (!lrSocket || !lrConnected) return false;
  lrSocket.write(line + '\n');
  return true;
}

function startBridge(onStatusChange) {
  if (running) return;
  running = true;
  notify = onStatusChange || (() => {});

  wss = new WebSocket.Server({ port: WS_PORT });

  wss.on('connection', (ws) => {
    let authed = false;
    clients.add(ws);
    ws.send(JSON.stringify({ type: 'status', lightroomConnected: lrConnected, authRequired: true }));

    ws.on('message', (raw) => {
      let msg;
      try {
        msg = JSON.parse(raw.toString());
      } catch (e) {
        return;
      }

      if (msg.type === 'auth') {
        authed = msg.token === TOKEN;
        ws.send(JSON.stringify({ type: 'authResult', ok: authed }));
        return;
      }
      if (!authed) {
        ws.send(JSON.stringify({ type: 'error', message: 'not authenticated' }));
        return;
      }

      if (msg.type === 'set' && typeof msg.key === 'string' && typeof msg.value === 'number') {
        const now = Date.now();
        const last = lastSentAt.get(msg.key) || 0;
        if (now - last < MIN_INTERVAL_MS) return;
        lastSentAt.set(msg.key, now);
        sendToLightroom(`SET ${msg.key} ${msg.value}`);
      } else if (msg.type === 'reset' && typeof msg.key === 'string') {
        sendToLightroom(`RESET ${msg.key}`);
      } else if (msg.type === 'action' && typeof msg.name === 'string') {
        sendToLightroom(`ACTION ${msg.name}`);
      }
    });

    ws.on('close', () => clients.delete(ws));
  });

  connectToLightroom();
  notify();
}

function stopBridge() {
  running = false;
  if (wss) {
    wss.close();
    wss = null;
  }
  if (lrSocket) {
    lrSocket.destroy();
    lrSocket = null;
  }
  clients.clear();
}

function getStatus() {
  return { running, lightroomConnected: lrConnected, port: WS_PORT };
}

function getToken() {
  return TOKEN;
}

function getAddresses() {
  return getLanAddresses();
}

module.exports = { startBridge, stopBridge, getStatus, getToken, getAddresses };
