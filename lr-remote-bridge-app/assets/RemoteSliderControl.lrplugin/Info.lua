return {

	-- EXPERIMENT: bumped from 6.0 (pre-dates AI masking entirely) on the
	-- theory that getDevelopSettings()/applyDevelopSettings() might return
	-- a fuller settings table -- including mask data -- for a plugin
	-- declaring a more current SDK target. Unconfirmed; revert to 6.0 if
	-- Plug-in Manager reports this as incompatible/needing a newer
	-- Lightroom, or if it loads fine but masks still aren't included.
	-- LrSdkMinimumVersion deliberately left low -- that's the actual hard
	-- floor Lightroom rejects on, no reason to also raise that.
	LrSdkVersion = 13.0,
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
