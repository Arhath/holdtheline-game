require( "ai_core" )

if BossTreant == nil then
	BossTreant = class({})
end

behaviorSystemBoss = {} -- create the global so we can assign to it
behaviorSystemFlower = {}
behaviorSystemMushroom ={}

DESIRE_ATTACK_FLOWER = 1.4

testcount = 0
scoreshowed = false
entBossUnit = nil
entBossFlower = nil
entBossMushroom = nil
entBossArena = nil
fBossArenaRange = 2000.0
strBossArenaName = "bossarena1"
bossTimePhase3 = 10

vecBossArenaPos = nil

function BossTreant:Init(handler, gameRound)
	self._fPhaseTime = 0
	self._bossHandler = handler
	self._gameRound = gameRound
	self._strBossUnit = "boss_treant" 
	self._strSpawner = "spawnerBoss"
	self._strRoundTitle = "Boss Treant"
	self._nPhase = 1
	entBossUnit = nil
	self.bFreezeBoss = false
	self.bLocReached = false
	self.bPhaseSwitch = true
	--self.abilityPhase2 = "boss_treant_phase_2"
	self.bOrbLeftReachedGoal = false
	self.bOrbRightReachedGoal = false
	
	self:SetArena()

	--print("bosshandlerinit")
	--print(fBossArenaDesire)
end


function BossTreant:SetArena()
	entBossArena = Entities:FindByName(nil, strBossArenaName)
	--print(strBossArenaName)
	if entBossArena ~= nil then
		--print ("bossarenafound")
		vecBossArenaPos = entBossArena:GetOrigin()
		vecBossArenaPos.z = 0
	end
end


function BossTreant:Begin()
	--print("begin")
	self:Spawn()
end


function BossTreant:Prepare()
	--print("prepare")
	PrecacheUnitByNameAsync( self._strBossUnit, function( sg ) self._sg = sg end )
end


function BossTreant:OnNPCSpawned( event )
	local spawnedUnit = EntIndexToHScript( event.entindex )

	if spawnedUnit:GetTeamNumber() == DOTA_TEAM_BADGUYS then
		spawnedUnit.Holdout_CoreNum = self._gameRound._nRoundNumber
		spawnedUnit.goalValue = 1
		--SetPhasing(spawnedUnit, 10)
	end
end


function BossTreant:Spawn()
	--print("spawn")
	local entSpawner = Entities:FindByName( nil, self._strSpawner)
	local vecSpawnLocation = nil
	
	if not entSpawner then
			--print( string.format( "Failed to find spawner named %s" , self._strSpawner) )
	end
	
	vecSpawnLocation = entSpawner:GetAbsOrigin()
	entBossUnit = CreateUnitByName( self._strBossUnit, vecSpawnLocation, true, nil, nil, DOTA_TEAM_BADGUYS )
	entBossUnit.MovementSystemActive = false
	entBossUnit.CanEnterGoal = false
	self._bossOriginalHealth = entBossUnit:GetMaxHealth()
	entBossUnit.difficultyApplier = nil
	self:ApplyDifficultyBuff(entBossUnit)
	behaviorSystemBoss = AICore:CreateBehaviorSystem( { BehaviorIdle } )--, BehaviorEarthsplitter, BehaviorRootHero, BehaviorSpawnFlowers, BehaviorSpawnMushrooms, BehaviorSpawnTrees, BehaviorRaiseNature, BehaviorMoveToArena, BehaviorAttack } )
	
	self._entQuest = SpawnEntityFromTableSynchronous( "quest", {
		name = self._strRoundTitle,
		title =  self._strRoundTitle
	})
	self._entQuest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_ROUND, 1 )
	--self._entQuest:SetTextReplaceString( self._gameMode:GetDifficultyString() )
	
	self._entKillCountSubquest = SpawnEntityFromTableSynchronous( "subquest_base", {
		show_progress_bar = true,
		progress_bar_hue_shift = -119
	} )
	self._entQuest:AddSubquest( self._entKillCountSubquest )
	self._entKillCountSubquest:SetTextReplaceValue( SUBQUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, entBossUnit:GetMaxHealth())
	
end


function BossTreant:UpdateBossDifficulty()
	self:ApplyDifficultyBuff(entBossUnit)
end


function BossTreant:ApplyDifficultyBuff(u)
	local nDifficultyStacks = self._gameRound._gameMode._entAncient:GetMana()
	if u.difficultyApplier == nil then
		local difficultyApplier = CreateItem("item_boss_difficulty_modifier_applier", u, u)
		u.difficultyApplier = difficultyApplier
		difficultyApplier:ApplyDataDrivenModifier(u, u, "modifier_boss_difficulty_passive", {duration=-1})
	end
	
	u:SetModifierStackCount("modifier_boss_difficulty_passive", nil, nDifficultyStacks)
	local hpPercent = u:GetHealth() / u:GetMaxHealth()
	u:SetMaxHealth(self._bossOriginalHealth * (1 + nDifficultyStacks / 100))
	u:SetHealth(u:GetMaxHealth() * hpPercent)
	--entBossUnit:AddNewModifier(entBossUnit, nil, "modifier_boss_difficulty" ,nil)
	--entBossUnit:SetModifierStackCount("modifier_boss_difficulty", nil, nDifficultyStacks)
end

function BossTreant:End()
	if self._sg ~= nil then
		UnloadSpawnGroupByHandle( self._sg )
		self._sg = nil
	end
end


function UnitCalcArenaDesire( unit, pos, range, desire, incr )
	local posUnit = unit:GetAbsOrigin()
		posUnit.z = 0
		pos.z = 0
		
		local distArena = ( pos - posUnit ):Length()
		--print (string.format( "dist arena: %d", distArena))
		local distDiff = distArena - range
		--print (string.format( "dist diff: %d", distDiff))
		--print(distDiff)
		
		if distDiff > 0 then
			return desire + incr * distDiff
			--print("distdiff > 0")
		else
			return 0.0
		end

end


function BossTreant:Think()

	if entBossUnit:IsAlive() or not entBossUnit:IsNull() then

		self:AIThink()
		
		if testcount == 2 and entBossUnit:GetHealth() >= entBossUnit:GetMaxHealth()/2 then
			entBossUnit:SetHealth(entBossUnit:GetMaxHealth()/2)
			GameRules:SetRuneSpawnTime(testcount)
			
		end
	
		if self._entKillCountSubquest then
			self._entKillCountSubquest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, entBossUnit:GetHealth())
		end
	 
		testcount = testcount + 1
		
	else
		if not scoreshowed then
			self:ShowScoreboard()
			scoreshowed = true
		end
	end
end


function BossTreant:ShowScoreboard()
	local roundEndSummary = {
		nRoundNumber = 1,
		nRoundDifficulty = 1,
		roundName = self._strRoundTitle,
		nTowers = 0,
		nTowersStanding = 0,
		nTowersStandingGoldReward = 0,
		nGoldBagsExpired = 0
	}

	local playerSummaryCount = 0
		
	for i = 1, DOTA_MAX_TEAM_PLAYERS do
		local nPlayerID = i-1
			
		if PlayerResource:HasSelectedHero( nPlayerID ) then
			local szPlayerPrefix = string.format( "Player_%d_", playerSummaryCount)
			playerSummaryCount = playerSummaryCount + 1
			roundEndSummary[ szPlayerPrefix .. "HeroName" ] = PlayerResource:GetSelectedHeroName( nPlayerID )
			roundEndSummary[ szPlayerPrefix .. "CreepKills" ] = 1
			roundEndSummary[ szPlayerPrefix .. "GoldBagsCollected" ] = 1
			roundEndSummary[ szPlayerPrefix .. "Deaths" ] = 0
			roundEndSummary[ szPlayerPrefix .. "PlayersResurrected" ] = 0
		end
			
	end
		
	FireGameEvent( "holdout_show_round_end_summary", roundEndSummary )	
end


function BossTreant:IsFinished()
end


function BossTreant:PhaseThink()
		--print (string.format( "phasethink: %d", self._nPhase))

	if self._nPhase == 1 then
		if self._fBossHpPercent <= 0.66 then
			self._fPhaseTime = 0
			self._nPhase = 2
		end
		
		--print("phase1think")

	self._fPhaseTime = self._fPhaseTime + 1	

	elseif self._nPhase == 2 then
	
		if self.bPhaseSwitch then
			self.bFreezeBoss = true
			SetPhasing(entBossUnit, -1)
			entBossUnit:AddNewModifier( entBossUnit, nil, "modifier_invulnerable", {} )
			self.bLocReached = false
			self.bPhaseSwitch = false
		end

		--print("Phase2")
		if self.bLocReached == false then
		--print("moving in position")
		
		
		
			local order =
				{
					UnitIndex = entBossUnit:entindex(),
					OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
				Position = vecBossArenaPos,
				}
			ExecuteOrderFromTable( order )
			
			local bossPos = entBossUnit:GetAbsOrigin()
			bossPos.z = 0
		
			local distArena = ( vecBossArenaPos - bossPos ):Length()
			
			if distArena <= 10 then
				self.bLocReached = true
				--entBossUnit:AddAbility(self.abilityPhase2)
				--[[local ability = entBossUnit:FindAbilityByName(self.abilityPhase2)
				--print(ability)
				local order =
				{
					UnitIndex = entBossUnit:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
					AbilityIndex = ability:entindex(),
				}]]
				strBossArenaName = "bossarena2"
				self:SetArena()

				local bossMaxHP = entBossUnit:GetMaxHealth()
				local orbHP = bossMaxHP * 0.1
				ExecuteOrderFromTable( order )

				self.entOrbLeft = CreateUnitByName( "treant_phase_2_orb", entBossUnit:GetOrigin() + Vector(-100, 200, 0), true, nil, nil, entBossUnit:GetTeamNumber() )
				self.entOrbLeft.CanEnterGoal = false
				SetPhasing(self.entOrbLeft, -1)
				self.entOrbLeft:SetMaxHealth(orbHP)
				self.entOrbLeft:SetHealth(orbHP)

				self.entOrbRight = CreateUnitByName( "treant_phase_2_orb", entBossUnit:GetOrigin() + Vector(100, 200, 0), true, nil, nil, entBossUnit:GetTeamNumber() )
				self.entOrbRight.CanEnterGoal = false
				SetPhasing(self.entOrbRight, -1)
				self.entOrbRight:SetMaxHealth(orbHP)
				self.entOrbRight:SetHealth(orbHP)
				
				entBossUnit:RemoveModifierByName("modifier_invulnerable")
				entBossUnit:SetHealth(entBossUnit:GetHealth() - orbHP * 2)
				entBossUnit:AddNewModifier( entBossUnit, nil, "modifier_invulnerable", {} )
				
				local shield_size = 150
				
				local entWp = Entities:FindByName(nil, "path_invader1_4")
				self.entOrbLeft:SetMustReachEachGoalEntity(false)
				
				
				self.entOrbLeft.particle = ParticleManager:CreateParticle( "particles/units/heroes/hero_abaddon/abaddon_aphotic_shield.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.entOrbLeft )
				ParticleManager:SetParticleControl(self.entOrbLeft.particle, 1, Vector(shield_size,0,shield_size))
				ParticleManager:SetParticleControl(self.entOrbLeft.particle, 2, Vector(shield_size,0,shield_size))
				ParticleManager:SetParticleControl(self.entOrbLeft.particle, 4, Vector(shield_size,0,shield_size))
				ParticleManager:SetParticleControl(self.entOrbLeft.particle, 5, Vector(shield_size,0,0))
				ParticleManager:SetParticleControlEnt(self.entOrbLeft.particle, 0, self.entOrbLeft, PATTACH_POINT_FOLLOW, "attach_hitloc", self.entOrbLeft:GetAbsOrigin(), true)
				
				
				entWp = Entities:FindByName(nil, "path_invader2_4")
				self.entOrbRight:SetMustReachEachGoalEntity(false)
				
				self.entOrbRight.particle = ParticleManager:CreateParticle( "particles/units/heroes/hero_abaddon/abaddon_aphotic_shield.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.entOrbRight )
				ParticleManager:SetParticleControl(self.entOrbRight.particle, 1, Vector(shield_size,0,shield_size))
				ParticleManager:SetParticleControl(self.entOrbRight.particle, 2, Vector(shield_size,0,shield_size))
				ParticleManager:SetParticleControl(self.entOrbRight.particle, 4, Vector(shield_size,0,shield_size))
				ParticleManager:SetParticleControl(self.entOrbRight.particle, 5, Vector(shield_size,0,0))
				ParticleManager:SetParticleControlEnt(self.entOrbRight.particle, 0, self.entOrbRight, PATTACH_POINT_FOLLOW, "attach_hitloc", self.entOrbRight:GetAbsOrigin(), true)
			end
		end
		
		if self.bLocReached then
			--print("reached position")
			
			local orbDistArenaLeft
			local orbDistArenaRight
			
			local orbHPPool = 0
			
			if not self.bOrbLeftReachedGoal or self.entOrbLeft:IsAlive() or not self.entOrbLeft:IsNull() then
				local orbPos
				local orbHP
				local orbHeight

				orbPos = self.entOrbLeft:GetAbsOrigin()
				orbPos.z = 0
				orbHeight = GetGroundHeight(orbPos, nil)

				--SafeSpawnCreature("treant_flower_creature", orbPos, 300, orbHeight, nil, nil, entBossUnit:GetTeamNumber())
				--SafeSpawnCreature("treant_mushroom_creature", orbPos, 300, orbHeight, nil, nil, entBossUnit:GetTeamNumber())
				--SafeSpawnCreature("npc_dota_furion_treant", orbPos, 300, orbHeight, nil, nil, entBossUnit:GetTeamNumber())
		
				orbDistArenaLeft = ( vecBossArenaPos - orbPos):Length()
				orbHP = self.entOrbLeft:GetHealth()
				orbHPPool = orbHPPool + orbHP
				
				if orbDistArenaLeft <= 900 then
					--print("setleftarenagoal")
					self.bOrbLeftReachedGoal = true
				end
				
			else
				orbDistArenaLeft = 0
			end
			
			if not self.bOrbRightReachedGoal or self.entOrbRight:IsAlive() or not self.entOrbRight:IsNull() then
				local orbPos
				local orbHP
				local orbHeight

				orbPos = self.entOrbRight:GetAbsOrigin()
				orbPos.z = 0
				orbHeight = GetGroundHeight(orbPos, nil)
						
				--SafeSpawnCreature("treant_flower_creature", orbPos, 300, orbHeight, nil, nil, entBossUnit:GetTeamNumber())
				--SafeSpawnCreature("treant_mushroom_creature", orbPos, 300, orbHeight, nil, nil, entBossUnit:GetTeamNumber())
				--SafeSpawnCreature("npc_dota_furion_treant", orbPos, 300, orbHeight, nil, nil, entBossUnit:GetTeamNumber())

				orbDistArenaRight = ( vecBossArenaPos - orbPos ):Length()
				
				orbHP = self.entOrbRight:GetHealth()
				orbHPPool = orbHPPool + orbHP
				
				if orbDistArenaRight <= 900 then
					--print("setrightarenagoal")
					self.bOrbRightReachedGoal = true
				end
			else
				orbDistArenaRight = 0
			end
			
			--print(orbDistArenaRight)
			--print(orbDistArenaLeft)
			
			--Phasenwechsel (von 2 nach 3)
			if self.bOrbLeftReachedGoal and self.bOrbRightReachedGoal then
				--print("orbs rached arena 2")
				self._nPhase = 3
				self._fPhaseTime = 0

				entBossUnit:SetHealth(entBossUnit:GetHealth() + orbHPPool)
				
				if self.entOrbLeft:IsAlive() or not self.entOrbLeft:IsNull() then
					UTIL_RemoveImmediate(self.entOrbLeft)
				end
				
				if self.entOrbRight:IsAlive() or not self.entOrbRight:IsNull() then
					UTIL_RemoveImmediate(self.entOrbRight)
				end
				
				local point = entBossArena:GetAbsOrigin()
				entBossUnit:SetAbsOrigin(point)
				FindClearSpaceForUnit(entBossUnit, point, false)
				entBossUnit:Stop()
				
				entBossUnit:RemoveAbility("treant_spawn_flowers")
				entBossUnit:RemoveAbility("treant_spawn_mushrooms")
				entBossUnit:RemoveAbility("treant_spawn_trees")
				entBossUnit:RemoveAbility("treant_raise_nature")

				entBossUnit:AddAbility("spawn_treants")

				entBossUnit:RemoveModifierByName("modifier_invulnerable")
				self.bFreezeBoss = false

				--Spawn Boss Ads
				entBossFlower = CreateUnitByName("treant_flower_creature_big", vecBossArenaPos + Vector(-300, -100, 0), false, nil, nil, entBossUnit:GetTeamNumber())
				entBossFlower.CanEnterGoal = false
				entBossFlower.MovementSystemActive = false
				behaviorSystemFlower = AICore:CreateBehaviorSystem( { BehaviorFlowerAttack, BehaviorFlowerRun, BehaviorFlowerIdle, BehaviorFlowerWard, BehaviorFlowerMoveToArena, BehaviorFlowerHeal } )

				entBossMushroom = CreateUnitByName("treant_mushroom_creature_big", vecBossArenaPos + Vector(300, -100, 0), false, nil, nil, entBossUnit:GetTeamNumber())
				entBossMushroom.CanEnterGoal = false
				entBossMushroom.MovementSystemActive = false
				behaviorSystemMushroom = AICore:CreateBehaviorSystem( { BehaviorMushroomIdle, BehaviorMushroomAttack, BehaviorMushroomMoveToArena, BehaviorMushroomTrap} ) --  
			end

		end

		self._fPhaseTime = self._fPhaseTime + 1

	elseif self._nPhase == 3 then
		--print("phase 3 think")

		local bossTimeFight = bossTimePhase3 * 0.6
		local bossTimeWalk =  bossTimePhase3 - bossTimeFight

		if self._fPhaseTime >= bossTimeFight then
			--Walk to ancient		
			local endPoint = Entities:FindByName(nil, "bossarena3")
			local vecEndPos = endPoint:GetAbsOrigin()
			vecEndPos .z = 0
			local distToEnd = (vecEndPos - vecBossArenaPos):Length()
			local distIncr = distToEnd / bossTimeWalk * 0.25
			
			if vecBossArenaPos.y + distIncr < vecEndPos.y then
				vecBossArenaPos = vecBossArenaPos + Vector(0, distIncr, 0)
			else
				vecBossArenaPos = vecEndPos
			end
		end
		
		self._fPhaseTime = self._fPhaseTime + 1
	end
end


function BossTreant:GetDistanceFromPos(vec)
	local bossPos = entBossUnit:GetAbsOrigin()
	bossPos.z = 0
		
	return ( vec - bossPos ):Length()

end

 
function BossTreant:AIThink()
	self._fBossHpPercent = entBossUnit:GetHealth() / entBossUnit:GetMaxHealth()
	
	self:PhaseThink()
	--print (string.format( "phase: %d", self._nPhase))
	
	if not self.bFreezeBoss then
		if entBossUnit ~= nil and not entBossUnit:IsNull() then
			behaviorSystemBoss:Think()
		end

		if entBossMushroom ~= nil and not entBossMushroom:IsNull() then
			behaviorSystemMushroom:Think()
		end

		if entBossFlower ~= nil and not entBossFlower:IsNull() then
			behaviorSystemFlower:Think()
		end
	end
	
end


--------------------------------------------------------------------------------------------------------





--------------------------------------------------------------------------------------------------------


BehaviorRootHero = {}

function BehaviorRootHero:Evaluate()
	self.ID = 9

	self.unit = entBossUnit
	self.ability = self.unit:FindAbilityByName("treant_root_hero")
	local target
	local desire = 0
	
	if self.ability and self.ability:IsFullyCastable() then
		local allEnemies = FindUnitsInRadius( self.unit:GetTeamNumber(), self.unit:GetOrigin(), nil, 700.0, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, 0, false )
		if #allEnemies > 0 then
			target = allEnemies[RandomInt( 1, #allEnemies )]
		end
	end

	if target then
		desire = 5
		self.order =
		{
			OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
			UnitIndex = self.unit:entindex(),
			TargetIndex = target:entindex(),
			AbilityIndex = self.ability:entindex()
		}
	end
	--print (string.format( "root Desire: %d", desire))
	return desire
end


function BehaviorRootHero:Begin()
	self.endTime = GameRules:GetGameTime() + 2
	self.unit.lastBehavior = self.ID
end

BehaviorRootHero.Continue = BehaviorRootHero.Begin --if we re-enter this ability, we might have a different target; might as well do a full reset

function BehaviorRootHero:Think(dt)
	if not self.ability:IsFullyCastable() and not self.ability:IsInAbilityPhase() then
		self.endTime = GameRules:GetGameTime()
	end
end


--------------------------------------------------------------------------------------------------------


BehaviorEarthsplitter = {}

function BehaviorEarthsplitter:Evaluate()
	self.ID = 8

	self.unit = entBossUnit
	self.ability = self.unit:FindAbilityByName("creature_earth_splitter")
	local target
	local desire = 0
	
	if self.ability and self.ability:IsFullyCastable() then
		local allEnemies = FindUnitsInRadius( self.unit:GetTeamNumber(), self.unit:GetOrigin(), nil, 800.0, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, 0, false )
		if #allEnemies > 0 then
			target = allEnemies[RandomInt( 1, #allEnemies )]
		end
	end

	if target then
		desire = 4
		self.order =
		{
			OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
			UnitIndex = self.unit:entindex(),
			Position = target:GetAbsOrigin(),
			AbilityIndex = self.ability:entindex()
		}
	end
	--print (string.format( "Earthsplitter Desire: %d", desire))
	return desire
end


function BehaviorEarthsplitter:Begin()
	self.endTime = GameRules:GetGameTime() + 1
	self.unit.lastBehavior = self.ID
end

BehaviorEarthsplitter.Continue = BehaviorEarthsplitter.Begin --if we re-enter this ability, we might have a different target; might as well do a full reset

function BehaviorEarthsplitter:Think(dt)
	if not self.ability:IsFullyCastable() and not self.ability:IsInAbilityPhase() then
		self.endTime = GameRules:GetGameTime()
	end
end
--------------------------------------------------------------------------------------------------------


BehaviorSpawnFlowers = {}

function BehaviorSpawnFlowers:Evaluate()
	self.ID = 7

	self.unit = entBossUnit
	self.ability = entBossUnit:FindAbilityByName("treant_spawn_flowers")
	local desire = 0
	
	if self.ability and self.ability:IsFullyCastable() then
		desire = 2
		self.order =
		{
			OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
			UnitIndex = self.unit :entindex(),
			AbilityIndex = self.ability:entindex()
		}
		--print (string.format( "flowers Desire: %d", desire))
	end
	return desire
end


function BehaviorSpawnFlowers:Begin()
	self.endTime = GameRules:GetGameTime() + 1
	self.unit.lastBehavior = self.ID
end

BehaviorSpawnFlowers.Continue = BehaviorSpawnFlowers.Begin --if we re-enter this ability, we might have a different target; might as well do a full reset

function BehaviorSpawnFlowers:Think(dt)
	if not self.ability:IsFullyCastable() and not self.ability:IsInAbilityPhase() then
		self.endTime = GameRules:GetGameTime()
	end
end


--------------------------------------------------------------------------------------------------------


BehaviorSpawnMushrooms = {}

function BehaviorSpawnMushrooms:Evaluate()
	self.ID = 6

	self.unit = entBossUnit
	self.ability = self.unit:FindAbilityByName("treant_spawn_mushrooms")
	local desire = 0
	
	if self.ability and self.ability:IsFullyCastable() then
	desire = 3
		self.order =
		{
			OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
			UnitIndex = self.unit:entindex(),
			AbilityIndex = self.ability:entindex()
		}
	
	--print (string.format( "mushroom Desire: %d", desire))
	end
	return desire
end


function BehaviorSpawnMushrooms:Begin()
	self.endTime = GameRules:GetGameTime() + 1
	self.unit.lastBehavior = self.ID
end

BehaviorSpawnMushrooms.Continue = BehaviorSpawnMushrooms.Begin --if we re-enter this ability, we might have a different target; might as well do a full reset

function BehaviorSpawnMushrooms:Think(dt)
	if not self.ability:IsFullyCastable() and not self.ability:IsInAbilityPhase() then
		self.endTime = GameRules:GetGameTime()
	end
end


--------------------------------------------------------------------------------------------------------


BehaviorSpawnTrees = {}

function BehaviorSpawnTrees:Evaluate()
	self.ID = 5

	self.unit = entBossUnit
	self.ability = entBossUnit:FindAbilityByName("treant_spawn_trees")
	local desire = 0
	
	if self.ability and self.ability:IsFullyCastable() then
	desire = 1
		self.order =
		{
			OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
			UnitIndex = self.unit:entindex(),
			AbilityIndex = self.ability:entindex()
		}
		--print (string.format( "tree Desire: %d", desire))
	end
	return desire
end


function BehaviorSpawnTrees:Begin()
	self.endTime = GameRules:GetGameTime() + 1
	self.unit.lastBehavior = self.ID
end

BehaviorSpawnTrees.Continue = BehaviorSpawnTrees.Begin --if we re-enter this ability, we might have a different target; might as well do a full reset

function BehaviorSpawnTrees:Think(dt)
	if not self.ability:IsFullyCastable() and not self.ability:IsInAbilityPhase() then
		self.endTime = GameRules:GetGameTime()
	end
end


--------------------------------------------------------------------------------------------------------


BehaviorRaiseNature = {}

function BehaviorRaiseNature:Evaluate()
	self.ID = 4

	self.unit = entBossUnit
	self.ability = entBossUnit:FindAbilityByName("treant_raise_nature")
	local desire = 0
	
	if self.ability and self.ability:IsFullyCastable() then
		local allTargets = FindUnitsInRadius( self.unit:GetTeamNumber(), self.unit:GetOrigin(), nil, 700.0, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, 0, 0, false )
		for n, u in pairs(allTargets) do
			local uName = u:GetUnitName()
			if not (uName == "treant_flower" or uName == "treant_mushroom" or uName == "ent_dota_tree" or uName == "dota_temp_tree") then
				table.remove(allTargets, n)
			end
		end
		desire = 1 * #allTargets

		self.order =
		{
			OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
			UnitIndex = self.unit:entindex(),
			AbilityIndex = self.ability:entindex()
		}
		--print (string.format( "raise Desire: %d", desire))
	end
	return desire
end


function BehaviorRaiseNature:Begin()
	self.endTime = GameRules:GetGameTime() + 2
	self.unit.lastBehavior = self.ID
end

BehaviorRaiseNature.Continue = BehaviorRaiseNature.Begin --if we re-enter this ability, we might have a different target; might as well do a full reset

function BehaviorRaiseNature:Think(dt)
	if not self.ability:IsFullyCastable() and not self.ability:IsInAbilityPhase() then
		self.endTime = GameRules:GetGameTime()
	end
end


--------------------------------------------------------------------------------------------------------


BehaviorMoveToArena = {}

function BehaviorMoveToArena:Evaluate()
	self.ID = 3

	self.unit = entBossUnit
	local desire = 0
	desire = UnitCalcArenaDesire(self.unit, vecBossArenaPos, fBossArenaRange, 5, 0.01)
	--print (string.format( "arenadesire: %d", fBossArenaDesire))
	if desire ~= nil and desire > 0 then
		self.order =
		{
			UnitIndex = self.unit:entindex(),
			OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
			Position = vecBossArenaPos,
		}
		--print (string.format( "move to arena Desire: %d", desire))
	end
	return desire
end


function BehaviorMoveToArena:Begin()
	self.endTime = GameRules:GetGameTime() + 0.9
	self.unit.lastBehavior = self.ID
end

BehaviorMoveToArena.Continue = BehaviorMoveToArena.Begin --if we re-enter this ability, we might have a different target; might as well do a full reset

function BehaviorMoveToArena:Think(dt)

end


--------------------------------------------------------------------------------------------------------


BehaviorAttack = {}

function BehaviorAttack:Evaluate()
	self.ID = 2

	self.unit = entBossUnit
	local desire = 0
	
	local target = AICore:WeakestEnemyHeroInRange( self.unit, 700 )
	
	if target ~= nil then
		desire = 0.5
		self.order =
		{
			UnitIndex = self.unit:entindex(),
			OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
			TargetIndex = target:entindex(),
		}
		--print (string.format( "attack desire: %d", desire))
	end
	return desire
end


function BehaviorAttack:Begin()
	self.endTime = GameRules:GetGameTime() + 0.9
	self.unit.lastBehavior = self.ID
end

BehaviorAttack.Continue = BehaviorAttack.Begin --if we re-enter this ability, we might have a different target; might as well do a full reset

function BehaviorAttack:Think(dt)

end


--------------------------------------------------------------------------------------------------------


BehaviorIdle = {}

function BehaviorIdle:Evaluate()
	self.ID = 1

	self.unit = entBossUnit
	local desire = 0.1
	
	local pos = nil
	local posUnit = self.unit:GetAbsOrigin()

	local distOld = -1

	if self.order ~= nil and self.order.Position ~= nil then
		distOld = GridNav:FindPathLength(posUnit, self.order.Position)
	end

	if self.unit.lastBehavior ~= self.ID or distOld == -1 or distOld < 250 or distOld > 2000 then

		repeat
		--print (string.format( "idle desire: %d", desire))
			pos = GetRandomPointInAoe(vecBossArenaPos, fBossArenaRange)
			local unitHeight = GetGroundHeight(posUnit, nil)
			local posHeight = GetGroundHeight(pos, nil)
			local dist = GridNav:FindPathLength(pos, posUnit)

		until unitHeight == posHeight or (dist ~= -1 and dist <= fBossArenaRange * 1.2)

		self.order =
		{
			UnitIndex = self.unit:entindex(),
			OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
			Position = pos,
		}
	end

	return desire
end


function BehaviorIdle:Begin()
	self.endTime = GameRules:GetGameTime() + 0.9
	self.unit.lastBehavior = self.ID
end

function BehaviorIdle:End()
end


BehaviorIdle.Continue = BehaviorIdle.Begin --if we re-enter this ability, we might have a different target; might as well do a full reset

function BehaviorIdle:Think(dt)
end


--------------------------------------------------------------------------------------------------------
---------------------------------------   MUSHROOM   ---------------------------------------------------
--------------------------------------------------------------------------------------------------------


BehaviorMushroomIdle = {}

function BehaviorMushroomIdle:Evaluate()
	self.ID = 1

	self.unit = entBossMushroom
	local desire = 0.1
	
	local pos = nil
	local posUnit = self.unit:GetAbsOrigin()

	local distOld = -1

	if self.order ~= nil and self.order.Position ~= nil then
		distOld = GridNav:FindPathLength(posUnit, self.order.Position)
	end

	if self.unit.lastBehavior ~= self.ID or distOld == -1 or distOld < 250 or distOld > 2000 then

		repeat
		--print (string.format( "idle desire: %d", desire))
			pos = GetRandomPointInAoe(vecBossArenaPos, fBossArenaRange)
			local unitHeight = GetGroundHeight(posUnit, nil)
			local posHeight = GetGroundHeight(pos, nil)
			local dist = GridNav:FindPathLength(pos, posUnit)

		until unitHeight == posHeight or (dist ~= -1 and dist <= fBossArenaRange * 1.2)

		self.order =
		{
			UnitIndex = self.unit:entindex(),
			OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
			Position = pos,
		}
	end

	return desire
end


function BehaviorMushroomIdle:Begin()
	self.endTime = GameRules:GetGameTime() + 0.9
	self.unit.lastBehavior = self.ID
end

function BehaviorMushroomIdle:End()
end


BehaviorMushroomIdle.Continue = BehaviorMushroomIdle.Begin --if we re-enter this ability, we might have a different target; might as well do a full reset

function BehaviorMushroomIdle:Think(dt)
end


--------------------------------------------------------------------------------------------------------


BehaviorMushroomMoveToArena = {}

function BehaviorMushroomMoveToArena:Evaluate()
	self.ID = 2

	self.unit = entBossMushroom
	local desire = 0
	arenaDesire = UnitCalcArenaDesire(self.unit, vecBossArenaPos, fBossArenaRange, 5, 0.01)
	--print (string.format( "arenadesire: %d", fBossArenaDesire))
	if arenaDesire ~= nil and arenaDesire > 0 then
		self.order =
		{
			UnitIndex = self.unit:entindex(),
			OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
			Position = vecBossArenaPos,
		}

		desire = arenaDesire
		--print (string.format( "move to arena Desire: %d", desire))
	end
	return desire
end


function BehaviorMushroomMoveToArena:Begin()
	self.endTime = GameRules:GetGameTime() + 0.9
	self.unit.lastBehavior = self.ID
end

BehaviorMushroomMoveToArena.Continue = BehaviorMushroomMoveToArena.Begin --if we re-enter this ability, we might have a different target; might as well do a full reset

function BehaviorMushroomMoveToArena:Think(dt)

end


--------------------------------------------------------------------------------------------------------


BehaviorMushroomAttack = {}

function BehaviorMushroomAttack:Evaluate()
	self.ID = 3

	self.unit = entBossMushroom
	local desire = 0
	
	local target = AICore:WeakestEnemyHeroInRange( self.unit, 700 )
	
	if target ~= nil then
		desire = 0.5
		self.order =
		{
			UnitIndex = self.unit:entindex(),
			OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
			TargetIndex = target:entindex(),
		}
		--print (string.format( "attack desire: %d", desire))
	end
	return desire
end


function BehaviorMushroomAttack:Begin()
	self.endTime = GameRules:GetGameTime() + 0.9
	self.unit.lastBehavior = self.ID
end

BehaviorMushroomAttack.Continue = BehaviorMushroomAttack.Begin --if we re-enter this ability, we might have a different target; might as well do a full reset

function BehaviorMushroomAttack:Think(dt)

end


--------------------------------------------------------------------------------------------------------


BehaviorMushroomTrap = {}

function BehaviorMushroomTrap:Evaluate()
	self.ID = 4

	self.unit = entBossMushroom
	self.ability = self.unit:FindAbilityByName("poison_trap")
	local position
	local desire = 0
	
	if self.ability and self.ability:IsFullyCastable() then
		local search = self.ability:GetSpecialValueFor("plant_radius") * 1.5
		local aoeMax = self.ability:GetSpecialValueFor("explosion_radius")
		local aoeMin = self.ability:GetSpecialValueFor("activation_radius")
		local team = DOTA_UNIT_TARGET_TEAM_ENEMY
		local who = DOTA_UNIT_TARGET_HERO
		position = UnitFindBestTargetPositionInAoe(self.unit, search, aoeMax, aoeMin, team, who)
	end

	if position ~= nil then
		desire = 4
		self.order =
		{
			OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
			UnitIndex = self.unit:entindex(),
			Position = position,
			AbilityIndex = self.ability:entindex()
		}
	end
	--print (string.format( "Earthsplitter Desire: %d", desire))
	return desire
end


function BehaviorMushroomTrap:Begin()
	self.endTime = GameRules:GetGameTime() + 1
	self.unit.lastBehavior = self.ID
end

BehaviorMushroomTrap.Continue = BehaviorMushroomTrap.Begin --if we re-enter this ability, we might have a different target; might as well do a full reset

function BehaviorMushroomTrap:Think(dt)
	if not self.ability:IsFullyCastable() and not self.ability:IsInAbilityPhase() then
		self.endTime = GameRules:GetGameTime()
	end
end


--------------------------------------------------------------------------------------------------------
------------------------------------------   FLOWER   --------------------------------------------------
--------------------------------------------------------------------------------------------------------


BehaviorFlowerIdle = {}

function BehaviorFlowerIdle:Evaluate()
	self.ID = 1

	self.unit = entBossFlower
	local desire = 0.1
	
	local pos = nil
	local posUnit = self.unit:GetAbsOrigin()

	local distOld = -1

	if self.order ~= nil and self.order.Position ~= nil then
		distOld = GridNav:FindPathLength(posUnit, self.order.Position)
	end

	if self.unit.lastBehavior ~= self.ID or distOld == -1 or distOld < 250 or distOld > 2000 then

		repeat
		--print (string.format( "idle desire: %d", desire))
			pos = GetRandomPointInAoe(vecBossArenaPos, fBossArenaRange)
			local unitHeight = GetGroundHeight(posUnit, nil)
			local posHeight = GetGroundHeight(pos, nil)
			local dist = GridNav:FindPathLength(pos, posUnit)

		until unitHeight == posHeight or (dist ~= -1 and dist <= fBossArenaRange * 1.2)

		self.order =
		{
			UnitIndex = self.unit:entindex(),
			OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
			Position = pos,
		}
	end

	return desire
end


function BehaviorFlowerIdle:Begin()
	self.endTime = GameRules:GetGameTime() + 0.9
	self.unit.lastBehavior = self.ID
end

function BehaviorFlowerIdle:End()
end


BehaviorFlowerIdle.Continue = BehaviorFlowerIdle.Begin --if we re-enter this ability, we might have a different target; might as well do a full reset

function BehaviorFlowerIdle:Think(dt)
end


--------------------------------------------------------------------------------------------------------


BehaviorFlowerMoveToArena = {}

function BehaviorFlowerMoveToArena:Evaluate()
	self.ID = 2

	self.unit = entBossFlower
	local desire = 0
	arenaDesire = UnitCalcArenaDesire(self.unit, vecBossArenaPos, fBossArenaRange, 4, 0.01)
	--print (string.format( "arenadesire: %d", fBossArenaDesire))
	if arenaDesire ~= nil and arenaDesire > 0 then
		self.order =
		{
			UnitIndex = self.unit:entindex(),
			OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
			Position = vecBossArenaPos,
		}

		desire = arenaDesire
		--print (string.format( "move to arena Desire: %d", desire))
	end
	return desire
end


function BehaviorFlowerMoveToArena:Begin()
	self.endTime = GameRules:GetGameTime() + 0.9
	self.unit.lastBehavior = self.ID
end

BehaviorFlowerMoveToArena.Continue = BehaviorFlowerMoveToArena.Begin --if we re-enter this ability, we might have a different target; might as well do a full reset

function BehaviorFlowerMoveToArena:Think(dt)

end


--------------------------------------------------------------------------------------------------------


BehaviorFlowerAttack = {}

function BehaviorFlowerAttack:Evaluate()
	self.ID = 3

	self.unit = entBossFlower
	local desire = 0
	
	local target = AICore:WeakestEnemyHeroInRange( self.unit, 700 )
	
	if target ~= nil then
		desire = DESIRE_ATTACK_FLOWER
		self.order =
		{
			UnitIndex = self.unit:entindex(),
			OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
			TargetIndex = target:entindex(),
		}
		--print (string.format( "attack desire: %d", desire))
	end
	return desire
end


function BehaviorFlowerAttack:Begin()
	self.endTime = GameRules:GetGameTime() + 0.9
	self.unit.lastBehavior = self.ID
end

BehaviorFlowerAttack.Continue = BehaviorFlowerAttack.Begin --if we re-enter this ability, we might have a different target; might as well do a full reset

function BehaviorFlowerAttack:Think(dt)

end


--------------------------------------------------------------------------------------------------------


BehaviorFlowerRun = {}

function BehaviorFlowerRun:Evaluate()
	self.ID = 4

	self.unit = entBossFlower
	local desire = 0

	if self.nextIdle == nil or GameRules:GetGameTime() >= self.nextIdle then

		local aoe = 800
		local nU = 100000
		local position = nil
		local danger = 100000

		local vUnits = FindUnitsInRadius( self.unit:GetTeamNumber(), self.unit:GetOrigin(), nil, aoe, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, 0, false )

		if #vUnits >= 2 then
			for _, unit in pairs(vUnits) do
				desire = desire + (1 - (self.unit:GetAbsOrigin() - unit:GetAbsOrigin()):Length() / aoe)
			end
			print(string.format("desire: %f", desire))

			if desire > DESIRE_ATTACK_FLOWER then

				local steps = 12

				for i = 0, steps do
					local deg = i * 360 / steps
					local pos = GetPointWithPolarOffset(self.unit:GetAbsOrigin(), deg, aoe )
					local dist = GridNav:FindPathLength(self.unit:GetAbsOrigin(), pos)
					local posZ = GetGroundHeight(pos, nil)
					local unitZ = GetGroundHeight(self.unit:GetAbsOrigin(), nil)
					local distToArena = (vecBossArenaPos - pos):Length()
					print(string.format("ground unit: %d, ground pos: %d, distance: %d", unitZ, posZ, dist))

					if dist ~= -1 and (posZ == unitZ or dist <= aoe * 2) and distToArena <= fBossArenaRange then
						local vU = FindUnitsInRadius( self.unit:GetTeamNumber(), pos, nil, aoe , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, 0, false )

						if #vU < nU then
							local dang = 0

							for _, u in pairs(vU) do
								dang = dang + 1 - (pos - u:GetAbsOrigin()):Length() / aoe
							end
							print(string.format("danger %f", dang))

							if dang < danger then
								nU = #vU
								danger = dang
								position = pos
								print("setting retreat position")
							end
						end
					end
				end
			end

			if position ~= nil then

				DebugDrawLine(self.unit:GetAbsOrigin(), position, 0, 255, 0, true, 1)
				DebugDrawText(position, string.format("desire: %d", desire), true, 1)
				self.order =
				{
					UnitIndex = self.unit:entindex(),
					OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
					Position = position,
				}
				--print (string.format( "attack desire: %d", desire))
			end
		end
	end

	return desire
end


function BehaviorFlowerRun:Begin()
	self.endTime = GameRules:GetGameTime() + 2.9
	self.nextIdle = GameRules:GetGameTime() + 7
	self.unit.lastBehavior = self.ID
end

BehaviorFlowerRun.Continue = BehaviorFlowerRun.Begin --if we re-enter this ability, we might have a different target; might as well do a full reset

function BehaviorFlowerRun:Think(dt)

end


--------------------------------------------------------------------------------------------------------


BehaviorFlowerWard = {}

function BehaviorFlowerWard:Evaluate()
	self.ID = 5

	self.unit = entBossFlower
	self.ability = self.unit:FindAbilityByName("spawn_flower")
	local position
	local desire = 0
	
	if self.ability and self.ability:IsFullyCastable() then
		local search = 1200
		local aoeMax = 700
		local aoeMin = 0
		local team = DOTA_UNIT_TARGET_TEAM_FRIENDLY
		local who = DOTA_UNIT_TARGET_CREEP
		position = UnitFindBestTargetPositionInAoe(self.unit, search, aoeMax, aoeMin, team, who)
	end

	if position ~= nil then
		desire = 3
		self.order =
		{
			OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
			UnitIndex = self.unit:entindex(),
			Position = position,
			AbilityIndex = self.ability:entindex()
		}
	end
	--print (string.format( "Earthsplitter Desire: %d", desire))
	return desire
end


function BehaviorFlowerWard:Begin()
	self.endTime = GameRules:GetGameTime() + 1
	self.unit.lastBehavior = self.ID
end

BehaviorFlowerWard.Continue = BehaviorFlowerWard.Begin --if we re-enter this ability, we might have a different target; might as well do a full reset

function BehaviorFlowerWard:Think(dt)
	if not self.ability:IsFullyCastable() and not self.ability:IsInAbilityPhase() then
		self.endTime = GameRules:GetGameTime()
	end
end


--------------------------------------------------------------------------------------------------------


BehaviorFlowerHeal = {}

function BehaviorFlowerHeal:Evaluate()
	self.ID = 6

	self.unit = entBossFlower
	self.ability = self.unit:FindAbilityByName("creature_aoe_heal")
	local desire = 0
	local target = nil
	local targetsMissingHealth = -1
	local search = 1200
	local aoe = 200
	local heal = 200
	
	if self.ability and self.ability:IsFullyCastable() then
		local allAllys = FindUnitsInRadius( self.unit:GetTeamNumber(), self.unit:GetOrigin(), nil, search, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, 0, 0, false )
		for _, ally in pairs(allAllys) do
			local units = FindUnitsInRadius( self.unit:GetTeamNumber(), ally:GetOrigin(), nil, aoe, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, 0, 0, false )
			local missingHealth = 0
			for _, unit in pairs(units) do
				missingHealth = missingHealth + math.min(unit:GetMaxHealth() - unit:GetHealth(), heal)
			end

			--DebugDrawText(ally:GetAbsOrigin(), string.format("health missing: %d", missingHealth), true, 4)

			if missingHealth > targetsMissingHealth then
				target = ally
				targetsMissingHealth = missingHealth
			end
		end
	end

	if target ~= nil then
		desire = 5
		self.order =
		{
			OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
			UnitIndex = self.unit:entindex(),
			TargetIndex = target:entindex(),
			AbilityIndex = self.ability:entindex()
		}
	end
	--print (string.format( "root Desire: %d", desire))
	return desire
end


function BehaviorFlowerHeal:Begin()
	self.endTime = GameRules:GetGameTime() + 2
	self.unit.lastBehavior = self.ID
end

BehaviorFlowerHeal.Continue = BehaviorFlowerHeal.Begin --if we re-enter this ability, we might have a different target; might as well do a full reset

function BehaviorFlowerHeal:Think(dt)
	if not self.ability:IsFullyCastable() and not self.ability:IsInAbilityPhase() then
		self.endTime = GameRules:GetGameTime()
	end
end