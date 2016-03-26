require( "bottle/moonwell_system" )
require( "bottle/bottle_shop")
require( "bottle/glyph_system")

if CBottleSystem == nil then
	CBottleSystem = class({})
end

BOTTLE_HEALTH = 1
BOTTLE_MANA = 2

MODIFIER_ = {
	"modifier_bottle_health_passive",
	"modifier_bottle_mana_passive",
}

MODIFIER_FX_ = {
	"modifier_bottle_health_fx",
	"modifier_bottle_mana_fx",
}

MODIFIER_CHARGES = "modifier_bottle_charges"

MODIFIER_APPLIER_ = {
	"item_bottle_health_applier",
	"item_bottle_mana_applier",
}

ABILITY_ = {
	"bottle_health",
	"bottle_mana",
}

BOTTLE_HEALTH_DURATION_BASE = 4.0
BOTTLE_MANA_DURATION_BASE = 4.0
GLYPH_EXPIRE_TIME = 90.0

BOTTLE_CHARGES_MAX_START = 100

BOTTLE_COST_START = 20


function CBottleSystem:Init( gameMode, team )
	self._gameMode = gameMode
	self._nTeam = team
	self._vHeroes = {}
	self._vMoonwells = {}
	self._vBottleShops = {}
	self:InitMoonwells()

	for i = 0, DOTA_MAX_PLAYERS-1 do
		local ent = Entities:FindByName(nil, "BottleShopBottle" .. i)
		if ent ~= nil then
			ent:AddNewModifier( ent, nil, "modifier_invulnerable", {} )
		end
	end

	self._vGlyphs = {}

	--Timers:CreateTimer(function()
		--CBottleSystem:Update()

		----return self:GetTickrate()
	--end
	--)

	Timers:CreateTimer(function()
		return self:GlyphThink()
	end
	)

	Timers:CreateTimer(function()
		return self:Think()
	end
	)
end

function CBottleSystem:Think()
	for _, hero in pairs(self._vHeroes) do
		if hero.BottleSystem then
			local reg = hero.BottleSystem.Reg * self:GetTickrate()
			hero.BottleSystem.RegExtern = hero.BottleSystem.Charges - hero.BottleSystem.LastCharges
			self:BottleAddCharges(hero, reg)
		end
	end

	return self:GetTickrate()
end

--[[for _, glyph in pairs(self._vGlyphs) do
		local heroes = {}

		if not glyph._PickedUp then
			local glyphOrig = glyph._entItem3D:GetAbsOrigin()
			heroes = FindUnitsInRadius( self._nTeam, glyphOrig, nil, 200, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, 0, 0, false )
			DebugDrawCircle(glyphOrig, Vector(0, 255, 0), 0, 200, true, 0.25)

			heroes = ListFilterWithFn(heroes,
											function(e)
												return not (e:IsStunned() or not e:IsAlive())
											end
											)

			--if #heroes > 0 then
			--	self:HeroPickUpGlyph(heroes[1], glyph)
			--end

			for _, hero in pairs(heroes) do
				--DebugDrawText(hero.MoveOrder, "worked", true, 7.0)
				if glyph._fSpawnTime <= hero.MoveOrderTime and not hero.MoveOrderPickedUpGlyph then
					dist = (glyphOrig - hero.MoveOrder):Length()
					print(dist)
					if dist <= 70 then
						self:HeroPickUpGlyph(hero, glyph)
					end
				end
			end
		end
	end

	return self:GetTickrate()]]

function CBottleSystem:GlyphThink()
	if #self._vGlyphs > 0 then
		for _, hero in pairs(self._vHeroes) do
			if not hero:IsStunned() and hero:IsAlive() then
				DebugDrawCircle(hero:GetAbsOrigin(), Vector(0, 255, 0), 0, 200, true, 0.25)
				for _, glyph in pairs(self._vGlyphs) do
					if not glyph._PickedUp then
						if glyph._fSpawnTime <= hero.MoveOrderTime and not hero.MoveOrderPickedUpGlyph then
							local glyphOrig = glyph._entItem3D:GetAbsOrigin()
							distHero = (glyphOrig - hero:GetAbsOrigin()):Length()
							distOrder = (glyphOrig - hero.MoveOrder):Length()
							--print(dist)
							if distOrder <= 70 and distHero <= 200 then
								self:HeroPickUpGlyph(hero, glyph)
							end
						end
					end
				end
			end
		end

		--Expire time check

		self._vGlyphs = ListFilterWithFn(self._vGlyphs,
		function(e)
			local expiryTime = GameRules:GetGameTime() - GLYPH_EXPIRE_TIME
			local item = e._entItem3D

			--print(item:GetCreationTime())
			--print(expiryTime)

			if not e._PickedUp and item:GetCreationTime() < expiryTime then

				local nFXIndex = ParticleManager:CreateParticle( "particles/items2_fx/veil_of_discord.vpcf", PATTACH_CUSTOMORIGIN, item )
				ParticleManager:SetParticleControl( nFXIndex, 0, item:GetOrigin() )
				ParticleManager:SetParticleControl( nFXIndex, 1, Vector( 35, 35, 25 ) )
				ParticleManager:ReleaseParticleIndex( nFXIndex )

				local inventoryItem = item:GetContainedItem()
				if inventoryItem then
					UTIL_Remove( inventoryItem )
				end

				if item then
					UTIL_Remove( item )
				end

				return false
			end

			return true
		end
		)
		--print (#self._vGlyphs)
	end

	return self:GetTickrate()
end

function CBottleSystem:InitBottleShop(pID)
	----print(string.format("player owner: %d", id))

	if self._vBottleShops[pID] ~= nil then
		return
	end

	if Entities:FindByName(nil, "BottleShopBottle" .. pID) ~= nil then
		local bottleShopObj = CBottleShop:CreateBottleShop("BottleShopPedestal" .. pID, "BottleShopBottle" .. pID, pID, self)
		self._vBottleShops[pID] = bottleShopObj
	end
end

function CBottleSystem:InitMoonwells()
	local i = 1
	while Entities:FindByName(nil, "moonwellradiant" .. i) ~= nil do
		local moonwellObj = CMoonwell:CreateMoonwell("moonwellradiant" .. i, "moonwellradiantwater" .. i, self)
		moonwellObj:SetMana(0, false)
		table.insert(self._vMoonwells, moonwellObj)
		i = i + 1
	end
end


function CBottleSystem:GetTickrate()
	return 0.20
end


function CBottleSystem:OnItemPickedUp( event )
	local item = EntIndexToHScript(event.ItemEntityIndex)
	local hero = EntIndexToHScript(event.HeroEntityIndex)
	local player = hero:GetPlayerOwner()
	--print("try pickup")

	if item ~= nil then
		--print("item exists")
	end

	local glyph = self:GetGlyph(item)

	if glyph ~= nil then
		--print("picking up")
		UTIL_Remove(item)
		self:HeroPickUpGlyph(hero, glyph)
	end
end


function CBottleSystem:GetGlyph(item)
	for _, glyph in pairs(self._vGlyphs) do
		if item:entindex() == glyph._entGlyphIndex then
			return glyph
		end
	end

	return nil
end


function CBottleSystem:SpawnGlyphOnPosition( pos, nType, lvl )
	if not IsValidGlyph(nType) then
		return false
	end

	--print("spawning glyph")

	local glyphObj = CGlyphObj:CreateGlyph(nType, lvl, self)

	if glyphObj == nil then
		return
	end

	table.insert(self._vGlyphs, glyphObj)

	--print("glyph created")

	glyphObj:SpawnOnPosition(pos)

	return true
end


function CBottleSystem:HeroPickUpGlyph( hero, glyph )
	local glyphBottle = glyph:GetBottleType()

	if hero.BottleSystem[glyphBottle].Glyph == nil then
		--hero:RemoveAbility(ABILITY_[glyphBottle])
	else
		hero.BottleSystem[glyphBottle].Glyph:Activate()
		--hero:RemoveAbility(GLYPH_ABILITY_[hero.BottleSystem[glyphBottle].Glyph._nType])
		hero.BottleSystem[glyphBottle].Glyph = nil
	end

	hero.BottleSystem[glyphBottle].Glyph = glyph
	--hero.BottleSystem[glyphBottle].Ability = hero:AddAbility(GLYPH_ABILITY_[glyph._nType])
	--hero.BottleSystem[glyphBottle].Ability:SetLevel(glyph._nLevel)
	glyph:PickUp(hero)

	if glyph._entItem3D ~= nil and not glyph._entItem3D:IsNull() then
		UTIL_Remove(glyph._entItem3D)
	end

	glyph._PickedUp = true
	hero.MoveOrderPickedUpGlyph = true

	self:HeroUpdateBottle(hero, glyphBottle)

end


function CBottleSystem:OnHeroSpawned( hero )
	if hero.BottleSystem.BottleShop == nil then
		local pID = hero:GetPlayerOwnerID()
		--print(string.format("playerId: %d", pID))
		self._vBottleShops[pID]:AddHero(hero)
	end

	ApplyModifier(hero, hero, MODIFIER_CHARGES, {duration=-1})
	self:BottleAddCharges(hero, hero.BottleSystem.ChargesMax)
end


function CBottleSystem:OnHeroInGame( hero )
	if hero:GetTeamNumber() ~= self._nTeam then
		return
	end

	hero.BottleSystem = {
		--Health Bottle
		[BOTTLE_HEALTH] = {
			LastCharges = 0,
			ChargesCost = BOTTLE_COST_START,
			Lvl = 1,
			Ability = hero:FindAbilityByName(ABILITY_[1]), --hero:AddAbility(ABILITY_[1]),
			Cooldown = 1,

			Think = {
				Expire = 0,
				Healing = 0,
				HealInstant = 0,
				Hps = 0,
				Tickrate = self:GetTickrate(),
				Timer = nil,
				TimeUsed = GameRules:GetGameTime(),
			},

			UpdateTimer = nil,
			Glyph = nil,
		},
		--Mana Bottle
		[BOTTLE_MANA] = {
			LastCharges = 0,
			ChargesCost = BOTTLE_COST_START,
			Lvl = 1,
			Ability = hero:FindAbilityByName(ABILITY_[2]), --hero:AddAbility(ABILITY_[2]),
			Cooldown = 1,

			Think = {
				Duration = 0,
				Healing = 0,
				HealInstant = 0,
				Hps = 0,
				Expire = 0,
				Tickrate = self:GetTickrate(),
				Timer = nil,
				TimeUsed = GameRules:GetGameTime(),
			},

			UpdateTimer = nil,
			Glyph = nil,
		},

		ChargesMax = BOTTLE_CHARGES_MAX_START,
		Charges = 0,

		Reg = 0.5,
		RegExtern = 0,

		BottleShop = nil,
	}

	hero.BottleSystem[BOTTLE_HEALTH].Ability:SetLevel(1)
	hero.BottleSystem[BOTTLE_MANA].Ability:SetLevel(1)

	local pID = hero:GetPlayerOwnerID()
	self:InitBottleShop(pID)
	--hero.BottleSystem[1].Ability:SetLevel(4)
	--hero.BottleSystem[2].Ability:SetLevel(4)
	--print("hero ingame")

	table.insert(self._vHeroes, hero)


end

function CBottleSystem:HeroUpdateBottle(hero, bottle)
	--if bottle ~= 1 then
	--	return
	--end

	local data = hero.BottleSystem.BottleShop:GetUpgradeLevels(bottle)

	hero.BottleSystem.ChargesMax = BOTTLE_CHARGES_MAX_START + (data[6]-1) * 10
	hero.BottleSystem[bottle].ChargesCost = BOTTLE_COST_START - (data[5]-1) * 2

	if hero:HasAbility(ABILITY_[bottle]) then
		local cdOld = hero.BottleSystem[bottle].Ability:GetCooldownTimeRemaining()
		local cdNew = 0
		--print(cdOld)

		if hero.BottleSystem[bottle].Glyph == nil then
			if hero.BottleSystem.Charges < hero.BottleSystem[bottle].ChargesCost then
				cdNew = (hero.BottleSystem[bottle].ChargesCost - hero.BottleSystem.Charges) / hero.BottleSystem.Reg --hero.BottleSystem[bottle].RegExtern
			elseif GameRules:GetGameTime() < hero.BottleSystem[bottle].Think.TimeUsed + hero.BottleSystem[bottle].Cooldown then
				cdNew = hero.BottleSystem[bottle].Think.TimeUsed + hero.BottleSystem[bottle].Cooldown - GameRules:GetGameTime()
			end

			if cdOld > 0 and cdNew == 0 then
				hero.BottleSystem[bottle].Ability:EndCooldown()
			elseif math.abs(cdOld - cdNew) > self:GetTickrate() then
				--print(cdOld)
				--print(cdNew)
				--print("starting new cooldown")
				hero.BottleSystem[bottle].Ability:EndCooldown()
				hero.BottleSystem[bottle].Ability:StartCooldown(cdNew)
				--print(hero.BottleSystem[bottle].Ability:GetCooldownTimeRemaining())
			end
		elseif cdOld > 0 then
			hero.BottleSystem[bottle].Ability:EndCooldown()
			--print("ending cooldown 2")
		end

		local charges = math.floor(hero.BottleSystem.Charges / hero.BottleSystem[bottle].ChargesCost)

		hero.BottleSystem[bottle].Ability.level = charges

		--print(string.format("abilitylevel: %f", hero.BottleSystem[bottle].Ability.level))
	end
end


function CBottleSystem:HeroUseBottle( hero, target, bottle )
	local bReturn = false

	if hero.BottleSystem[bottle].Glyph ~= nil then
		--print("glyph")
		hero.BottleSystem[bottle].Glyph:Activate()
		--hero:RemoveAbility(GLYPH_ABILITY_[hero.BottleSystem[bottle].Glyph._nType])
		hero.BottleSystem[bottle].Glyph = nil
		--hero.BottleSystem[bottle].Ability = hero:AddAbility(ABILITY_[bottle])
		--hero.BottleSystem[bottle].Ability:SetLevel(1)

		bReturn = true
	else
		--print("no glyph")
		if hero.BottleSystem.Charges >= hero.BottleSystem[bottle].ChargesCost then
			self:BottleAddCharges(hero, -hero.BottleSystem[bottle].ChargesCost)
			self:BottleActivate(hero, target, bottle)
			hero.BottleSystem[bottle].Think.TimeUsed = GameRules:GetGameTime()
			bReturn = true
		end
	end

	self:HeroUpdateBottle(hero, bottle)

	return bReturn
end

function CBottleSystem:HeroGetUpgradeLevelsCombined( hero, bottle )
	local data = hero.BottleSystem.BottleShop:GetUpgradeLevels(bottle)

	local sum = 0

	for i = 1, #data do
		sum = sum + data[i]
	end

	return sum
end


function CBottleSystem:BottleCalcThink( hero, bottle )
	local data = hero.BottleSystem.BottleShop:GetUpgradeLevels(bottle)

	local healTime = 0
	local healPct = 0
	local healPctInstant = 0
	local hps = 0

	if bottle == BOTTLE_HEALTH then

		healTime = 			BOTTLE_HEALTH_DURATION_BASE + 1 * ( data[3] - 1 )
		healPct = 			( 0.3 + ( data[1] - 1 ) * 0.1 ) * healTime / BOTTLE_HEALTH_DURATION_BASE
		healPctInstant = 	(0.2 + ( data[2] - 1 ) * 0.05 ) * healPct
		hps =				1 + ( data[4] - 1 ) * 0.1

	elseif bottle == BOTTLE_MANA then

		healTime = 			BOTTLE_MANA_DURATION_BASE + 1 * ( data[3] - 1 )
		healPct = 			( 0.3 + ( data[1] - 1 ) * 0.1 ) * healTime / BOTTLE_MANA_DURATION_BASE
		healPctInstant = 	(0.2 + ( data[2] - 1 ) * 0.05) * healPct
		hps =				1 + ( data[4] - 1 ) * 0.1
	end

	hero.BottleSystem[bottle].Think.HealInstant = healPctInstant
	hero.BottleSystem[bottle].Think.Healing = healPct * hps
	hero.BottleSystem[bottle].Think.Duration = healTime
	hero.BottleSystem[bottle].Think.Hps = hero.BottleSystem[bottle].Think.Healing / healTime
	hero.BottleSystem[bottle].Think.Expire = GameRules:GetGameTime() + hero.BottleSystem[bottle].Think.Duration
end


function CBottleSystem:BottleActivate(hero, target, bottle)

	self:BottleCalcThink(hero, bottle)
	local heal = hero.BottleSystem[bottle].Think.HealInstant

	if target ~= hero and target.BottleSystem.BottleShop ~= nil then
		self:BottleCalcThink(target, bottle)
		local tHeal = target.BottleSystem[bottle].Think.HealInstant
		if heal > tHeal then
			local pctDiff = tHeal / heal
			heal = tHeal + (heal - tHeal) * pctDiff
		end
	end

	self:HeroBottleHeal(target, bottle, heal)
	--DebugDrawText(target:GetAbsOrigin() + Vector(0, 0, 450), string.format("inst: %f", heal), true, 2)

	target:RemoveModifierByName(MODIFIER_[bottle])
	target:RemoveModifierByName(MODIFIER_FX_[bottle])

	ApplyModifier(hero, target, MODIFIER_[bottle], {duration=hero.BottleSystem[bottle].Think.Duration})
	ApplyModifier(hero, target, MODIFIER_FX_[bottle], {duration=hero.BottleSystem[bottle].Think.Duration})

	local timerID = DoUniqueString('bottle')
	target.BottleSystem[bottle].Think.Timer = timerID
	Timers:CreateTimer(function()
		return CBottleSystem:BottleThink(hero, target, bottle, timerID)
	end
	)
end

function CBottleSystem:BottleThink( hero, target, bottle, timer )
	if timer ~= target.BottleSystem[bottle].Think.Timer then
		return nil
	end

	if hero.BottleSystem[bottle].Think.Expire >= GameRules:GetGameTime() then

		local heal = hero.BottleSystem[bottle].Think.Hps

		if target.BottleSystem.BottleShop ~= nil then
			local tHeal = target.BottleSystem[bottle].Think.Hps
			if heal > tHeal then
				local pctDiff = tHeal / heal
				heal = tHeal + (heal - tHeal) * pctDiff
			end
		end

		local duration = math.ceil(hero.BottleSystem[bottle].Think.Expire - GameRules:GetGameTime())

		target:SetModifierStackCount(MODIFIER_[bottle], hero, duration)

		heal = heal * hero.BottleSystem[bottle].Think.Tickrate

		self:HeroBottleHeal(target, bottle, heal)
		--DebugDrawText(target:GetAbsOrigin()+ Vector(0, 0, 400), string.format("h: %f", heal), true, 0.2)

		return hero.BottleSystem[bottle].Think.Tickrate
	end

	return nil
end


function IsBottleFull(hero)
	if hero.BottleSystem.Charges >= hero.BottleSystem.ChargesMax then
		return true
	else
		return false
	end
end
	

function CBottleSystem:HeroBottleHeal( hero, bottle, amount )
	if bottle == BOTTLE_HEALTH then
		amount = hero:GetMaxHealth() * amount
		if hero:GetHealth() + amount < hero:GetMaxHealth() then
			hero:SetHealth(hero:GetHealth() + amount)
		else
			hero:SetHealth(hero:GetMaxHealth())
		end
	elseif bottle == BOTTLE_MANA then
		amount = hero:GetMaxMana() * amount
		if hero:GetMana() + amount < hero:GetMaxMana() then
			hero:SetMana(hero:GetMana() + amount)
		else
			hero:SetMana(hero:GetMaxMana())
		end
	end
end


function CBottleSystem:BottleAddCharges( hero, charges)

	if hero == nil or hero.BottleSystem == nil then
		return 0
	end

	local chargesUsed = 0
	local oldCharges = hero.BottleSystem.Charges

	if charges == 0 then
		return 0
	end

	local newCharges = math.max(hero.BottleSystem.Charges + charges, 0)
	newCharges = math.min(newCharges, hero.BottleSystem.ChargesMax)

	chargesUsed = newCharges - hero.BottleSystem.Charges
	hero.BottleSystem.Charges = newCharges
	hero.BottleSystem.LastCharges = hero.BottleSystem.Charges

	for n = 1, 2 do
		self:HeroUpdateBottle(hero, n)
	end
	
	if math.floor(hero.BottleSystem.Charges) ~= math.floor(oldCharges) then
		hero:SetModifierStackCount(MODIFIER_CHARGES, hero, math.floor(hero.BottleSystem.Charges))
	end
	----print(string.format("charges: %f", hero.BottleSystem.Charges))
	----print(string.format("refilled: %f", chargesUsed))
	return chargesUsed
end


function CBottleSystem:Bottle( ... )
	-- body
end