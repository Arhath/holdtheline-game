function TrapPlant( event ) 

	local caster = event.caster
	local ability = event.ability
	local ability_level = ability:GetLevel() - 1
	local target_point = event.target_points[1]
	
	-- Modifiers
	local modifier_trap = event.modifier_trap
	local modifier_tracker = event.modifier_tracker

	-- Ability variables
	local activation_time = ability:GetLevelSpecialValueFor("activation_time", ability_level) 
	local duration = ability:GetLevelSpecialValueFor("duration", ability_level) 
	local radius = ability:GetLevelSpecialValueFor("plant_radius", ability_level) 
	
	-- Create the trap and apply the trap modifier		
    local trap = CreateUnitByName("mushroom_poison_trap", target_point, false, nil, nil, caster:GetTeamNumber())
	trap:AddNewModifier(caster, ability, "modifier_kill", {Duration = duration})
    ability:ApplyDataDrivenModifier(caster, trap, modifier_trap, {})
	
	--Apply the unit tracker after the activation time
	Timers:CreateTimer(activation_time, function()
		ability:ApplyDataDrivenModifier(caster, trap, modifier_tracker, {})
	end)	
end

--[[Author: Pizzalol
	Date: 24.03.2015.
	Tracks if any enemy units are within the mine radius]]
function TrapTracker( event )
	local target = event.target
	local caster = event.caster
	local ability = event.ability
	local ability_level = ability:GetLevel() - 1

	-- Ability variables
	local trigger_radius = ability:GetLevelSpecialValueFor("activation_radius", ability_level) 
	local explode_delay = ability:GetLevelSpecialValueFor("explode_delay", ability_level) 

	-- Modifiers
	local modifier_target = event.modifier_target
 
	-- Target variables
	local target_team = DOTA_UNIT_TARGET_TEAM_ENEMY
	local target_types = DOTA_UNIT_TARGET_ALL 
	local target_flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES

	-- Find the valid units in the trigger radius
	local units = FindUnitsInRadius(target:GetTeamNumber(), target:GetAbsOrigin(), nil, trigger_radius, target_team, target_types, target_flags, FIND_CLOSEST, false) 

	-- If there is a valid unit in range then explode on unit
	if #units > 0 then
		Timers:CreateTimer(explode_delay, function()
			if target:IsAlive() then
				ability:ApplyDataDrivenModifier(caster, units[1], modifier_target, {})
				--local particleName = "particles/units/heroes/hero_techies/techies_land_mine_explode.vpcf"
				--ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN, target, player)
				--particleName = "particles/units/heroes/hero_venomancer/venomancer_poison_nova.vpcf"
				--ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN, target)
				UTIL_Remove(target)
			end
		end)
	end
end

function PoisonNova( event )
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local abilityDamage = ability:GetLevelSpecialValueFor("damage", (ability:GetLevel() - 1))
	local targetHP = target:GetHealth()
	local targetMagicResist = target:GetMagicalArmorValue()
	-- Calculating damage that would be dealt
	local damagePostReduction = abilityDamage * (1 - targetMagicResist)
	print("Damage post reduction: " .. tonumber(damagePostReduction))

	local damageTable = {}
	damageTable.attacker = caster
	damageTable.victim = target
	damageTable.damage_type = ability:GetAbilityDamageType()
	damageTable.ability = ability
	damageTable.damage = abilityDamage

	-- Checking if its lethal damage
	-- Set hp to 1
	if targetHP <= damagePostReduction then
		-- Adjusting it to non lethal damage
		damageTable.damage = ((targetHP / (1 - targetMagicResist)) - 1.8)
		print("Adjusted non lethal damage: " .. tonumber(damageTable.damage))
	end

	print("TARGET HEALTH: " .. tonumber(targetHP))
	print("DEALING DAMAGE: " .. tonumber(damageTable.damage))
	ApplyDamage(damageTable)
end

function Death_fx()
	local target = event.target
	local caster = event.caster
	local particleName = "particles/units/heroes/hero_techies/techies_land_mine_explode.vpcf"
	ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN, target)
end