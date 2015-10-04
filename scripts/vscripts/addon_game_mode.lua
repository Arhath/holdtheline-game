--[[
Holdout Example

	Underscore prefix such as "_function()" denotes a local function and is used to improve readability
	
	Variable Prefix Examples
		"fl"	Float
		"n"		Int
		"v"		Table
		"b"		Boolean
]]

require( "holdout_game_round" )
require( "holdout_game_spawner" )
require( "misc/trigger" )
require( "misc/timers" )
require( "misc/utility_functions" )
require( "boss/holdout_game_bosshandler" )
require( "ai/movement_system" )
require( "bottle/bottle_system" )
require( "misc/gate_system")

if CHoldoutGameMode == nil then
	CHoldoutGameMode = class({})
	--print (string.format( "Create Class") )
end

MAX_LEVEL = 125

XP_PER_LEVEL_TABLE = {}
XP_PER_LEVEL_TABLE[1] = 200
for i=1, MAX_LEVEL - 1 do
	XP_PER_LEVEL_TABLE[i+1] = XP_PER_LEVEL_TABLE[i] + i * 200
	--print(XP_PER_LEVEL_TABLE[i])
end



-- Precache resources
function Precache( context )
	--PrecacheResource( "particle", "particles/generic_gameplay/winter_effects_hero.vpcf", context )
	PrecacheUnitByNameSync("treant_mushroom_creature_big", context)
	PrecacheResource( "particle", "particles/items2_fx/veil_of_discord.vpcf", context )	
	PrecacheResource( "particle_folder", "particles/frostivus_gameplay", context )
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_elder_titan", context )
	PrecacheResource( "particle", "particles/econ/courier/courier_platinum_roshan/platinum_roshan_ambient.vpcf", context )
	PrecacheResource( "particle", "particles/econ/items/antimage/antimage_weapon_manta/antimage_blade_primary_manta_passive.vpcf", context )
	PrecacheResource( "particle", "particles/econ/items/spectre/spectre_weapon_diffusal/spectre_diffusal_ambient.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_warlock/warlock_upheaval_debuff.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_abaddon/abaddon_aphotic_shield.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_treant/treant_leech_seed_projectile.vpcf", context )
	PrecacheResource( "particle", "particles/econ/items/drow/drow_head_mania/mask_of_madness_active_mania.vpcf", context )
	PrecacheResource( "particle", "particles/econ/items/tinker/boots_of_travel/teleport_start_bots_counter.vpcf", context )
	PrecacheResource( "particle", "particles/econ/items/tinker/boots_of_travel/teleport_end_bots.vpcf", context )
	PrecacheItemByNameSync( "item_tombstone", context )
	PrecacheItemByNameSync( "item_bag_of_gold", context )
	PrecacheItemByNameSync( "item_glyph_mana", context )
	PrecacheItemByNameSync( "item_slippers_of_halcyon", context )
	PrecacheItemByNameSync( "item_greater_clarity", context )
end

-- Actually make the game mode when we activate
function Activate()
		GameRules.holdOut = CHoldoutGameMode()
		--print (string.format( "Activated") )
		GameRules.holdOut:InitGameMode()
end

TREE_HEALTH = 10
START_LUMBER = 500

function CHoldoutGameMode:InitGameMode()
--print (string.format( "InitGameMode") )
	self._nRoundNumber = 1
	self._vCoreUnitsReachedGoal =  {}
	self._vCoreUnitsReachedGoal[DOTA_TEAM_GOODGUYS] = 0
	self._vCoreUnitsReachedGoal[DOTA_TEAM_BADGUYS] = 0
	self._currentRound = nil
	self._nextRound = nil
	self._flLastThinkGameTime = nil
	self._entAncient = Entities:FindByName( nil, "dota_goodguys_fort" )
	self._entAncient:SetMana(100.0)
	self._nTeam = DOTA_TEAM_GOODGUYS
	self._nTeamEnemy = DOTA_TEAM_BADGUYS
	self._vHeroes = {}

	self._movementSystem = CMovementSystem()
	self._movementSystem:Init(self, DOTA_TEAM_BADGUYS)

	self._bottleSystem = CBottleSystem()
	self._bottleSystem:Init(self, DOTA_TEAM_GOODGUYS)

	self._gateSystem = CGateSystem()
	self._gateSystem:Init(self, DOTA_TEAM_GOODGUYS)
	
	Timers:CreateTimer(5, function()
		TestSpawn("treant_mushroom_creature_big","testspawner_2", 0, DOTA_TEAM_GOODGUYS)
		return nil
		end
		)
	
	if not self._entAncient then
		--print( "Ancient entity not found!" )
	end
	
	entSheepCenter = Entities:FindByName( nil, "sheepcenter" )
	if entSheepCenter ~= nil then
		--print("sheep center found")
		vecSheepCenter = entSheepCenter:GetOrigin()
		vecSheepCenter.z = 0
	end

	entShopSheep = Entities:FindByName(nil, "shopsheep")
	if entShopSheep ~= nil then
		--print("shepfound")
	end
	entShopSheep:AddNewModifier( entShopSheep, nil, "modifier_invulnerable", {} )
	
	fSheepIdleRange = 200.0
	fSheepNextIdle = GameRules:GetGameTime()
	fSheepIdleIntervall = 4.0

	GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 4 )
	GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 0 )

	self:_ReadGameConfiguration()
	GameRules:SetTimeOfDay( 0.75 )
	GameRules:SetHeroRespawnEnabled( true)
	GameRules:SetUseUniversalShopMode( true )
	GameRules:SetHeroSelectionTime( 30.0 )
	GameRules:SetPreGameTime( 2.0 )
	GameRules:SetPostGameTime( 60.0 )
	GameRules:SetTreeRegrowTime( 120.0 )
	GameRules:SetHeroMinimapIconScale( 0.7 )
	GameRules:SetCreepMinimapIconScale( 0.7 )
	GameRules:SetRuneMinimapIconScale( 0.7 )
	GameRules:SetGoldTickTime( 0.5 )
	GameRules:SetGoldPerTick( 2 )
	GameRules:SetUseBaseGoldBountyOnHeroes(false)
	GameRules:SetRuneSpawnTime(180.0)

	GameRules:GetGameModeEntity():SetRemoveIllusionsOnDeath( false )
	GameRules:GetGameModeEntity():SetTopBarTeamValuesOverride( true )
	GameRules:GetGameModeEntity():SetTopBarTeamValuesVisible( false )
	GameRules:GetGameModeEntity():SetLoseGoldOnDeath( false )

	mode:SetUseCustomHeroLevels ( true )
	mode:SetCustomHeroMaxLevel ( MAX_LEVEL )

	mode:SetCustomXPRequiredToReachNextLevel( XP_PER_LEVEL_TABLE )


--	GameRules:GetGameModeEntity():SetHUDVisible( DOTA_HUD_VISIBILITY_TOP_TIMEOFDAY, false )
--	GameRules:GetGameModeEntity():SetHUDVisible( DOTA_HUD_VISIBILITY_TOP_HEROES, false )
--	GameRules:GetGameModeEntity():SetHUDVisible( DOTA_HUD_VISIBILITY_TOP_SCOREBOARD, false )
--	GameRules:GetGameModeEntity():SetHUDVisible( DOTA_HUD_VISIBILITY_ACTION_PANEL, false )
--	GameRules:GetGameModeEntity():SetHUDVisible( DOTA_HUD_VISIBILITY_ACTION_MINIMAP, false )
--	GameRules:GetGameModeEntity():SetHUDVisible( DOTA_HUD_VISIBILITY_INVENTORY_PANEL, true )
--	GameRules:GetGameModeEntity():SetHUDVisible( DOTA_HUD_VISIBILITY_INVENTORY_ITEMS, false )
--	GameRules:GetGameModeEntity():SetHUDVisible( DOTA_HUD_VISIBILITY_INVENTORY_SHOP, false )
--	GameRules:GetGameModeEntity():SetHUDVisible( DOTA_HUD_VISIBILITY_INVENTORY_GOLD, false )
--	GameRules:GetGameModeEntity():SetHUDVisible( DOTA_HUD_VISIBILITY_INVENTORY_PROTECT, false )
--	GameRules:GetGameModeEntity():SetHUDVisible( DOTA_HUD_VISIBILITY_INVENTORY_COURIER, false )
--	GameRules:GetGameModeEntity():SetHUDVisible( DOTA_HUD_VISIBILITY_INVENTORY_QUICKBUY, false )
--	GameRules:GetGameModeEntity():SetHUDVisible( DOTA_HUD_VISIBILITY_SHOP_SUGGESTEDITEMS, false )

	-- Custom console commands
	Convars:RegisterCommand( "holdout_test_round", function(...) return self:_TestRoundConsoleCommand( ... ) end, "Test a round of holdout.", FCVAR_CHEAT )
	Convars:RegisterCommand( "holdout_spawn_gold", function(...) return self._GoldDropConsoleCommand( ... ) end, "Spawn a gold bag.", FCVAR_CHEAT )
	Convars:RegisterCommand( "holdout_status_report", function(...) return self:_StatusReportConsoleCommand( ... ) end, "Report the status of the current holdout game.", FCVAR_CHEAT )
	-- Set all towers invulnerable
	for _, ward in pairs( Entities:FindAllByName( "ward" ) ) do
		ward:AddNewModifier( ward, nil, "modifier_invulnerable", {} )
	end
	
	for _, tower in pairs( Entities:FindAllByName( "dota_goodguys_tower1_mid" ) ) do
		tower:AddNewModifier( tower, nil, "modifier_invulnerable", {} )
	end

	-- Hook into game events allowing reload of functions at run time
	ListenToGameEvent( "npc_spawned", Dynamic_Wrap( CHoldoutGameMode, "OnNPCSpawned" ), self )
	ListenToGameEvent( "player_reconnected", Dynamic_Wrap( CHoldoutGameMode, 'OnPlayerReconnected' ), self )
	ListenToGameEvent( "entity_killed", Dynamic_Wrap( CHoldoutGameMode, 'OnEntityKilled' ), self )
	ListenToGameEvent( "dota_item_picked_up", Dynamic_Wrap( CHoldoutGameMode, 'OnItemPickedUp' ), self )
	ListenToGameEvent( "dota_holdout_revive_complete", Dynamic_Wrap( CHoldoutGameMode, 'OnHoldoutReviveComplete' ), self )
	--print (string.format( "hookentity") )
	ListenToGameEvent( "game_rules_state_change", Dynamic_Wrap( CHoldoutGameMode, "OnGameRulesStateChange" ), self )
	ListenToGameEvent('dota_rune_activated_server', Dynamic_Wrap(CHoldoutGameMode, 'OnRuneActivated'), self)
	ListenToGameEvent('entity_hurt', Dynamic_Wrap(CHoldoutGameMode, 'OnEntityHurt'), self)


	CustomGameEventManager:RegisterListener( "unit_right_click", Dynamic_Wrap(CHoldoutGameMode, "OnUnitRightClick"))
	CustomGameEventManager:RegisterListener( "unit_left_click", Dynamic_Wrap(CHoldoutGameMode, "OnUnitLeftClick"))
	


	-- Register OnThink with the game engine so it is called every 0.25 seconds
	--GameRules:GetGameModeEntity():SetThink( "OnThink", self, 0.25 )
	Timers:CreateTimer(function()
		self:OnThink()
		return 0.25
	end
	)
end


-- Read and assign configurable keyvalues if applicable
function CHoldoutGameMode:_ReadGameConfiguration()
	local kv = LoadKeyValues( "scripts/maps/" .. GetMapName() .. ".txt" )
	kv = kv or {} -- Handle the case where there is not keyvalues file

	self._bAlwaysShowPlayerGold = kv.AlwaysShowPlayerGold or false
	self._bRestoreHPAfterRound = kv.RestoreHPAfterRound or false
	self._bRestoreMPAfterRound = kv.RestoreMPAfterRound or false
	self._bRewardForTowersStanding = kv.RewardForTowersStanding or false
	self._bUseReactiveDifficulty = kv.UseReactiveDifficulty or false

	self._nTowerRewardAmount = tonumber( kv.TowerRewardAmount or 0 )
	self._nTowerScalingRewardPerRound = tonumber( kv.TowerScalingRewardPerRound or 0 )

	self._flPrepTimeBetweenRounds = tonumber( kv.PrepTimeBetweenRounds or 0 )
	self._flItemExpireTime = tonumber( kv.ItemExpireTime or 10.0 )

	self:_ReadRandomSpawnsConfiguration( kv["RandomSpawns"] )
	self:_ReadLootItemDropsConfiguration( kv["ItemDrops"] )
	self:_ReadRoundConfigurations( kv )
	
	mode = GameRules:GetGameModeEntity()        
    mode:SetCameraDistanceOverride(1600.0)
	mode:SetBuybackEnabled( false)
	mode:SetFogOfWarDisabled(false)
end


function CHoldoutGameMode:ShopSheepIdle()
	if GameRules:GetGameTime() >= fSheepNextIdle then
		fSheepNextIdle = fSheepNextIdle + RandomInt(1, fSheepIdleIntervall)
		
		order =
		{
			UnitIndex = entShopSheep:entindex(),
			OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
			Position = vecSheepCenter + Vector(RandomInt(-(fSheepIdleRange), fSheepIdleRange), RandomInt(-(fSheepIdleRange), fSheepIdleRange) , 0),
		}
		
		ExecuteOrderFromTable( order )
		----print("sheep idle")
	end
end


-- Verify spawners if random is set
function CHoldoutGameMode:ChooseRandomSpawnInfo()
	if #self._vRandomSpawnsList == 0 then
		error( "Attempt to choose a random spawn, but no random spawns are specified in the data." )
		return nil
	end
	return self._vRandomSpawnsList[ RandomInt( 1, #self._vRandomSpawnsList ) ]
end

function CHoldoutGameMode:GetSpawnerList()
	return  self._vRandomSpawnsList
end


-- Verify valid spawns are defined and build a table with them from the keyvalues file
function CHoldoutGameMode:_ReadRandomSpawnsConfiguration( kvSpawns )
	self._vRandomSpawnsList = {}
	if type( kvSpawns ) ~= "table" then
		return
	end
	for _,sp in pairs( kvSpawns ) do			-- Note "_" used as a shortcut to create a temporary throwaway variable
		table.insert( self._vRandomSpawnsList, {
			szSpawnerName = sp.SpawnerName or "",
			szFirstWaypoint = sp.Waypoint or ""
		} )
	end
end


-- If random drops are defined read in that data
function CHoldoutGameMode:_ReadLootItemDropsConfiguration( kvLootDrops )
	self._vLootItemDropsList = {}
	if type( kvLootDrops ) ~= "table" then
		return
	end
	for _,lootItem in pairs( kvLootDrops ) do
		table.insert( self._vLootItemDropsList, {
			szItemName = lootItem.Item or "",
			nChance = tonumber( lootItem.Chance or 0 )
		})
	end
end


-- Set number of rounds without requiring index in text file
function CHoldoutGameMode:_ReadRoundConfigurations( kv )
	self._vRounds = {}
	while true do
		local szRoundName = string.format("Round%d", #self._vRounds + 1 )
		local kvRoundData = kv[ szRoundName ]
		if kvRoundData == nil then
			return
		end
		local roundObj = CHoldoutGameRound()
		roundObj:ReadConfiguration( kvRoundData, self, #self._vRounds + 1 )
		table.insert( self._vRounds, roundObj )
	end
end


-- When game state changes set state in script
function CHoldoutGameMode:OnGameRulesStateChange()
	local nNewState = GameRules:State_Get()
	if nNewState == DOTA_GAMERULES_STATE_PRE_GAME then
		--ShowGenericPopup( "#holdout_instructions_title", "#holdout_instructions_body", "", "", DOTA_SHOWGENERICPOPUP_TINT_SCREEN )
	elseif nNewState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		self._flPrepTimeEnd = GameRules:GetGameTime() + self._flPrepTimeBetweenRounds
	end
end

function CHoldoutGameMode:SpawnRunes()
	--print("runes Spawned")
	--Timers:CreateTimer(1, function()
	--	GameRules:SetRuneSpawnTime(-1.0)
	--end
	--)
end


function CHoldoutGameMode:OnUnitRightClick( event )
	local pID = event.pID
	local unit = EntIndexToHScript(event.mainSelected)
	local mPos = Vector(0, 0, 0)
	local eventName = event.name

	mPos.x = event.mouseX
	mPos.y = event.mouseY
	--mPos.z = GetGroundHeight(mPos, nil)

	if eventName == "doublepressed" then

		--SafeSpawnCreature("npc_dota_creature_kobold_tunneler", mPos, 50, mPos.z, nil, nil, DOTA_TEAM_BADGUYS)
		UnitTeleportToPosition(unit, mPos, true)
		print(eventName)
	end

	--
end

function CHoldoutGameMode:OnUnitLeftClick( event )
	local pID = event.pID
	local unit = EntIndexToHScript(event.mainSelected)
	local mPos = Vector(0, 0, 0)
	local eventName = event.name

	mPos.x = event.mouseX
	mPos.y = event.mouseY
	--mPos.z = GetGroundHeight(mPos, nil)

	--if eventName == "doublepressed" then

		--SafeSpawnCreature("npc_dota_creature_kobold_tunneler", mPos, 50, mPos.z, nil, nil, DOTA_TEAM_BADGUYS)
		unit:SetControllableByPlayer(pID, true)
		--UnitTeleportToPosition(unit, mPos, true)
		print(eventName)
	--end

	--
end


-- Evaluate the state of the game
function CHoldoutGameMode:OnThink()
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		self:_CheckForDefeat()
		self:_ThinkLootExpiry()
		
		self:ShopSheepIdle()
		--self:_CheckForUnitInGoal()

		if self._flPrepTimeEnd ~= nil then
			self:_ThinkPrepTime()
		elseif self._currentRound ~= nil then
			self._currentRound:Think()
			if self._currentRound:IsFinished() then
			
				if self._currentRound:IsBoss() == 1 then
					self._entAncient:SetMana(100)
				else
					local roundMana = 2
					self._entAncient:SetMana(self._entAncient:GetMana() - roundMana )
					PopupNumbers(self._entAncient, "gold", Vector(0, 255, 0), 1.0, roundMana, POPUP_SYMBOL_PRE_PLUS, nil)
				end
				self._currentRound:End()
				self._currentRound = nil
				-- Heal all players
				self:_RefreshPlayers()

				self._nRoundNumber = self._nRoundNumber + 1
				if self._nRoundNumber > #self._vRounds then
					self._nRoundNumber = 1
					GameRules:MakeTeamLose( DOTA_TEAM_BADGUYS )
				else
					self._nextRound = self._vRounds[self._nRoundNumber]
					self._nextRound:Prepare()
					--self:SpawnRunes()
					self._flPrepTimeEnd = GameRules:GetGameTime() + self._flPrepTimeBetweenRounds
				end
			end
		end
	elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then		-- Safe guard catching any state that may exist beyond DOTA_GAMERULES_STATE_POST_GAME
		return nil
	end
	return 1
end


function CHoldoutGameMode:OnEntityHurt(keys)
  --Debug--print("[BAREBONES] Entity Hurt")
  --Debug--printTable(keys)

	local damagebits = keys.damagebits -- This might always be 0 and therefore useless
	if keys.entindex_attacker ~= nil and keys.entindex_killed ~= nil then
		local entCause = EntIndexToHScript(keys.entindex_attacker)
		local entVictim = EntIndexToHScript(keys.entindex_killed)

		self._movementSystem:OnEntityHurt(keys)
	
		----print(string.format("damagedone: %d", damagebits))
	
		if entVictim:IsRealHero() then
			local trees = GridNav:GetAllTreesAroundPoint(entVictim:GetAbsOrigin(), 140, true)
		
			for _, tree in pairs(trees) do
				----print(string.format("tree height: %d hero height: %d", tree:GetAbsOrigin().z, entVictim:GetAbsOrigin().z))
				if tree:GetAbsOrigin().z == entVictim:GetAbsOrigin().z then
					if tree.damage == nil then
						tree.damage = 1
					else
						tree.damage = tree.damage + 1
					end
					
					--PopupNumbers(tree, "gold", Vector(0, 255, 0), 1.0, TREE_HEALTH - tree.damage, POPUP_SYMBOL_PRE_PLUS, nil)
			
					if tree.damage >= TREE_HEALTH then
						tree:CutDown(entVictim:GetTeamNumber())
						tree.damage = 0
					end
				end
			end
		end
	end
end


function OnRadiantGoalEnter(trigger)
	----print(trigger.activator)
	local u = trigger.activator
	GameRules.holdOut:OnUnitEntersGoal(u, DOTA_TEAM_GOODGUYS)
end


--[[
function CHoldoutGameMode:_CheckForUnitInGoal()
	self._vCoreUnitsReachedGoal[DOTA_TEAM_BADGUYS] = self._vCoreUnitsReachedGoal[DOTA_TEAM_BADGUYS] + 1
	--print (string.format( "Units Reached Goal: %d", self._vCoreUnitsReachedGoal[DOTA_TEAM_BADGUYS]  ) )
end
]]


function CHoldoutGameMode:OnUnitEntersGoal(u, team)
	if u.Holdout_CoreNum ~= nil and u:GetTeamNumber() ~= team and u.CanEnterGoal ~= false then
		local CoreValue = u.CoreValue
		u.EnteredGoal = true

		PopupNumbers(self._entAncient, "gold", Vector(255, 0, 0), 1.0, CoreValue, POPUP_SYMBOL_PRE_PLUS, nil)
		u:ForceKill(false)
		
		self._vCoreUnitsReachedGoal[team] = self._vCoreUnitsReachedGoal[team] + 1
		----print (string.format( "Units Reached Goal: %d", self._vCoreUnitsReachedGoal[team]  ) )
		self._entAncient:SetMana(self._entAncient:GetMana() + CoreValue)
		if self._currentRound ~= nil then
			if self._currentRound:IsBoss() == 1 then
				self._currentRound:UpdateBossDifficulty()
			end
		end
	end
end


function CHoldoutGameMode:OnUnitEntersEnergyGate(u)
	if u.Holdout_CoreNum ~= nil and u:HasModifier("modifier_nether_buff_passive") then
		--Timers:CreateTimer(
			--function()
				local nFXIndex = ParticleManager:CreateParticle( "particles/items2_fx/veil_of_discord.vpcf", PATTACH_CUSTOMORIGIN, u )
				ParticleManager:SetParticleControl( nFXIndex, 0, u:GetOrigin() )
				ParticleManager:SetParticleControl( nFXIndex, 1, Vector( 35, 35, 25 ) )
				ParticleManager:ReleaseParticleIndex( nFXIndex )
				u:RemoveModifierByName("modifier_nether_buff_passive")
				u:RemoveModifierByName("modifier_nether_buff_fx")
			--	return 1.0
			--end
		--)
	end
end


function CHoldoutGameMode:OnUnitLeavesCleansingWater(u)
	--[[if u.Holdout_IsCore and u.Holdout_IsSpawnBuffed then
		u.Holdout_IsSpawnBuffed = false
		--print ("Debuff Unit.")
	end
	]] 
end


function CHoldoutGameMode:_RefreshPlayers()
	--[[
	for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
		if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS then
			if PlayerResource:HasSelectedHero( nPlayerID ) then
				local hero = PlayerResource:GetSelectedHeroEntity( nPlayerID )
				if not hero:IsAlive() then
					hero:RespawnUnit()
				end
				hero:SetHealth( hero:GetMaxHealth() )
				hero:SetMana( hero:GetMaxMana() )
			end
		end
	end
	]]
end


function CHoldoutGameMode:_CheckForDefeat()
	if GameRules:State_Get() ~= DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		return
	end

	if not self._entAncient or self._entAncient:GetHealth() <= 0 then
		GameRules:MakeTeamLose( DOTA_TEAM_GOODGUYS )
		return
	end
end


function CHoldoutGameMode:_ThinkPrepTime()
	if GameRules:GetGameTime() >= self._flPrepTimeEnd then
		self._flPrepTimeEnd = nil
		if self._entPrepTimeQuest then
			UTIL_Remove( self._entPrepTimeQuest )
			self._entPrepTimeQuest = nil
		end

		if self._nRoundNumber > #self._vRounds then
			GameRules:SetGameWinner( DOTA_TEAM_GOODGUYS )
			return false
		end
		self._currentRound = self._vRounds[ self._nRoundNumber ]
		self._currentRound:Begin()
		return
	end

	if not self._entPrepTimeQuest then
		self._entPrepTimeQuest = SpawnEntityFromTableSynchronous( "quest", { name = "PrepTime", title = "#DOTA_Quest_Holdout_PrepTime" } )
		self._entPrepTimeQuest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_ROUND, self._nRoundNumber )
		self._entPrepTimeQuest:SetTextReplaceString( self:GetDifficultyString() )

		self._vRounds[ self._nRoundNumber ]:Precache()
	end
	self._entPrepTimeQuest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, self._flPrepTimeEnd - GameRules:GetGameTime() )
end


function CHoldoutGameMode:_ThinkLootExpiry()
	if self._flItemExpireTime <= 0.0 then
		return
	end

	local flCutoffTime = GameRules:GetGameTime() - self._flItemExpireTime

	for _,item in pairs( Entities:FindAllByClassname( "dota_item_drop")) do
		local containedItem = item:GetContainedItem()
		if containedItem:GetAbilityName() == "item_bag_of_gold" or item.Holdout_IsLootDrop then
			self:_ProcessItemForLootExpiry( item, flCutoffTime )
		end
	end
end


function CHoldoutGameMode:_ProcessItemForLootExpiry( item, flCutoffTime )
	if item:IsNull() then
		return false
	end
	if item:GetCreationTime() >= flCutoffTime then
		return true
	end

	local containedItem = item:GetContainedItem()
	if containedItem and containedItem:GetAbilityName() == "item_bag_of_gold" then
		if self._currentRound and self._currentRound.OnGoldBagExpired then
			self._currentRound:OnGoldBagExpired()
		end
	end

	local nFXIndex = ParticleManager:CreateParticle( "particles/items2_fx/veil_of_discord.vpcf", PATTACH_CUSTOMORIGIN, item )
	ParticleManager:SetParticleControl( nFXIndex, 0, item:GetOrigin() )
	ParticleManager:SetParticleControl( nFXIndex, 1, Vector( 35, 35, 25 ) )
	ParticleManager:ReleaseParticleIndex( nFXIndex )
	local inventoryItem = item:GetContainedItem()
	if inventoryItem then
		UTIL_Remove( inventoryItem )
	end
	UTIL_Remove( item )
	return false
end


function CHoldoutGameMode:GetDifficultyString()
	local nDifficulty = GameRules:GetCustomGameDifficulty()
	if nDifficulty > 4 then
		return string.format( "(+%d)", nDifficulty )
	elseif nDifficulty > 0 then
		return string.rep( "+", nDifficulty )
	else
		return ""
	end
end


function CHoldoutGameMode:_SpawnHeroClientEffects( hero, nPlayerID )
	local nPlayerID = hero:GetPlayerOwnerID()
	-- Spawn these effects on the client, since we don't need them to stay in sync or anything
	-- ParticleManager:ReleaseParticleIndex( ParticleManager:CreateParticleForPlayer( "particles/generic_gameplay/winter_effects_hero.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero, PlayerResource:GetPlayer( nPlayerID ) ) )	-- Attaches the breath effects to players for winter maps
	ParticleManager:ReleaseParticleIndex( ParticleManager:CreateParticleForPlayer( "particles/frostivus_gameplay/frostivus_hero_light.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero, PlayerResource:GetPlayer( nPlayerID ) ) )
end


function CHoldoutGameMode:OnNPCSpawned( event )

	local spawnedUnit = EntIndexToHScript( event.entindex )
	if not spawnedUnit or spawnedUnit:GetClassname() == "npc_dota_thinker" or spawnedUnit:IsPhantom() then
		return
	end

	self._movementSystem:OnNPCSpawned(event)

	if spawnedUnit:IsCreep() then
		----print("scaling creature")
		spawnedUnit:SetHPGain( spawnedUnit:GetMaxHealth() * 0.3 ) -- LEVEL SCALING VALUE FOR HP
		spawnedUnit:SetManaGain( 0 )
		spawnedUnit:SetHPRegenGain( 0 )
		spawnedUnit:SetManaRegenGain( 0 )
		if spawnedUnit:IsRangedAttacker() then
			spawnedUnit:SetDamageGain( ( ( spawnedUnit:GetBaseDamageMax() + spawnedUnit:GetBaseDamageMin() ) / 2 ) * 0.1 ) -- LEVEL SCALING VALUE FOR DPS
		else
			spawnedUnit:SetDamageGain( ( ( spawnedUnit:GetBaseDamageMax() + spawnedUnit:GetBaseDamageMin() ) / 2 ) * 0.2 ) -- LEVEL SCALING VALUE FOR DPS
		end
		spawnedUnit:SetArmorGain( 0 )
		spawnedUnit:SetMagicResistanceGain( 0 )
		spawnedUnit:SetDisableResistanceGain( 0 )
		spawnedUnit:SetAttackTimeGain( 0 )
		spawnedUnit:SetMoveSpeedGain( 0 )
		spawnedUnit:SetBountyGain( 0 )
		spawnedUnit:SetXPGain( 0 )
		spawnedUnit:CreatureLevelUp( GameRules:GetCustomGameDifficulty() )
	end
	
	if self._currentRound ~= nil then
		self._currentRound:OnNPCSpawned( event )
	end

	-- Attach client side hero effects on spawning players
	if spawnedUnit:IsRealHero() and spawnedUnit.bFirstSpawned == nil then
		spawnedUnit.bFirstSpawned = true
		self:OnHeroInGame(spawnedUnit)
	end

	if spawnedUnit:IsRealHero() and spawnedUnit:GetTeamNumber()	== self._nTeam then
		self._bottleSystem:OnHeroSpawned(spawnedUnit)
		self:_SpawnHeroClientEffects( spawnedUnit )
	end

	--for nPlayerID = 0, DOTA_MAX_PLAYERS-1 do
		--if ( PlayerResource:IsValidPlayer( nPlayerID ) ) then
		--		
		--self:_SpawnHeroClientEffects( spawnedUnit, nPlayerID )
		--end
	--end
end

function CHoldoutGameMode:OnHeroInGame( hero )
	local player = hero:GetPlayerOwner()
	player.lumber = 0

	ModifyLumber(player, START_LUMBER)
	self._bottleSystem:OnHeroInGame(hero)

	table.insert(self._vHeroes, hero)
end

function ModifyLumber( player, lumber_value )
	if lumber_value == 0 then return end
	if lumber_value > 0 then
		player.lumber = player.lumber + lumber_value
	    CustomGameEventManager:Send_ServerToPlayer(player, "player_lumber_changed", { lumber = math.floor(player.lumber) })
	else
		if PlayerHasEnoughLumber( player, math.abs(lumber_value) ) then
			player.lumber = player.lumber + lumber_value
		    CustomGameEventManager:Send_ServerToPlayer(player, "player_lumber_changed", { lumber = math.floor(player.lumber) })
		end
	end
end

-- Attach client-side hero effects for a reconnecting player
function CHoldoutGameMode:OnPlayerReconnected( event )
	local nReconnectedPlayerID = event.PlayerID
	for _, hero in pairs( Entities:FindAllByClassname( "npc_dota_hero" ) ) do
		if hero:IsRealHero() then
			self:_SpawnHeroClientEffects( hero, nReconnectedPlayerID )
		end
	end
end


function CHoldoutGameMode:OnEntityKilled( event )

	self._movementSystem:OnEntityKilled(event)

	local killedUnit = EntIndexToHScript( event.entindex_killed )
	if killedUnit and killedUnit:GetTeamNumber() == self._nTeamEnemy then
		if killedUnit:IsRealHero() then
			local newItem = CreateItem( "item_tombstone", killedUnit, killedUnit )
			newItem:SetPurchaseTime( 0 )
			newItem:SetPurchaser( killedUnit )
			local tombstone = SpawnEntityFromTableSynchronous( "dota_item_tombstone_drop", {} )
			----print (string.format( "TombstoneSpawned") )
			tombstone:SetContainedItem( newItem )
			tombstone:SetAngles( 0, RandomFloat( 0, 360 ), 0 )
			FindClearSpaceForUnit( tombstone, killedUnit:GetAbsOrigin(), true )
		end

		if killedUnit.Holdout_CoreNum ~= nil then
			self._vRounds[killedUnit.Holdout_CoreNum]:OnEntityKilled( event )
			self._bottleSystem:SpawnGlyphOnPosition(killedUnit:GetAbsOrigin(), 1, 1)
		end 
	end
	
	
end

function CHoldoutGameMode:OnItemPickedUp( event )

	self._bottleSystem:OnItemPickedUp(event)

	if event.itemname == "item_bag_of_gold" then

		local item = EntIndexToHScript(event.ItemEntityIndex)
		local hero = EntIndexToHScript(event.HeroEntityIndex)
		local player = hero:GetPlayerOwner()
		local lumber = item:GetPurchaseTime()

		PopupNumbers(hero, "gold", Vector(0, 255, 0), 2.0, math.floor(lumber), POPUP_SYMBOL_POST_EXCLAMATION, nil)
		ModifyLumber(player, lumber)
	end
end

function CHoldoutGameMode:OnHoldoutReviveComplete( event )
	self._currentRound:OnHoldoutReviveComplete( event )
end


function CHoldoutGameMode:OnRuneActivated( event )
	--Deep--printTable( event ) 
end


function CHoldoutGameMode:CheckForLootItemDrop( killedUnit )
	for _,itemDropInfo in pairs( self._vLootItemDropsList ) do
		if RollPercentage( itemDropInfo.nChance ) then
			local newItem = CreateItem( itemDropInfo.szItemName, nil, nil )
			newItem:SetPurchaseTime( 0 )
			if newItem:IsPermanent() and newItem:GetShareability() == ITEM_FULLY_SHAREABLE then
				item:SetStacksWithOtherOwners( true )
			end
			local drop = CreateItemOnPositionSync( killedUnit:GetAbsOrigin(), newItem )
			drop.Holdout_IsLootDrop = true
		end
	end
end


function CHoldoutGameMode:ComputeTowerBonusGold( nTowersTotal, nTowersStanding )
	local nRewardPerTower = self._nTowerRewardAmount + self._nTowerScalingRewardPerRound * (self._nRoundNumber - 1)
	return nRewardPerTower * nTowersStanding
end

-- Leveling/gold data for console command "holdout_test_round"
--[[XP_PER_LEVEL_TABLE = {
	0,-- 1
	200,-- 2
	500,-- 3
	900,-- 4
	1400,-- 5
	2000,-- 6
	2600,-- 7
	3200,-- 8
	4400,-- 9
	5400,-- 10
	6000,-- 11
	8200,-- 12
	9000,-- 13
	10400,-- 14
	11900,-- 15
	13500,-- 16
	15200,-- 17
	17000,-- 18
	18900,-- 19
	20900,-- 20
	23000,-- 21
	25200,-- 22
	27500,-- 23
	29900,-- 24
	32400 -- 25
}

STARTING_GOLD = 625
ROUND_EXPECTED_VALUES_TABLE = {
	{ gold = STARTING_GOLD, xp = 0 }, -- 1
	{ gold = 1054+STARTING_GOLD, xp = XP_PER_LEVEL_TABLE[4] }, -- 2
	{ gold = 2212+STARTING_GOLD, xp = XP_PER_LEVEL_TABLE[5] }, -- 3
	{ gold = 3456+STARTING_GOLD, xp = XP_PER_LEVEL_TABLE[6] }, -- 4
	{ gold = 4804+STARTING_GOLD, xp = XP_PER_LEVEL_TABLE[8] }, -- 5
	{ gold = 6256+STARTING_GOLD, xp = XP_PER_LEVEL_TABLE[9] }, -- 6
	{ gold = 7812+STARTING_GOLD, xp = XP_PER_LEVEL_TABLE[9] }, -- 7
	{ gold = 9471+STARTING_GOLD, xp = XP_PER_LEVEL_TABLE[10] }, -- 8
	{ gold = 11234+STARTING_GOLD, xp = XP_PER_LEVEL_TABLE[11] }, -- 9
	{ gold = 13100+STARTING_GOLD, xp = XP_PER_LEVEL_TABLE[13] }, -- 10
	{ gold = 15071+STARTING_GOLD, xp = XP_PER_LEVEL_TABLE[13] }, -- 11
	{ gold = 17145+STARTING_GOLD, xp = XP_PER_LEVEL_TABLE[14] }, -- 12
	{ gold = 19322+STARTING_GOLD, xp = XP_PER_LEVEL_TABLE[16] }, -- 13
	{ gold = 21604+STARTING_GOLD, xp = XP_PER_LEVEL_TABLE[18] }, -- 14
	{ gold = 23368+STARTING_GOLD, xp = XP_PER_LEVEL_TABLE[18] } -- 15
}]]

-- Custom game specific console command "holdout_test_round"
function CHoldoutGameMode:_TestRoundConsoleCommand( cmdName, roundNumber, delay )
	local nRoundToTest = tonumber( roundNumber )
	----print (string.format( "Testing round %d", nRoundToTest ) )
	if nRoundToTest <= 0 or nRoundToTest > #self._vRounds then
		Msg( string.format( "Cannot test invalid round %d", nRoundToTest ) )
		return
	end

	local nExpectedGold = ROUND_EXPECTED_VALUES_TABLE[nRoundToTest].gold or 600
	local nExpectedXP = ROUND_EXPECTED_VALUES_TABLE[nRoundToTest].xp or 0
	for nPlayerID = 0, DOTA_MAX_PLAYERS-1 do
		if PlayerResource:IsValidPlayer( nPlayerID ) then
			PlayerResource:ReplaceHeroWith( nPlayerID, PlayerResource:GetSelectedHeroName( nPlayerID ), nExpectedGold, nExpectedXP )
			PlayerResource:SetBuybackCooldownTime( nPlayerID, 0 )
			PlayerResource:SetBuybackGoldLimitTime( nPlayerID, 0 )
			PlayerResource:ResetBuybackCostTime( nPlayerID )
		end
	end

	if self._entPrepTimeQuest then
		UTIL_Remove( self._entPrepTimeQuest )
		self._entPrepTimeQuest = nil
	end

	if self._currentRound ~= nil then
		self._currentRound:End()
		self._currentRound = nil
	end

	for _,item in pairs( Entities:FindAllByClassname( "dota_item_drop")) do
		local containedItem = item:GetContainedItem()
		if containedItem then
			UTIL_Remove( containedItem )
		end
		UTIL_Remove( item )
	end

	if self._entAncient and not self._entAncient:IsNull() then
		self._entAncient:SetHealth( self._entAncient:GetMaxHealth() )
	end

	self._flPrepTimeEnd = GameRules:GetGameTime() + self._flPrepTimeBetweenRounds
	self._nRoundNumber = nRoundToTest
	if delay ~= nil then
		self._flPrepTimeEnd = GameRules:GetGameTime() + tonumber( delay )
	end
end

function CHoldoutGameMode:_GoldDropConsoleCommand( cmdName, goldToDrop )
	local newItem = CreateItem( "item_bag_of_gold", nil, nil )
	newItem:SetPurchaseTime( 0 )
	if goldToDrop == nil then goldToDrop = 100 end
	newItem:SetCurrentCharges( goldToDrop )
	local spawnPoint = Vector( 0, 0, 0 )
	local heroEnt = PlayerResource:GetSelectedHeroEntity( 0 )
	if heroEnt ~= nil then
		spawnPoint = heroEnt:GetAbsOrigin()
	end
	local drop = CreateItemOnPositionSync( spawnPoint, newItem )
	newItem:LaunchLoot( true, 300, 0.75, spawnPoint + RandomVector( RandomFloat( 50, 350 ) ) )
end

function CHoldoutGameMode:_StatusReportConsoleCommand( cmdName )
	--print( "*** Holdout Status Report ***" )
	--print( string.format( "Current Round: %d", self._nRoundNumber ) )
	if self._currentRound then
		self._currentRound:StatusReport()
	end
	--print( "*** Holdout Status Report End *** ")
end