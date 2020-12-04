--Determines states to show/hide crosshair panel in.
Hooks:PostHook(PlayerMovement, "change_state", "DynamicCrosshairsPostPlayerMovementChangeState", function(self, name)
	if not self._current_state_name then return end

	local valid_states = {
		standard = true,
		carry = true,
		bipod = true
	}

	if DynamicCrosshairs.Options:GetValue("DownedCrosshair") then
		valid_states.bleed_out = true
	end

	if DynamicCrosshairs.Options:GetValue("TasedCrosshair") then
		valid_states.tased = true
	end

	if DynamicCrosshairs.Options:GetValue("CasingCrosshair") then
		valid_states.mask_off = true
	end

	if valid_states[ self._current_state_name ] then
		managers.hud:show_crosshair_panel(true)
	else
		managers.hud:show_crosshair_panel(false)
	end
end) 