--[[
	DevelopClipboard

	Copy/paste for Develop settings, using the same pattern documented by
	experienced Lightroom SDK plugin authors on Adobe's own community forums
	(photo:getDevelopSettings() / photo:applyDevelopSettings() are real,
	if lightly-documented, LrPhoto methods -- not LrDevelopController calls,
	since they operate on stored settings rather than the live UI).

	"Paste" applies to every currently-selected (target) photo, which lets
	you copy from one photo in Develop, then select several photos back in
	the Library grid and paste to all of them at once -- matching
	Lightroom's own multi-photo Sync behavior.
]]

local LrApplication = import 'LrApplication'
local LrTasks = import 'LrTasks'
local LrDialogs = import 'LrDialogs'

local DevelopClipboard = {}
local storedSettings = nil

-- Previously both functions failed completely silently on every path,
-- success included -- there was no way to tell from the phone (or even
-- standing at the computer) whether a tap had done anything at all. Every
-- path now shows a bezel (Lightroom's own on-canvas notification) so it's
-- unambiguous.
function DevelopClipboard.copy()
	local catalog = LrApplication.activeCatalog()
	local photo = catalog:getTargetPhoto()
	if not photo then
		LrDialogs.showBezel('Copy Settings: no photo selected', 2)
		return
	end
	storedSettings = photo:getDevelopSettings()
	LrDialogs.showBezel('Copied develop settings', 1.5)
end

function DevelopClipboard.paste()
	if not storedSettings then
		LrDialogs.showBezel('Nothing copied yet -- use Copy Settings first', 2)
		return
	end

	LrTasks.startAsyncTask(function()
		local catalog = LrApplication.activeCatalog()
		local photos = catalog:getTargetPhotos()

		if not photos or #photos == 0 then
			LrDialogs.showBezel('Paste Settings: no photo selected', 2)
			return
		end

		catalog:withWriteAccessDo('Paste Develop Settings (Remote Slider Control)', function()
			for _, photo in ipairs(photos) do
				photo:applyDevelopSettings(storedSettings)
			end
		end)
		LrDialogs.showBezel('Pasted settings to ' .. #photos .. ' photo(s)', 1.5)
	end)
end

return DevelopClipboard
