treant_spawn_treants = class ({})

function treant_spawn_treants:GetAOERadius()
	return self:GetSpecialValueFor( "spawn_radius" )
end

function treant_spawn_treants:GetNumberTrees()
	return self:GetSpecialValueFor( "number_treants" )
end

function treant_spawn_treants:OnSpellStart() 
	local caster = self:GetCaster()
	local posCaster = caster:GetAbsOrigin()
	local trees = GridNav:GetAllTreesAroundPoint(posCaster, self:GetAOERadius(), true)
	local teamCaster = caster:GetTeamNumber()
	local treesSpawned = 0
	
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
end

