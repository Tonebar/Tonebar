local LrDialogs = import 'LrDialogs'

local server = _G.RemoteSliderControlServer

if not server then
	LrDialogs.message('Remote Slider Control', 'Server module has not loaded yet.', 'warning')
else
	LrDialogs.message(
		'Remote Slider Control',
		'Status: ' .. tostring(server.status) ..
		'\nPort: ' .. tostring(server.PORT) ..
		'\n\nRemember: this listens on localhost only. The phone app ' ..
		'connects to a separate Wi-Fi bridge, which forwards commands ' ..
		'to this port.',
		'info'
	)
end
