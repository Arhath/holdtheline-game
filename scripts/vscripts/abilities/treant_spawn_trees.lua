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
		tree = CreateTempTree( SpawnLocation, 40 )
		ParticleManager:CreateParticle("particles/units/heroes/hero_venomancer/venomancer_ward_spawn_d.vpcf", PATTACH_ABSORIGIN, tree)
	end
end

