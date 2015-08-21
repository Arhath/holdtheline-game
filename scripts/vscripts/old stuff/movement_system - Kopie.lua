if CMovementSystem == nil then
	CMovementSystem = class({})
end

MAX_TIME_FOR_TARGET = 10.0
RANGE_NEXT_WAYPOINT = 400.0
AGGRO_RANGE_MAX		= 900.0
AGGRO_RANGE_MIN		= 400.0
AGGRO_UNITS_MIN_RANGE = 20
ATTACK_AGGRO_AOE = 400.0

MAX_TIME_IGNORE = 5.0




function CMovementSystem:OnNPCSpawned( event )
	local spawnedUnit = EntIndexToHScript( event.entindex )
	if not spawnedUnit or spawnedUnit:GetClassname() == "npc_dota_thinker" or spawnedUnit:IsPhantom() or spawnedUnit:GetClassname() == "npc_dota_companion" or spawnedUnit:GetClassname() == "npc_dota_elder_titan_ancestral_spirit" then
		return
	end

	----print("checking unit for movement system")
	if spawnedUnit:GetTeamNumber() == self:GetTeam() then
		----print("inserting unit to table movement system")
		table.insert(self._vUnits, spawnedUnit)
		spawnedUnit.MovementSystem =
		{
			Type = "attacker",
			NextWaypoint = nil,
			TargetList = {},
			Target = nil,
			IgnoreTarget = nil,
			IgnoreTime = 0,
			TargetTime = 0,
			MaxTargetTime = 0,
			CanChangeTarget = true,
		}
	end

	if spawnedUnit:GetTeamNumber() ~= self:GetTeam() then
		table.insert(self._vAggroUnits, spawnedUnit)
		spawnedUnit.MovementSystem =
		{
			Type = "defender",
			TargetList = {},
		}
	end

end


function CMovementSystem:OnEntityKilled( event )
	local killedUnit = EntIndexToHScript( event.entindex_killed )

	if killedUnit then
		for i, unit in pairs(self._vUnits) do
			if unit == killedUnit then
				table.remove(self._vUnits, i)
				if unit.MovementSystem.Target ~= nil then
					for k, t in pairs(unit.MovementSystem.Target.MovementSystem.TargetList) do
						if unit == t then
							table.remove(unit.MovementSystem.Target.MovementSystem.TargetList, k)
						end
					end
				end
				----print("removing unit from table movement system")
			end
		end

		for i, unit in pairs(self._vAggroUnits) do
			if unit == killedUnit then
				table.remove(self._vAggroUnits, i)
			end
		end
	end
end

function CMovementSystem:OnEntityHurt( keys)
	local damagebits = keys.damagebits -- This might always be 0 and therefore useless
	if keys.entindex_attacker ~= nil and keys.entindex_killed ~= nil then
		local entCause = EntIndexToHScript(keys.entindex_attacker)
		local entVictim = EntIndexToHScript(keys.entindex_killed)
	
		----print(string.format("damagedone: %d", damagebits))
		if entCause.MovementSystem == nil or entVictim.MovementSystem == nil then
			return
		end

		if entCause.MovementSystem.Type == "defender" and entVictim.MovementSystem.Type == "attacker" then
			local newTargets =
			FindUnitsInRadius(
				entVictim:GetTeamNumber(),
				entVictim:GetAbsOrigin(),
				nil,
				ATTACK_AGGRO_AOE,
				self._nTeamEnemy,
				DOTA_UNIT_TARGET_ALL,
				DOTA_UNIT_TARGET_FLAG_NONE,
				FIND_CLOSEST,
				false
			)

			for _, nt in pairs(newTargets) do
				self:UnitAggroTarget(nt, entCause, MAX_TIME_FOR_TARGET, false)
			end

			self:UnitAggroTarget(entVictim, entCause, MAX_TIME_FOR_TARGET, true)
		end

		if entCause.MovementSystem.Type == "attacker" and entVictim.MovementSystem.Type == "defender" then
			self:UnitAggroTarget(entCause, entVictim, MAX_TIME_FOR_TARGET, true)
		end
	end
end


function CMovementSystem:Init( gameMode, team)
	self._gameMode = gameMode
	self._nTeam = team

	if self._nTeam == DOTA_TEAM_GOODGUYS then
		self._nTeamEnemy = DOTA_TEAM_BADGUYS
	elseif self._nTeam == DOTA_TEAM_BADGUYS then
		self._nTeamEnemy = DOTA_TEAM_GOODGUYS
	end

	self._vUnits = {}
	self._vAggroUnits = {}

	self._vWaypoints =
	{
	"path_invader1_1", "path_invader1_2", "path_invader1_3", "path_invader1_4", "path_invader1_5", "path_invader1_6", "path_invader1_7", "path_invader1_8", "end",
	"path_invader2_1", "path_invader2_2", "path_invader2_3", "path_invader2_4", "path_invader2_5", "path_invader2_6", "path_invader1_7", "path_invader1_8", "end"
	}

	Timers:CreateTimer(function()
    	self:Think()
		return self:GetTickrate()
	end
    )
end


function CMovementSystem:Think()
	for _, au in pairs(self._vAggroUnits) do
		local aggroRange = AGGRO_RANGE_MAX - (#au.MovementSystem.TargetList * (AGGRO_RANGE_MAX - AGGRO_RANGE_MIN) / AGGRO_UNITS_MIN_RANGE)
		--print(string.format("aggrorange: %d  numtargets: %d", aggroRange, #au.MovementSystem.TargetList))
		local pos = au:GetAbsOrigin()

		local newTargets =
			FindUnitsInRadius(
				au:GetTeamNumber(),
				pos,
				nil,
				aggroRange,
				self._nTeamEnemy,
				DOTA_UNIT_TARGET_ALL,
				DOTA_UNIT_TARGET_FLAG_NONE,
				FIND_CLOSEST,
				false
			)

		for _, nt in pairs(newTargets) do
			self:UnitAggroTarget(nt, au, MAX_TIME_FOR_TARGET, false)
		end
	end

	for _,unit in pairs(self._vUnits) do
		self:UnitThink(unit)
	end
end

function CMovementSystem:UnitThink( unit )
	--local system = unit.MovementSystem

	if unit.MovementSystem.IgnoreTarget ~= nil then
		if unit.MovementSystem.IgnoreTime >= MAX_TIME_IGNORE then
			unit.MovementSystem.IgnoreTarget = nil
			unit.MovementSystem.IgnoreTime = 0
			print("unignoring target")
		else
			print(string.format("ignore time: %d", unit.MovementSystem.IgnoreTime))
			unit.MovementSystem.IgnoreTime = unit.MovementSystem.IgnoreTime + self:GetTickrate()
		end
	end

	if unit.MovementSystem.Target ~= nil then
		if unit.MovementSystem.TargetTime >= unit.MovementSystem.MaxTargetTime then

			unit.MovementSystem.IgnoreTarget = unit.MovementSystem.Target
			unit.MovementSystem.IgnoreTime = 0

			for i, t in pairs(unit.MovementSystem.Target.MovementSystem.TargetList) do
				if unit == t then
					table.remove(unit.MovementSystem.Target.MovementSystem.TargetList, i)
				end
			end

			unit.MovementSystem.IgnoreTarget = unit.MovementSystem.Target
			unit.MovementSystem.IgnoreTime = 0
			unit.MovementSystem.Target = nil
			unit.MovementSystem.TargetTime = 0
			unit.MovementSystem.MaxTargetTime = 0
			unit.MovementSystem.CanChangeTarget = true
			unit.MovementSystem.NextWaypoint = nil

			print("max target time reached")
			print("ignore unit: " .. unit.MovementSystem.IgnoreTarget:GetName())
		else
			--print(string.format("target time: %d", unit.MovementSystem.TargetTime))
			unit.MovementSystem.TargetTime = unit.MovementSystem.TargetTime + self:GetTickrate()
		end
	end

	if unit.MovementSystem.Target ~= nil then
		self:UnitAttackTarget(unit, unit.MovementSystem.Target)
		--print("unitthinkattack")
	else
		----print("UnitThinkMovement")
		self:UnitThinkMovement(unit)
	end
end

function  CMovementSystem:UnitAggroTarget( unit, target, time, always)
	local bNewTarget = true

	if not always then

		if unit.MovementSystem.Target ~= nil then
			if not unit.MovementSystem.CanChangeTarget then
				--print("not setting target")
				return
			end
		end

		if unit.MovementSystem.IgnoreTarget == target then
			return
		end
	end

	--print("settingTarget")

	if target.MovementSystem.Type == "defender" then
		if #target.MovementSystem.TargetList > 0 then

			for _, ot in pairs(target.MovementSystem.TargetList) do
				if ot == unit then
					bNewTarget = false
					break
				end
			end

		end

		if bNewTarget then
			table.insert(target.MovementSystem.TargetList, unit)
		end
	end

	unit.MovementSystem.Target = target
	unit.MovementSystem.TargetTime = 0
	unit.MovementSystem.MaxTargetTime = time
	unit.MovementSystem.CanChangeTarget = false
	unit.MovementSystem.IgnoreTarget = nil
	unit.MovementSystem.IgnoreTime = 0
	--print("new aggro Target: " .. unit.MovementSystem.Target:GetName())
end


function CMovementSystem:GetTeam(  )
	return self._nTeam
end


function CMovementSystem:UnitThinkMovement( unit )
	if unit:IsNull() then
		return
	end

	local posUnit = unit:GetAbsOrigin()
	local bSetBest = true
	local bestDist = nil
	local nBest = nil

	if unit.MovementSystem.NextWaypoint == nil then
		--print("finding next waypoint")
		for i, str in pairs(self._vWaypoints) do
			if str == "end" then
				if self._vWaypoints[i + 1] == nil then
					break
				end
			else
				--print("best waypoint math")
				local waypoint = Entities:FindByName(nil, str)
				if waypoint ~= nil then
					--print("got a waypoint")
					local orig = waypoint:GetOrigin()
					local dist = GridNav:FindPathLength(posUnit, orig)

					if nBest == nil then
						bSetBest = true
					else
						if dist < bestDist then
							--print("setting bool")
							bSetBest = true
						end
					end

					if bSetBest then
						bestDist = dist
						nBest = i

						bSetBest = false
						--print(string.format("setting best waypoint: %d", nBest))
					end
				end
			end
		end

		if nBest ~= nil then
			unit.MovementSystem.NextWaypoint = nBest
		end
	end

	local n = unit.MovementSystem.NextWaypoint
	local entWp = Entities:FindByName(nil, self._vWaypoints[n])

	if entWp ~= nil then
		--print("found waypoint")
		local loc = entWp:GetAbsOrigin()
		local dist = GridNav:FindPathLength(posUnit, loc)

		self:UnitMoveToPosition(unit, loc)

		if dist < RANGE_NEXT_WAYPOINT then
			if self._vWaypoints[n + 1] ~= "end" then
				--print(string.format("waypoint reached setting next: %d", n + 1))
				unit.MovementSystem.NextWaypoint = n + 1
			end
		end
	end
end


function CMovementSystem:UnitMoveToPosition( unit, pos )
	--print("moveunit")
	order =
		{
			UnitIndex = unit:entindex(),
			OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
			Position = pos,
		}
	ExecuteOrderFromTable(order)
end


function CMovementSystem:UnitAttackTarget( unit, target )
	order =
		{
			UnitIndex = unit:entindex(),
			OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
			TargetIndex = target:entindex(),
		}
	ExecuteOrderFromTable(order)
end


function CMovementSystem:UnitGetMovementSystem( unit )
	return unit.MovementSystem
end

function CMovementSystem:GetTickrate()
	return 0.25
end