function FlowersPlant(event)

	local caster = event.caster
	local ability = event.ability
	local ability_level = ability:GetLevel() - 1
	local posCaster = caster:GetAbsOrigin()

	local modifier_flower = event.modifier_flower
	local modifier_caster = event.modifier_caster
	
	-- Initialize the count and table
	caster.flower_count = caster.flower_count or 0
	caster.flower_table = caster.flower_table or {}
	
		-- Ability variables
	local max_flowers = ability:GetLevelSpecialValueFor("max_flowers", ability_level) 
	local number_flowers = ability:GetLevelSpecialValueFor("number_flowers", ability_level) 
	local radius = ability:GetLevelSpecialValueFor("spawn_radius", ability_level) 
	
	--Plant	and add Aura
	for n = 0, number_flowers do	
		local SpawnLocation = posCaster + RandomVector( RandomFloat( 300, radius) )
		local flower = CreateUnitByName("treant_flower", SpawnLocation, false, nil, nil, caster:GetTeamNumber())
		
		ability:ApplyDataDrivenModifier(caster, flower, modifier_flower, {})
		
			-- Update the count and table
		table.insert(caster.flower_table, flower)
		caster.flower_count = caster.flower_count + 1
		
		-- If we exceeded the maximum number then kill the oldest one
		if caster.flower_count > max_flowers then
			caster.flower_table[1]:ForceKill(true)
		end
	end
	
	-- Increase caster stack count of the caster modifier and add it to the caster if it doesnt exist
	if not caster:HasModifier(modifier_caster) then
		ability:ApplyDataDrivenModifier(caster, caster, modifier_caster, {})
	end

	caster:SetModifierStackCount(modifier_caster, ability, caster.flower_count)
end

function FlowerDeath(event)
	local caster = event.caster
	local unit = event.unit
	local ability = event.ability
	local ability_level = ability:GetLevel() - 1

	-- Ability variables
	local modifier_caster = event.modifier_caster

	-- Find the flower and remove it from the table
	for i = 1, #caster.flower_table do
		if caster.flower_table[i] == unit then
			table.remove(caster.flower_table, i)
			caster.flower_count = caster.flower_count - 1
			break
		end
	end

	-- Update the stack count
	caster:SetModifierStackCount(modifier_caster, ability, caster.flower_count)
	if caster.flower_count < 1 then
		caster:RemoveModifierByNameAndCaster(modifier_caster, caster) 
	end
end
