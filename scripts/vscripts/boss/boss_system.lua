if CBossSystem == nil then
	CBossSystem = class({})
end


UNIT_TYPE_BOSS = 1
UNIT_TYPE_BOSS_MINI = 2
UNIT_TYPE_ADD = 3


function CBossSystem:BossThink()
	if #self._vPhases <= 0 then
		return
	end

	local bNextPhase = self._vPhases[self._nCurrentPhase]:Run()
	if bNextPhase then
		if self._nCurrentPhase + 1 < self._nCurrentPhase then
			self._nCurrentPhase = self._nCurrentPhase + 1
		else
			return nil
		end
	end

	return self._TICKRATE
end

function CBossSystem:AddArena( name, id)

	local entArena = Entities:FindByName(nil, name)

	if entArena then
		self._vArenas[id] = entArena
	end
end


function CBossSystem:Init(data)
	self._TICKRATE = 0.25

	self._vPhases = {}
	self._nPhases = 0
	self._nCurrentPhase = 1

	self._vUnitsData = {}
	self._vUnits = {}

	self:ReadConfig(data)

	Timers:CreateTimer(function()
		return self:BossThink()
	end
	)
end


function CBossSystem:ReadConfig( data )
	if type( data ) ~= "table" then
		return
	end

	for _, phase in pairs(data.Phases) do
		self:AddPhase(phase)
	end

	for _, arena in pairs(data.Arenas) do
		self:AddArena(arena.name, arena.id)
	end

	for _, unit in pairs(data.Units) do
		self:RegisterUnit(unit)
	end
end


function CBossSystem:RegisterUnit(unitData)
	local data =
	{
		name = unit.name,
		id = unit.id,
		unitType = unit.type,
	}

	self._vUnitsData[id] = data
end


function CBossSystem:SpawnUnit(id, pos)
	if type(self._vUnitsData[id]) ~= "table" then
		return
	end

	local name = self._vUnitsData[id].name
	local unit = UnitSpawnAdd(orb, name, 0, 300, 300, nil, nil)

	self._vUnits[id] = unit
end


function CBossSystem:AddPhase(phase)
	local phaseObj = CPhase()
	self._nPhases = self._nPhases + 1
	phaseObj.Init(phase)
end


function CBossSystem:PhaseAddPhaseSegment(nPhase, fn)
	if nPhase >= 0 and nPhase <= self._nPhases then
		self._vPhases[nPhase]:AddPhaseSegment(fn)
	end
end


--#########################################################################################################################################################################################################################################


if CPhase == nil then
	CPhase = class({})
end


function CPhase:Init(phase)
	self._nSegments = 0
	self._vSegments = {}

	self._nCurrentSegment = 1

	for _, fn in pairs(phase) do
		self:AddPhaseSegment(fn)
	end
end


function CPhase:Run()
	if self._nSegments <= 0 then
		return true
	end

	local bNextSegment = self._vSegments[self._nCurrentSegment]:Run()
	if bNextSegment then
		if self._nCurrentSegment + 1 < self._nSegments then
			self._nCurrentSegment = self._nCurrentSegment + 1

			return false
		else
			return true
		end
	end

	return false
end


function CPhase:AddPhaseSegment(fn)
	local segmentObj = CPhaseSegment()
	segmentObj.Init(fn)
	self._nSegments = self._nSegments + 1
	self._vSegments[self._nSegments] = segmentObj
end


--#########################################################################################################################################################################################################################################


if CPhaseSegment == nil then
	CPhaseSegment = class({})
end


function CPhaseSegment:Init(fn)
	self._function = fn
end


function CPhaseSegment:Run()
	if self._function == nil then
		return true
	end

	return self._vSegments[self._nCurrentSegment]._function
end