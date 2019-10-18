Hooks:PostHook(PlayerStandard, "init", "CrosshairCooldownInit", function(self, unit)
	self._crosshair_cooldown = 0.0
end)

Hooks:PostHook(PlayerStandard, "update", "ActiveCrosshairMovement", function(self, t, dt)
	if self:_is_meleeing() or self:_interacting() then
		if not self._crosshair_melee then
			self._crosshair_melee = true
			managers.hud:set_crosshair_visible(false)
			managers.hud:set_crosshair_offset(0)
		end
	elseif not self:_is_meleeing() and not self:_interacting() then
		if self._crosshair_melee then
			self._crosshair_melee = nil
			managers.hud:set_crosshair_visible(true)
			self:_update_crosshair_offset(t)
		end
	end

	if self._fwd_ray and self._fwd_ray.unit then

		local unit = self._fwd_ray.unit
		
		local function is_teammate(unit)
			for _ , u_data in pairs(managers.groupai:state():all_criminals()) do
				if u_data.unit == unit then return true end
			end
		end
		
		if managers.enemy:is_civilian(unit) then
			managers.hud:set_crosshair_color(Color(194 / 255 , 252 / 255 , 151 / 255))
		elseif managers.enemy:is_enemy(unit) then
			managers.hud:set_crosshair_color(Color( 1 , 1 , 0.2 , 0 ))
		elseif is_teammate(unit) then
			managers.hud:set_crosshair_color(Color( 0.2 , 0.8 , 1 ))
		else
			managers.hud:set_crosshair_color(Color.white)
		end
		
	else
	
		managers.hud:set_crosshair_color(Color.white)
		
	end

	self:_update_crosshair_offset(t)
	self._crosshair_cooldown = math.max(0.0, self._crosshair_cooldown - dt)
end)

function PlayerStandard:_update_crosshair_offset(t)
	if not alive(self._equipped_unit) then
		return
	end
	
	if self:_is_meleeing() or self:_interacting() then
		if self._crosshair_melee then
			managers.hud:set_crosshair_offset(0)
			return
		end
	end
	
	if self._state_data.in_steelsight then
		managers.hud:set_crosshair_visible(false)
		managers.hud:set_crosshair_offset(0)
		return
	end
	
	managers.hud:set_crosshair_visible(true)
	local weapon = self._equipped_unit:base()
	local weapon_data = self._equipped_unit:base():weapon_tweak_data()
	local crosshair_spread = ((21 - weapon_data.stats.spread) / 84)

	if self._shooting and self._crosshair_cooldown == 0.0 then
		crosshair_spread = crosshair_spread + ((26 - weapon_data.stats.recoil) / 26) + 0.01
		self._crosshair_cooldown = 0.1
	end

	if self._running then 
		crosshair_spread = crosshair_spread + ((26 - weapon_data.stats.recoil) / 130) + 0.01
	end

	if self._state_data.in_air then 
		crosshair_spread = crosshair_spread + ((26 - weapon_data.stats.recoil) / 104) + 0.01
	end
	
	if self._moving then
		crosshair_spread = crosshair_spread + ((26 - weapon_data.stats.recoil) / 182) + 0.01
	end

	managers.hud:set_crosshair_offset(crosshair_spread)
	
	return
end