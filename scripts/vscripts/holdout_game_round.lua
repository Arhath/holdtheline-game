--[[
	CHoldoutGameRound - A single round of Holdout
]]

require( "boss/boss_handler")

if CHoldoutGameRound == nil then
	CHoldoutGameRound = class({})
end

XP_BUFFER_PCT = 0.1
GOLD_BUFFER_PCT = 0.1

CORE_VALUE_CREEP = 1
CORE_VALUE_CHAMPION = 3
CORE_VALUE_MINIBOSS = 7

SPAWNERS_ =
{
	"path_invader1_1",
	"path_invader2_1",
}

GOLD_VALUES_TEAMSIZE_ = {
	{
		10,
		0,
	},

	{
		7,
		3,
	},

	{
		5,
		2.5,
	},

	{
		4,
		2,
	},

	{
		3.2,
		1.7,
	},
}


function CHoldoutGameRound:ReadConfiguration( kv, gameMode, roundNumber )
	self._gameMode = gameMode
	self._nRoundNumber = roundNumber
	self._szRoundQuestTitle = kv.round_quest_title or "#DOTA_Quest_Holdout_Round"
	self._szRoundTitle = kv.round_title or string.format( "Round%d", roundNumber )

	self._nMaxGold = tonumber( kv.MaxGold or 0 )
	self._nMaxWood = tonumber( kv.MaxWood or 0)
	self._nBagCount = tonumber( kv.BagCount or 0 )
	self._nBagVariance = tonumber( kv.BagVariance or 0 )
	self._nFixedXP = tonumber( kv.FixedXP or 0 )
	self._nXPBuffer = 0
	self._nGoldBuffer = 0
	self._nWoodBuffer = 0
	self._nBoss = tonumber( kv.Boss or 0 )
	self._flPrepTime = tonumber( kv.PrepTime or gameMode._flPrepTimeBetweenRounds or 0 )

	self._bossHandler = nil
	
	if self:IsBoss() then
		self._bossHandler = CBossHandler()
		self._bossHandler:Init(self, self._nBoss)
		print("is boss init")
	else

		--init Packs

		self._vPacks = {}

		for str, pack in pairs( kv["Packs"] ) do
			self._vPacks[str] = pack
			print(str)
			for s, p in pairs(pack) do
				print(s)
				print("npc: " .. p["NPCName"])
				print( "value: " .. p["CoreValue"])
				print("count: " .. p["UnitsPerSpawn"])
			end

			print(self:PackGetUnitCount(str))
			print(self:PackGetValue(str))
		end

		print("asd")
		print(self:PackGetUnitCount("1"))

		--init spawners

		self._vSpawners = {}
		local spawners = self._gameMode:GetSpawnerList()

		for k, v in pairs( kv ) do
			if type( v ) == "table" and v.PackName then
				if v.SpawnerName == "all" then
					for i = 1, #spawners do
						local k2 = i .. k
						local v2 = shallowcopy(v)

						--print(v.GroupWithUnit)
						if v.GroupWithUnit then
							v2.GroupWithUnit = i .. v.GroupWithUnit
						end

						if v.WaitForUnit then
							v2.WaitForUnit = i .. v.WaitForUnit
						end

						print(spawners[i].SpawnerName)
						v2.SpawnerName = SPAWNERS_[i]

						local spawn = CHoldoutGameSpawner()
						spawn:ReadConfiguration( k2, v2, self )
						self._vSpawners[ k2 ] = spawn
					end
				else
					if v.SpawnerName == "left" then
						v.SpawnerName = SPAWNERS_[1]
					elseif v.SpawnerName == "right" then
						v.SpawnerName = SPAWNERS_[2]
					elseif v.SpawnerName == "random" then

						v.SpawnerName = SPAWNERS_[RandomInt(1, #SPAWNERS_)]
					--local name = v.name
					----print( "spawnername:" .. name)
					end

					local spawn = CHoldoutGameSpawner()
					spawn:ReadConfiguration( k, v, self )
					--table.insert(self._vSpawners, spawner)
					self._vSpawners[ k ] = spawn
				end
			end
		end

		for _, spawner in pairs( self._vSpawners ) do
			print(string.format("name: " .. spawner._szName))
			print(string.format("spawn: " .. spawner._szSpawnerName))
			print(string.format("wait: " .. spawner._szWaitForPack))
			print(string.format("group: " .. spawner._szGroupWithPack))


			spawner:PostLoad( self._vSpawners )
		end
	end
end

function CHoldoutGameRound:PackGetUnitCount(str)
	if self._vPacks[str] then
		local count = 0

		for _, n in pairs(self._vPacks[str]) do
			count = count + n["UnitsPerSpawn"]
		end

		return count
	end

	return 0
end


function CHoldoutGameRound:PackGetValue(str)
	if self._vPacks[str] then
		local count = 0

		for _, n in pairs(self._vPacks[str]) do
			count = count + (n["UnitsPerSpawn"] * n["CoreValue"])
		end

		return count
	end

	return 0
end


function CHoldoutGameRound:Prepare()
	if self:IsBoss() then
		self._bossHandler:Prepare()
		
		print("prepare boss")
	end
	print("prepare round")
	self._gameMode._flPrepTimeBetweenRounds = self._flPrepTime
end


function CHoldoutGameRound:IsBoss()
	if IsValidBoss(self._nBoss) then
		return true
	end

	return false
end

function CHoldoutGameRound:UpdateBossDifficulty()
	if self:IsBoss() then
		self._bossHandler:UpdateBossDifficulty()
		print("update boss difficulty")
	end
end


function CHoldoutGameRound:Precache()
	if not self:IsBoss() then
		for _, spawner in pairs( self._vSpawners ) do
			spawner:Precache()
		end
	end
end


function CHoldoutGameRound:Begin()
	self._vEnemiesRemaining = {}

	self._vPlayerStats = {}
	for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
		self._vPlayerStats[ nPlayerID ] = {
			nCreepsKilled = 0,
			nGoldBagsCollected = 0,
			nPriorRoundDeaths = PlayerResource:GetDeaths( nPlayerID ),
			nPlayersResurrected = 0
		}
	end

	self._nGoldRemainingInRound = self._nMaxGold
	self._nWoodRemainingInRound = self._nMaxWood
	self._nGoldBagsRemaining = self._nBagCount
	self._nGoldBagsExpired = 0
	self._nCoreUnitsTotal = 0
	self._nCoreValueTotal = 0
	self._nCoreUnitsSpawnedValue = 0	
	self._nCoreUnitsKilled = 0
	
	if not self:IsBoss()then
		for _, spawner in pairs( self._vSpawners ) do
			spawner:Begin()
			self._nCoreUnitsTotal = self._nCoreUnitsTotal + spawner:GetTotalUnitsToSpawn()
			self._nCoreValueTotal = self._nCoreValueTotal + spawner:GetTotalCoreValue()
		end

		self._entQuest = SpawnEntityFromTableSynchronous( "quest", {
			name = self._szRoundTitle,
			title =  self._szRoundQuestTitle
		})
		self._entQuest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_ROUND, self._nRoundNumber )
		self._entQuest:SetTextReplaceString( self._gameMode:GetDifficultyString() )

		self._entKillCountSubquest = SpawnEntityFromTableSynchronous( "subquest_base", {
			show_progress_bar = true,
			progress_bar_hue_shift = -119
		} )
		self._entQuest:AddSubquest( self._entKillCountSubquest )
		self._entKillCountSubquest:SetTextReplaceValue( SUBQUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, self._nCoreValueTotal )
	else
		self._bossHandler:Begin()
	end
end


function CHoldoutGameRound:StopListeningEvents()
	for _, eID in pairs( self._vEventHandles ) do
		StopListeningToGameEvent( eID )
	end
	self._vEventHandles = {}
end


function CHoldoutGameRound:StopListeningToSpawn()
	StopListeningToGameEvent( self._vEventHandles[1] )
end


function CHoldoutGameRound:End()
	if not self.IsBoss then
		for _,spawner in pairs( self._vSpawners ) do
			spawner:End()
		end
	end

	if self._entQuest then
		UTIL_RemoveImmediate( self._entQuest )
		self._entQuest = nil
		self._entKillCountSubquest = nil
	end

	--[[local nTowers = 0
	local nTowersStanding = 0
	for _,unit in pairs( FindUnitsInRadius( DOTA_TEAM_GOODGUYS, Vector( 0, 0, 0 ), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BUILDING, DOTA_UNIT_TARGET_FLAG_DEAD, FIND_ANY_ORDER, false ) ) do
		if unit:IsTower() then
			nTowers = nTowers + 1
			if unit:IsAlive() then
				nTowersStanding = nTowersStanding + 1
			end
		end
	end
	local nTowersStandingGoldReward = self._gameMode:ComputeTowerBonusGold( nTowers, nTowersStanding )
	for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
		if PlayerResource:HasSelectedHero( nPlayerID ) then
			PlayerResource:ModifyGold( nPlayerID, nTowersStandingGoldReward, true, DOTA_ModifyGold_Unspecified )
		end
	end

	local roundEndSummary = {
		nRoundNumber = self._nRoundNumber - 1,
		nRoundDifficulty = GameRules:GetCustomGameDifficulty(),
		roundName = self._szRoundTitle,
		nTowers = nTowers,
		nTowersStanding = nTowersStanding,
		nTowersStandingGoldReward = nTowersStandingGoldReward,
		nGoldBagsExpired = self._nGoldBagsExpired
	}

	local playerSummaryCount = 0
	for i = 1, DOTA_MAX_TEAM_PLAYERS do
		local nPlayerID = i-1
		if PlayerResource:HasSelectedHero( nPlayerID ) then
			local szPlayerPrefix = string.format( "Player_%d_", playerSummaryCount)
			playerSummaryCount = playerSummaryCount + 1
			local playerStats = self._vPlayerStats[ nPlayerID ]
			roundEndSummary[ szPlayerPrefix .. "HeroName" ] = PlayerResource:GetSelectedHeroName( nPlayerID )
			roundEndSummary[ szPlayerPrefix .. "CreepKills" ] = playerStats.nCreepsKilled
			roundEndSummary[ szPlayerPrefix .. "GoldBagsCollected" ] = playerStats.nGoldBagsCollected
			roundEndSummary[ szPlayerPrefix .. "Deaths" ] = PlayerResource:GetDeaths( nPlayerID ) - playerStats.nPriorRoundDeaths
			roundEndSummary[ szPlayerPrefix .. "PlayersResurrected" ] = playerStats.nPlayersResurrected
		end
	end
	FireGameEvent( "holdout_show_round_end_summary", roundEndSummary )
	]]
end


function CHoldoutGameRound:Think()
	------print (self:IsBoss()) 
	if not self:IsBoss() then
		for _, spawner in pairs( self._vSpawners ) do
			spawner:Think()
		end
	else
		self._bossHandler:Think()
	end
end


function CHoldoutGameRound:ChooseRandomSpawnInfo()
	return self._gameMode:ChooseRandomSpawnInfo()
end


function CHoldoutGameRound:IsFinished()
	if not self:IsBoss()then
		for _, spawner in pairs( self._vSpawners ) do
			if not spawner:IsFinishedSpawning() then
				return false
			end
		end
	else
		return self._bossHandler:IsFinished()
	end
	
	if not self._lastEnemiesRemaining == nEnemiesRemaining then
		self._lastEnemiesRemaining = nEnemiesRemaining
		----print ( string.format( "%d enemies remaining in the round...", #self._vEnemiesRemaining ) )
	end
	return true
end


-- Rather than use the xp granting from the units keyvalues file,
-- we let the round determine the xp per unit to grant as a flat value.
-- This is done to make tuning of rounds easier.
function CHoldoutGameRound:GetXPPerCoreUnit()
	if self._nCoreUnitsTotal == 0 then
		return 0
	else
		return self._nFixedXP / self._nCoreValueTotal
	end
end

function CHoldoutGameRound:GetGoldPerCoreUnit()
	if self._nCoreUnitsTotal == 0 then
		return 0
	else
		return self._nMaxGold / self._nCoreValueTotal
	end
end



function CHoldoutGameRound:OnNPCSpawned( event )
	local spawnedUnit = EntIndexToHScript( event.entindex )
	if not spawnedUnit or spawnedUnit:IsPhantom() or spawnedUnit:GetClassname() == "npc_dota_thinker" or spawnedUnit:GetUnitName() == "" then
		return
	end

	if self:IsBoss() then
		self._bossHandler:OnNPCSpawned(event)
	end

	if spawnedUnit:GetTeamNumber() == DOTA_TEAM_BADGUYS then
		--spawnedUnit:SetMustReachEachGoalEntity(false)
		table.insert( self._vEnemiesRemaining, spawnedUnit )
		spawnedUnit.unitName = spawnedUnit:GetUnitName()
	end
end


function CHoldoutGameRound:OnEntityKilled( event )
	----print("entity killed !!!!! round trigger")
	local killedUnit = EntIndexToHScript( event.entindex_killed )
	if not killedUnit then
		return
	end

	local attackerUnit = EntIndexToHScript( event.entindex_attacker or -1 )
	local pID = attackerUnit:GetPlayerOwnerID()


	for i, unit in pairs( self._vEnemiesRemaining ) do
		if killedUnit == unit then
			table.remove( self._vEnemiesRemaining, i )
			break
		end
	end	

	if killedUnit.Holdout_CoreNum == self._nRoundNumber then
		self._nCoreUnitsKilled = self._nCoreUnitsKilled + 1
		self:_CheckForGoldBagDrop( killedUnit )
		self._gameMode:CheckForLootItemDrop( killedUnit )

		local xpGain = killedUnit.RewardXP or 0
		--print(string.format("xpGain = %d", xpGain))
		local goldGain = killedUnit.RewardGold or 0
		--print(string.format("goldGain = %d", goldGain))
		local bGoal = killedUnit.EnteredGoal or false

		----print(string.format("enteredGoal = %d", bGoal))
		if bGoal then
			local xpBuffer = self._nFixedXP * XP_BUFFER_PCT - self._nXPBuffer
			--print(string.format("xpbuffer = %d", xpBuffer))
			xpGain = math.min( xpBuffer, xpGain)
			

			self._nXPBuffer = self._nXPBuffer + xpGain

			local goldBuffer = self._nMaxGold * GOLD_BUFFER_PCT - self._nGoldBuffer
			goldGain = math.min( goldBuffer, goldGain)

			self._nGoldBuffer = self._nGoldBuffer + goldGain
		end

		local goldModifier = goldGain

		if goldGain > 0 then
			--ParticleManager:SetParticleControl(pidx, 1, Vector(tonumber(presymbol), tonumber(number), tonumber(postsymbol)))
  			--ParticleManager:SetParticleControl(pidx, 2, Vector(lifetime, digits, 0))
  			--ParticleManager:SetParticleControl(pidx, 3, color)
			
		end

		for _, hero in pairs(self._gameMode._vHeroes) do
			--[[if xpGain > 0 then
				--print(xpGain)
				
				if GameRules:GetGameTime() >= hero.ShowExperienceNextUpdate or GameRules:GetGameTime() >= hero.ShowExperienceNextUpdateDelay then
					hero.ShowExperienceNextUpdateDelay = GameRules:GetGameTime() + INTERVALL_SHOW_EXPERIENCE_MAX
					GameRules.holdOut:ExperiencePopup(hero)
				end

				hero.ShowExperienceNextUpdate = GameRules:GetGameTime() + INTERVALL_SHOW_EXPERIENCE_MIN

				self._gameMode:HeroAddExperience(hero, xpGain, DOTA_ModifyXP_CreepKill, true, false)
				--DebugDrawText(hero:GetAbsOrigin(), string.format(xpGain), true, 0.5)
				--AddExperience(float amount, int nReason, bool bApplyBotDifficultyScaling, bool bIncrementTotal)
				hero.ShowExperiencePool = hero.ShowExperiencePool + xpGain
				--print(xpGain)
			end]]

			--print(string.format("goldgain: %f", goldGain))

			self._gameMode:HeroAddExperience(hero, xpGain, DOTA_ModifyXP_CreepKill, true, false)

			if goldGain > 0 then

				goldModifier = goldGain

				if attackerUnit == nil or hero ~= attackerUnit then
					goldModifier = goldGain * 0.33
				end

				self._gameMode:PlayerModifyGold(hero:GetPlayerOwnerID(), goldModifier, true, DOTA_ModifyGold_CreepKill)
				
				--goldAdd = goldRound + pendingGoldPlayerResource:ModifyGold(hero:GetPlayerOwnerID(), goldModifier, true, DOTA_ModifyGold_CreepKill)

				local goldFx = ParticleManager:CreateParticle("particles/econ/items/alchemist/alchemist_midas_knuckles/alch_knuckles_lasthit_coins.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
				ParticleManager:ReleaseParticleIndex( goldFx )

				if attackerUnit ~= nil and attackerUnit ~= killedUnit then
					PopupNumbers(killedUnit, PATTACH_ABSORIGIN_FOLLOW, "gold", Vector(255, 200, 33), 2.0, math.floor(goldModifier), POPUP_SYMBOL_PRE_PLUS, nil, hero:GetPlayerOwnerID())
				else
					PopupNumbers(self._gameMode._entAncient, PATTACH_ABSORIGIN_FOLLOW, "gold", Vector(255, 200, 33), 2.0, math.floor(goldModifier), POPUP_SYMBOL_PRE_PLUS, nil, hero:GetPlayerOwnerID())
				end

				--print(goldModifier)
			end
		end
	end

	if attackerUnit then
		local playerID = attackerUnit:GetPlayerOwnerID()
		local playerStats = self._vPlayerStats[ playerID ]
		if playerStats then
			playerStats.nCreepsKilled = playerStats.nCreepsKilled + 1
		end
	end
end


function CHoldoutGameRound:OnHoldoutReviveComplete( event )
	local castingHero = EntIndexToHScript( event.caster )
	if castingHero then
		local nPlayerID = castingHero:GetPlayerOwnerID()
		local playerStats = self._vPlayerStats[ nPlayerID ]
		if playerStats then
			playerStats.nPlayersResurrected = playerStats.nPlayersResurrected + 1
		end
	end
end


function CHoldoutGameRound:OnItemPickedUp( event )
end


function CHoldoutGameRound:_CheckForGoldBagDrop( killedUnit )
	if self._nGoldRemainingInRound <= 0 then
		return
	end

	local nGoldToDrop = 0
	local nCoreUnitsRemaining = self._nCoreUnitsTotal - self._nCoreUnitsKilled
	if nCoreUnitsRemaining <= 0 then
		nGoldToDrop = self._nGoldRemainingInRound
	else
		local flCurrentDropChance = self._nGoldBagsRemaining / (1 + nCoreUnitsRemaining)
		if RandomFloat( 0, 1 ) <= flCurrentDropChance then
			if self._nGoldBagsRemaining <= 1 then
				nGoldToDrop = self._nGoldRemainingInRound
			else
				nGoldToDrop = math.floor( self._nGoldRemainingInRound / self._nGoldBagsRemaining )
				nCurrentGoldDrop = math.max(1, RandomInt( nGoldToDrop - self._nBagVariance, nGoldToDrop + self._nBagVariance  ) )
			end
		end
	end
	
	nGoldToDrop = math.min( nGoldToDrop, self._nGoldRemainingInRound )
	if nGoldToDrop <= 0 then
		return
	end
	self._nGoldRemainingInRound = math.max( 0, self._nGoldRemainingInRound - nGoldToDrop )
	self._nGoldBagsRemaining = math.max( 0, self._nGoldBagsRemaining - 1 )

	--[[local newItem = CreateItem( "item_bag_of_gold", nil, nil )
	newItem:SetPurchaseTime( nGoldToDrop )
	newItem:SetCurrentCharges( 0 )
	local drop = CreateItemOnPositionSync( killedUnit:GetAbsOrigin(), newItem )
	local dropTarget = killedUnit:GetAbsOrigin() + RandomVector( RandomFloat( 50, 350 ) )
	newItem:LaunchLoot( true, 300, 0.75, dropTarget )
	]]
end


function CHoldoutGameRound:StatusReport( )
	----print( string.format( "Enemies remaining: %d", #self._vEnemiesRemaining ) )
	for _,e in pairs( self._vEnemiesRemaining ) do
		if e:IsNull() then
			----print( string.format( "<Unit %s Deleted from C++>", e.unitName ) )
		else
			----print( e:GetUnitName() )
		end
	end
	----print( string.format( "Spawners: %d", #self._vSpawners ) )
	for _,s in pairs( self._vSpawners ) do
		s:StatusReport()
	end
end