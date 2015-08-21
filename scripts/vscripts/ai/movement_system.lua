if CMovementSystem == nil then
	CMovementSystem = class({})
end

MOVEMENT_SYSTEM_STATE_ACTIVE = 1
MOVEMENT_SYSTEM_STATE_PAUSE = 2

MOVEMENT_SYSTEM_TYPE_ATTACKER = 1
MOVEMENT_SYSTEM_TYPE_DEFENDER = 2

MAX_TARGET_TIME			= 10.0
MIN_TARGET_TIME			= 7.0
RANGE_NEXT_WAYPOINT 	= 300.0
AGGRO_RANGE_MAX			= 900.0
AGGRO_RANGE_MIN			= 400.0
AGGRO_UNITS_MIN_RANGE	= 20
ATTACK_AGGRO_AOE		= 400.0

WAYPOINT_ACTIVATION_RADIUS = 400.0
WAYPOINT_ANTI_STUCK_RADIUS = 600.0

WAYPOINT_ANTI_STUCK_TIME_MAX = 10.0

MAX_TIME_IGNORE			= 5.0
MAX_TIME_FOLLOW_NO_VISION = 4.0

MAX_DISTANCE_AGGRO = 2000.0

MAX_STUCK_TIME = 4.0

debugtimer = 0.0

AGGRO_TYPE_DAMAGE_ENEMY	= 5
AGGRO_TYPE_DAMAGE_OWN	= 3
AGGRO_TYPE_DAMAGE_AOE	= 2
AGGRO_TYPE_SIGHT		= 1

AGGRO_OVERWRITE_ALL		= 10
AGGRO_OVERWRITE_RENEW	= 2
AGGRO_OVERWRITE_NORMAL	= 1

UPDATE_INTERVALL = 0.5



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
			Type = MOVEMENT_SYSTEM_TYPE_ATTACKER,
			NextWaypoint = nil,
			TargetList = {},
			Target = nil,
			AggroType = 0,
			IgnoreTarget = nil,
			IgnoreTime = 0,
			TargetTime = 0,
			NoVisionTime = 0,
			MaxTargetTime = 0,
			MinTargetTime = 0,
			CanChangeTarget = true,
			StuckTime = 0,
			LastPosition = spawnedUnit:GetAbsOrigin(),
			State = MOVEMENT_SYSTEM_STATE_ACTIVE,
			ForceUpdate = true,
		}
	end

	if spawnedUnit:GetTeamNumber() ~= self:GetTeam() then
		table.insert(self._vAggroUnits, spawnedUnit)
		spawnedUnit.MovementSystem =
		{
			Type = MOVEMENT_SYSTEM_TYPE_DEFENDER,
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

		if entCause.MovementSystem.Type == MOVEMENT_SYSTEM_TYPE_DEFENDER and entVictim.MovementSystem.Type == MOVEMENT_SYSTEM_TYPE_ATTACKER then
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

			--DebugDrawCircle(entVictim:GetOrigin() + Vector(0, 0, 100), Vector(255, 255, 255), 0, ATTACK_AGGRO_AOE, false, 1)

			for _, nt in pairs(newTargets) do
				self:UnitAggroTarget(nt, entCause, MAX_TARGET_TIME, 4, AGGRO_TYPE_DAMAGE_AOE, AGGRO_OVERWRITE_RENEW)
			end

			self:UnitAggroTarget(entVictim, entCause, MAX_TARGET_TIME, 7, AGGRO_TYPE_DAMAGE_ENEMY, AGGRO_OVERWRITE_RENEW)
			--entVictim.MovementSystem.StuckTime = 0
		end

		if entCause.MovementSystem.Type == MOVEMENT_SYSTEM_TYPE_ATTACKER and entVictim.MovementSystem.Type == MOVEMENT_SYSTEM_TYPE_DEFENDER then

			local newTargets =
			FindUnitsInRadius(
				entCause:GetTeamNumber(),
				entCause:GetAbsOrigin(),
				nil,
				ATTACK_AGGRO_AOE,
				self._nTeamEnemy,
				DOTA_UNIT_TARGET_ALL,
				DOTA_UNIT_TARGET_FLAG_NONE,
				FIND_CLOSEST,
				false
			)

			----DebugDrawCircle(entCause:GetOrigin() + Vector(0, 0, 100), Vector(255, 255, 255), 0, ATTACK_AGGRO_AOE, false, 0.5)

			for _, nt in pairs(newTargets) do
				self:UnitAggroTarget(nt, entVictim, MAX_TARGET_TIME, 4, AGGRO_TYPE_DAMAGE_AOE, AGGRO_OVERWRITE_NORMAL)
			end

			self:UnitAggroTarget(entCause, entVictim, MAX_TARGET_TIME, 7, AGGRO_TYPE_DAMAGE_OWN, AGGRO_OVERWRITE_RENEW)
			entCause.MovementSystem.StuckTime = 0
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
	"path_invader1_1", "path_invader1_2", "path_invader1_3", "path_invader1_4", "path_invader1_5", "path_invader1_6", "path_invader1_7", "path_invader1_8", "path_invader1_9", "path_invader1_10", "path_invader1_11", "path_invader1_12", "path_invader1_13", "path_invader1_14", "path_invader1_15", "path_invader1_16", "path_invader1_17", "path_invader1_18", "path_invader1_19", "path_invader1_20", "path_invader1_21", "path_invader1_22", "path_invader1_23", "end",
	"path_invader2_1", "path_invader2_2", "path_invader2_3", "path_invader2_4", "path_invader2_5", "path_invader2_6", "path_invader2_7", "path_invader2_8", "path_invader2_9", "path_invader2_10", "path_invader2_11", "path_invader2_12", "path_invader2_13", "path_invader2_14", "path_invader2_15", "path_invader2_16", "path_invader2_17", "path_invader2_18", "path_invader2_19", "path_invader2_20", "path_invader2_21", "path_invader2_22", "path_invader2_23", "end"
	}

	self.NextUpdate = GameRules:GetGameTime()

	Timers:CreateTimer(function()
    	self:Think()
		return self:GetTickrate()
	end
    )
end


function CMovementSystem:Think()
	for _, au in pairs(self._vAggroUnits) do

		for k, t in pairs(au.MovementSystem.TargetList) do
			if t:IsNull() or not t:IsAlive() then
				table.remove(au.MovementSystem.TargetList, k)
			else
				--DebugDrawLine(au:GetOrigin() + Vector(0, 0, 100),t:GetOrigin() + Vector(0, 0, 100), 255, 255, 255, false, 0.25)
				----print(t:GetName())
			end
		end

		local aggroNum = #au.MovementSystem.TargetList
		if #au.MovementSystem.TargetList > AGGRO_UNITS_MIN_RANGE  then
			aggroNum = AGGRO_UNITS_MIN_RANGE
		end
		
		local aggroRange = AGGRO_RANGE_MAX - (aggroNum * (AGGRO_RANGE_MAX - AGGRO_RANGE_MIN) / AGGRO_UNITS_MIN_RANGE)
		----print(string.format("aggrorange: %d  numtargets: %d", aggroRange, #au.MovementSystem.TargetList))
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
			self:UnitAggroTarget(nt, au, MAX_TARGET_TIME, 4, AGGRO_TYPE_SIGHT, AGGRO_OVERWRITE_NORMAL)
		end

		--DebugDrawText(au:GetOrigin() + Vector(0, 0, 100), string.format("Targets: %d", #au.MovementSystem.TargetList), false, 0.25)
		--DebugDrawCircle(au:GetOrigin() + Vector(0, 0, 100), Vector(255, 255, 255), 0, aggroRange, false, 0.25)
	end
	local gameTime = GameRules:GetGameTime()

	for i,unit in pairs(self._vUnits) do
		if unit.MovementSystemActive ~= nil then
			if unit.MovementSystemActive == false then
				table.remove(self._vUnits, i)
			end
		else
			if self.NextUpdate >= gameTime or unit.MovementSystem.ForceUpdate then
				self:UnitThink(unit)
				unit.MovementSystem.ForceUpdate = false
			end
		end
	end

	if self.NextUpdate >= gameTime then
		self.NextUpdate = self.NextUpdate + UPDATE_INTERVALL
	end
end

function CMovementSystem:UnitThink( unit )
	--local system = unit.MovementSystem
	if unit:IsNull() or not unit:IsAlive() then
		return
	end

	if unit.MovementSystem.State ~= MOVEMENT_SYSTEM_STATE_ACTIVE then
		if unit.MovementSystem.State == MOVEMENT_SYSTEM_STATE_PAUSE then
			self:UnitSetTarget(unit, nil, false)
			unit.MovementSystem.NextWaypoint = nil
		end
	else

		if unit.MovementSystem.StuckTime >= MAX_STUCK_TIME then
			SetPhasing(unit, 2)
			unit.MovementSystem.StuckTime = 0
		else
			if (unit:GetAbsOrigin() - unit.MovementSystem.LastPosition):Length() == 0 then
				unit.MovementSystem.StuckTime = unit.MovementSystem.StuckTime + self:GetTickrate()
			else
				unit.MovementSystem.StuckTime = 0
			end

			unit.MovementSystem.LastPosition = unit:GetAbsOrigin()
		end

		if unit.MovementSystem.IgnoreTarget ~= nil then
			if unit.MovementSystem.IgnoreTime >= MAX_TIME_IGNORE then
				unit.MovementSystem.IgnoreTarget = nil
				unit.MovementSystem.IgnoreTime = 0
				--print("unignoring target")
			else
				--print(string.format("ignore time: %d", unit.MovementSystem.IgnoreTime))
				unit.MovementSystem.IgnoreTime = unit.MovementSystem.IgnoreTime + self:GetTickrate()
			end
		end

		if unit.MovementSystem.Target ~= nil then

			if not unit.MovementSystem.Target:IsAlive() then
				self:UnitSetTarget(unit, nil, false)
			else

				if unit.MovementSystem.TargetTime >= unit.MovementSystem.MaxTargetTime then

					self:UnitSetTarget(unit, nil, true)

					--print("max target time reached")
					--print("ignore unit: " .. unit.MovementSystem.IgnoreTarget:GetName())
				else

					if not unit:CanEntityBeSeenByMyTeam(unit.MovementSystem.Target) then
						if unit.MovementSystem.Target:IsInvisible() then
							self:UnitSetTarget(unit, nil, false)
						else
							if unit.MovementSystem.NoVisionTime >= MAX_TIME_FOLLOW_NO_VISION then
								self:UnitSetTarget(unit, nil, true)
							else
								unit.MovementSystem.NoVisionTime = unit.MovementSystem.NoVisionTime + self:GetTickrate()
							end
						end
					else
						unit.MovementSystem.NoVisionTime = 0
					end

					if  unit.MovementSystem.Target ~= nil then
						local posUnit = unit:GetAbsOrigin()
						local posTarget = unit.MovementSystem.Target:GetAbsOrigin()
						local dist = (posUnit - posTarget):Length()
						local distNav = GridNav:FindPathLength(posUnit, posTarget)

						if dist > MAX_DISTANCE_AGGRO or distNav > MAX_DISTANCE_AGGRO then
							self:UnitSetTarget(unit, nil, true)
						end
					end

					if  unit.MovementSystem.Target ~= nil then

						if unit.MovementSystem.TargetTime >= unit.MovementSystem.MinTargetTime then
							unit.MovementSystem.CanChangeTarget = true
						end

						--print(string.format("target time: %d", unit.MovementSystem.TargetTime))
						unit.MovementSystem.TargetTime = unit.MovementSystem.TargetTime + self:GetTickrate()
					end
				end
			end
		end

		if unit.MovementSystem.Target ~= nil then
			self:UnitAttackTarget(unit, unit.MovementSystem.Target)
			----print("unitthinkattack")
		else
			----print("UnitThinkMovement")
			self:UnitThinkMovement(unit)
		end

		--if debugtimer >= 1.0 then

		if unit.MovementSystem.Target ~= nil then
			--DebugDrawText(unit:GetOrigin() + Vector(0, 0, 100), string.format("Target: %d", unit.MovementSystem.TargetTime), false, 0.25)
		elseif unit.MovementSystem.IgnoreTarget ~= nil then
			--DebugDrawText(unit:GetOrigin() + Vector(0, 0, 100), string.format("Ignore: %d", unit.MovementSystem.IgnoreTime), false, 0.25)
		end

		--	debugtimer = 0.0
		--end

		--debugtimer = debugtimer + self:GetTickrate()
	end
end


function CMovementSystem:UnitSetTarget(unit, data, ignore)

	if unit.MovementSystem.Target ~= nil then
		for i, t in pairs(unit.MovementSystem.Target.MovementSystem.TargetList) do
			if unit == t then
				table.remove(unit.MovementSystem.Target.MovementSystem.TargetList, i)
			end
		end
	end

	if data == nil then
		if ignore then
			unit.MovementSystem.IgnoreTarget = unit.MovementSystem.Target
		else
			unit.MovementSystem.IgnoreTarget = nil
		end

		unit.MovementSystem.IgnoreTime = 0
		unit.MovementSystem.Target = nil
		unit.MovementSystem.AggroType = 0
		unit.MovementSystem.TargetTime = 0
		unit.MovementSystem.NoVisionTime = 0
		unit.MovementSystem.MaxTargetTime = 0
		unit.MovementSystem.MinTargetTime = 0
		unit.MovementSystem.CanChangeTarget = true
		unit.MovementSystem.NextWaypoint = nil
		unit.MovementSystem.StuckTime = 0
	else
		unit.MovementSystem.Target = data.target
		unit.MovementSystem.AggroType = data.aggroType
		unit.MovementSystem.TargetTime = 0
		unit.MovementSystem.NoVisionTime = 0
		unit.MovementSystem.MaxTargetTime = data.timeMax
		unit.MovementSystem.MinTargetTime = data.timeMin
		unit.MovementSystem.CanChangeTarget = false
		unit.MovementSystem.IgnoreTarget = nil
		unit.MovementSystem.IgnoreTime = 0
		unit.MovementSystem.StuckTime = 0
	end

	unit.MovementSystem.ForceUpdate = true
end


function  CMovementSystem:UnitAggroTarget( unit, target, timeMax, timeMin, aggroType, overwrite)
	local bNewTarget = true

	if unit.MovementSystem.Type == MOVEMENT_SYSTEM_TYPE_ATTACKER and target.MovementSystem.Type == MOVEMENT_SYSTEM_TYPE_DEFENDER and unit:CanEntityBeSeenByMyTeam(target) then

		if overwrite ~= AGGRO_OVERWRITE_ALL then

			if unit.MovementSystem.Target ~= nil then
				if overwrite ~= AGGRO_OVERWRITE_RENEW then
					if not unit.MovementSystem.CanChangeTarget then
						if unit.MovementSystem.AggroType >= aggroType then
							----print("not setting target")
							return
						end
					else
						if unit.MovementSystem.Target == target then
							return
						end
					end
				else
					if not unit.MovementSystem.CanChangeTarget then
						if unit.MovementSystem.AggroType > aggroType then
							return
						elseif unit.MovementSystem.Target ~= target then		
							return
						end
					end
				end
			end

			if unit.MovementSystem.IgnoreTarget == target then
				if aggroType < AGGRO_TYPE_DAMAGE_OWN then
					return
				end
			end
		end

		--print("settingTarget")
		if unit.MovementSystem.Target ~= nil then
			if unit.MovementSystem.Target == target then
				bNewTarget = false
			else
				for i, t in pairs(unit.MovementSystem.Target.MovementSystem.TargetList) do
					if unit == t then
						table.remove(unit.MovementSystem.Target.MovementSystem.TargetList, i)
					end
				end
			end
		end

		if bNewTarget then
			table.insert(target.MovementSystem.TargetList, unit)
		end

		local data = {
			target = target,
			aggroType = aggroType,
			timeMax = timeMax,
			timeMin = timeMin,
		}

		self:UnitSetTarget(unit, data, false)
		--print("new aggro Target: " .. unit.MovementSystem.Target:GetName())

		--DebugDrawLine(unit:GetOrigin() + Vector(0, 0, 100),target:GetOrigin() + Vector(0, 0, 100), 255, 255, 255, false, 1)
	end
end


function CMovementSystem:GetTeam(  )
	return self._nTeam
end


function CMovementSystem:UnitThinkMovement( unit )
	if unit:IsNull() then
		return
	end

	local nBest = nil
	local bestDist = 999999
	
	local posUnit = unit:GetAbsOrigin()
	local vAbsDist = {999999, 9999999, 999999}
	local vWP = {nil, nil, nil}

	if unit.MovementSystem.NextWaypoint == nil then
		--print("finding next waypoint")
		for i, str in pairs(self._vWaypoints) do
			if str == "end" then
			else
				local waypoint = Entities:FindByName(nil, str)
				if waypoint ~= nil then
					local orig = waypoint:GetOrigin()
					orig.z = GetGroundHeight(orig, nil)
					local dist = (orig - posUnit):Length()


					if dist < vAbsDist[1] then
						vAbsDist[3] = vAbsDist[2]
						vWP[3] = vWP[2]
						vAbsDist[2] = vAbsDist[1]
						vWP[2] = vWP[1]
						vAbsDist[1] = dist
						vWP[1] = i
					elseif dist < vAbsDist[2] then
						vAbsDist[3] = vAbsDist[2]
						vWP[3] = vWP[2]
						vAbsDist[2] = dist
						vWP[2] = i
					elseif dist < vAbsDist[3] then
						vAbsDist[3] = dist
						vWP[3] = i
					end
				end
			end
		end

		for i = 1, 3 do

			local waypoint = Entities:FindByName(nil, self._vWaypoints[vWP[i]])

			if waypoint ~= nil then
				--print("got a waypoint")
				local orig = waypoint:GetOrigin()
				orig.z = GetGroundHeight(orig, nil)
				local dist = GridNav:FindPathLength(posUnit, orig)

				if dist ~= -1 then
					if dist < bestDist then
						bestDist = dist
						nBest = vWP[i]
					end
				end
			end
		end

		if nBest ~= nil then
			if  self._vWaypoints[nBest + 1] ~= "end" then
				local waypoint1 = Entities:FindByName(nil, self._vWaypoints[nBest])
				local waypoint2 = Entities:FindByName(nil, self._vWaypoints[nBest + 1])
				local pos1 = waypoint1:GetOrigin()
				pos1.z = 256
				local pos2 = waypoint2:GetOrigin()
				pos2.z = 256
				local pos3 = unit:GetOrigin()
				pos3.z = 256

				if pos3 == pos1 then
					nBest = nBest + 1
				else
					local angletest = GetAngleBetweenVectors(pos1 - pos2, pos1 - pos3)
						--print(string.format("angletest: %d", angletest))

					--DebugDrawText(pos1, string.format("angle diff: %d", angletest), false, 2)
					----DebugDrawText(pos2, "waypoint 2", false, 20)
					----DebugDrawText(pos3, "Unit", false, 20)

					--DebugDrawLine(pos1, pos2, 0, 255, 255, false, 2)
					--DebugDrawLine(pos3, pos1, 0, 255, 0, false, 2)

					if angletest < 75 	then
						nBest = nBest + 1
					end
				end
			end

			unit.MovementSystem.NextWaypoint = nBest
		end
	end

	local n = unit.MovementSystem.NextWaypoint
	local entWp = Entities:FindByName(nil, self._vWaypoints[n])

	if entWp ~= nil then
		--print("found waypoint")
		local loc = entWp:GetAbsOrigin()
		local dist = GridNav:FindPathLength(posUnit, loc)

		--DebugDrawCircle(loc + Vector(0, 0, 100), Vector(255, 255, 255), 0, RANGE_NEXT_WAYPOINT, false, 0.25)

		self:UnitMoveToPosition(unit, loc)

		if dist <= RANGE_NEXT_WAYPOINT then
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