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
MAX_TIME_NO_DAMAGE = 12.0
MAX_TIME_IGNORE_SIGHT = 7.0

MAX_DISTANCE_AGGRO = 1400.0

MAX_STUCK_TIME = 4.0

debugtimer = 0.0

AGGRO_TYPE_DAMAGE_ENEMY_MELEE	= 7
AGGRO_TYPE_DAMAGE_ENEMY_RANGE	= 6
AGGRO_TYPE_DAMAGE_OWN			= 5
AGGRO_TYPE_DAMAGE_AOE_MELEE		= 4
AGGRO_TYPE_DAMAGE_AOE_RANGE		= 3
AGGRO_TYPE_SIGHT				= 1

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
		self._vUnits[spawnedUnit:entindex()] = spawnedUnit
		spawnedUnit.MovementSystem =
		{
			Type = MOVEMENT_SYSTEM_TYPE_ATTACKER,
			NextWaypoint = nil,
			TargetList = {},
			TargetNum = 0,
			Target = nil,
			AggroType = 0,
			IgnoreTarget = nil,
			IgnoreTime = 0,
			TargetTime = 0,
			NoVisionTime = 0,
			NoDamageTime = 0,
			IgnoreSight = false,
			MaxTargetTime = 0,
			MinTargetTime = 0,
			CanChangeTarget = true,
			StuckTime = 0,
			LastPosition = spawnedUnit:GetAbsOrigin(),
			State = MOVEMENT_SYSTEM_STATE_ACTIVE,
			ForceUpdate = true,
			LastFrame = GameRules:GetGameTime(),
		}
	end

	if spawnedUnit:GetTeamNumber() ~= self:GetTeam() then
		self._vAggroUnits[spawnedUnit:entindex()] =  spawnedUnit
		spawnedUnit.MovementSystem =
		{
			Type = MOVEMENT_SYSTEM_TYPE_DEFENDER,
			TargetList = {},
			TargetNum = 0,
		}
	end

end


function CMovementSystem:OnEntityKilled( event )
	local killedUnit = EntIndexToHScript( event.entindex_killed )

	if killedUnit then
		self._vUnits[killedUnit:entindex()] = nil

		if killedUnit.MovementSystem.Target ~= nil then
			killedUnit.MovementSystem.Target.MovementSystem.TargetList[killedUnit:entindex()] = nil
			killedUnit.MovementSystem.Target.MovementSystem.TargetNum = killedUnit.MovementSystem.Target.MovementSystem.TargetNum - 1
		end
		----print("removing unit from table movement system")

		self._vAggroUnits[killedUnit:entindex()] = nil
	end
end

function CMovementSystem:OnEntityHurt( keys)
	local damagebits = keys.damagebits
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

			local atkRange = entCause:GetAttackRange()
			local aggroTypeAoe = AGGRO_TYPE_DAMAGE_AOE_MELEE
			local aggroTypeDmg = AGGRO_TYPE_DAMAGE_ENEMY_MELEE

			if atkRange > 200 then
				aggroTypeAoe = AGGRO_TYPE_DAMAGE_AOE_RANGE
				aggroTypeDmg = AGGRO_TYPE_DAMAGE_ENEMY_RANGE
			end


			DebugDrawCircle(entVictim:GetOrigin(), Vector(255, 0, 0), 0, ATTACK_AGGRO_AOE, true, 1)

			self:UnitAggroTarget(entVictim, entCause, MAX_TARGET_TIME, 7, aggroTypeDmg, AGGRO_OVERWRITE_RENEW)
			entVictim.MovementSystem.NoDamageTime = 0
			entVictim.MovementSystem.IgnoreSight = false
			--entVictim.MovementSystem.StuckTime = 0

			for _, nt in pairs(newTargets) do
				self:UnitAggroTarget(nt, entCause, MAX_TARGET_TIME, 4, aggroTypeAoe, AGGRO_OVERWRITE_RENEW)
			end
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

			self:UnitAggroTarget(entCause, entVictim, MAX_TARGET_TIME, 7, AGGRO_TYPE_DAMAGE_OWN, AGGRO_OVERWRITE_RENEW)
			entCause.MovementSystem.NoDamageTime = 0
			entCause.MovementSystem.IgnoreSight = false
			entCause.MovementSystem.StuckTime = 0

			--DebugDrawCircle(entCause:GetOrigin() + Vector(0, 0, 100), Vector(255, 255, 255), 0, ATTACK_AGGRO_AOE, false, 0.5)

			--for _, nt in pairs(newTargets) do
			--	self:UnitAggroTarget(nt, entVictim, MAX_TARGET_TIME, 4, AGGRO_TYPE_DAMAGE_AOE, AGGRO_OVERWRITE_NORMAL)
			--end
		end
	end
end


function CMovementSystem:OnUnitRightClick( event )
	local pID = event.pID
	local unit = EntIndexToHScript(event.mainSelected)

	if unit.MovementSystem == nil or unit.MovementSystem.Type ~= MOVEMENT_SYSTEM_TYPE_DEFENDER then
		return
	end

	local mPos = Vector(0, 0, 0)
	local eventName = event.name

	mPos.x = event.mouseX
	mPos.y = event.mouseY
	local uPos = unit:GetAbsOrigin()
	local dist = GridNav:FindPathLength(uPos, mPos)
	DebugDrawLine(mPos, uPos, 255, 255, 255, true, 4.0)
	local ms = unit:GetMoveSpeedModifier(unit:GetBaseMoveSpeed())
	local time = dist / ms

	local teleporter = nil

	--[[for i = 1, #self._vTeleporters do
		local distTp = (self._vTeleporters[i][1]:GetAbsOrigin() - uPos):Length2D() + (mPos - self._vTeleporters[i][2]:GetAbsOrigin()):Length2D()
		local timeTp = distTp / ms + TELEPORTER_TIME
		print(timeTp)

		if timeTp < time then
			DebugDrawText(unit:GetAbsOrigin(), "use teleporter", true, 7.0)
			teleporter = i
			--time = timeTp
		end
	end]]

	--DebugDrawText(mPos, string.format("dist: %f, ms: %f, time: %f", dist, ms, time), true, 4.0)
	local i = -4000

	while i <= 4000 do
		local j = -4000

		while j <= 4000 do
			local newPos = uPos + Vector(i, j, 0)
			local d1 = GridNav:FindPathLength(uPos, newPos)
			print(d2)
			DebugDrawText(newPos , string.format("%d", d1), true, 100.0)
			j = j + 500
		end
	i = i + 200
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
	"path_invader1_1", "path_invader1_2", "path_invader1_3", "path_invader1_4", "path_invader1_5", "path_invader1_6", "path_invader1_7", "path_invader1_8", "path_invader1_9", "path_invader1_10", "path_invader1_11", "path_invader1_12", "path_invader1_13", "path_invader1_14", "path_invader1_15", "path_invader1_16", "path_invader1_17", "path_invader1_18", "path_invader1_19", "path_invader1_20", "path_invader1_21", "path_invader1_22", "path_invader_end", "end",
	"path_invader2_1", "path_invader2_2", "path_invader2_3", "path_invader2_4", "path_invader2_5", "path_invader2_6", "path_invader2_7", "path_invader2_8", "path_invader2_9", "path_invader2_10", "path_invader2_11", "path_invader2_12", "path_invader2_13", "path_invader2_14", "path_invader2_15", "path_invader2_16", "path_invader2_17", "path_invader2_18", "path_invader2_19", "path_invader2_20", "path_invader2_21", "path_invader2_22", "path_invader_end", "end"
	}

	self._vTeleporters =
	{
		{
			Entities:FindByName(nil, "RadiantTeleportLeft"),
			Entities:FindByName(nil, "RadiantTeleportLeftFar"),
		},

		{
			Entities:FindByName(nil, "RadiantTeleportRight"),
			Entities:FindByName(nil, "RadiantTeleportRightFar"),
		},

		{
			Entities:FindByName(nil, "RadiantTeleportLeftFar"),
			Entities:FindByName(nil, "RadiantTeleportLeft"),
		},

		{
			Entities:FindByName(nil, "RadiantTeleportRightFar"),
			Entities:FindByName(nil, "RadiantTeleportRight"),
		},
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

		if not UnitIsDead(au) then
			for _, t in pairs(au.MovementSystem.TargetList) do
				if UnitIsDead(t) then
					au.MovementSystem.TargetList[t:entindex()] = nil
				else
					--DebugDrawLine(au:GetOrigin() + Vector(0, 0, 100),t:GetOrigin() + Vector(0, 0, 100), 255, 255, 255, false, 0.25)
					----print(t:GetName())
				end
			end

			local aggroNum = au.MovementSystem.TargetNum

			if aggroNum > AGGRO_UNITS_MIN_RANGE  then
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

			--[[
			local atkRange = au:GetAttackRange()
			local aggroTypeSight = AGGRO_TYPE_SIGHT_MELEE

			if atkRange > 200 then
				aggroTypeSight = AGGRO_TYPE_SIGHT_RANGE
			end
			]]

			for _, nt in pairs(newTargets) do
				self:UnitAggroTarget(nt, au, MAX_TARGET_TIME, 4, AGGRO_TYPE_SIGHT, AGGRO_OVERWRITE_NORMAL)
			end

			DebugDrawText(au:GetOrigin(), string.format("Targets: %d", aggroNum), true, 0.25)
			DebugDrawCircle(au:GetOrigin(), Vector(0, 255, 0), 0, aggroRange, true, 0.25)
		end
	end

	local gameTime = GameRules:GetGameTime()

	for _, unit in pairs(self._vUnits) do
		if not UnitIsDead(unit) then
			if unit.MovementSystem.State == MOVEMENT_SYSTEM_STATE_ACTIVE then
				if self.NextUpdate >= gameTime or unit.MovementSystem.ForceUpdate then
					self:UnitThink(unit)
					unit.MovementSystem.ForceUpdate = false
				end
			end
		end
	end

	if self.NextUpdate >= gameTime then
		self.NextUpdate = self.NextUpdate + UPDATE_INTERVALL
	end
end

function CMovementSystem:UnitThink( unit )
	local timePassed = GameRules:GetGameTime() - unit.MovementSystem.LastFrame
	unit.MovementSystem.LastFrame = GameRules:GetGameTime()

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
				unit.MovementSystem.StuckTime = unit.MovementSystem.StuckTime + timePassed
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
				unit.MovementSystem.IgnoreTime = unit.MovementSystem.IgnoreTime + timePassed
			end
		end

		if unit.MovementSystem.Target ~= nil then

			if UnitIsDead(unit.MovementSystem.Target) then
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
								unit.MovementSystem.NoVisionTime = unit.MovementSystem.NoVisionTime + timePassed
							end
						end
					else
						unit.MovementSystem.NoVisionTime = 0
					end

					if  unit.MovementSystem.Target ~= nil then
						local posUnit = unit:GetAbsOrigin()
						local posTarget = unit.MovementSystem.Target:GetAbsOrigin()
						local dist = (posUnit - posTarget):Length2D()

						local tAtkRange = unit.MovementSystem.Target:GetAttackRange()
						local uAtkRange = unit:GetAttackRange()
						--local distNav = GridNav:FindPathLength(posUnit, posTarget)
						if tAtkRange < dist then
							if dist > uAtkRange + MAX_DISTANCE_AGGRO then --or distNav > MAX_DISTANCE_AGGRO then
								self:UnitSetTarget(unit, nil, true)
							end
						end
					end

					if  unit.MovementSystem.Target ~= nil then

						if unit.MovementSystem.TargetTime >= unit.MovementSystem.MinTargetTime then
							unit.MovementSystem.CanChangeTarget = true
						end

						--print(string.format("target time: %d", unit.MovementSystem.TargetTime))
						unit.MovementSystem.TargetTime = unit.MovementSystem.TargetTime + timePassed
					end
				end
			end
		end

		if unit.MovementSystem.Target ~= nil then
			if unit.MovementSystem.IgnoreSight == false then
				if unit.MovementSystem.NoDamageTime > MAX_TIME_NO_DAMAGE then
					unit.MovementSystem.IgnoreSight = true
					unit.MovementSystem.NoDamageTime = 0

					if unit.MovementSystem.AggroType < AGGRO_TYPE_DAMAGE_OWN then
						self:UnitSetTarget(unit, nil, false)
					end
				else
					unit.MovementSystem.NoDamageTime = unit.MovementSystem.NoDamageTime + timePassed
				end
			end
		else
			if unit.MovementSystem.IgnoreSight == true then
				if unit.MovementSystem.NoDamageTime > MAX_TIME_IGNORE_SIGHT then
					unit.MovementSystem.IgnoreSight = false
					unit.MovementSystem.NoDamageTime = 0
				else
					unit.MovementSystem.NoDamageTime = unit.MovementSystem.NoDamageTime + timePassed
				end
			else
				if unit.MovementSystem.NoDamageTime > 0 then
					unit.MovementSystem.NoDamageTime = unit.MovementSystem.NoDamageTime - math.min(unit.MovementSystem.NoDamageTime, timePassed * 2)
				end
			end
		end

		
		if unit.MovementSystem.Target ~= nil then
			self:UnitAttackTarget(unit, unit.MovementSystem.Target)
			unit.MovementSystem.ForceUpdate = true
			----print("unitthinkattack")
		else
			----print("UnitThinkMovement")

			self:UnitThinkMovement(unit)
		end


		if unit.MovementSystem.Target ~= nil then
			--DebugDrawText(unit:GetOrigin(), string.format("Target: %d", unit.MovementSystem.TargetTime), true, 0.25)
			DebugDrawText(unit:GetOrigin(), string.format("it: %d", unit.MovementSystem.NoDamageTime), true, 0.25)
		elseif unit.MovementSystem.IgnoreTarget ~= nil then
			DebugDrawText(unit:GetOrigin(), string.format("Ignore: %d", unit.MovementSystem.IgnoreTime), true, 0.25)
		end
	end
end


function CMovementSystem:UnitSetTarget(unit, data, ignore)

	if unit.MovementSystem.Target ~= nil then
		unit.MovementSystem.Target.MovementSystem.TargetList[unit:entindex()] = nil
		unit.MovementSystem.Target.MovementSystem.TargetNum = unit.MovementSystem.Target.MovementSystem.TargetNum - 1
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
		unit.MovementSystem.IgnoreTarget = unit.MovementSystem.IgnoreTarget
		unit.MovementSystem.IgnoreTime = unit.MovementSystem.IgnoreTime
		unit.MovementSystem.StuckTime = 0

		unit.MovementSystem.Target.MovementSystem.TargetList[unit:entindex()] = unit
		unit.MovementSystem.Target.MovementSystem.TargetNum = unit.MovementSystem.Target.MovementSystem.TargetNum + 1
	end

	unit.MovementSystem.ForceUpdate = true
end


function  CMovementSystem:UnitAggroTarget( unit, target, timeMax, timeMin, aggroType, overwrite)
	if unit.MovementSystem.Type == MOVEMENT_SYSTEM_TYPE_ATTACKER and target.MovementSystem.Type == MOVEMENT_SYSTEM_TYPE_DEFENDER and unit:CanEntityBeSeenByMyTeam(target) then
		if overwrite ~= AGGRO_OVERWRITE_ALL then

			if unit.MovementSystem.Target ~= nil then
				if overwrite ~= AGGRO_OVERWRITE_RENEW then
					if not unit.MovementSystem.CanChangeTarget then
						if aggroType <= unit.MovementSystem.AggroType then
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
						if aggroType < unit.MovementSystem.AggroType then
							return
						end
					elseif unit.MovementSystem.Target ~= target then		
						return
					end
				end
			end

			if unit.MovementSystem.IgnoreTarget == target then
				if aggroType < AGGRO_TYPE_DAMAGE_OWN then
					return
				end
			end

			if unit.MovementSystem.IgnoreSight and aggroType < AGGRO_TYPE_DAMAGE_OWN then
				return
			end
		end

		--print("settingTarget")

		local data = {
			target = target,
			aggroType = aggroType,
			timeMax = timeMax,
			timeMin = timeMin,
		}

		self:UnitSetTarget(unit, data, false)
		ApplyModifier(unit, target, "modifier_vision", {Duration = 2}, true)
		--print("new aggro Target: " .. unit.MovementSystem.Target:GetName())

		DebugDrawLine(unit:GetOrigin(), target:GetOrigin(), 255, 0, 0, true, 1)
	end
end


function CMovementSystem:GetTeam(  )
	return self._nTeam
end


function CMovementSystem:UnitThinkMovement( unit )
	if UnitIsDead(unit) then
		return
	end

	local nBest = nil
	local bestDist = 999999
	
	local posUnit = unit:GetAbsOrigin()
	local vAbsDist = {999999, 9999999, 999999}
	local vWP = {nil, nil, nil}

	if unit.MovementSystem.NextWaypoint == nil then
		unit.MovementSystem.OrderPosition = nil
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
				pos1.z = GetGroundHeight(pos1, nil)
				local pos2 = waypoint2:GetOrigin()
				pos2.z = GetGroundHeight(pos2, nil)

				if posUnit == pos1 then
					nBest = nBest + 1
				else
					local angletest = GetAngleBetweenVectors(pos1 - pos2, pos1 - posUnit)
						--print(string.format("angletest: %d", angletest))

					DebugDrawText(pos1, string.format("angle diff: %d", angletest), true, 2)
					DebugDrawText(pos2, "waypoint 2", true, 20)
					--DebugDrawText(posUnit, "Unit", false, 20)

					DebugDrawLine(pos1, pos2, 0, 255, 255, true, 2)
					DebugDrawLine(posUnit, pos1, 0, 255, 0, true, 2)

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
		local pos = entWp:GetAbsOrigin()
		pos.z = GetGroundHeight(pos, nil)

		if unit.MovementSystem.OrderPosition == nil then
			unit.MovementSystem.OrderPosition = GetRandomPointInAoe(pos, RANGE_NEXT_WAYPOINT)
			unit.MovementSystem.OrderPosition.z = GetGroundHeight(unit.MovementSystem.OrderPosition, nil)
		end

		local dist1 = (pos - posUnit):Length()
		local dist2 = (unit.MovementSystem.OrderPosition - posUnit):Length() --GridNav:FindPathLength(posUnit, unit.MovementSystem.OrderPosition)


		--DebugDrawCircle(pos + Vector(0, 0, 100), Vector(255, 255, 255), 0, RANGE_NEXT_WAYPOINT, false, 0.25)
		--DebugDrawText(posUnit, string.format("z: %d / %d", posUnit.z, unit.MovementSystem.OrderPosition.z), true, 0.25)
		DebugDrawLine(posUnit, unit.MovementSystem.OrderPosition, 0, 255, 0, true, 0.25)

		self:UnitMoveToPosition(unit, unit.MovementSystem.OrderPosition)

		local travelDist = unit:GetMoveSpeedModifier(unit:GetBaseMoveSpeed()) * self:GetTickrate()

		if dist2 - travelDist <= RANGE_NEXT_WAYPOINT / 4 then
			unit.MovementSystem.ForceUpdate = true
			DebugDrawText(unit:GetAbsOrigin(), "forceUpdate", true, self.GetTickrate())
		end

		if dist1 <= RANGE_NEXT_WAYPOINT * 1.1 and dist2 <= RANGE_NEXT_WAYPOINT / 4 then
			if self._vWaypoints[n + 1] ~= "end" then
				--print(string.format("waypoint reached setting next: %d", n + 1))
				unit.MovementSystem.NextWaypoint = n + 1

				local posWp1 = Entities:FindByName(nil, self._vWaypoints[n]):GetOrigin()
				local posWp2 = Entities:FindByName(nil, self._vWaypoints[n + 1]):GetOrigin()

				unit.MovementSystem.OrderPosition = posUnit + posWp2 - posWp1
				unit.MovementSystem.OrderPosition.z = GetGroundHeight(unit.MovementSystem.OrderPosition, nil)
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