'use strict';

const { app, Tray, Menu, nativeImage, clipboard, shell } = require('electron');
const path = require('path');
const fs = require('fs');
const os = require('os');
const { startBridge, stopBridge, getStatus, getToken, getAddresses } = require('./bridge');

let tray = null;
let refreshIntervalId = null;

// A plain app.quit() asks Electron to go through its normal graceful
// shutdown -- but for a menu-bar-only ("accessory") app on macOS, that
// sequence can silently stall (commonly the Tray object or a still-running
// setInterval holding things open), leaving the process and menu bar icon
// behind even though before-quit already ran and stopped the bridge. Doing
// the cleanup ourselves and forcing an immediate process exit sidesteps
// that instead of hoping the graceful path completes.
function quitForReal() {
  stopBridge();
  if (refreshIntervalId) clearInterval(refreshIntervalId);
  if (tray) tray.destroy();
  app.exit(0);
}

// Copies the bundled plugin folder out to the user's Documents the first
// time it's needed, then reveals it in Finder/Explorer. Lightroom Classic
// has no "drop it here and it just works" plugin folder on any platform --
// every third-party plugin is added manually via Plug-in Manager -- so this
// gets the user to a folder they can point Plug-in Manager at, which is as
// far as this can be automated.
function revealPlugin() {
  const bundledInsideAsar = path.join(__dirname, '..', 'assets', 'RemoteSliderControl.lrplugin');
  // In a packaged app, __dirname points inside the sealed app.asar archive.
  // Simple reads (readFile, etc.) get transparently redirected by Electron
  // to the real files, but fs.cpSync's recursive directory walk doesn't
  // reliably follow that redirection -- it silently copies nothing from a
  // path that, as far as it's concerned, doesn't really contain files.
  // asarUnpack (see package.json) puts real copies in the sibling
  // app.asar.unpacked folder; pointing there directly sidesteps the
  // problem instead of relying on Electron's auto-redirection. In dev mode
  // (`npm start`) there's no app.asar at all, so this replace is a no-op.
  const bundled = bundledInsideAsar.replace('app.asar', 'app.asar.unpacked');
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
    { label: 'Bridge address (also discoverable automatically):', enabled: false },
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
    { label: 'Quit', click: quitForReal },
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
  refreshIntervalId = setInterval(refreshMenu, 5000);
});

app.on('window-all-closed', () => {
  // Intentionally a no-op -- this app only lives in the tray, there are no
  // windows to close, and it should keep running (and keep Lightroom
  // reachable) even with nothing else open.
});

// Covers quit triggered any other way than the menu item (Cmd+Q, Dock
// right-click Quit, etc.) so it's forceful there too, not just from our own
// menu -- otherwise those paths would still hit the original stuck-graceful-
// shutdown problem.
app.on('before-quit', (event) => {
  event.preventDefault();
  quitForReal();
});
