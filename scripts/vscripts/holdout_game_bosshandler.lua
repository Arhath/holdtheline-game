--[[
	CHoldoutGameBossHandler - Handles Bosses
]]

require ( "boss_treant" )

PREROUND = 0
PREPARE = 1
INPROGRESS = 2
ENDED = 3

Gamestates = {PREROUND, PREPARE, INPROGRESS, ENDED}

if CHoldoutGameBossHandler == nil then
	CHoldoutGameBossHandler = class({})
end


function CHoldoutGameBossHandler:Init( gameRound, nBoss )
	self._gameRound = gameRound
	self._nBoss = nBoss
	self._gamestate = PREROUND
	
	if self._nBoss == 1 then
		self._bossObj = BossTreant()
		self._bossObj:Init(self, self._gameRound)
		print("Boss: 1")
	end
	
end


function CHoldoutGameBossHandler:Begin()
	self._bossObj:Begin()
	self._gamestate = INPROGRESS
	print("Begin Boss")
end

function CHoldoutGameBossHandler:UpdateBossDifficulty()
	self._bossObj:UpdateBossDifficulty()
end

function CHoldoutGameBossHandler:Prepare()
	self._bossObj:Prepare()
	self._gamestate = PREPARE
	print("Prepare Boss")
end


function CHoldoutGameBossHandler:End()
	self._bossObj:End()
	self._gamestate = ENDED
end


function CHoldoutGameBossHandler:Think()
	print("Think")
	if self._gamestate == PREPARE then
		self:Begin()
	end
	
	if self._gamestate == INPROGRESS then
		self._bossObj:Think()
	end
end


function CHoldoutGameBossHandler:IsFinished()
	return self._bossObj:IsFinished()
end