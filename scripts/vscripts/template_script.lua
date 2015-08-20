require( "utility_functions" )


local TICKRATE = 0.5
local behaviorSystem = {}

local MOVEMENT_SYSTEM_STATE_ACTIVE = 1
local MOVEMENT_SYSTEM_STATE_PAUSE = 2

local CASTING_ALAWAYS = 1
local CASTING_ONSIGHT = 2
local CASTING_INFIGHT = 3

local ABILITY_TYPE_BUFF = 1
local ABILITY_TYPE_HEAL = 2
local ABILITY_TYPE_DEBUFF = 3
local ABILITY_TYPE_DAMAGE = 4

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
				local radius = ability:GetSpecialValueFor("aoe_radius")
				local search = ability:GetSpecialValueFor("search_radius")
				local category = ability:GetSpecialValueFor("ability_type")
				local casting = ability:GetSpecialValueFor("casting_when")
				local abilityValue = ability:GetSpecialValueFor("ability_value")

				local bCasting = true

				if casting ~= CASTING_ALAWAYS then
					if casting == CASTING_INFIGHT then
						if self.unit.MovementSystem.Target == nil then
							bCasting = false
						end
					end
				end

				if bCasting then
					--Print(string.format("castrange: %d", castRange))
					if search == 0 then
						if castRange ~= 0 then
							search = castRange * 1.5
						else
							search = 700
						end
					end
					--Print(string.format("radius: %d", radius))

					if bit.band(behavior, DOTA_ABILITY_BEHAVIOR_POINT) > 0 then
						local team = DOTA_UNIT_TARGET_TEAM_ENEMY
						local unitType = targetType
						--Print("behavior point")
						if radius == 0 then
							radius = 200.0
						end

						if category == ABILITY_TYPE_BUFF or category == ABILITY_TYPE_HEAL then
							team = DOTA_UNIT_TARGET_TEAM_FRIENDLY
						elseif category == ABILITY_TYPE_DEBUFF or category == ABILITY_TYPE_DAMAGE then
							team = DOTA_UNIT_TARGET_TEAM_ENEMY
						elseif targetTeam ~= 0 then
							team = targetTeam
						end

						if unitType == 0 then
							unitType = DOTA_UNIT_TARGET_ALL
						end

						position = UnitFindBestTargetPositionInAoe(self.unit, search, radius, 0, team, unitType)

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
								if category == ABILITY_TYPE_BUFF then
									for _, unit in pairs(allAllys) do
										local hPct = unit:GetHealth() / unit:GetMaxHealth()

										if hPct > numAllys then
											target = unit
											numAllys = hPct
											value = 2.5
										end
									end
								elseif category == ABILITY_TYPE_HEAL then
									for _, unit in pairs(allAllys) do
										if abilityValue == 0 then
											local hPct = unit:GetHealth() / unit:GetMaxHealth()

											if hPct < numAllys or numAllys == 0 and hPct ~= 1 then
												target = unit
												numAllys = hPct
												value = 2.5
											end
										else
											local efficiency = math.min(unit:GetMaxHealth() - unit:GetHealth(), abilityValue)

											if efficiency > numAllys then
												target = unit
												numAllys = efficiency
												value = 2.5
											end
										end
									end
								else
									if abilityValue == 0 then
										target = allAllys[RandomInt(1, #allAllys)]
										value = 2.5
									else
										for _, unit in pairs(allAllys) do
											local efficiency = math.min(unit:GetHealth(), abilityValue)
											if efficiency > numAllys then
												target = unit
												numAllys = efficiency
												value = 2.5
											end
										end
									end
								end
							end
						else
							--Print("target with radius")
							if category == ABILITY_TYPE_BUFF then
								for _, ally in pairs(allAllys) do
									local units = FindUnitsInRadius( ally:GetTeamNumber(), ally:GetOrigin(), nil, radius, targetTeam, targetType, 0, 0, false )
									local targetUnits = 0

									for _, unit in pairs(units) do
										local hPct = unit:GetHealth() / unit:GetMaxHealth()
										if hPct >= 0.2 then
											targetUnits = targetUnits + 1
										end
									end

									if targetUnits > numAllys then
										target = unit
										numAllys = targetUnits
										value = targetUnits
									end
								end
							elseif category == ABILITY_TYPE_HEAL then
								for _, ally in pairs(allAllys) do
									local units = FindUnitsInRadius( ally:GetTeamNumber(), ally:GetOrigin(), nil, radius, targetTeam, targetType, 0, 0, false )
									local targUnits = 0

									for _, unit in pairs(units) do
										if abilityValue == 0 then
											local hPct = unit:GetHealth() / unit:GetMaxHealth()
											if hPct <= 0.9 then
												targetUnits = targetUnits + 1
											end
										else
											local efficiency = math.min(unit:GetMaxHealth() - unit:GetHealth(), abilityValue)
											targetUnits = targetUnits + efficiency
										end
									end
									if targetUnits > numAllys then
										target = unit
										numAllys = targetUnits
										value = #units
									end
								end
							else
								for _, ally in pairs(allAllys) do
									local units = FindUnitsInRadius( ally:GetTeamNumber(), ally:GetOrigin(), nil, radius, targetTeam, targetType, 0, 0, false )

									if abilityValue == 0 then
										if #units > numAllys then
											target = ally
											numAllys = #units
											value = #units
										end
									else
										local targUnits = 0

										for _, unit in pairs(units) do
											local efficiency = math.min(unit:GetHealth(), abilityValue)
											targetUnits = targetUnits + efficiency
										end

										if targetUnits > numAllys then
											target = unit
											numAllys = targetUnits
											value = #units
										end
									end
								end
							end
						end
					elseif bit.band(behavior, DOTA_ABILITY_BEHAVIOR_NO_TARGET) > 0 then
						local unitType = targetType

						if unitType == 0 then
							unitType = DOTA_UNIT_TARGET_ALL
						end
						--Print("behavior no target")
						if radius == 0 then
							local units = {}
							if casting == CASTING_ONSIGHT then
								if category == ABILITY_TYPE_BUFF or category == ABILITY_TYPE_HEAL then
									if abilityValue == 0 then
										local hPct = self.unit:GetHealth() / self.unit:GetMaxHealth()

										if hPct >= 0.9 then
											units = FindUnitsInRadius( self.unit:GetTeamNumber(), self.unit:GetOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, unitType, 0, 0, false )
										end
									else
										local efficiency = unit:GetMaxHealth() - unit:GetHealth()
										if efficiency >= abilityValue then
											units = FindUnitsInRadius( self.unit:GetTeamNumber(), self.unit:GetOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, unitType, 0, 0, false )
										end
									end
								else
									units = FindUnitsInRadius( self.unit:GetTeamNumber(), self.unit:GetOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, unitType, 0, 0, false )
								end

								if #units > 0 then
									value = 2.5
								end 
							else
								value = 2.5
							end
						elseif category == ABILITY_TYPE_BUFF then
								local units = FindUnitsInRadius( self.unit:GetTeamNumber(), self.unit:GetOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, unitType, 0, 0, false )
								local targetUnits = 0

								for _, unit in pairs(units) do
									local hPct = unit:GetHealth() / unit:GetMaxHealth()
									if hPct >= 0.2 then
										targetUnits = targetUnits + 1
									end
								end

								if targetUnits > numAllys then
									target = unit
									numAllys = targetUnits
									value = targetUnits
								end
						elseif category == ABILITY_TYPE_HEAL then
							local units = FindUnitsInRadius( self.unit:GetTeamNumber(), self.unit:GetOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, unitType, 0, 0, false )
							local targetUnits = 0

							for _, unit in pairs(units) do
								if abilityValue == 0 then
									local hPct = unit:GetHealth() / unit:GetMaxHealth()
									if hPct <= 0.9 then
										targetUnits = targetUnits + 1
									end
								else
									local efficiency = math.min(unit:GetMaxHealth() - unit:GetHealth(), abilityValue)
									targetUnits = targetUnits + efficiency
								end
							end

							if targetUnits > numAllys then
								target = unit
								numAllys = targetUnits
								value = #units
							end
						else
							local units = FindUnitsInRadius( self.unit:GetTeamNumber(), self.unit:GetOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, unitType, 0, 0, false )

							if #units > numAllys then
								target = unit
								numAllys = #units
								value = #units
							end
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