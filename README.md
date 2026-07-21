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

local DevelopClipboard = {}
local storedSettings = nil

function DevelopClipboard.copy()
	local catalog = LrApplication.activeCatalog()
	local photo = catalog:getTargetPhoto()
	if photo then
		storedSettings = photo:getDevelopSettings()
	end
end

function DevelopClipboard.paste()
	if not storedSettings then return end

	LrTasks.startAsyncTask(function()
		local catalog = LrApplication.activeCatalog()
		local photos = catalog:getTargetPhotos()

		catalog:withWriteAccessDo('Paste Develop Settings (Remote Slider Control)', function()
			for _, photo in ipairs(photos) do
				photo:applyDevelopSettings(storedSettings)
			end
		end)
	end)
end

return DevelopClipboard
