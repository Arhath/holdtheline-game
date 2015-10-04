require( "misc/utility_functions" )

if CGateSystem == nil then
	CGateSystem = class({})
end

function CGateSystem:Init( gameMode, team )
	self._gameMode = gameMode
	self._nTeam = team
	self._vGates = {}

	local i = 1
	while Entities:FindByName(nil, "RadiantGate" .. i) ~= nil do
		local gateObj = CGateObj:CreateGate("RadiantGate" .. i, self, team)

		table.insert(self._vGates, gateObj)
		i = i + 1
	end

	--[[Timers:CreateTimer(function()
		CGateSystem:Update()

		return self:GetTickrate()
	end
	)]]
end

function CGateSystem:GetTickrate()
	return 0.1
end


function CGateSystem:Update()
	for _, gate in pairs(self._vGates) do
		gate:Update(self:GetTickrate())
	end
end



if CGateObj == nil then
	CGateObj = class({})
end


function CGateObj:AddGateUnit( unit )
	if not unit:GetTeamNumber() == self._nTeam then
		return
	end
	print("add gate unit")
	--self._entGate:SetControllableByPlayer(unit:GetPlayerOwnerID(), true)
	table.insert(self._vHeroes, unit)
	self:UpdateCapSpeed()
	self._bNeedUpdate = true
end


function CGateObj:RemoveGateUnit( unit )
	for i, u in pairs(self._vHeroes) do
		if unit == u then
			table.remove(self._vHeroes, i)
			self:UpdateCapSpeed()
			self._bNeedUpdate = true
			print("remove gate unit")
		end
	end
end


function CGateObj:CreateGate( str , gateSystem, team )
	local gateObj = CGateObj()
	if CGateObj:Init(str , gateSystem, team) then
		return CGateObj
	end
	
	return nil
end


function CGateObj:UpdateCapSpeed()
	self._fCapSpeed = 0

	for i = 1, #self._vHeroes do
		self._fCapSpeed = self._fCapSpeed + 1 / i
	end
end


function CGateObj:Init( str , gateSystem, team )
	self._entGate = Entities:FindByName(nil, str)
	self._entTrigger = Entities:FindByName(nil, str .. "Trigger")

	if self._entTrigger ~= nil and self._entGate ~= nil then

		--[[for id = 1, DOTA_MAX_PLAYERS do
			if PlayerResource:IsValidPlayer(id) then
				self._entGate:SetControllableByPlayer(1, true)
			end
		end
		]]

		print("creating gate: " .. str)
		self._fObjOffset1 = 50
		self._fObjOffset2 = 100

		self._vHeroes = {}
		self._nTeam = team
		self._gateSystem = gateSystem
		self._fCapTime = 0
		self._nStage = 1

		self._bFortifie = false
		self._bFortifieTime = 0

		self._bNeedUpdate = false

		self._bAnimationPhaseFinished = true
		self._fAnimationSpeed = 40.0

		self._fCapTimeStage_ = {5, 5, 5}
		self._fLastFrame = GameRules:GetGameTime()


		self._AnimationPhase = 1


		self._entGateMatrix = {
			{
				Entities:FindByName(nil, str .. "WallLeft1"),
				Entities:FindByName(nil, str .. "WallLeft2"),
				Entities:FindByName(nil, str .. "WallLeft3"),
				Entities:FindByName(nil, str .. "WallRight1"),
				Entities:FindByName(nil, str .. "WallRight2"),
				Entities:FindByName(nil, str .. "WallRight3"),
			},

			{
				Entities:FindByName(nil, str .. "WallLeft1Blocker"),
				Entities:FindByName(nil, str .. "WallLeft2Blocker"),
				Entities:FindByName(nil, str .. "WallLeft3Blocker"),
				Entities:FindByName(nil, str .. "WallRight1Blocker"),
				Entities:FindByName(nil, str .. "WallRight2Blocker"),
				Entities:FindByName(nil, str .. "WallRight3Blocker"),
				--Entities:FindByName(nil, str .. "WallLeft1"),
				--Entities:FindByName(nil, str .. "WallLeft2"),
				--Entities:FindByName(nil, str .. "WallRight1"),
				--Entities:FindByName(nil, str .. "WallRight2"),
			},
		}

		for _, ent in pairs(self._entGateMatrix[2]) do
			ent.MovementSystemActive = false
			ent:AddNewModifier( ent, nil, "modifier_invulnerable", {} )
			ent.Gate = self
		end

		self._vGateStartMatrix = {
			{
				self._entGateMatrix[1][1]:GetOrigin(),
				self._entGateMatrix[1][2]:GetOrigin(),
				self._entGateMatrix[1][3]:GetOrigin(),
				self._entGateMatrix[1][4]:GetOrigin(),
				self._entGateMatrix[1][5]:GetOrigin(),
				self._entGateMatrix[1][6]:GetOrigin(),
			},

			{
				self._entGateMatrix[2][1]:GetOrigin(),
				self._entGateMatrix[2][2]:GetOrigin(),
				self._entGateMatrix[2][3]:GetOrigin(),
				self._entGateMatrix[2][4]:GetOrigin(),
				self._entGateMatrix[2][5]:GetOrigin(),
				self._entGateMatrix[2][6]:GetOrigin(),
			},
		}

		self._vGatePhaseOffsetMatrix = {
			{
				Vector(0, 0, 0),
				Vector(0, 0, 0),
				Vector(0, 0, 0),
				Vector(0, 0, 0),
				Vector(0, 0, 0),
				Vector(0, 0, 0),
			},

			{
				Vector(208, 0, 0),
				Vector(208, 0, 0),
				Vector(208, 0, 0),
				Vector(-208, 0, 0),
				Vector(-208, 0, 0),
				Vector(-208, 0, 0),
			},

			{
				Vector(208, 0, 0),
				Vector(384, 0, 0),
				Vector(384, 0, 0),
				Vector(-208, 0, 0),
				Vector(-384, 0, 0),
				Vector(-384, 0, 0),
			},

			{
				Vector(208, 0, 0),
				Vector(384, 0, 0),
				Vector(604, 0, 0),
				Vector(-208, 0, 0),
				Vector(-384, 0, 0),
				Vector(-604, 0, 0),
			},
		}

		self._entTrigger.Gate = self
		self._entGate.Gate = self

		Timers:CreateTimer(function()
			return CGateObj:Update()
		end
		)

		return true
	end

	return false
end

function CGateObj:GetTickrate()
	return self._gateSystem:GetTickrate()
end

function CGateObj:Fortifie()
	print("gate fortifie")
	self._bFortifie = true
	self._bFortifieTime = 10.0
end

function CGateObj:Update()
	local timePassed = GameRules:GetGameTime() - self._fLastFrame
	if self._bNeedUpdate or self._bFortifie then
		if #self._vHeroes > 0 then
			if self._fCapTime >= self._fCapTimeStage_[self._nStage] then
				if self._nStage < #self._fCapTimeStage_ then
					self._fCapTime = self._fCapTime - self._fCapTimeStage_[self._nStage]
					self:SetStage(self._nStage + 1)
				else
					self._fCapTime = self._fCapTimeStage_[self._nStage]
					self._bNeedUpdate = false
				end
			else
				self._fCapTime = self._fCapTime	+ timePassed * self._fCapSpeed
			end
		else
			if self._fCapTime <= 0 then
				if self._nStage > 1 then
					self._fCapTime = self._fCapTimeStage_[self._nStage - 1]
					self:SetStage(self._nStage - 1)
				else
					self._fCapTime = 0
					self._bNeedUpdate = false
				end
			else
				self._fCapTime = self._fCapTime	- timePassed
			end
		end

		if self._bFortifieTime > 0 then
			self._bFortifieTime = self._bFortifieTime - timePassed
		else
			self._bFortifieTime = 0
			self._bFortifie = false
		end
	end

	DebugDrawText(self._vGateStartMatrix[1][1], string.format("stage: %d, cap time: %f", self._nStage, self._fCapTime), true, 0.1)
	DebugDrawText(self._entGate:GetAbsOrigin(), string.format("fortifie: %f", self._bFortifieTime), true, timePassed)

	self:UpdateGateAnimation()

	self._fLastFrame = GameRules:GetGameTime()

	return self:GetTickrate()
end


function CGateObj:SetStage( stage )
	if stage == self._nStage then
		return
	end

	if stage <= 0 then
		stage = 1
	end

	self._nStage = stage

	self._fLastFrame = GameRules:GetGameTime()
end

function CGateObj:GetStage()
	if self._bFortifie then
		return 4
	else
		return self._nStage
	end
end

function CGateObj:GetAnimationSpeed()
	if self._bFortifie then
		return 200
	else
		return self._fAnimationSpeed
	end
end


function CGateObj:UpdateGateAnimation()
	if self._bAnimationPhaseFinished and self:GetStage() == self._AnimationPhase then
		return
	end

	self._bAnimationPhaseFinished = false

	local timePassed = GameRules:GetGameTime() - self._fLastFrame

	local vecAnimation = self:GetStage() - self._AnimationPhase
	local nextAnimation = self:GetStage()

	if vecAnimation ~= 0 then
		nextAnimation = self._AnimationPhase + vecAnimation / math.sqrt(math.pow(vecAnimation, 2))
	end

	local animationFinished = true

	for n = 1, 2 do
		for i, ent in pairs(self._entGateMatrix[n]) do

			local orig = ent:GetOrigin()
			local pos = self._vGateStartMatrix[n][i] + self._vGatePhaseOffsetMatrix[nextAnimation][i]
			local vecDir =  pos - orig
			local dist = self:GetAnimationSpeed() * timePassed
			local newOrig

			if dist < vecDir:Length() then
				local vecMove = vecDir / vecDir:Length() * math.min(dist, vecDir:Length())

				newOrig = orig + vecMove
				animationFinished = false
			else
				newOrig = pos
			end

			if n == 2 then
				local aoe = 170 --wall:GetPaddedCollisionRadius()
				--newOrig.z = GetGroundHeight(newOrig, nil)
				DebugDrawCircle(newOrig, Vector(0, 255, 0), 0, aoe, true, timePassed)

				local newTargets =
				FindUnitsInRadius(
				DOTA_TEAM_GOODGUYS,
				newOrig,
				nil,
				aoe,
				DOTA_TEAM_BADGUYS,
				DOTA_UNIT_TARGET_ALL,
				DOTA_UNIT_TARGET_FLAG_NONE,
				FIND_CLOSEST,
				false
				)

				newTargets = ListFilterWithFn	( newTargets, 
												function(e) 
													return e.Gate == nil
												end
												)

				DebugDrawText(newOrig, string.format("units: %d",#newTargets), true, timePassed)

				for _, target in pairs(newTargets) do
					local targetOrig = target:GetAbsOrigin()
					local targetOffset = targetOrig - newOrig
					local targetNewOrig = newOrig + targetOffset / targetOffset:Length() * aoe * 1.2
					DebugDrawLine(newOrig, targetOrig, 0, 0, 255, true, timePassed)
					DebugDrawLine(targetOrig, targetNewOrig, 255, 0, 255, true, timePassed)
					FindClearSpaceForUnit(target, targetNewOrig, true)
				end
			end

			ent:SetOrigin(newOrig)
		end
	end

	if animationFinished then
		self._bAnimationPhaseFinished = true
		self._AnimationPhase = nextAnimation
	end
end