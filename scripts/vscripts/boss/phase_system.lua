if CBossSystem == nil then
	CBossSystem = class({})
end

function CBossSystem:Init(nPhases)
	self._vPhases = {}
	self._nPhases = 0
	self._TICKRATE = 0.25

	self._nCurrentPhase = 1

	for n = 1, nPhases do
		self:AddPhase()
	end

	Timers:CreateTimer(function()
		return self:BossThink()
	end
	)
end

function CBossSystem:BossThink()
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

function CBossSystem:AddPhase()
	local phaseObj = CPhase()
	self._nPhases = self._nPhases + 1
	phaseObj.Init(self._nPhases)
end

function CBossSystem:PhaseAddPhaseSegment(nPhase, fn)
	if nPhase >= 0 and nPhase <= self._nPhases then
		self._vPhases[nPhase]:AddPhaseSegment(fn)
	end
end

if CPhase == nil then
	CPhase = class({})
end

function CPhase:Init(n)
	self._nPhase = n
	self._nSegments = 0
	self._vSegments = {}

	self._nCurrentSegment = 0
end

function CPhase:Run()
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

if CPhaseSegment == nil then
	CPhaseSegment = class({})
end

function CPhaseSegment:Init(fn)
	self._function = fn
end

function CPhaseSegment:Run()
	return self._vSegments[self._nCurrentSegment]._function
end