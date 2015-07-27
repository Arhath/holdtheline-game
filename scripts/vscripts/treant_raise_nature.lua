treant_raise_nature = class ({})

function treant_raise_nature:GetAOERadius()
	return self:GetSpecialValueFor( "spawn_radius" )
end

function treant_raise_nature:GetNumberTrees()
	return self:GetSpecialValueFor( "number_treants" )
end

function treant_raise_nature:GetNumberFlowers()
	return self:GetSpecialValueFor( "number_flowers" )
end

function treant_raise_nature:GetNumberMushrooms()
	return self:GetSpecialValueFor( "number_mushrooms" )
end


function treant_raise_nature:OnSpellStart() 

		--Variablen
	local caster = self:GetCaster()
	local posCaster = caster:GetAbsOrigin()
	local radius =	self:GetAOERadius()
	

	local flowers = {}
	local mushrooms = {}
	
	local teamCaster = caster:GetTeamNumber()
	local treesSpawned = 0
	local flowersSpawned = 0
	local mushroomsSpawned = 0



	--Bäume finden
	local trees = GridNav:GetAllTreesAroundPoint(posCaster, radius, true)
	
	--Flowers und Mushrooms finden
	local units = FindUnitsInRadius( caster:GetTeamNumber(), caster:GetOrigin(), nil, radius , DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false )

	for _, u in pairs(units) do
		if u:GetUnitName() == "treant_flower" then
			table.insert(flowers, u)
		end
		
		if u:GetUnitName() == "treant_mushroom" then
			table.insert(mushrooms, u)
		end
	end

	---------------------
	--Monster beschwören
	----------------------	
	--Für alle Bäume
	for _, tree in pairs (trees) do
		if treesSpawned > self:GetNumberTrees() then break end
		
		local posTree = tree:GetAbsOrigin()
		
		--print (tree:GetClassname())
		local treeClass = tree:GetClassname()
		if treeClass == "ent_dota_tree" then
			tree:CutDown(teamCaster)
		else
			UTIL_RemoveImmediate( tree )
		end
		
		local entUnit = CreateUnitByName("npc_dota_furion_treant", posTree, true, nil, nil, teamCaster)
		treesSpawned = treesSpawned + 1
	end
	
	--Für alle Flowers
	for _, flower in pairs (flowers) do
		if flowersSpawned > self:GetNumberFlowers() then break end
		
		local posFlower = flower:GetAbsOrigin()

		local entUnit = CreateUnitByName("treant_flower_creature", posFlower, true, nil, nil, teamCaster)
		flowersSpawned = flowersSpawned + 1
		
		flower:ForceKill(false)
	end
	
	--Für alle Mushrooms
	for _, mushroom in pairs (mushrooms) do
		if mushroomsSpawned > self:GetNumberMushrooms() then break end
		
		local posMushroom = mushroom:GetAbsOrigin()

		local entUnit = CreateUnitByName("treant_mushroom_creature", posMushroom, true, nil, nil, teamCaster)
		mushroomsSpawned = mushroomsSpawned + 1
		
		mushroom:ForceKill(false)
	end
end

