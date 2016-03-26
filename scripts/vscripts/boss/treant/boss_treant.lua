require( "ai/ai_core" )
require("misc/utility_functions")

if BossTreant == nil then
	BossTreant = class({})
end

behaviorSystemBoss = {} -- create the global so we can assign to it
behaviorSystemFlower = {}
behaviorSystemMushroom ={}

DESIRE_ATTACK_FLOWER = 1.4

INTRO_TIME = 5

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

ORB_ADD_SPAWN_INTERVALL = 4
ORB_TETHER_COOLDOWN = 5
ORB_TETHER_RANGE = 700

PHASE_TIME_ =
{
	[1] = 60,
	[2] = 60,
	[3] = 60,
}

PHASE_ARENA_STR_ =
{
	[1] = "bossarena1",
	[2] = "bossarena2",
	[3] = "bossarena2",
}

PHASE_ARENA_ENT_ = {}

function BossTreant:Init(handler, gameRound)
	self._TICKRATE = 0.25
	self._fPhaseTime = 0
	self._bossHandler = handler
	self._gameRound = gameRound
	self._fPrepTime = self._gameRound._flPrepTime
	self._fPrepTimeEnd = nil
	self._strBossUnit = "boss_treant" 
	self._strSpawner = "spawnerBoss"
	self._strRoundTitle = "Boss Treant"
	self._nPhase = 0
	self.bFreezeBoss = false
	self.bLocReached = false
	--self.abilityPhase2 = "boss_treant_phase_2"
	self.bOrbLeftReachedGoal = false
	self.bOrbRightReachedGoal = false

	self._nTeam = self._gameRound._gameMode._nTeam
	self._nTeamEnemy = self._gameRound._gameMode._nTeamEnemy
	
	self:FindArenas()
	self:SetPhase(1)

	------print("bosshandlerinit")
	------print(fBossArenaDesire)
end


function BossTreant:FindArenas()
	for n, str in pairs(PHASE_ARENA_STR_) do
		local arena = Entities:FindByName(nil, str)
		------print(strBossArenaName)
		if arena ~= nil then
			PHASE_ARENA_ENT_[n] = arena
		end
	end
end


function BossTreant:Begin()
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


function BossTreant:Prepare()
	self._fPrepTimeEnd = GameRules:GetGameTime() + self._fPrepTime

	----print("prepare")
	PrecacheUnitByNameAsync( self._strBossUnit, function( sg ) self._sg = sg end )

	local data =
	{
		destination = Entities:FindByName(nil, self._strSpawner):GetAbsOrigin(),
		wisp_damage = 0,
		center_damage_max = 20,
		center_damage_min = 2,
		spawn_number = 2,
		function_finished = function() return GameRules:GetGameTime() >= self._fPrepTimeEnd - INTRO_TIME end,
		function_execute = function() self:Spawn() end,
	}
	self:WispPhase(data)
end


function BossTreant:WispPhase(data)
	local posLines = {
		{
			Vector(_BoundingBox[2][1][1], _BoundingBox[2][1][2], 512),
			Vector(_BoundingBox[2][1][1], _BoundingBox[2][2][2], 512),
		},

		{
			Vector(_BoundingBox[2][2][1], _BoundingBox[2][1][2], 512),
			Vector(_BoundingBox[2][2][1], _BoundingBox[2][2][2], 512),
		},
	}

	--[[posLines[1][1] = Vector(_BoundingBox[2][1].x, _BoundingBox[2][1].y, 512)
	posLines[1][2] = Vector(_BoundingBox[2][1].x, _BoundingBox[2][2].y, 512)
	posLines[2][1] = Vector(_BoundingBox[2][2].x, _BoundingBox[2][1].y, 512)
	posLines[2][2] = Vector(_BoundingBox[2][2].x, _BoundingBox[2][2].y, 512)]]

	local vecLines = {
		posLines[1][2] - posLines[1][1],
		posLines[2][2] - posLines[2][1],
	}
	
	--vecLines[1] = posLines[1][2] - posLines[1][1]
	--vecLines[2] = posLines[2][2] - posLines[2][1]

	self._vWisps = {}

	local nWispsEntered = 0

	local wispCenter = nil
	local fxGround = nil

	CENTER_SIZE_MAX = data.center_size_max or 500
	CENTER_SIZE_MIN = data.center_size_min or 10

	local centerWisp_size = CENTER_SIZE_MIN

	MIN_HEIGHT_SPAWN = 300
	MAX_HEIGHT_SPAWN = 600

	MAX_DISTORTION = 75

	MAX_MOVE_SPEED = 800

	WISP_COLLISION_RADIUS = data.wisp_collision or 200
	WISP_DAMAGE = data.wisp_damage or 0

	WISP_CENTER_DAMAGE_MIN = data.center_damage_min or 0
	WISP_CENTER_DAMAGE_MAX = data.center_damage_max or 0

	POINT_DESTINATION = data.destination

	fnCheckFinished = data.function_finished or function() return false end
	fnExecute = data.function_execute or function() end

	wispCenter = CreateUnitByName("dummy_unit", POINT_DESTINATION, true, nil, nil, self._nTeamEnemy)
	wispCenter:SetAbsOrigin(wispCenter:GetAbsOrigin() + Vector(0, 0, 200))

	wispCenter.particle = ParticleManager:CreateParticle( "particles/wisp_force_field.vpcf", PATTACH_ABSORIGIN_FOLLOW, wispCenter )
	--ParticleManager:SetParticleControlEnt(wispCenter.particle , 0, wispCenter, PATTACH_POINT_FOLLOW, "attach_hitloc", wispCenter:GetAbsOrigin(), true)

	--wispCenter.particle2 = ParticleManager:CreateParticle( "particles/units/heroes/hero_treant/treant_eyesintheforest_d.vpcf", PATTACH_ABSORIGIN_FOLLOW, wispCenter )
	--ParticleManager:SetParticleControl(wispCenter.particle2 , 1, Vector(1,500,1))

	ApplyModifier(wispCenter, wispCenter, "modifier_fx", {Duration = -1}, true)
	ApplyModifier(wispCenter, wispCenter, "modifier_wisp_center_ambient", {Duration = -1}, true)
	ApplyModifier(wispCenter, wispCenter, "modifier_wisp_center_ambient2", {Duration = -1}, true)

	wispCenter.particle3 = ParticleManager:CreateParticle( "particles/units/heroes/hero_furion/furion_teleport_end.vpcf", PATTACH_ABSORIGIN_FOLLOW, wispCenter )
	--ApplyModifier(wispCenter, wispCenter, "modifier_wisp_center_ambient3", {Duration = -1}, true)

	--fxGround = CreateUnitByName("dummy_unit", POINT_DESTINATION, true, nil, nil, self._nTeam)
	--fxGround.particle = 
	--ApplyModifier(fxGround, fxGround, "modifier_fx_ground", {Duration = -1}, true)
	--ParticleManager:SetParticleControlEnt(fxGround.particleGround , 0, fxGround, PATTACH_POINT_FOLLOW, "attach_hitloc", wispCenter:GetAbsOrigin(), true)

	wispCenter.MovementSystem.State = MOVEMENT_SYSTEM_STATE_NONE
	POINT_DESTINATION = wispCenter:GetOrigin()

	MAX_TETHERS = data.max_tethers or 5

	local bEnd = false

	local nWispsSpawned = 0

	local nTethers = 0
	--for n = 1, MAX_TETHERS do
	--	local tether = ParticleManager:CreateParticle( "particles/units/heroes/hero_wisp/wisp_tether.vpcf", PATTACH_ABSORIGIN_FOLLOW, wispCenter )
	--	ParticleManager:SetParticleControl(tether , 1, POINT_DESTINATION + Vector(0, 0, 150) )
	--	table.insert(vTethers, tether)
	--end

	tetherCount = 1

	SPAWN_NUMBER = 2

	Timers:CreateTimer(function()

		if fnCheckFinished() then
			bEnd = true
		end

		for n = 1, SPAWN_NUMBER do
			local rand = RandomInt(1, 2)
			local spawnPos = posLines[rand][1] + vecLines[rand] * RandomFloat(0, 1)
			local wisp = CreateUnitByName("dummy_unit", spawnPos, true, nil, nil, self._nTeamEnemy)
			wisp.MaxDist = (POINT_DESTINATION - spawnPos):Length()
			wisp.MoveSpeedBase = wisp:GetBaseMoveSpeed() * RandomFloat(0.95, 1.05)

			ApplyModifier(wisp, wisp, "modifier_wisp", {Duration = -1}, true)
			ApplyModifier(wisp, wisp, "modifier_fx", {Duration = -1}, true)
			wisp.MovementSystem.State = MOVEMENT_SYSTEM_STATE_NONE
			wisp:SetOrigin(wisp:GetOrigin() + Vector(0, 0, RandomInt(MIN_HEIGHT_SPAWN, MAX_HEIGHT_SPAWN)))
			--wisp.Particle = ParticleManager:CreateParticle("particles/test_particle/treant_orb.vpcf", PATTACH_ABSORIGIN_FOLLOW, wisp)
			--ParticleManager:SetParticleControlEnt(wisp.Particle , 0, wisp, PATTACH_POINT_FOLLOW, "attach_hitloc", wisp:GetAbsOrigin(), true)
			--ParticleManager:SetParticleControl(wisp.Particle, 0, wisp:GetAbsOrigin())

			--local shield_size = 200

			--[[wisp.particle = ParticleManager:CreateParticle( "particles/units/heroes/hero_abaddon/abaddon_aphotic_shield.vpcf", PATTACH_ABSORIGIN_FOLLOW, wisp )
			ParticleManager:SetParticleControl(wisp.particle , 1, Vector(shield_size,0,shield_size))
			ParticleManager:SetParticleControl(wisp.particle , 2, Vector(shield_size,0,shield_size))
			ParticleManager:SetParticleControl(wisp.particle , 4, Vector(shield_size,0,shield_size))
			ParticleManager:SetParticleControl(wisp.particle , 5, Vector(shield_size,0,0))
			ParticleManager:SetParticleControlEnt(wisp.particle , 0, wisp, PATTACH_POINT_FOLLOW, "attach_hitloc", wisp:GetAbsOrigin(), true)]]

			nWispsSpawned = nWispsSpawned + 1
			----print(nWispsSpawned)

			table.insert(self._vWisps, wisp)
		end

		----print(#self._vWisps)
		self._vWisps = ListFilterWithFn(self._vWisps, function(e)
			return UnitAlive(e) and not e.entered
		end
		)

		for _, wisp in pairs(self._vWisps) do
			local pos = wisp:GetOrigin()
			local vecDest = POINT_DESTINATION - pos

			wisp.colliders = FindUnitsInRadius( wisp:GetTeamNumber(), wisp:GetOrigin(), nil, WISP_COLLISION_RADIUS, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, 0, false )

			wisp:SetBaseMoveSpeed(wisp.MoveSpeedBase * 0.8 + wisp.MoveSpeedBase * 0.4 * (1 - vecDest:Length2D() / wisp.MaxDist))

			if vecDest:Length2D() <= math.max(RandomFloat(centerWisp_size/2, centerWisp_size), 100) or bEnd == true or #wisp.colliders > 0 then

				--ParticleManager:ReleaseParticleIndex( ParticleManager:CreateParticle( "particles/units/heroes/hero_wisp/wisp_guardian_explosion_small.vpcf", PATTACH_ABSORIGIN_FOLLOW, wisp))

				--ParticleManager:SetParticleControl(vTethers[tetherCount], 1, wispCenter:GetOrigin() + Vector(0, 0, 140))
				--ParticleManager:SetParticleControl(vTethers[tetherCount], 0, wisp:GetOrigin() + Vector(0, 0, 140))

				if #wisp.colliders > 0 then
					for _, unit in pairs(wisp.colliders) do
						local dmgTable =
						{
							victim = unit,
							attacker = wisp,
							damage = WISP_DAMAGE,
							damage_type = DAMAGE_TYPE_PURE,
						}
						ApplyDamage(dmgTable)
					end

					ApplyModifier(wisp, wisp, "modifier_wisp_explosion2", {Duration = 1}, true)
				else
					local expl2 = RandomInt(0, 100)

					if expl2 <= 70 then
						ApplyModifier(wisp, wisp, "modifier_wisp_explosion", {Duration = 1}, true)
					else
						ApplyModifier(wisp, wisp, "modifier_wisp_explosion2", {Duration = 1}, true)
					end

					if wisp.tether == nil or wisp.tether == -1 then
						wisp.tether = ParticleManager:CreateParticle( "particles/units/heroes/hero_wisp/wisp_tether.vpcf", PATTACH_ABSORIGIN_FOLLOW, wisp)
						ParticleManager:SetParticleControl(wisp.tether , 1, wispCenter:GetOrigin() + Vector(0, 0, 140) )
						ParticleManager:ReleaseParticleIndex(wisp.tether)

						wisp:SetBaseMoveSpeed(wisp.MoveSpeedBase * 1.7)
					else
						nTethers = nTethers - 1
					end

					nWispsEntered = nWispsEntered + 1

					centerWisp_size = math.min(centerWisp_size + (500/centerWisp_size), CENTER_SIZE_MAX)

					ParticleManager:SetParticleControl(wispCenter.particle , 1, Vector(centerWisp_size,0,0))
				end

				wisp:RemoveModifierByName("modifier_wisp")

				Timers:CreateTimer(0.4, function()
					UTIL_Remove(wisp)

					return nil
				end
				)

				wisp.entered = true

				--ParticleManager:SetParticleControl(wispCenter.particle2 , 1, Vector(1,math.max(500, centerWisp_size * 3),1))
			else
				if vecDest:Length2D() <= math.max(centerWisp_size, 100) * 2 + 500 and centerWisp_size >= CENTER_SIZE_MAX * 3/7 then
					if wisp.tether == nil and nTethers < MAX_TETHERS then
						local rand = RandomInt(0, 100)
						if rand <= 25 then
							wisp.tether = ParticleManager:CreateParticle( "particles/units/heroes/hero_wisp/wisp_tether.vpcf", PATTACH_ABSORIGIN_FOLLOW, wisp)
							wisp:SetBaseMoveSpeed(wisp.MoveSpeedBase * 2.7)
							ParticleManager:SetParticleControl(wisp.tether , 1, wispCenter:GetOrigin() + Vector(0, 0, 140) )
							ParticleManager:ReleaseParticleIndex(wisp.tether)

							nTethers = nTethers + 1
						else
							wisp.tether = -1
						end
					end
				end

				local scale = vecDest:Length() / wisp.MaxDist
				local distort = MAX_DISTORTION * scale
				if wisp.tether and wisp.tether ~= -1 then
					distort = distort / 4
				end
				local distortVec = RotatePosition(Vector(0,0,0), QAngle(0,RandomFloat(-distort, distort),0), vecDest:Normalized())
				local newPos = pos + (distortVec * MAX_MOVE_SPEED * self._TICKRATE)
				--wisp:SetOrigin(newPos)
				local order = 
				{
					UnitIndex = wisp:entindex(),
					OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
					Position = newPos,
				}

				ExecuteOrderFromTable(order)
				--wisp:SetOrigin(pos + Vector(0,0,100))
			end
		end

		local centerCollision = math.max(centerWisp_size, 100)
		wispCenter.colliders = FindUnitsInRadius( wispCenter:GetTeamNumber(), wispCenter:GetOrigin(), nil, centerCollision, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, 0, false )
		DebugDrawCircle(wispCenter:GetOrigin(), Vector(255, 0, 0), 0, centerCollision, true, self._TICKRATE)

		if #wispCenter.colliders > 0 then
			for _, unit in pairs(wispCenter.colliders) do
				local dist = (unit:GetAbsOrigin() - wispCenter:GetAbsOrigin()):Length2D()
				local dmgScale = (1 - dist / centerCollision)
				local dmg = math.max(WISP_CENTER_DAMAGE_MIN, WISP_CENTER_DAMAGE_MAX * dmgScale) * self._TICKRATE

				local dmgTable =
				{
					victim = unit,
					attacker = wispCenter,
					damage = dmg,
					damage_type = DAMAGE_TYPE_PURE,
				}
				ApplyDamage(dmgTable)
				
				--ApplyModifier(wispCenter, unit, "modifier_wisp_center_burn", {Duration = -1}, true)
			end
		end

		DebugDrawText(POINT_DESTINATION, string.format("Wisps: %f", nWispsEntered), true, self._TICKRATE)

		if bEnd then
			--wispCenter.particle3 = ParticleManager:CreateParticle( "particles/units/heroes/hero_furion/furion_teleport_end.vpcf", PATTACH_ABSORIGIN_FOLLOW, wispCenter )
			--ParticleManager:SetParticleControl(wispCenter.particle3 , 1, Vector(1,500,1))
			ApplyModifier(wispCenter, wispCenter, "modifier_wisp_center_explosion", {Duration = -1}, true)
			--UTIL_Remove(wispCenter)
			ParticleManager:DestroyParticle(wispCenter.particle, true)
			wispCenter:RemoveModifierByName("modifier_wisp_center_ambient")
			wispCenter:RemoveModifierByName("modifier_wisp_center_ambient2")

			Timers:CreateTimer(4, function()
				UTIL_Remove(wispCenter)

				return nil
			end
			)

			fnExecute()

			return nil
		end

		return self._TICKRATE
	end
	)
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
	----print("spawn")
	local entSpawner = Entities:FindByName( nil, self._strSpawner)
	local vecSpawnLocation = nil
	
	if not entSpawner then
		----print( string.format( "Failed to find spawner named %s" , self._strSpawner) )
	end
	
	vecSpawnLocation = entSpawner:GetAbsOrigin()
	entBossUnit = CreateUnitByName( self._strBossUnit, vecSpawnLocation, true, nil, nil, DOTA_TEAM_BADGUYS )
	entBossUnit:SetAngles(0, 270, 0)
	ApplyModifier(entBossUnit, entBossUnit, "modifier_vision", {Duration = -1}, true)
	entBossUnit.MovementSystem.State = MOVEMENT_SYSTEM_STATE_NONE
	entBossUnit.CanEnterGoal = false
	self._bossOriginalHealth = entBossUnit:GetMaxHealth()
	self:ApplyDifficultyBuff(entBossUnit)
	behaviorSystemBoss = AICore:CreateBehaviorSystem( { BehaviorIdle, BehaviorEatTree, BehaviorEarthsplitter, BehaviorRootHero, BehaviorSpawnFlowers, BehaviorSpawnMushrooms, BehaviorSpawnTrees, BehaviorRaiseNature, BehaviorMoveToArena, BehaviorAttack } )

	CustomGameEventManager:Send_ServerToTeam(self._nTeam, "show_boss_health", { bossName = "Treant", bossMaxHealth = entBossUnit:GetMaxHealth() })

	--entBossUnit:DestroyAllSpeechBubbles()
	--entBossUnit:AddSpeechBubble(DOTA_SPEECH_USER_TEAM, "!", 4, 0, 0)
end


function BossTreant:UpdateBossDifficulty()
	self:ApplyDifficultyBuff(entBossUnit)
end


function BossTreant:ApplyDifficultyBuff(u)
	local nDifficultyStacks = self._gameRound._gameMode._entAncient:GetMana()
	
	ApplyModifier(u, u, "modifier_boss_difficulty_passive", {duration=-1}, false)
	
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
	------print (string.format( "dist arena: %d", distArena))
	local distDiff = distArena - range
	------print (string.format( "dist diff: %d", distDiff))
	------print(distDiff)
	
	if distDiff > 0 then
		return desire + incr * distDiff
		------print("distdiff > 0")
	else
		return 0.0
	end
end


function BossTreant:Think()

	if entBossUnit:IsAlive() or not entBossUnit:IsNull() then

		self:AIThink()
		
		if testcount == 30 and entBossUnit:GetHealth() >= entBossUnit:GetMaxHealth()/2 then
			entBossUnit:SetHealth(entBossUnit:GetMaxHealth()/2)
			GameRules:SetRuneSpawnTime(testcount)
			
		end
	
		if self._entKillCountSubquest then
			self._entKillCountSubquest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, entBossUnit:GetHealth())
		end
	 
		testcount = testcount + 1

		CustomGameEventManager:Send_ServerToTeam(self._nTeam, "update_boss_health", { current_health = entBossUnit:GetHealth() })
		
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


function BossTreant:FreezeUnit(unit, bool)
	unit.Freeze = bool

	if bool then
		DisarmUnit(unit, -1)
	else
		DisarmUnit(unit, 0)
	end
end

PHASE_MAX = 3


function BossTreant:PhaseThink()
		------print (string.format( "phasethink: %d", self._nPhase))

	if self._nPhase == 1 then
		if self._fBossHpPercent <= 0.66 then
			self:FreezeUnit(entBossUnit, true)
			SetPhasing(entBossUnit, -1)
			entBossUnit:AddNewModifier( entBossUnit, nil, "modifier_invulnerable", {} )
			self.bLocReached = false

			local order =
			{
				UnitIndex = entBossUnit:entindex(),
				OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
				Position = vecBossArenaPos,
			}
			ExecuteOrderFromTable( order )
			entBossUnit.MoveOrder = vecBossArenaPos

			self:SetPhase(self._nPhase + 1)
		end
		
		------print("phase1think")

	elseif self._nPhase == 2 then

		------print("Phase2")
		if self.bLocReached == false then
		------print("moving in position")
			
			local bossPos = entBossUnit:GetAbsOrigin()
		
			local distArena = ( entBossUnit.MoveOrder - bossPos ):Length2D()
			DebugDrawText(bossPos, string.format("dist: %f", distArena), true, self._TICKRATE)
			if distArena <= 10 then
				self.bLocReached = true

				local bossMaxHP = entBossUnit:GetMaxHealth()
				local orbHP = bossMaxHP * 0.1
				local orb_size = 240

				self._vOrbs = {}

				spawnPosOrbs =
				{
					[1] = Vector(-100, 200, 0),
					[2] = Vector(100, 200, 0),
				}

				for n = 1, 2 do
					local orb = CreateUnitByName( "treant_phase_2_orb", entBossUnit:GetOrigin() + spawnPosOrbs[n], true, nil, nil, entBossUnit:GetTeamNumber() )
					ApplyModifier(orb, orb, "modifier_flying", {Duration = -1}, true)
					SetPhasing(orb, -1)
					orb.CanEnterGoal = false
					orb.ReachedGoal = false
					--SetPhasing(orb, -1)
					orb:SetMaxHealth(orbHP)
					orb:SetHealth(orbHP)
					--self.entOrbLeft.MovementSystem.State = MOVEMENT_SYSTEM_STATE_MOVE

					orb.particle = ParticleManager:CreateParticle( "particles/wisp_force_field.vpcf", PATTACH_ABSORIGIN_FOLLOW, orb )
					ParticleManager:SetParticleControl(orb.particle, 1, Vector(orb_size,0,0))
					ApplyModifier(orb, orb, "modifier_vision", {Duration = -1}, true)
					ApplyModifier(orb, orb, "modifier_wisp_center_ambient", {Duration = -1}, true)
					ApplyModifier(orb, orb, "modifier_wisp_center_ambient2", {Duration = -1}, true)
					orb.MovementSystem.UnitType = UNIT_TYPE_MOVE

					table.insert(self._vOrbs, orb)

					orb.tether_cooldown = GameRules:GetGameTime() + ORB_TETHER_COOLDOWN

					-- Spawner Thinker

					Timers:CreateTimer(function()
						if orb.ReachedGoal then
							if orb.tether then
								ParticleManager:DestroyParticle(orb.tether, true)
								orb.tether_target.MovementSystem.UnitType = UNIT_TYPE_NORMAL
							end

							return nil
						end

						if not orb.nextSpawn or GameRules:GetGameTime() >= orb.nextSpawn then
							UnitSpawnAdd(orb, "treant_flower_creature", 0, 300, 300, nil, nil)
							UnitSpawnAdd(orb, "treant_mushroom_creature", 0, 300, 300, nil, nil)
							UnitSpawnAdd(orb, "npc_dota_creature_treant", 0, 300, 300, nil, nil)

							orb.nextSpawn = GameRules:GetGameTime() + ORB_ADD_SPAWN_INTERVALL
						end

						if orb.tether and not UnitAlive(orb.tether_target)then
							ParticleManager:DestroyParticle(orb.tether, true)
							ParticleManager:ReleaseParticleIndex(orb.tether)
							orb.tether_target = nil
							orb.tether = nil

							orb.tether_cooldown = GameRules:GetGameTime() + ORB_TETHER_COOLDOWN
						end

						if not orb.tether and GameRules:GetGameTime() >= orb.tether_cooldown then
							orb.tether_target = UnitSpawnAdd(orb, "npc_dota_creature_treant_big", 0, 500, 500, nil, nil)
							orb.tether_target.MovementSystem.UnitType = UNIT_TYPE_GUARD_UNIT
							orb.tether_target.MovementSystem.GuardUnit = orb
							orb.tether = ParticleManager:CreateParticle( "particles/units/heroes/hero_wisp/wisp_tether.vpcf", PATTACH_ABSORIGIN_FOLLOW, orb)
							ParticleManager:SetParticleControlEnt( orb.tether, 1, orb.tether_target, PATTACH_ABSORIGIN_FOLLOW, nil, orb.tether_target:GetOrigin(), false )
						end

						return self._TICKRATE
					end
					)
				end

				entBossUnit:RemoveModifierByName("modifier_invulnerable")
				entBossUnit:SetHealth(entBossUnit:GetHealth() - orbHP * 2)
				entBossUnit:AddNewModifier( entBossUnit, nil, "modifier_invulnerable", {} )
			end
		else
			------print("reached position")

			for _, orb in pairs(self._vOrbs) do

				if UnitAlive(orb) and not orb.ReachedGoal then
					local orbPos = orb:GetAbsOrigin()

					distArena = ( vecBossArenaPos - orbPos):Length2D()
					
					if distArena <= 900 then
						------print("setleftarenagoal")
						orb.ReachedGoal = true
						orb.MovementSystem.State = MOVEMENT_SYSTEM_STATE_NONE
					end
				end
			end

			------print(orbDistArenaRight)
			------print(orbDistArenaLeft)
			
			--Phasenwechsel (von 2 nach 3)
			local orbsReachedGoal = true

			for _, orb in pairs(self._vOrbs) do
				if UnitAlive(orb) and not orb.ReachedGoal then
					orbsReachedGoal = false
				end
			end

			if orbsReachedGoal then
				self:SetPhase(self._nPhase + 1)

				local fWispPhaseEndTime = GameRules:GetGameTime() + 20
				wispPhaseEnded = false

				local data =
				{
					destination = Entities:FindByName(nil, "bossarena2"):GetAbsOrigin(),
					wisp_damage = 0,
					center_damage_max = 20,
					center_damage_min = 2,
					spawn_number = 2,
					function_finished = function() return GameRules:GetGameTime() > fWispPhaseEndTime end,
					function_execute = function() wispPhaseEnded = true
					print("wispPhaseEdnded")end,
				}
				self:WispPhase(data) 
			end

		end

	elseif self._nPhase == 3 then
		------print("phase 3 think")

		if wispPhaseEnded then
			--entBossUnit:SetHealth(entBossUnit:GetHealth() + orbHPPool)
			wispPhaseEnded = false

			for _, orb in pairs(self._vOrbs) do
				if UnitAlive(orb) then
					UTIL_Remove(orb)
				end
			end

			self._vOrbs = {}

			entBossUnit:SetAbsOrigin(vecBossArenaPos)
			FindClearSpaceForUnit(entBossUnit, vecBossArenaPos, false)
			entBossUnit:Stop()

			entBossUnit:RemoveAbility("treant_spawn_flowers")
			entBossUnit:RemoveAbility("treant_spawn_mushrooms")
			entBossUnit:RemoveAbility("treant_spawn_trees")
			entBossUnit:RemoveAbility("treant_raise_nature")

			entBossUnit:AddAbility("spawn_treants")

			entBossUnit:RemoveModifierByName("modifier_invulnerable")
			self:FreezeUnit(entBossUnit, false)

			--Spawn Boss Ads
			entBossFlower = CreateUnitByName("treant_flower_creature_big", vecBossArenaPos + Vector(-300, -100, 0), false, nil, nil, entBossUnit:GetTeamNumber())
			entBossFlower.CanEnterGoal = false
			entBossFlower.MovementSystem.State = MOVEMENT_SYSTEM_STATE_NONE
			behaviorSystemFlower = AICore:CreateBehaviorSystem( { BehaviorFlowerAttack, BehaviorFlowerRun, BehaviorFlowerIdle, BehaviorFlowerWard, BehaviorFlowerMoveToArena, BehaviorFlowerHeal } )

			entBossMushroom = CreateUnitByName("treant_mushroom_creature_big", vecBossArenaPos + Vector(300, -100, 0), false, nil, nil, entBossUnit:GetTeamNumber())
			entBossMushroom.CanEnterGoal = false
			entBossMushroom.MovementSystem.State = MOVEMENT_SYSTEM_STATE_NONE
			behaviorSystemMushroom = AICore:CreateBehaviorSystem( { BehaviorMushroomIdle, BehaviorMushroomAttack, BehaviorMushroomMoveToArena, BehaviorMushroomTrap} ) -- 
		end

		local bossTimeFight = bossTimePhase3 * 0.6
		local bossTimeWalk =  bossTimePhase3 - bossTimeFight

		if GameRules:GetGameTime() >= self._fTimePhaseStart + PHASE_TIME_[self._nPhase] then
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
		
	end
end

function BossTreant:SetPhase(n)
	if n <= PHASE_MAX and n > 0 then
		self._nPhase = n
		self._fTimePhaseStart = GameRules:GetGameTime()
		vecBossArenaPos = PHASE_ARENA_ENT_[self._nPhase]:GetOrigin()
		vecBossArenaPos.z = 0
	end
end

 
function BossTreant:AIThink()
	self._fBossHpPercent = entBossUnit:GetHealth() / entBossUnit:GetMaxHealth()
	
	self:PhaseThink()
	------print (string.format( "phase: %d", self._nPhase))
	
	if UnitAlive(entBossUnit) and not entBossUnit.Freeze then
		behaviorSystemBoss:Think()
	end

	if UnitAlive(entBossMushroom) and not entBossMushroom.Freeze then
		behaviorSystemMushroom:Think()
	end

	if UnitAlive(entBossFlower) and not entBossFlower.Freeze then
		behaviorSystemFlower:Think()
	end
	
end


--------------------------------------------------------------------------------------------------------



--TREANT BEAHAVIOR SYSTEM

--------------------------------------------------------------------------------------------------------
BehaviorEatTree = {}

function BehaviorEatTree:Evaluate()
	self.ID = 9

	self.unit = entBossUnit
	self.ability = self.unit:FindAbilityByName("treant_eat_tree")
	local target
	local desire = 0

	
	if self.ability and self.ability:IsFullyCastable() and self.unit:GetHealth() / self.unit:GetMaxHealth() <= 0.9 then
		local trees = GridNav:GetAllTreesAroundPoint(self.unit:GetOrigin(), 500, true)

		trees = ListFilterWithFn ( trees, 
										function(e) 
											return TreeIsAlive(e) and IsSameHeigth(e, self.unit)					
										end 
										)
		if #trees > 0 then
			target = trees[1]

			for _, tree in pairs(trees) do
				local distTree =(tree:GetAbsOrigin() - self.unit:GetOrigin()):Length()
				local distTarget = (target:GetAbsOrigin() - self.unit:GetOrigin()):Length()

				if distTree < distTarget then
					target = tree
				end
			end
		end
	end

	if target then
		desire = 100
		DebugDrawText(target:GetAbsOrigin(), "Tree Target", true, 1)

		local vecTotree = self.unit:GetAbsOrigin() - target:GetAbsOrigin()
		local posMove = target:GetAbsOrigin() -- + (vecTotree / vecTotree:Length() * 100) -- Offset

		self.order =
		{
			OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
			UnitIndex = self.unit:entindex(),
			Position = posMove,
			delay = 1.5,
			target = target, 
		}
	end

	----print (string.format( "eatTree Desire: %d", desire))
	return desire
end


function BehaviorEatTree:Begin()
	self.endTime = GameRules:GetGameTime() + 10
	self.unit.lastBehavior = self.ID
	self.orderTimer = 0
	DebugDrawText(self.unit:GetAbsOrigin(), string.format("Begin"), true, 2)

	ApplyModifier(self.unit, self.order.target, modifier_tree_highlight_fx, {Duration = -1}, true )
end

BehaviorEatTree.Continue = BehaviorEatTree.Begin --if we re-enter this ability, we might have a different target; might as well do a full reset

function BehaviorEatTree:Think(dt)
	if not self.ability:IsFullyCastable() and not self.ability:IsInAbilityPhase() or not TreeIsAlive(self.order.target) then
		----print(TreeIsAlive(self.order.target))
		self.endTime = GameRules:GetGameTime()
	else
		local distTarget = (self.order.Position - self.unit:GetAbsOrigin()):Length()

		DebugDrawText(self.unit:GetAbsOrigin(), string.format("DistTarget: %f", distTarget), true, dt)

		if distTarget <= 200 then
			self.unit:Stop()
			self.orderTimer = self.orderTimer + dt

			--DebugDrawText(self.order.target:GetAbsOrigin(), string.format("Timer: %f", self.orderTimer), true, dt)

			if self.orderTimer >= self.order.delay then
				UnitCutDownTree(self.unit, self.order.target) 

				local order =
				{
					OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
					UnitIndex = self.unit:entindex(),
					AbilityIndex = self.ability:entindex()
				}

				ExecuteOrderFromTable(order)
			end
		end
	end
end


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
	------print (string.format( "root Desire: %d", desire))
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
	------print (string.format( "Earthsplitter Desire: %d", desire))
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
			UnitIndex = self.unit:entindex(),
			AbilityIndex = self.ability:entindex()
		}
		------print (string.format( "flowers Desire: %d", desire))
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
	
	------print (string.format( "mushroom Desire: %d", desire))
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
		------print (string.format( "tree Desire: %d", desire))
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
		local allUnits = FindUnitsInRadius( self.unit:GetTeamNumber(), self.unit:GetAbsOrigin(), nil, 700.0, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, 0, 0, false )
		for n, u in pairs(allUnits) do
			local uName = u:GetUnitName()
			if not (uName == "treant_flower" or uName == "treant_mushroom") then
				table.remove(allUnits, n)
			end
		end

		local allTrees = GridNav:GetAllTreesAroundPoint(self.unit:GetAbsOrigin(), 700, true)

		numberTargets = #allUnits + #allTrees
		DebugDrawText(self.unit:GetAbsOrigin(), string.format("Targets: %f", numberTargets), true, 3)

		if numberTargets > 10 then
			desire =  7
		end

		self.order =
		{
			OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
			UnitIndex = self.unit:entindex(),
			AbilityIndex = self.ability:entindex()
		}
		------print (string.format( "raise Desire: %d", desire))
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
	------print (string.format( "arenadesire: %d", fBossArenaDesire))
	if desire ~= nil and desire > 0 then
		self.order =
		{
			UnitIndex = self.unit:entindex(),
			OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
			Position = vecBossArenaPos,
		}
		------print (string.format( "move to arena Desire: %d", desire))
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
		------print (string.format( "attack desire: %d", desire))
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
		------print (string.format( "idle desire: %d", desire))
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
		------print (string.format( "idle desire: %d", desire))
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
	------print (string.format( "arenadesire: %d", fBossArenaDesire))
	if arenaDesire ~= nil and arenaDesire > 0 then
		self.order =
		{
			UnitIndex = self.unit:entindex(),
			OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
			Position = vecBossArenaPos,
		}

		desire = arenaDesire
		------print (string.format( "move to arena Desire: %d", desire))
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
		------print (string.format( "attack desire: %d", desire))
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
	local position = nil
	local desire = 0
	
	if self.ability and self.ability:IsFullyCastable() then
		local search = self.ability:GetSpecialValueFor("plant_radius") * 1.5
		local aoeMax = self.ability:GetSpecialValueFor("explosion_radius")
		local aoeMin = self.ability:GetSpecialValueFor("activation_radius")
		local team = DOTA_UNIT_TARGET_TEAM_ENEMY
		local who = DOTA_UNIT_TARGET_HERO
		local vUnits = FindUnitsInRadius( self.unit:GetTeamNumber(), self.unit:GetOrigin(), nil, search, team, who, 0, 0, false )
		if #vUnits > 1 then
			position = UnitFindBestTargetPositionInAoe(self.unit, search, aoeMax, aoeMin, team, who)
		end
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
	------print (string.format( "Earthsplitter Desire: %d", desire))
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
		------print (string.format( "idle desire: %d", desire))
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
	------print (string.format( "arenadesire: %d", fBossArenaDesire))
	if arenaDesire ~= nil and arenaDesire > 0 then
		self.order =
		{
			UnitIndex = self.unit:entindex(),
			OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
			Position = vecBossArenaPos,
		}

		desire = arenaDesire
		------print (string.format( "move to arena Desire: %d", desire))
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
		------print (string.format( "attack desire: %d", desire))
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
			----print(string.format("desire: %f", desire))

			if desire > DESIRE_ATTACK_FLOWER then

				local steps = 12

				for i = 0, steps do
					local deg = i * 360 / steps
					local pos = GetPointWithPolarOffset(self.unit:GetAbsOrigin(), deg, aoe )
					local dist = GridNav:FindPathLength(self.unit:GetAbsOrigin(), pos)
					local posZ = GetGroundHeight(pos, nil)
					local unitZ = GetGroundHeight(self.unit:GetAbsOrigin(), nil)
					local distToArena = (vecBossArenaPos - pos):Length()
					----print(string.format("ground unit: %d, ground pos: %d, distance: %d", unitZ, posZ, dist))

					if dist ~= -1 and (posZ == unitZ or dist <= aoe * 2) and distToArena <= fBossArenaRange then
						local vU = FindUnitsInRadius( self.unit:GetTeamNumber(), pos, nil, aoe , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, 0, false )

						if #vU < nU then
							local dang = 0

							for _, u in pairs(vU) do
								dang = dang + 1 - (pos - u:GetAbsOrigin()):Length() / aoe
							end
							----print(string.format("danger %f", dang))

							if dang < danger then
								nU = #vU
								danger = dang
								position = pos
								----print("setting retreat position")
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
				------print (string.format( "attack desire: %d", desire))
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
	------print (string.format( "Earthsplitter Desire: %d", desire))
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
	------print (string.format( "root Desire: %d", desire))
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