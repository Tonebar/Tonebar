return {

	LrSdkVersion = 6.0,
	LrSdkMinimumVersion = 6.0,

	LrToolkitIdentifier = 'com.example.remotesliderscontrol',
	LrPluginName = 'Remote Slider Control',

	-- Runs once when the plugin loads (catalog opens with plugin enabled).
	-- This is what auto-starts the socket listener so the user doesn't
	-- have to click anything.
	LrInitPlugin = 'Init.lua',

	-- IMPORTANT: LrInitPlugin scripts are documented to not reliably fire
	-- on their own at Lightroom's cold launch -- this is what actually
	-- forces it to run every time, rather than only after certain trigger
	-- conditions (like being reloaded during an export). This is almost
	-- certainly why the listener needed manual restarting after every
	-- fresh Lightroom launch: the auto-start script likely wasn't being
	-- invoked at all, not failing partway through.
	LrForceInitPlugin = true,

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
