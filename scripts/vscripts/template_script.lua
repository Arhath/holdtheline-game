require( "utility_functions" )


local TICKRATE = 0.5
local behaviorSystem = {}

local MOVEMENT_SYSTEM_STATE_ACTIVE = 1
local MOVEMENT_SYSTEM_STATE_PAUSE = 2

--[[-------------------------------------------------------------------------
	Setup the focus on ancient think on spawn
-----------------------------------------------------------------------------]]


function Spawn( entityKeyValues )

	behaviorSystem = AICore:CreateBehaviorSystem( { BehaviorMovementSystem, BehaviorAbility } )

	Timers:CreateTimer(2, function()
		return AIThink()
	end
	)
end


--[[-------------------------------------------------------------------------
-----------------------------------------------------------------------------]]


function AIThink()

	----Print( "BloodlustThink" )

	if thisEntity == nil or thisEntity:IsNull() or not thisEntity:IsAlive() then
		--Print("unit died stopping ai for unit")
		return nil
	end

	behaviorSystem:Think()

	return TICKRATE
end


--[[-------------------------------------------------------------------------
-----------------------------------------------------------------------------]]


BehaviorMovementSystem = {}

function BehaviorMovementSystem:Evaluate()
	self.ID = 0

	self.unit = thisEntity
	local desire = 0.5

	local rand = RandomInt(1, 100)

	if rand > 50 then
		desire = 2.7
		--Print("delaying abilities")
	else
		--Print("no delay")
	end

	----Print (string.format( "movement system Desire: %d", desire))
	return desire
end


function BehaviorMovementSystem:Begin()
	self.endTime = GameRules:GetGameTime()
	self.unit.lastBehavior = self.ID
	self.unit.MovementSystem.State = MOVEMENT_SYSTEM_STATE_ACTIVE
	self.unit.MovementSystem.ForceUpdate = true
end

BehaviorMovementSystem.Continue = BehaviorMovementSystem.Begin --if we re-enter this ability, we might have a different target; might as well do a full reset

function BehaviorEarthsplitter:Think(dt)
end


--[[-------------------------------------------------------------------------
-----------------------------------------------------------------------------]]


BehaviorAbility = {}

function BehaviorAbility:Evaluate()
	--Print("abilityealuate")
	self.ID = 7

	self.unit = thisEntity

	local abilityCount = self.unit:GetAbilityCount()
	local bestAbility = nil
	local bestValue = 0
	local position = nil
	local target = nil


	--Print(string.format("ability count: %d", abilityCount))

	for i = 0, 8 do
		local ability = self.unit:GetAbilityByIndex(i)

		if ability ~= nil and ability:IsFullyCastable() then
			--Print("ability: " .. ability:GetName())
			local behavior = ability:GetBehavior()
			local level = ability:GetLevel()

			--Print(string.format("level: %d", level))
			--Print(bit.band(behavior, DOTA_ABILITY_BEHAVIOR_PASSIVE))
			if bit.band(behavior, DOTA_ABILITY_BEHAVIOR_PASSIVE) == 0 and level > 0 then
				--Print("ability no passive and level > 0")
				local value = 0

				local abilityType = ability:GetAbilityType()
				local targetType = ability:GetAbilityTargetType()
				local targetTeam = ability:GetAbilityTargetTeam()
				local castRange = ability:GetCastRange()
				local search = 700.0

				--Print(string.format("castrange: %d", castRange))
				if castRange ~= 0 then
					search = castRange * 1.5
				end

				local radius = ability:GetSpecialValueFor("radius")
				--Print(string.format("radius: %d", radius))

				if bit.band(behavior, DOTA_ABILITY_BEHAVIOR_POINT) > 0 then
					--Print("behavior point")
					if radius == 0 then
						radius = 200.0
					end
					if targetTeam == 0 then
						position = UnitFindBestTargetPositionInAoe(self.unit, search, radius, 0, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL)
					else
						if targetType == 0 then
							position = UnitFindBestTargetPositionInAoe(self.unit, search, radius, 0, targetTeam, DOTA_UNIT_TARGET_ALL)
						else
							position = UnitFindBestTargetPositionInAoe(self.unit, search, radius, 0, targetTeam, targetType)
						end
					end
					if position ~= nil then
						value = 2.5
					end
				elseif bit.band(behavior, DOTA_ABILITY_BEHAVIOR_UNIT_TARGET) > 0 then
					--Print("behavior target")
					local allAllys = FindUnitsInRadius( self.unit:GetTeamNumber(), self.unit:GetOrigin(), nil, search, targetTeam, targetType, 0, 0, false )

					local numAllys = 0

					if radius == 0 then
						--Print("target without radius")
						if #allAllys > 0 then
							--Print("found target")
							target = allAllys[RandomInt(1, #allAllys)]
							value = 2.5
						end
					else
						--Print("target with radius")

						for _, ally in pairs(allAllys) do
							local units = FindUnitsInRadius( self.unit:GetTeamNumber(), ally:GetOrigin(), nil, radius, targetTeam, targetType, 0, 0, false )

							if #allAllys > numAllys then
								target = ally
								numAllys = #allAllys
								value = #allAllys
							end
						end
					end
				elseif bit.band(behavior, DOTA_ABILITY_BEHAVIOR_NO_TARGET) > 0 then
					--Print("behavior no target")
					if bit.band(targetTeam, DOTA_UNIT_TARGET_TEAM_ENEMY) > 0 or bit.band(targetTeam, DOTA_UNIT_TARGET_TEAM_FRIENDLY) > 0 or bit.band(targetTeam, DOTA_UNIT_TARGET_TEAM_BOTH) > 0 then
						--Print("spell has target team")

						--Print(string.format("search: %d", search))
						local allAllys

						if targetType == 0 then
							allAllys = FindUnitsInRadius( self.unit:GetTeamNumber(), self.unit:GetOrigin(), nil, search, targetTeam, DOTA_UNIT_TARGET_ALL, 0, 0, false )
						else
							allAllys = FindUnitsInRadius( self.unit:GetTeamNumber(), self.unit:GetOrigin(), nil, search, targetTeam, targetType, 0, 0, false )
						end
						--Print(string.format("numunits: %d", #allAllys))
						if radius == 0 then
							if #allAllys > 0 then
								value = 2.5
							end
						elseif #allAllys > 0 then
							value = #allAllys
						end
					else			
						value = 2.5
					end
				end

				if bit.band(behavior, DOTA_ABILITY_BEHAVIOR_CHANNELLED) > 0 then
					--Print("behavior channeled")
				end


				if value > bestValue then
					bestValue = value
					bestAbility = ability
					--Print("setting best ability")
				end
			end
		end
	end

	--Print(string.format("value: %f", bestValue))
	local desire = 0

	if bestAbility ~= nil then
		--Print("found best ability")

		self.ability = bestAbility
		desire = bestValue

		if position ~= nil then
			--Print("setting point order")	

			self.order =
			{
				OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
				UnitIndex = self.unit:entindex(),
				Position = position,
				AbilityIndex = self.ability:entindex()
			}
		end

		if target ~= nil then
			--Print("setting target order")	

			self.order =
			{
				OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
				UnitIndex = self.unit:entindex(),
				TargetIndex = target:entindex(),
				AbilityIndex = self.ability:entindex()
			}
		end

		if target == nil and position == nil then
			--Print("setting no target order")	

			self.order =
			{
				OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
				UnitIndex = self.unit:entindex(),
				AbilityIndex = self.ability:entindex()
			}
		end
		----Print (string.format( "Earthsplitter Desire: %d", desire))
	end

	return desire
end


function BehaviorAbility:Begin()
	self.endTime = GameRules:GetGameTime() + 7
	self.unit.lastBehavior = self.ID
	self.unit.MovementSystem.State = MOVEMENT_SYSTEM_STATE_PAUSE
	self.unit.MovementSystem.ForceUpdate = true
end

BehaviorAbility.Continue = BehaviorAbility.Begin --if we re-enter this ability, we might have a different target; might as well do a full reset

function BehaviorAbility:Think(dt)
	if not self.ability:IsFullyCastable() and not self.ability:IsInAbilityPhase() and not self.ability:IsChanneling() then
		--DebugDrawText(self.unit:GetAbsOrigin(), "ending cast", true, 4)
		self.unit.MovementSystem.State = MOVEMENT_SYSTEM_STATE_ACTIVE
		self.unit.MovementSystem.ForceUpdate = true
		self.endTime = GameRules:GetGameTime()
	end
end