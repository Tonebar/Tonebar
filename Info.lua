local LrDialogs = import 'LrDialogs'
local LrTasks = import 'LrTasks'

local server = _G.RemoteSliderControlServer

if server then
	server.stop()
	LrTasks.startAsyncTask(function()
		LrTasks.sleep(0.5) -- give the old socket a moment to release the port
		server.start()
		LrDialogs.showBezel('Remote Slider Control listener restarted', 2)
	end)
end
