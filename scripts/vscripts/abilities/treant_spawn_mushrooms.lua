function MushroomsPlant(event)

	local caster = event.caster
	local ability = event.ability
	local ability_level = ability:GetLevel() - 1
	local posCaster = caster:GetAbsOrigin()

	local modifier_mushroom = event.modifier_mushroom
	local modifier_caster = event.modifier_caster
	
	-- Initialize the count and table
	caster.mushroom_count = caster.mushroom_count or 0
	caster.mushroom_table = caster.mushroom_table or {}
	
		-- Ability variables
	local max_mushrooms = ability:GetLevelSpecialValueFor("max_mushrooms", ability_level) 
	local number_mushrooms = ability:GetLevelSpecialValueFor("number_mushrooms", ability_level) 
	local radius = ability:GetLevelSpecialValueFor("spawn_radius", ability_level) 
	
	--Plant	and add Aura
	for n = 0, number_mushrooms do	
		local SpawnLocation = posCaster + RandomVector( RandomFloat( 300, radius) )
		local mushroom = CreateUnitByName("treant_mushroom", SpawnLocation, false, nil, nil, caster:GetTeamNumber())
		
		ParticleManager:CreateParticle("particles/units/heroes/hero_venomancer/venomancer_ward_spawn_d.vpcf", PATTACH_ABSORIGIN, mushroom)

		ability:ApplyDataDrivenModifier(caster, mushroom, modifier_mushroom, {})
		mushroom:AddNewModifier(caster, nil, "modifier_kill", {duration = 180})

			-- Update the count and table
		table.insert(caster.mushroom_table, mushroom)
		caster.mushroom_count = caster.mushroom_count + 1
		
		-- If we exceeded the maximum number then kill the oldest one
		if caster.mushroom_count > max_mushrooms then
			caster.mushroom_table[1]:ForceKill(true)
		end
	end
	
	-- Increase caster stack count of the caster modifier and add it to the caster if it doesnt exist
	if not caster:HasModifier(modifier_caster) then
		ability:ApplyDataDrivenModifier(caster, caster, modifier_caster, {})
	end

	caster:SetModifierStackCount(modifier_caster, ability, caster.mushroom_count)
end

function MushroomDeath(event)
	print("mushroom died")
	local caster = event.caster
	local unit = event.unit
	local ability = event.ability
	local ability_level = ability:GetLevel() - 1

	-- Ability variables
	local modifier_caster = event.modifier_caster

	-- Find the mushroom and remove it from the table
	for i = 1, #caster.mushroom_table do
		if caster.mushroom_table[i] == unit then
			table.remove(caster.mushroom_table, i)
			print("removing")
			caster.mushroom_count = caster.mushroom_count - 1
			break
		end
	end

	-- Update the stack count
	caster:SetModifierStackCount(modifier_caster, ability, caster.mushroom_count)
	if caster.mushroom_count < 1 then
		caster:RemoveModifierByNameAndCaster(modifier_caster, caster) 
	end
end