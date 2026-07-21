--[[
	Maps the short parameter keys our phone app uses (matching the keys in
	PARAM_LIBRARY in the mobile app) to the real parameter names that
	LrDevelopController.setValue / getValue expect.

	All names below are confirmed against Adobe's official LrDevelopController
	reference (the full documented parameter list, not the "2012"-suffixed
	names used by the separate photo:getDevelopSettings API):

		adjustPanel:  Temperature, Tint, Exposure, Highlights, Shadows,
		              Contrast, Whites, Blacks, Clarity, Vibrance, Saturation
		detailPanel:  Sharpness, SharpenRadius, SharpenDetail, SharpenEdgeMasking,
		              LuminanceSmoothing, LuminanceNoiseReductionDetail,
		              LuminanceNoiseReductionContrast
		effectsPanel: Dehaze, PostCropVignetteAmount, PostCropVignetteMidpoint,
		              PostCropVignetteFeather, PostCropVignetteRoundness,
		              PostCropVignetteHighlightContrast
		calibratePanel: ShadowTint, RedHue, RedSaturation, GreenHue,
		              GreenSaturation, BlueHue, BlueSaturation
		mixerPanel:   {Saturation,Hue,Luminance}AdjustmentRed/Orange/Yellow/
		              Green/Aqua/Blue/Purple/Magenta
]]

local ParamMap = {}

ParamMap.toLightroom = {
	-- Basic
	exposure    = 'Exposure',
	contrast    = 'Contrast',
	highlights  = 'Highlights',
	shadows     = 'Shadows',
	whites      = 'Whites',
	blacks      = 'Blacks',
	texture     = 'Texture',
	clarity     = 'Clarity',
	dehaze      = 'Dehaze',
	temp        = 'Temperature', -- handled specially in RemoteServer.lua (Kelvin conversion)
	tint        = 'Tint',
	vibrance    = 'Vibrance',
	saturation  = 'Saturation',

	-- Sharpening
	sharp_amount   = 'Sharpness',
	sharp_radius   = 'SharpenRadius',
	sharp_detail   = 'SharpenDetail',
	sharp_masking  = 'SharpenEdgeMasking',

	-- Noise Reduction (luminance)
	noise_luminance          = 'LuminanceSmoothing',
	noise_luminance_detail   = 'LuminanceNoiseReductionDetail',
	noise_luminance_contrast = 'LuminanceNoiseReductionContrast',

	-- Post-Crop Vignette
	vignette_amount     = 'PostCropVignetteAmount',
	vignette_midpoint   = 'PostCropVignetteMidpoint',
	vignette_feather    = 'PostCropVignetteFeather',
	vignette_roundness  = 'PostCropVignetteRoundness',
	vignette_highlights = 'PostCropVignetteHighlightContrast',

	-- Camera Calibration
	calib_shadow_tint = 'ShadowTint',
	calib_red_hue     = 'RedHue',
	calib_red_sat     = 'RedSaturation',
	calib_green_hue   = 'GreenHue',
	calib_green_sat   = 'GreenSaturation',
	calib_blue_hue    = 'BlueHue',
	calib_blue_sat    = 'BlueSaturation',

	-- Color Mixer / HSL
	mixer_red_hue      = 'HueAdjustmentRed',
	mixer_red_sat      = 'SaturationAdjustmentRed',
	mixer_red_lum      = 'LuminanceAdjustmentRed',
	mixer_orange_hue   = 'HueAdjustmentOrange',
	mixer_orange_sat   = 'SaturationAdjustmentOrange',
	mixer_orange_lum   = 'LuminanceAdjustmentOrange',
	mixer_yellow_hue   = 'HueAdjustmentYellow',
	mixer_yellow_sat   = 'SaturationAdjustmentYellow',
	mixer_yellow_lum   = 'LuminanceAdjustmentYellow',
	mixer_green_hue    = 'HueAdjustmentGreen',
	mixer_green_sat    = 'SaturationAdjustmentGreen',
	mixer_green_lum    = 'LuminanceAdjustmentGreen',
	mixer_aqua_hue     = 'HueAdjustmentAqua',
	mixer_aqua_sat     = 'SaturationAdjustmentAqua',
	mixer_aqua_lum     = 'LuminanceAdjustmentAqua',
	mixer_blue_hue     = 'HueAdjustmentBlue',
	mixer_blue_sat     = 'SaturationAdjustmentBlue',
	mixer_blue_lum     = 'LuminanceAdjustmentBlue',
	mixer_purple_hue   = 'HueAdjustmentPurple',
	mixer_purple_sat   = 'SaturationAdjustmentPurple',
	mixer_purple_lum   = 'LuminanceAdjustmentPurple',
	mixer_magenta_hue  = 'HueAdjustmentMagenta',
	mixer_magenta_sat  = 'SaturationAdjustmentMagenta',
	mixer_magenta_lum  = 'LuminanceAdjustmentMagenta',
}

-- Quick-action buttons. Confirmed via the SDK reference:
--   LrDevelopController.setAutoTone()
--   LrDevelopController.showClipping()
--   LrSelection.flagAsPick() / flagAsReject()
-- Note showClipping() isn't documented as a toggle (there's no matching
-- "hideClipping"), so this is wired as a simple tap-to-show button for now
-- rather than the true "hold while dragging" behavior from desktop
-- Lightroom -- that would need multi-touch gesture support we don't have
-- yet. Worth testing what repeated taps actually do on your version.
function ParamMap.buildActions(LrDevelopController, LrSelection)
	return {
		auto = function()
			LrDevelopController.setAutoTone()
		end,
		clipping = function()
			LrDevelopController.showClipping()
		end,
		pick = function()
			LrSelection.flagAsPick()
		end,
		reject = function()
			LrSelection.flagAsReject()
		end,
	}
end

return ParamMap
