function SpellStart( event )
	local caster = event.caster
	local entSpawn = Entities:FindByName(nil, "bossarena1")	
	local ability = event.ability
	local ability_level = ability:GetLevel() - 1

	local number_eyes = ability:GetLevelSpecialValueFor("number_eyes", ability_level) 
	local duration = ability:GetLevelSpecialValueFor("duration", ability_level) 

	local modifier_thinker = event.modifier_thinker

	CreateItem("item_gem", caster, caster)

	if entSpawn == nil then
		print("Error: No Spawner found!")
	else
		local point = entSpawn:GetOrigin()

		for n = 0, number_eyes do
			local SpawnLocation = point + Vector( RandomFloat( -2700, 2700), RandomFloat( -1600, 1500), 0 )
			local eye = CreateUnitByName("nightbane_eye_of_night", SpawnLocation, false, nil, nil, caster:GetTeamNumber())		
			eye:AddNewModifier(caster, ability, "modifier_kill", {Duration = duration})	
			ability:ApplyDataDrivenModifier(caster, eye, modifier_thinker, {})
		end
	end
end

function SpawnUnits( event )
	local target = event.target
	local posTarget = target:GetAbsOrigin()

	local wards = {}

	for n = 0, 2 do
		local SpawnLocation = posTarget + RandomVector(RandomFloat(100, 300))
		local ghost = CreateUnitByName("treant_mushroom_creature_big", SpawnLocation, false, nil, nil, target:GetTeamNumber())

		local units = FindUnitsInRadius( target:GetTeamNumber(), target:GetOrigin(), nil, 4000 , DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false )
		for _, u in pairs(units) do
			if u:GetUnitName() == "mushroom_poison_trap" then
				table.insert(wards, u)
			end
		end

		local posSentry = wards[1]:GetAbsOrigin()
		ghost:MoveToPosition(SpawnLocation + RandomVector(1000))
	end
end