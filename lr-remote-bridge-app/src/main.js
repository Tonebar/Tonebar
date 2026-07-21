'use strict';

const { app, Tray, Menu, nativeImage, clipboard, shell } = require('electron');
const path = require('path');
const fs = require('fs');
const os = require('os');
const { startBridge, stopBridge, getStatus, getToken, getAddresses } = require('./bridge');

let tray = null;

// Copies the bundled plugin folder out to the user's Documents the first
// time it's needed, then reveals it in Finder/Explorer. Lightroom Classic
// has no "drop it here and it just works" plugin folder on any platform --
// every third-party plugin is added manually via Plug-in Manager -- so this
// gets the user to a folder they can point Plug-in Manager at, which is as
// far as this can be automated.
function revealPlugin() {
  const bundled = path.join(__dirname, '..', 'assets', 'RemoteSliderControl.lrplugin');
  const dest = path.join(os.homedir(), 'Documents', 'RemoteSliderControl.lrplugin');

  try {
    if (!fs.existsSync(dest)) {
      fs.cpSync(bundled, dest, { recursive: true });
    }
    shell.showItemInFolder(dest);
  } catch (e) {
    shell.showItemInFolder(bundled);
  }
}

function buildMenu() {
  const status = getStatus();
  const addresses = getAddresses();
  const token = getToken();

  const addressItems = addresses.length
    ? addresses.map((a) => ({
        label: `ws://${a}:${status.port}  (click to copy)`,
        click: () => clipboard.writeText(`ws://${a}:${status.port}`),
      }))
    : [{ label: 'No network address found', enabled: false }];

  const connectionLabel = status.lightroomConnected
    ? '●  Connected to Lightroom'
    : status.running
    ? '○  Waiting for Lightroom plugin...'
    : '○  Stopped';

  return Menu.buildFromTemplate([
    { label: connectionLabel, enabled: false },
    { type: 'separator' },
    { label: 'Bridge address:', enabled: false },
    ...addressItems,
    { type: 'separator' },
    { label: `Pairing token: ${token}`, click: () => clipboard.writeText(token) },
    { label: 'Copy token', click: () => clipboard.writeText(token) },
    { type: 'separator' },
    { label: 'Reveal Lightroom plugin folder...', click: revealPlugin },
    {
      label: 'Restart bridge',
      click: () => {
        stopBridge();
        startBridge(refreshMenu);
      },
    },
    { type: 'separator' },
    {
      label: 'Start at login',
      type: 'checkbox',
      checked: app.getLoginItemSettings().openAtLogin,
      click: (menuItem) => app.setLoginItemSettings({ openAtLogin: menuItem.checked }),
    },
    { type: 'separator' },
    { label: 'Quit', click: () => app.quit() },
  ]);
}

function refreshMenu() {
  if (tray) tray.setContextMenu(buildMenu());
}

app.whenReady().then(() => {
  if (process.platform === 'darwin' && app.dock) app.dock.hide();

  const iconPath = path.join(__dirname, '..', 'assets', 'trayIconTemplate.png');
  const icon = nativeImage.createFromPath(iconPath);
  icon.setTemplateImage(true);

  tray = new Tray(icon);
  tray.setToolTip('Remote Slider Control Bridge');
  tray.setContextMenu(buildMenu());

  startBridge(refreshMenu);

  // Addresses/token don't change at runtime, but re-checking the menu
  // occasionally keeps the connection dot honest without needing every
  // single event wired up individually.
  setInterval(refreshMenu, 5000);
});

app.on('window-all-closed', () => {
  // Intentionally a no-op -- this app only lives in the tray, there are no
  // windows to close, and it should keep running (and keep Lightroom
  // reachable) even with nothing else open.
});

app.on('before-quit', () => {
  stopBridge();
});
