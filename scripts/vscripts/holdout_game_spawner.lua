--[[
	CHoldoutGameSpawner - A single unit spawner for Holdout.
]]
if CHoldoutGameSpawner == nil then
	CHoldoutGameSpawner = class({})
end


function CHoldoutGameSpawner:ReadConfiguration( name, kv, gameRound )
	self._gameRound = gameRound
	self._dependentSpawners = {}

	self._szGroupWithPack = kv.GroupWithPack or ""
	self._szName = name
	self._szPackName = kv.PackName or ""
	self._szSpawnerName = kv.SpawnerName or ""
	self._szWaitForPack = kv.WaitForPack or ""

	self._nCreatureLevel = tonumber( kv.CreatureLevel or 1 )
	self._nTotalPacksToSpawn = tonumber( kv.TotalPacksToSpawn or 0 )

	self._flSpawnInterval = tonumber( kv.SpawnInterval or 0 )
	self._flInitialWait = tonumber( kv.WaitForTime or 0 )

	self._bDontOffsetSpawn = ( tonumber( kv.DontOffsetSpawn or 0 ) ~= 0 )

	self._vg = {}
	self._nTimers = 0
	self._vUnitTables = {}

	self._nInterval = 0
end


function CHoldoutGameSpawner:PostLoad( spawnerList )
	self._waitForUnit = spawnerList[ self._szWaitForPack ]
	if self._szWaitForPack ~= "" and not self._waitForUnit then
		print( self._szName .. " has a wait for unit " .. self._szWaitForPack .. " that is missing from the round data." )
	elseif self._waitForUnit then
		table.insert( self._waitForUnit._dependentSpawners, self )
	end

	self._groupWithUnit = spawnerList[ self._szGroupWithPack ]
	if self._szGroupWithPack ~= "" and not self._groupWithUnit then
		print ( self._szName .. " has a group with unit " .. self._szGroupWithPack .. " that is missing from the round data." )
	elseif self._groupWithUnit then
		table.insert( self._groupWithUnit._dependentSpawners, self )
	end

	for _, unit in pairs(self._gameRound._vPacks[self._szPackName]) do

		local uTable = {}

		uTable.szNPCClassToSpawn = unit["NPCName"] or ""
		uTable.cValue = tonumber(unit["CoreValue"] or 1)
		uTable.nSpawn = tonumber(unit["UnitsPerSpawn"] or 1)
		uTable.fWait = tonumber(unit["WaitForTime"] or 0)
		uTable.nInterval = tonumber(unit["SpawnInterval"] or 1)
		uTable.nDelay = tonumber(unit["SkipSpawns"] or 0)

		table.insert(self._vUnitTables, uTable)
	end
end


function CHoldoutGameSpawner:Precache()
	--print(self._szPackName)
	--print(self._gameRound._vPacks[self._szPackName])
	--print(self._nTotalPacksToSpawn)
	--print(self:GetTotalUnitsToSpawn())
	--print(self:GetTotalCoreValue())

	for _, n in pairs(self._gameRound._vPacks[self._szPackName]) do
		local name = n["NPCName"]
		PrecacheUnitByNameAsync( name, function( sg ) table.insert(self._vg, sg) end )
	end
end


function CHoldoutGameSpawner:Begin()
	self._nPacksSpawnedThisRound = 0
	
	self._vecSpawnLocation = nil
	if self._szSpawnerName ~= "" then
		local entSpawner = Entities:FindByName( nil, self._szSpawnerName )
		if not entSpawner then
			print( string.format( "Failed to find spawner named %s for %s\n", self._szSpawnerName, self._szName ) )
		end
		self._vecSpawnLocation = entSpawner:GetAbsOrigin()
	end

	if self._waitForUnit ~= nil or self._groupWithUnit ~= nil then
		self._flNextSpawnTime = nil
	else
		self._flNextSpawnTime = GameRules:GetGameTime() + self._flInitialWait
	end
end


function CHoldoutGameSpawner:End()
	if self._vg ~= nil then
		for _, g in pairs(self._vg) do
			UnloadSpawnGroupByHandle( g )
		end

		self._vg = nil
	end
end


function CHoldoutGameSpawner:ParentSpawned( parentSpawner )
	if parentSpawner == self._groupWithUnit then
		-- Make sure we use the same spawn location as parentSpawner.
		self:_DoSpawn()
	elseif parentSpawner == self._waitForUnit then
		if parentSpawner:IsFinishedSpawning() and self._flNextSpawnTime == nil then
			self._flNextSpawnTime = parentSpawner._flNextSpawnTime + self._flInitialWait
		end
	end
end


function CHoldoutGameSpawner:Think()
	if not self._flNextSpawnTime then
		return
	end
	
	if GameRules:GetGameTime() >= self._flNextSpawnTime then
		self:_DoSpawn()
		for _,s in pairs( self._dependentSpawners ) do
			s:ParentSpawned( self )
		end

		if self:IsFinishedSpawning() then
			self._flNextSpawnTime = nil
		else
			self._flNextSpawnTime = self._flNextSpawnTime + self._flSpawnInterval
		end
	end
end


function CHoldoutGameSpawner:GetTotalUnitsToSpawn()
	return self._nTotalPacksToSpawn * self._gameRound:PackGetUnitCount(self._szPackName)
end

function CHoldoutGameSpawner:GetTotalCoreValue()
	return self._nTotalPacksToSpawn * self._gameRound:PackGetValue(self._szPackName)
end


function CHoldoutGameSpawner:IsFinishedSpawning()
	return (( self._nTotalPacksToSpawn <= self._nPacksSpawnedThisRound ) or ( self._groupWithUnit ~= nil )) and (self._nTimers == 0)
end


function CHoldoutGameSpawner:_GetSpawnLocation()
	if self._groupWithUnit then
		return self._groupWithUnit:_GetSpawnLocation()
	else
		return self._vecSpawnLocation
	end
end


function CHoldoutGameSpawner:_UpdateRandomSpawn()
	--print( "Choosing Random Spawn.")
	self._vecSpawnLocation = Vector( 0, 0, 0 )

	local spawnInfo = self._gameRound:ChooseRandomSpawnInfo()
	if spawnInfo == nil then
		--print( string.format( "Failed to get random spawn info for spawner %s.", self._szName ) )
		return
	end
	
	local entSpawner = Entities:FindByName( nil, spawnInfo.szSpawnerName )
	if not entSpawner then
		--print( string.format( "Failed to find spawner named %s for %s.", spawnInfo.szSpawnerName, self._szName ) )
		return
	end
	self._vecSpawnLocation = entSpawner:GetAbsOrigin()
end


function CHoldoutGameSpawner:_DoSpawn()

	if self._nTotalPacksToSpawn - self._nPacksSpawnedThisRound <= 0 then
		return
	elseif self._nPacksSpawnedThisRound == 0 then
		--print( string.format( "Started spawning %s at %.2f", self._szName, GameRules:GetGameTime() ) )
	end

	if self._szSpawnerName == "" then
		self:_UpdateRandomSpawn()
	end

	local vBaseSpawnLocation = self:_GetSpawnLocation()
	if not vBaseSpawnLocation then return end

	----for each unit in pack spawn units and set core values accordingly

	for _, unit in pairs(self._vUnitTables) do

		--spawn delayed

		if self._nInterval >= unit.nDelay and Modulo2(math.max((self._nInterval - unit.nDelay), 0), unit.nInterval) == 0 then

			if unit.szNPCClassToSpawn ~= "" then
				self._nTimers = self._nTimers + 1

				local spawnTimer = Timers:CreateTimer(unit.fWait, function()
					for n = 1, unit.nSpawn do

						local vSpawnLocation = vBaseSpawnLocation
						if not self._bDontOffsetSpawn then
							vSpawnLocation = vSpawnLocation + RandomVector( RandomFloat( 0, 200 ) )
						end

						local entUnit = CreateUnitByName( unit.szNPCClassToSpawn, vSpawnLocation, true, nil, nil, DOTA_TEAM_BADGUYS )
						if entUnit then
							if entUnit:IsCreature() then
								entUnit:CreatureLevelUp( self._nCreatureLevel - 1 )
							end

							ApplyModifier(entUnit, entUnit, "modifier_nether_buff_passive", {duration=-1}, false)
							ApplyModifier(entUnit, entUnit, "modifier_nether_buff_fx", {duration=-1}, false)
							
							entUnit.Holdout_CoreNum = self._gameRound._nRoundNumber
							entUnit.CoreValue = unit.cValue 
							entUnit:SetDeathXP(0)
							entUnit:SetMaximumGoldBounty(0)
							entUnit:SetBountyGain(0)
							entUnit:SetMinimumGoldBounty(0)
							entUnit.RewardXP = math.floor(self._gameRound:GetXPPerCoreUnit() * unit.cValue)
							entUnit.RewardGold = math.floor(self._gameRound:GetGoldPerCoreUnit() * unit.cValue)

							self._gameRound._nCoreUnitsSpawnedValue = self._gameRound._nCoreUnitsSpawnedValue + unit.cValue
						end
					end

					if self._gameRound._entKillCountSubquest then
						self._gameRound._entKillCountSubquest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, self._gameRound._nCoreUnitsSpawnedValue)
					end

					self._nTimers = self._nTimers - 1

					return nil
				end
				)
			end
		end
	end

	self._nPacksSpawnedThisRound = self._nPacksSpawnedThisRound + 1
	self._nInterval = self._nInterval + 1
end


function CHoldoutGameSpawner:StatusReport()
	--print( string.format( "** Spawner %s", self._szNPCClassName ) )
	--print( string.format( "%d of %d spawned", self._nPacksSpawnedThisRound, self._nTotalPacksToSpawn ) )
end