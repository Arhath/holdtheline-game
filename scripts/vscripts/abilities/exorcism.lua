--[[
	Author: Noya, physics by BMD
	Date: 02.02.2015.
	Spawns spirits for exorcism and applies the modifier that takes care of its logic
]]
require( "libraries/physics")

function ExorcismStart( event )
	local caster = event.caster
	caster.radiusFactor = 0
	local ability = event.ability
	local radius = ability:GetLevelSpecialValueFor( "radius", ability:GetLevel() - 1 )
	local duration = ability:GetLevelSpecialValueFor( "duration", ability:GetLevel() - 1 )
	local spirits = ability:GetLevelSpecialValueFor( "spirits", ability:GetLevel() - 1 )
	local delay_between_spirits = ability:GetLevelSpecialValueFor( "delay_between_spirits", ability:GetLevel() - 1 )
	local unit_name = "dummy_unit"

	-- Witchcraft level
	local witchcraft_ability = caster:FindAbilityByName("death_prophet_witchcraft_datadriven")
	if not witchcraft_ability then
		caster:FindAbilityByName("death_prophet_witchcraft")
	end

	-- If witchcraft ability found, get the number of extra spirits and increase
	if witchcraft_ability then
		local extra_spirits = witchcraft_ability:GetLevelSpecialValueFor( "exorcism_1_extra_spirits", witchcraft_ability:GetLevel() - 1 )
		if extra_spirits then
			spirits = spirits + extra_spirits
		end
	end

	-- Initialize the table to keep track of all spirits
	caster.spirits = {}
	print("Spawning "..spirits.." spirits")
	for i=1,spirits do
		Timers:CreateTimer(i * delay_between_spirits, function()
			local unit = CreateUnitByName(unit_name, caster:GetAbsOrigin(), true, caster, caster, caster:GetTeamNumber())

			-- The modifier takes care of the physics and logic
			ability:ApplyDataDrivenModifier(caster, unit, "modifier_exorcism_spirit", {})
			
			-- Add the spawned unit to the table
			table.insert(caster.spirits, unit)

			-- Initialize the number of hits, to define the heal done after the ability ends
			unit.numberOfHits = 0

			-- Double check to kill the units, remove this later
			Timers:CreateTimer(duration+10, function() if unit and IsValidEntity(unit) then unit:RemoveSelf() end end)
		end)
	end
end

-- Movement logic for each spirit
-- Units have 4 states: 
	-- acquiring: transition after completing one target-return cycle.
	-- target_acquired: tracking an enemy or point to collide
	-- returning: After colliding with an enemy, move back to the casters location
	-- end: moving back to the caster to be destroyed and heal
function ExorcismPhysics( event )
	local caster = event.caster
	local unit = event.target
	local ability = event.ability
	local radius = ability:GetLevelSpecialValueFor( "radius", ability:GetLevel() - 1 )
	local duration = ability:GetLevelSpecialValueFor( "duration", ability:GetLevel() - 1 )
	local spirit_speed = ability:GetLevelSpecialValueFor( "spirit_speed", ability:GetLevel() - 1 )
	local min_damage = ability:GetLevelSpecialValueFor( "min_damage", ability:GetLevel() - 1 )
	local max_damage = ability:GetLevelSpecialValueFor( "max_damage", ability:GetLevel() - 1 )
	local max_damage = ability:GetLevelSpecialValueFor( "max_damage", ability:GetLevel() - 1 )
	local average_damage = ability:GetLevelSpecialValueFor( "average_damage", ability:GetLevel() - 1 )
	local give_up_distance = ability:GetLevelSpecialValueFor( "give_up_distance", ability:GetLevel() - 1 )
	local max_distance = ability:GetLevelSpecialValueFor( "max_distance", ability:GetLevel() - 1 )
	local heal_percent = ability:GetLevelSpecialValueFor( "heal_percent", ability:GetLevel() - 1 ) * 0.01
	local min_time_between_attacks = ability:GetLevelSpecialValueFor( "min_time_between_attacks", ability:GetLevel() - 1 )
	local abilityDamageType = ability:GetAbilityDamageType()
	local abilityTargetType = ability:GetAbilityTargetType()
	local particleDamage = "particles/units/heroes/hero_death_prophet/death_prophet_exorcism_attack.vpcf"
	local particleDamageBuilding = "particles/units/heroes/hero_death_prophet/death_prophet_exorcism_attack_building.vpcf"
	--local particleNameHeal = "particles/units/heroes/hero_nyx_assassin/nyx_assassin_vendetta_start_sparks_b.vpcf"

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
	unit:Hibernate(true)
	unit:SetGroundBehavior(PHYSICS_GROUND_LOCK)

	-- This is to skip frames
	local frameCount = 0

	-- Store the damage done
	unit.damage_done = 0

	-- Store the interval between attacks, starting at min_time_between_attacks
	unit.last_attack_time = GameRules:GetGameTime() - min_time_between_attacks

	-- Color Debugging for points and paths. Turn it false later!
	local Debug = true
	local pathColor = Vector(255,255,255) -- White to draw path
	local draw_duration = 3

	-- This is set to repeat on each frame
	unit:OnPhysicsFrame(function(unit)

		-- Move the unit orientation to adjust the particle
		unit:SetForwardVector( ( unit:GetPhysicsVelocity() ):Normalized() )

		-- Current positions
		local source = caster:GetAbsOrigin()
		local current_position = unit:GetAbsOrigin()

		-- Update the radius
		if(caster.radiusFactor ~= 0) then
			radius = radius + caster.radiusFactor*5
			if (radius > max_distance) then
			radius = max_distance
			elseif (radius <= 100) then
				radius = 100
			end
		end

		-- Print the path on Debug mode
		if Debug then DebugDrawCircle(current_position, pathColor, 0, 2, true, draw_duration) end

		local enemies = nil

		-- Use this if skipping frames is needed (--if frameCount == 0 then..)
		frameCount = (frameCount + 1) % 3

		-- Movement and Collision detection are state independent

		-- MOVEMENT	

		-- MAX DISTANCE CHECK
		-- Get the direction
		local diff = source - current_position
        diff.z = 0
        local direction = diff:Normalized()

		if(diff:Length()<radius) then
			local scale = diff:Length()/radius
        	local angle = 90 + scale * 90
        	direction = RotatePosition(Vector(0,0,0), QAngle(0,angle,0), direction)
        elseif (diff:Length()<max_distance) then
        	local scale = (diff:Length()-radius)/radius
        	local angle = 90 - scale * 90
        	direction = RotatePosition(Vector(0,0,0), QAngle(0,angle,0), direction)
        	--print(scale)
        end

        print(diff:Length())

		-- Calculate the angle difference
		local angle_difference = RotationDelta(VectorToAngles(unit:GetPhysicsVelocity():Normalized()), VectorToAngles(direction)).y
		
		-- Set the new velocity
		if math.abs(angle_difference) < 5 then
			-- CLAMP
			local newVel = unit:GetPhysicsVelocity():Length() * direction
			unit:SetPhysicsVelocity(newVel)
		elseif angle_difference > 0 then
			local newVel = RotatePosition(Vector(0,0,0), QAngle(0,10,0), unit:GetPhysicsVelocity())
			unit:SetPhysicsVelocity(newVel)
		else		
			local newVel = RotatePosition(Vector(0,0,0), QAngle(0,-10,0), unit:GetPhysicsVelocity())
			unit:SetPhysicsVelocity(newVel)
		end


		-- COLLISION CHECK
		local vEnemies = FindUnitsInRadius( unit:GetTeamNumber(), unit:GetOrigin(), nil, 100, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, 0, false )

		-- Do physical damage here, and increase hit counter. 
		if vEnemies ~= nil then
			for _, enemy in pairs(vEnemies) do
				-- Damage
				if not enemy:IsAttackImmune() then
					local damage_table = {}

					local spirit_damage = RandomInt(min_damage,max_damage)
					damage_table.victim = enemy
					damage_table.attacker = caster					
					damage_table.damage_type = abilityDamageType
					damage_table.damage = spirit_damage

					ApplyDamage(damage_table)

					-- Calculate how much physical damage was dealt
					local targetArmor = enemy:GetPhysicalArmorValue()
					local damageReduction = ((0.06 * targetArmor) / (1 + 0.06 * targetArmor))
					local damagePostReduction = spirit_damage * (1 - damageReduction)

					unit.damage_done = unit.damage_done + damagePostReduction

					-- Damage particle, different for buildings
					if enemy.InvulCount == 0 then
						local particle = ParticleManager:CreateParticle(particleDamageBuilding, PATTACH_ABSORIGIN, enemy)
						ParticleManager:SetParticleControl(particle, 0, enemy:GetAbsOrigin())
						ParticleManager:SetParticleControlEnt(particle, 1, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)
					elseif unit.damage_done > 0 then
						local particle = ParticleManager:CreateParticle(particleDamage, PATTACH_ABSORIGIN, enemy)
						ParticleManager:SetParticleControl(particle, 0, enemy:GetAbsOrigin())
						ParticleManager:SetParticleControlEnt(particle, 1, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)
					end

					-- Increase the numberOfHits for this unit
					unit.numberOfHits = unit.numberOfHits + 1 

					print(unit.numberOfHits)
					-- Fire Sound on the target unit
					enemy:EmitSound("Hero_DeathProphet.Exorcism.Damage")
					
					-- Update the attack time of the unit.
					unit.last_attack_time = GameRules:GetGameTime()
				end
			end
		end

    end)
end

-- Change the state to end when the modifier is removed
function ExorcismEnd( event )
	local caster = event.caster
	local targets = caster.spirits

	print("Exorcism End")
	caster:StopSound("Hero_DeathProphet.Exorcism")
	for _,unit in pairs(targets) do		
	   	if unit and IsValidEntity(unit) then
    	  	unit.state = "end"
    	end
	end

	-- Reset the last_targeted
	caster.last_targeted = nil
end

-- Kill all units when the owner dies or the spell is cast while the first one is still going
function ExorcismDeath( event )
	local caster = event.caster
	local targets = caster.spirits or {}

	print("Exorcism Death")
	caster:StopSound("Hero_DeathProphet.Exorcism")
	for _,unit in pairs(targets) do		
	   	if unit and IsValidEntity(unit) then
    	  	unit:SetPhysicsVelocity(Vector(0,0,0))
	        unit:OnPhysicsFrame(nil)

			-- Kill
	        unit:ForceKill(false)
    	end
	end
end


function ToggleOn( event )
	local caster = event.caster

	-- Make sure that the opposite ability is toggled off.
	ResetToggleState( caster, event.opposite_ability )

	-- Change the movement factor
	caster.radiusFactor = event.radiusFactor
end

--[[
	Author: Ractidous
	Date: 09.02.2015.
	Reset the movement factor.
]]
function ToggleOff( event )
	event.caster.radiusFactor = 0
end

--[[
	Author: Ractidous
	Date: 09.02.2015.
	Reset the toggle state.
]]
function ResetToggleState( caster, abilityName )
	local ability = caster:FindAbilityByName( abilityName )
	if ability:GetToggleState() then
		ability:ToggleAbility()
	end
end