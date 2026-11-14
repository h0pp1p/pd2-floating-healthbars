local mvec_add = mvector3.add
local mvec_mul = mvector3.multiply
local mvec_set = mvector3.set
local to_vec = Vector3()

function HUDManager:reset_floating_healthbar()
	self._healthbar_panel = self._healthbar_panel or managers.hud:panel(PlayerBase.PLAYER_INFO_HUD_FULLSCREEN_PD2)

	self._next_unit_raycast_t = 0

	self._unit_slotmask_no_walls, self._unit_slot_mask_empty = FloatingHealthbars:character_slot_mask()
	self._unit_slotmask = self._unit_slotmask_no_walls + managers.slot:get_mask("bullet_blank_impact_targets")

	if self._unit_healthbar and self._unit_healthbar:alive() then
		self._unit_healthbar:destroy()
		self._unit_healthbar = nil
		self._force_healthbar_update = true
		self:update_floating_healthbar(0)
		self._force_healthbar_update = nil
	end
end

local function should_show_healthbar(unit)
	local dmg = alive(unit) and unit:character_damage()
	if not dmg or not dmg.health_ratio or dmg._dead then
		return false
	elseif unit:unit_data().name_label_id then
		return false
	elseif FloatingHealthbars.settings.damaged_only and dmg:health_ratio() >= 1 then
		return false
	end
	return true
end

function HUDManager:update_floating_healthbar(t)
	if self._next_unit_raycast_t > t then
		return
	end

	self._next_unit_raycast_t = t + 0.05

	local player = managers.player:local_player()
	if not alive(player) or self._unit_slot_mask_empty or FloatingHealthbars.settings.loud_only and managers.groupai and managers.groupai:state():whisper_mode() then
		if self._unit_healthbar and self._unit_healthbar:alive() then
			self._unit_healthbar:destroy()
			self._unit_healthbar = nil
		end
		return
	end

	local cam = player:camera()
	local from = cam:position()
	mvec_set(to_vec, cam:forward())
	mvec_mul(to_vec, player:movement():current_state():in_steelsight() and FloatingHealthbars.settings.max_distance_ads or FloatingHealthbars.settings.max_distance)
	mvec_add(to_vec, from)
	local ray1 = World:raycast("ray", from, to_vec, "slot_mask", self._unit_slotmask_no_walls, "sphere_cast_radius", 30)
	local ray2 = World:raycast("ray", from, to_vec, "slot_mask", self._unit_slotmask)

	local unit = ray1 and (not ray2 or ray2.unit == ray1.unit or ray2.distance > ray1.distance + 60) and ray1.unit or ray2 and ray2.unit
	if unit and unit:in_slot(8) and unit:parent() and unit:parent():in_slot(self._unit_slotmask_no_walls) then
		unit = unit:parent()
	end

	if self._unit_healthbar and (self._unit_healthbar._unit ~= unit or not self._unit_healthbar:alive()) then
		self._unit_healthbar:hide()
		self._unit_healthbar = nil
	end

	if not self._unit_healthbar and should_show_healthbar(unit) then
		self._unit_healthbar = unit:unit_data()._healthbar or EnemyHealthBar:new(self._healthbar_panel, unit)
		self._unit_healthbar:show(self._force_healthbar_update)
	end
end

Hooks:PostHook(HUDManager, "init_finalize", "init_finalize_enemy_health_bars", HUDManager.reset_floating_healthbar)
Hooks:PostHook(HUDManager, "update", "update_enemy_health_bars", HUDManager.update_floating_healthbar)
