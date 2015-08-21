require( "misc/utility_functions" )


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

local UTILITY_TYPE_STUN = 1
local UTILITY_TYPE_MOVEMENT = 2
local UTILITY_TYPE_OBSTRUCTION = 3

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

	--print( "BloodlustThink" )

	if thisEntity == nil or thisEntity:IsNull() or not thisEntity:IsAlive() then
		print("unit died stopping ai for unit")
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
		print("delaying abilities")
	else
		print("no delay")
	end

	--print (string.format( "movement system Desire: %d", desire))
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
	print("abilityealuate")
	self.ID = 7

	self.unit = thisEntity

	local abilityCount = self.unit:GetAbilityCount()
	local bestAbility = nil
	local bestValue = 0
	local position = nil
	local target = nil


	print(string.format("ability count: %d", abilityCount))

	for i = 0, 8 do
		local ability = self.unit:GetAbilityByIndex(i)

		if ability ~= nil and ability:IsFullyCastable() then
			print("ability: " .. ability:GetName())
			local behavior = ability:GetBehavior()
			local level = ability:GetLevel()

			print(string.format("level: %d", level))
			print(bit.band(behavior, DOTA_ABILITY_BEHAVIOR_PASSIVE))
			if bit.band(behavior, DOTA_ABILITY_BEHAVIOR_PASSIVE) == 0 and level > 0 then
				print("ability no passive and level > 0")
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
				local utility = 0--ability:GetSpecialValueFor("utility_type")
				local utilityValue = 0--ability:GetSpecialValueFor("utility_value")

				local bCasting = true
				local numAllys = 0

				if casting ~= CASTING_ALAWAYS then
					if casting == CASTING_INFIGHT then
						if self.unit.MovementSystem.Target == nil then
							bCasting = false
						end
					end
				end

				if bCasting then
					print(string.format("castrange: %d", castRange))
					if search == 0 then
						if castRange ~= 0 then
							search = castRange * 1.5
						else
							search = 700
						end
					end
					print(string.format("radius: %d", radius))

					if bit.band(behavior, DOTA_ABILITY_BEHAVIOR_POINT) > 0 then
						local team = DOTA_UNIT_TARGET_TEAM_ENEMY
						local unitType = targetType
						print("behavior point")
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

						if utility == 0 then
							position = UnitFindBestTargetPositionInAoe(self.unit, search, radius, 0, team, unitType)
						else
							position = UnitFindBestTargetPositionInAoeUtility(self.unit, search, radius, 0, team, unitType, utility)
						end

						if position ~= nil then
							value = 2.5
						end
					elseif bit.band(behavior, DOTA_ABILITY_BEHAVIOR_UNIT_TARGET) > 0 then
						print("behavior target")
						local allAllys = FindUnitsInRadius( self.unit:GetTeamNumber(), self.unit:GetOrigin(), nil, search, targetTeam, targetType, 0, 0, false )

						if utility == UTILITY_TYPE_MOVEMENT then
							if utilityValue ~= 0 then
								for i, ally in pairs(allAllys) do
									local posUnit = ally:GetAbsOrigin()
									local vec = ally:GetAnglesAsVector()
									local pos = GetPointWithPolarOffset(posUnit, vec.yaw, utility_value)
									local dist = GridNav:FindPathLength(posUnit, pos)

									if dist == -1 then
										table.remove(allAllys, i)
									end
								end
							end
						end

						if radius == 0 then
							print("target without radius")
							if #allAllys > 0 then
								print("found target")
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
										if utility == UTILITY_TYPE_STUN or utility == UTILITY_TYPE_MOVEMENT then
											local isChannel = false
											for _, ally in pairs(allAllys) do
												if ally:IsChanneling() then
													target = ally
													isChannel = true
												end
											end
										end
										if not isChannel then
											target = allAllys[RandomInt(1, #allAllys)]
											value = 2.5
										end
									else
										for _, unit in pairs(allAllys) do
											local efficiency = math.min(unit:GetHealth(), abilityValue)
											if unit:IsChanneling() then
												efficiency = efficiency + abilityValue * 4
											end
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
							print("target with radius")
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
										if utility == UTILITY_TYPE_STUN or utility == UTILITY_TYPE_MOVEMENT then
											local bonus = 0

											for _, unit in pairs(units) do
												if unit:IsChanneling() then
													bonus = bonus + 2
												end
											end

											if #units + bonus > numAllys then
												target = ally
												numAllys = #units
												value = #units
											end
										else
											if #units > numAllys then
												target = ally
												numAllys = #units
												value = #units
											end
										end
									else
										local targUnits = 0

										for _, unit in pairs(units) do
											local efficiency = math.min(unit:GetHealth(), abilityValue)
											if unit:IsChanneling() then
												efficiency = efficiency + abilityValue * 3
											end
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
						print("behavior no target")
						print(radius)
						if radius == 0 then

							if utility == UTILITY_TYPE_MOVEMENT then
								print("movement utility")
								if utilityValue ~= 0 then
									for i, ally in pairs(allAllys) do
										local posUnit = self.unit:GetAbsOrigin()
										local vec = self.unit:GetAnglesAsVector()
										local pos = GetPointWithPolarOffset(posUnit, vec.yaw, utility_value)
										local dist = GridNav:FindPathLength(posUnit, pos)

										if dist == -1 then
											bCasting = false
										end
									end
								end
							end

							if bCasting then
							print("casting ability")
								local units = {}

								if casting == CASTING_ONSIGHT then
									print("casting onsight")
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
										print("dmg or other")
										units = FindUnitsInRadius( self.unit:GetTeamNumber(), self.unit:GetOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, unitType, 0, 0, false )
									end

									if #units > 0 then
										value = 2.5
									end 
								else
									value = 2.5
								end
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
							print("asdasdsada sdasdasdsadasdsad")
							local units = FindUnitsInRadius( self.unit:GetTeamNumber(), self.unit:GetOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, unitType, 0, 0, false )

							if utility == UTILITY_TYPE_STUN or utility == UTILITY_TYPE_MOVEMENT then
								local bonus = 0

								for _, unit in pairs(units) do
									if unit:IsChanneling() then
										bonus = bonus + 2
									end
								end

								if #units + bonus > numAllys then
									target = ally
									numAllys = #units
									value = #units + bonus
								end

							elseif #units > numAllys then
								target = unit
								numAllys = #units
								value = #units
							end
						end
					end

					if bit.band(behavior, DOTA_ABILITY_BEHAVIOR_CHANNELLED) > 0 then
						print("behavior channeled")
					end


					if value > bestValue then
						bestValue = value
						bestAbility = ability
						print("setting best ability")
					end
				end
			end
		end
	end

	print(string.format("value: %f", bestValue))
	local desire = 0

	if bestAbility ~= nil then
		print("found best ability")

		self.ability = bestAbility
		desire = bestValue

		if position ~= nil then
			print("setting point order")	

			self.order =
			{
				OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
				UnitIndex = self.unit:entindex(),
				Position = position,
				AbilityIndex = self.ability:entindex()
			}
		end

		if target ~= nil then
			print("setting target order")	

			self.order =
			{
				OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
				UnitIndex = self.unit:entindex(),
				TargetIndex = target:entindex(),
				AbilityIndex = self.ability:entindex()
			}
		end

		if target == nil and position == nil then
			print("setting no target order")	

			self.order =
			{
				OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
				UnitIndex = self.unit:entindex(),
				AbilityIndex = self.ability:entindex()
			}
		end
		--print (string.format( "Earthsplitter Desire: %d", desire))
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