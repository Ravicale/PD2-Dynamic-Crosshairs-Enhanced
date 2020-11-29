--Initialize required information once player enters their standard non-casing state..
Hooks:PostHook(PlayerStandard, "_enter", "ActivateCrosshairPanel", function(self, enter_data)
    --Cooldown on crosshair expansion from shooting, allows for a satisfying jiggle for full auto guns.
    self._next_crosshair_jiggle = 0.0

    --Ignore the steelsight state for weapons that you don't actually aim down sights with, Restoration mod adds LMG Sights so also check for that.
    if SC or DynamicCrosshairs.Options:GetValue("LMGIronSights") then
        self._ignore_steelsight = self._equipped_unit:base():is_category("akimbo", "bow", "minigun")
    else
        self._ignore_steelsight = self._equipped_unit:base():is_category("akimbo", "bow", "lmg", "minigun")
    end

    --Set the crosshair to be visible.
    managers.hud:show_crosshair_panel(true)
end)

--Update whenever to ignore steelsights whenever the equipped gun changes.
Hooks:PostHook(PlayerStandard, "inventory_clbk_listener", "ChangeActiveCategory", function(self, unit, event)
    if event == "equip" then
        if SC or DynamicCrosshairs.Options:GetValue("LMGIronSights") then
            self._ignore_steelsight = self._equipped_unit:base():is_category("akimbo", "bow", "minigun")
        else
            self._ignore_steelsight = self._equipped_unit:base():is_category("akimbo", "bow", "lmg", "minigun")
        end
    end
end)

--Update crosshair each frame.
Hooks:PostHook(PlayerStandard, "update", "ActiveCrosshairMovement", function(self, t, dt)
    local crosshair_visible = alive(self._equipped_unit) and
                              not self:_is_meleeing() and
                              not self:_interacting() and
                              (not self._state_data.in_steelsight or self._ignore_steelsight)

    if crosshair_visible then
        --Ensure that crosshair is actually visible.
        managers.hud:set_crosshair_visible(true)

        --Set crosshair color based on what's being aimed at.
        if self._fwd_ray and self._fwd_ray.unit then
            local unit = self._fwd_ray.unit
            
            local function is_teammate(unit)
                for _ , u_data in pairs(managers.groupai:state():all_criminals()) do
                    if u_data.unit == unit then return true end
                end
            end
            
            if managers.enemy:is_civilian(unit) then
                managers.hud:set_crosshair_color(DynamicCrosshairs.Options:GetValue("CivilianColor"))
            elseif managers.enemy:is_enemy(unit) then
                managers.hud:set_crosshair_color(DynamicCrosshairs.Options:GetValue("EnemyColor"))
            elseif is_teammate(unit) then
                managers.hud:set_crosshair_color(DynamicCrosshairs.Options:GetValue("FriendlyColor"))
            else
                managers.hud:set_crosshair_color(DynamicCrosshairs.Options:GetValue("GenericColor"))
            end
        else
            managers.hud:set_crosshair_color(DynamicCrosshairs.Options:GetValue("GenericColor"))
        end

        --Update crosshair size.
        self:_update_crosshair_offset(t)
    else
        --Hide the crosshair and set its size to 0 when it shouldn't be seen.
        managers.hud:set_crosshair_visible(false)
        managers.hud:set_crosshair_offset(0)
    end
end)

--Calculates the crosshair size.
--Overwrite vanilla function to avoid potential weirdness.
function PlayerStandard:_update_crosshair_offset(t)
    if not alive(self._equipped_unit) then
        return
    end

    local weapon = self._equipped_unit:base()

    --Get current weapon's spread values to determine base size.
    -- "/ 24" keeps the size in check and very roughly matches the weapon's actual spread.
    -- the "+ 0.01" prevents the crosshair from clipping with itself.
    local crosshair_spread = (weapon:_get_spread(self._unit) / 24) + 0.01

    --Make crosshair grow when shooting. Has a cooldown so that fast firing weapons result in a satisfying jiggle.
    if DynamicCrosshairs.Options:GetValue("ShootingEffects") then
        if self._shooting and t and self._next_crosshair_jiggle < t then
            crosshair_spread = crosshair_spread + (weapon._recoil / 3) + 0.01
            self._next_crosshair_jiggle = t + 0.1 or 0.1
        end
    end

    if DynamicCrosshairs.Options:GetValue("MovementEffects") then
        --Moving spread actually varies in Restoration Mod based on weapon stats, so we only need to manually change size in vanilla.
        if not SC and self._moving then
            crosshair_spread = crosshair_spread + (weapon._recoil / 24) + 0.01
        end

        --Use weapon stability to change size when running.
        if self._running then 
            crosshair_spread = crosshair_spread + (weapon._recoil / 24) + 0.01
        end

        --Use weapon stability to change size when in the air.
        if self._state_data.in_air then 
            crosshair_spread = crosshair_spread + (weapon._recoil / 24) + 0.01
        end
    end

    --Set the final size of the crosshair.
    managers.hud:set_crosshair_offset(crosshair_spread)
end