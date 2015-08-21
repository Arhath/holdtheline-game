treant_spawn_treants = class ({})

function treant_spawn_treants:GetAOERadius()
	return self:GetSpecialValueFor( "spawn_radius" )
end

function treant_spawn_treants:GetNumberTrees()
	return self:GetSpecialValueFor( "number_treants" )
end

function treant_spawn_treants:GetNumberFlowers()
	return self:GetSpecialValueFor( "number_flowers" )
end

function treant_spawn_treants:GetNumberMushrooms()
	return self:GetSpecialValueFor( "number_mushrooms" )
end


function treant_spawn_treants:OnSpellStart() 
	local caster = self:GetCaster()
	local posCaster = caster:GetAbsOrigin()
	local radius =	self:GetAOERadius()
	
	local trees = GridNav:GetAllTreesAroundPoint(posCaster, radius, true)
	local flowers = Entities:FindByNameWithin(treant_mushroom, posCaster, radius)	
	local mushrooms = Entities:FindByNameWithin(treant_mushroom, posCaster, radius)						  

	local teamCaster = caster:GetTeamNumber()
	local treesSpawned = 0
	local flowersSpawned = 0
	local mushoomsSpawned = 0
	
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
	
	for _, flower in pairs (flowers) do
		if flowersSpawned > self:GetNumberFlowers() then break end
		
		local posFlower = flower:GetAbsOrigin()

		
		
		local entUnit = CreateUnitByName("treant_flower_creature", posFlower, true, nil, nil, teamCaster)
		flowersSpawned = flowersSpawned + 1
	end
	
	for _, mushroom in pairs (mushrooms) do
		if muchsroomsSpawned > self:GetNumberMushrooms() then break end
		
		local posMushroom = tree:GetAbsOrigin()

		local entUnit = CreateUnitByName("treant_mushroom_creature", posMushroom, true, nil, nil, teamCaster)
		mushroomsSpawned = mushroomsSpawned + 1
	end
end

