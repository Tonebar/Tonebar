return {

	LrSdkVersion = 6.0,
	LrSdkMinimumVersion = 6.0,

	LrToolkitIdentifier = 'com.example.remotesliderscontrol',
	LrPluginName = 'Remote Slider Control',

	-- Runs once when the plugin loads (catalog opens with plugin enabled).
	-- This is what auto-starts the socket listener so the user doesn't
	-- have to click anything.
	LrInitPlugin = 'Init.lua',

	LrExportMenuItems = {
		{
			title = 'Remote Slider Control: Show Status',
			file = 'ShowStatus.lua',
		},
		{
			title = 'Remote Slider Control: Restart Listener',
			file = 'RestartServer.lua',
		},
	},

	VERSION = { major = 0, minor = 1, revision = 0, build = 1 },
}
