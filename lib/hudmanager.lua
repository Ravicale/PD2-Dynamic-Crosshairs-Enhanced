Hooks:PostHook(HUDManager, "_player_hud_layout", "DynamicCrosshairsPostHUDManagerPlayerInfoHUDLayout", function(self)
	self._crosshair_main = managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2).panel:panel({
		name = "crosshair_main",
		halign = "grow",
		valign = "grow"
	})
	
	local crosshair_panel = self._crosshair_main:panel({
		name = "crosshair_panel"
	})

	function generate_crosshair_template(name, rotation)
		return {
			name = name,
			rotation = rotation,
			texture = "guis/textures/crosshair",
			valign = "scale",
			halign = "scale",
			w = 1,
			h = 1
		}
	end

	local crosshair_part_right = crosshair_panel:bitmap(
		generate_crosshair_template("crosshair_part_right", 0)
	)
	
	local crosshair_part_bottom = crosshair_panel:bitmap(
		generate_crosshair_template("crosshair_part_bottom", 90)
	)
	
	local crosshair_part_left = crosshair_panel:bitmap(
		generate_crosshair_template("crosshair_part_left", 180)
	)
	
	local crosshair_part_top = crosshair_panel:bitmap(
		generate_crosshair_template("crosshair_part_top", 270)
	)

	crosshair_panel:set_center(managers.hud:script(PlayerBase.PLAYER_INFO_HUD_PD2).panel:center())
	
	self:set_crosshair_offset(tweak_data.weapon.crosshair.DEFAULT_OFFSET)
	self._ch_offset = 0
	self._ch_current_offset = 0
	self._ch_fov = 0

	self._crosshair_parts = {
		crosshair_part_left,
		crosshair_part_top,
		crosshair_part_right,
		crosshair_part_bottom
	}

	self:_layout_crosshair()
end)

function HUDManager:set_crosshair_color(color)
	if not self._crosshair_main then return end
	
	self._crosshair_parts = self._crosshair_parts or {
		self._crosshair_main:child("crosshair_panel"):child("crosshair_part_left"),
		self._crosshair_main:child("crosshair_panel"):child("crosshair_part_top"),
		self._crosshair_main:child("crosshair_panel"):child("crosshair_part_right"),
		self._crosshair_main:child("crosshair_panel"):child("crosshair_part_bottom")
	}
	
	for _ , part in ipairs(self._crosshair_parts) do
		part:set_color(color)
	end
end

function HUDManager:show_crosshair_panel(visible)
	if not self._crosshair_main then return end
	self._crosshair_main:set_visible(visible)
end

--Take FOV into account for crosshair size.
function HUDManager:set_camera_fov(fov)
	self._ch_fov = fov
end

function HUDManager:set_crosshair_offset(offset)
	--Compensate for FOV. 2700000 is a close-enough base mult for the crosshair size. 
	local scale_mult = 2700000 / (self._ch_fov or 75)

	self._ch_offset = math.tan(math.rad(math.min(math.max(offset, 0), 180))) * scale_mult
end

function HUDManager:set_crosshair_visible(visible)
	if not self._crosshair_main then return end
	
	if visible and not self._crosshair_visible then
		self._crosshair_visible = true
		self._crosshair_main:child("crosshair_panel"):stop()
		
		self._crosshair_main:child("crosshair_panel"):animate(function(o)
			self._crosshair_main:child("crosshair_panel"):set_visible(true)
			over(0.5, function(p)
				self._crosshair_main:child("crosshair_panel"):set_alpha(math.lerp(self._crosshair_main:child("crosshair_panel"):alpha(), 1, p))
			end)
		end)
	elseif not visible and self._crosshair_visible then
		self._crosshair_visible = nil
		self._crosshair_main:child("crosshair_panel"):stop()
		
		self._crosshair_main:child("crosshair_panel"):animate(function(o)
			over(0.5 , function(p)
				self._crosshair_main:child("crosshair_panel"):set_alpha(math.lerp(self._crosshair_main:child("crosshair_panel"):alpha(), 0, p))
			end)
			self._crosshair_main:child("crosshair_panel"):set_visible(false)
		end)
	end
end

function HUDManager:_update_crosshair_offset(t, dt)
	--Aim for crosshairs to settle into position within ~0.125 seconds. Just a magic number that feels ok.
	--Crosshair size set to a bigger value than it currently is.
	if self._ch_current_offset > self._ch_offset then
		self._ch_current_offset = math.max(self._ch_current_offset - ((self._ch_current_offset - self._ch_offset) * dt * 8), self._ch_offset)
	--Crosshair size set to a smaller value than it currently is.
	else
		self._ch_current_offset = math.min(self._ch_current_offset + ((self._ch_offset - self._ch_current_offset) * dt * 8), self._ch_offset)
	end

	self:_layout_crosshair()
end

function HUDManager:_layout_crosshair()
	if not self._crosshair_main then return end
	
	local crosshair = self._crosshair_main:child("crosshair_panel")
	local x = crosshair:center_x() - crosshair:left()
	local y = crosshair:center_y() - crosshair:top()

	local length = math.floor(DynamicCrosshairs.Options:GetValue("Length"))
	local width = math.floor(DynamicCrosshairs.Options:GetValue("Thickness"))
	
	for _ , part in ipairs(self._crosshair_parts) do
		local rotation = part:rotation()
		part:set_w(length) --Refresh size in case user changed these settings. Look into caching them using a menumanager hook later for perf?
		part:set_h(width)
		part:set_center_x(x + math.cos(rotation) * (self._ch_current_offset + length * 0.5))
		part:set_center_y(y + math.sin(rotation) * (self._ch_current_offset + length * 0.5))
	end
end