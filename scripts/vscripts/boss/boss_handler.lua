--[[
	CBossHandler - Handles Bosses
]]

require ( "boss/treant/boss_treant" )

PREROUND = 0
PREPARE = 1
INPROGRESS = 2
ENDED = 3

Gamestates = {PREROUND, PREPARE, INPROGRESS, ENDED}

function IsValidBoss( n )
	if n == 1 then
		return true
	end

	return false
end


if CBossHandler == nil then
	CBossHandler = class({})
end


function CBossHandler:Init( gameRound, nBoss )
	self._gameRound = gameRound
	self._nBoss = nBoss
	self._gamestate = PREROUND
	
	if self._nBoss == 1 then
		self._bossObj = BossTreant()
		self._bossObj:Init(self, self._gameRound)
		--print("Boss: 1")
	end
	
end


function CBossHandler:OnNPCSpawned( event )
	self._bossObj:OnNPCSpawned(event)
end


function CBossHandler:Begin()
	self._bossObj:Begin()
	self._gamestate = INPROGRESS
	--print("Begin Boss")
end

function CBossHandler:UpdateBossDifficulty()
	self._bossObj:UpdateBossDifficulty()
end

function CBossHandler:Prepare()
	self._bossObj:Prepare()
	self._gamestate = PREPARE
	--print("Prepare Boss")
end


function CBossHandler:End()
	self._bossObj:End()
	self._gamestate = ENDED
end


function CBossHandler:Think()
	--print("Think")
	if self._gamestate == PREPARE then
		self:Begin()
	end
	
	if self._gamestate == INPROGRESS then
		self._bossObj:Think()
	end
end


function CBossHandler:IsFinished()
	return self._bossObj:IsFinished()
end