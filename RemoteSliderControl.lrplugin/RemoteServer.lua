--[[
	RemoteServer

	Opens an LrSocket "receive" listener and applies incoming text commands
	to the Develop module via LrDevelopController.

	IMPORTANT CAVEAT: LrSocket.bind only opens a socket on localhost -- it
	cannot accept connections arriving from another device over Wi-Fi.
	That means the phone app can't connect to this port directly. You'll
	need a small relay running on the same computer (the "Wi-Fi bridge")
	that listens on the LAN for the phone and forwards each line to
	127.0.0.1:PORT, where this listener picks it up. This plugin is only
	the Lightroom-facing half of the system.

	Protocol (newline-terminated ASCII lines):
		SET <key> <value>      e.g.  SET exposure 1.35
		RESET <key>             e.g.  RESET contrast
		ACTION <name>            e.g.  ACTION pick
]]

local LrSocket           = import 'LrSocket'
local LrTasks            = import 'LrTasks'
local LrFunctionContext  = import 'LrFunctionContext'
local LrDevelopController = import 'LrDevelopController'
local LrApplicationView  = import 'LrApplicationView'
local LrSelection        = import 'LrSelection'
local LrUndo             = import 'LrUndo'
local LrApplication      = import 'LrApplication'

local ParamMap = require 'ParamMap'
local DevelopClipboard = require 'DevelopClipboard'
local actions = ParamMap.buildActions(LrDevelopController, LrSelection, LrUndo, LrApplication)

local RemoteServer = {}

RemoteServer.PORT = 41102
RemoteServer.running = false
RemoteServer.status = 'stopped'

local function clamp(v, lo, hi)
	if v < lo then return lo end
	if v > hi then return hi end
	return v
end

-- Our phone app's Temp slider is a relative -100..100 "cooler <-> warmer"
-- control, but Lightroom's real Temperature parameter is an absolute
-- color temperature in Kelvin, and the *valid range* for that varies by
-- photo (RAW/DNG support a huge range; other formats are documented to
-- behave differently and may support a much narrower window). Rather than
-- assume a fixed range, we ask Lightroom for the real one each time via
-- getRange() and scale our slider to fit it.
local function temperatureFromSlider(sliderValue)
	local minK, maxK = LrDevelopController.getRange('Temperature')
	local baseline = (minK + maxK) / 2
	local halfSpan = (maxK - minK) / 2
	local kelvin = baseline + (sliderValue / 100) * halfSpan
	return clamp(kelvin, minK, maxK)
end

local function applyCommand(line)
	line = line:gsub('%s+$', '')
	if line == '' then return end

	local cmd, rest = line:match('^(%u+)%s*(.*)$')
	if not cmd then return end

	if cmd == 'SET' then
		LrApplicationView.switchToModule('develop')
		local key, value = rest:match('^(%S+)%s+(%-?%d+%.?%d*)$')
		if key and value then
			local numValue = tonumber(value)
			if key == 'temp' then
				LrDevelopController.setValue('Temperature', temperatureFromSlider(numValue))
			else
				local lrParam = ParamMap.toLightroom[key]
				if lrParam then
					LrDevelopController.setValue(lrParam, numValue)
				end
			end
		end

	elseif cmd == 'RESET' then
		LrApplicationView.switchToModule('develop')
		local key = rest:match('^(%S+)$')
		local lrParam = (key == 'temp') and 'Temperature' or ParamMap.toLightroom[key]
		if lrParam then
			-- Lightroom's own per-parameter reset. This correctly falls back
			-- to each parameter's real default (e.g. the photo's as-shot
			-- white balance for Temperature) instead of us guessing what
			-- "reset" should mean -- which is what was causing Temperature
			-- to behave inconsistently versus other sliders.
			LrDevelopController.resetToDefault(lrParam)
		end

	elseif cmd == 'ACTION' then
		local name = rest:match('^(%S+)$')
		local DEVELOP_ONLY_ACTIONS = { auto = true, clipping = true }
		if name and DEVELOP_ONLY_ACTIONS[name] then
			LrApplicationView.switchToModule('develop')
		end

		if name == 'copy_settings' then
			DevelopClipboard.copy()
		elseif name == 'paste_settings' then
			DevelopClipboard.paste()
		else
			local fn = name and actions[name]
			if fn then fn() end
		end
	end
end

function RemoteServer.start()
	if RemoteServer.running then return end

	LrTasks.startAsyncTask(function()
		LrFunctionContext.callWithContext('remote_slider_control_server', function(context)
			RemoteServer.running = true

			-- Some Lightroom subsystems (switching Develop module, binding
			-- a socket) aren't reliably ready the instant this plugin
			-- loads at Lightroom's own cold-start -- that was silently
			-- killing this whole task on first launch, leaving status
			-- stuck at its default "stopped" until someone noticed and
			-- clicked Restart Listener by hand. Retrying a few times with
			-- a short pause makes this self-healing instead.
			local receiver = nil
			local attempts = 0
			while RemoteServer.running and not receiver and attempts < 15 do
				attempts = attempts + 1
				RemoteServer.status = attempts == 1 and 'starting' or ('starting (retry ' .. attempts .. ')')

				local ok, result = pcall(function()
					-- Make sure Develop-only calls (setValue, setAutoTone,
					-- etc.) have somewhere valid to act.
					LrApplicationView.switchToModule('develop')

					-- IMPORTANT: reuse the same socket via :reconnect()
					-- when the bridge disconnects, rather than creating a
					-- brand new LrSocket.bind() on the same port. This is
					-- the pattern shown in Adobe's own example plugins --
					-- binding a fresh socket to a port that was just
					-- released can fail to actually start listening
					-- again, which is what was causing the "still says
					-- listening, but never actually connects" symptom.
					return LrSocket.bind {
						functionContext = context,
						plugin = _PLUGIN,
						port = RemoteServer.PORT,
						mode = 'receive',

						onConnecting = function(_, port)
							RemoteServer.status = 'listening on 127.0.0.1:' .. tostring(port)
						end,

						onConnected = function(_, _)
							RemoteServer.status = 'bridge connected'
						end,

						onMessage = function(_, message)
							local msgOk, msgErr = pcall(applyCommand, message)
							if not msgOk then
								RemoteServer.status = 'error: ' .. tostring(msgErr)
							end
						end,

						onClosed = function(socket)
							RemoteServer.status = 'bridge disconnected, reconnecting...'
							if RemoteServer.running then
								socket:reconnect()
							end
						end,

						onError = function(socket, err)
							if err == 'timeout' then
								if RemoteServer.running then socket:reconnect() end
							else
								RemoteServer.status = 'socket error: ' .. tostring(err)
							end
						end,
					}
				end)

				if ok then
					receiver = result
				else
					LrTasks.sleep(1)
				end
			end

			if not receiver then
				RemoteServer.status = 'failed to start after retries -- try Restart Listener'
				RemoteServer.running = false
				return
			end

			while RemoteServer.running do
				LrTasks.sleep(0.2)
			end

			receiver:close()
			RemoteServer.status = 'stopped'
		end)
	end)
end

function RemoteServer.stop()
	RemoteServer.running = false
end

return RemoteServer
