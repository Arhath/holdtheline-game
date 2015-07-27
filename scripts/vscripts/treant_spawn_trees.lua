treant_spawn_trees = class ({})

function treant_spawn_trees:GetAOERadius()
	return self:GetSpecialValueFor( "spawn_radius" )
end

function treant_spawn_trees:GetNumberTrees()
	return self:GetSpecialValueFor( "number_trees" )
end

function treant_spawn_trees:OnSpellStart() 
	local caster = self:GetCaster()
	local posCaster = caster:GetAbsOrigin()
	
	for n = 0, self:GetNumberTrees() do	
		local SpawnLocation = posCaster + RandomVector( RandomFloat( 300, self:GetAOERadius() )) 
		CreateTempTree( SpawnLocation, 60 )
	end
end

