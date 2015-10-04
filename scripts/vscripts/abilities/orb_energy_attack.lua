function Thinker( event )
	local caster = event.caster
	local ability = event.ability
	local ability_level = ability:GetLevel() - 1

	-- Ability variables
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level) 
	local explosion_radius = ability:GetLevelSpecialValueFor("explosion_radius", ability_level) 
	local damage = ability:GetLevelSpecialValueFor("damage", ability_level) 
	local knockback = ability:GetLevelSpecialValueFor("knockback", ability_level) 

		-- Make the spirit a physics unit
	Physics:Unit(unit)
	 
	-- General properties
	unit:PreventDI(true)
	unit:SetAutoUnstuck(false)
	unit:SetNavCollisionType(PHYSICS_NAV_NOTHING)
	unit:FollowNavMesh(false)
	unit:SetPhysicsVelocityMax(spirit_speed)
	unit:SetPhysicsVelocity(spirit_speed * RandomVector(1))
	unit:SetPhysicsFriction(0)
	unit:Hibernate(false)
	unit:SetGroundBehavior(PHYSICS_GROUND_LOCK)
end