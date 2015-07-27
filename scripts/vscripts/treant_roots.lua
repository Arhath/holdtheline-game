function RootsPlant( event ) 

	local caster = event.caster
	local ability = event.ability
	local ability_level = ability:GetLevel() - 1
	local posCaster = caster:GetAbsOrigin()
	
	
	-- Initialize the count and table
	caster.root_count = caster.root_count or 0
	caster.root_table = caster.root_table or {}


	-- Modifiers
	local modifier_root = event.modifier_root
	local modifier_tracker = event.modifier_tracker
	local modifier_caster = event.modifier_caster

	-- Ability variables
	local activation_time = ability:GetLevelSpecialValueFor("activation_time", ability_level) 
	local max_roots = ability:GetLevelSpecialValueFor("max_roots", ability_level) 
	local duration = ability:GetLevelSpecialValueFor("duration", ability_level) 
	local number_roots = ability:GetLevelSpecialValueFor("number_roots", ability_level) 
	local radius = ability:GetLevelSpecialValueFor("plant_radius", ability_level) 

	print(number_roots)
	local number_roots = 5
	
	
	-- Create the roots and apply the root modifier
	for n = 1, number_roots, 1 do		
		local SpawnLocation = posCaster + RandomVector( RandomFloat( 200, radius)) 
    	local root = CreateUnitByName("treant_root_trap", SpawnLocation, false, nil, nil, caster:GetTeamNumber())
    	ability:ApplyDataDrivenModifier(caster, root, modifier_root, {})
		
		Timers:CreateTimer(activation_time, function()
		ability:ApplyDataDrivenModifier(caster, root, modifier_tracker, {})
		end)
		
		-- Update the count and table
		table.insert(caster.root_table, root)
		caster.root_count = caster.root_count + 1
		
		-- If we exceeded the maximum number of mines then kill the oldest one
		if caster.root_count > max_roots then
			caster.root_table[1]:ForceKill(true)
		end
    end
   

	-- Increase caster stack count of the caster modifier and add it to the caster if it doesnt exist
	if not caster:HasModifier(modifier_caster) then
		ability:ApplyDataDrivenModifier(caster, caster, modifier_caster, {})
	end

	caster:SetModifierStackCount(modifier_caster, ability, caster.root_count)

	-- Apply the tracker after the activation time
end
--[[Author: Pizzalol
	Date: 24.03.2015.
	Stop tracking the root and create vision on the root area]]
function RootDeath( event )
	local caster = event.caster
	local unit = event.unit
	local ability = event.ability
	local ability_level = ability:GetLevel() - 1

	-- Ability variables
	local modifier_caster = event.modifier_caster
	local vision_radius = ability:GetLevelSpecialValueFor("vision_radius", ability_level) 
	local vision_duration = ability:GetLevelSpecialValueFor("vision_duration", ability_level)

	-- Find the root and remove it from the table
	for i = 1, #caster.root_table do
		if caster.root_table[i] == unit then
			table.remove(caster.root_table, i)
			caster.root_count = caster.root_count - 1
			break
		end
	end

	-- Create vision on the mine position
	ability:CreateVisibilityNode(unit:GetAbsOrigin(), vision_radius, vision_duration)

	-- Update the stack count
	caster:SetModifierStackCount(modifier_caster, ability, caster.root_count)
	if caster.root_count < 1 then
		caster:RemoveModifierByNameAndCaster(modifier_caster, caster) 
	end
end

--[[Author: Pizzalol
	Date: 24.03.2015.
	Tracks if any enemy units are within the mine radius]]
function RootsTracker( event )
	local target = event.target
	local ability = event.ability
	local ability_level = ability:GetLevel() - 1

	-- Ability variables
	local trigger_radius = ability:GetLevelSpecialValueFor("activation_radius", ability_level) 
	local explode_delay = ability:GetLevelSpecialValueFor("explode_delay", ability_level) 
	print("trigger_radius")
 
	-- Target variables
	local target_team = DOTA_UNIT_TARGET_TEAM_ENEMY
	local target_types = DOTA_UNIT_TARGET_ALL 
	local target_flags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	
	-- Find the valid units in the trigger radius
	local units = FindUnitsInRadius(target:GetTeamNumber(), target:GetAbsOrigin(), nil, trigger_radius, target_team, target_types, target_flags, FIND_CLOSEST, false) 

	-- If there is a valid unit in range then expand the root
	if #units > 0 then
		Timers:CreateTimer(explode_delay, function()
			if target:IsAlive() then
				target:ForceKill(true) 
			end
		end)
	end
end