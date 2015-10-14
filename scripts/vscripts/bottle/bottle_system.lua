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

MODIFIER_STACKS_ = {
	"modifier_bottle_health_stacks",
	"modifier_bottle_mana_stacks",
}

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
		local moonwellObj = CMoonwell:CreateMoonwell("moonwellradiant" .. i, "moonwellradiantwater" .. i, "triggermoonwellradiant" .. i, self)
		moonwellObj:SetMana(0, false)
		table.insert(self._vMoonwells, moonwellObj)
		i = i + 1
	end
end


function CBottleSystem:GetTickrate()
	return 0.25
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
		hero:RemoveAbility(ABILITY_[glyphBottle])
	else
		hero.BottleSystem[glyphBottle].Glyph:Activate()
		hero:RemoveAbility(GLYPH_ABILITY_[hero.BottleSystem[glyphBottle].Glyph._nType])
		hero.BottleSystem[glyphBottle].Glyph = nil
	end

	hero.BottleSystem[glyphBottle].Glyph = glyph
	hero.BottleSystem[glyphBottle].Ability = hero:AddAbility(GLYPH_ABILITY_[glyph._nType])
	hero.BottleSystem[glyphBottle].Ability:SetLevel(glyph._nLevel)
	glyph:PickUp(hero)

	self:HeroUpdateBottle(hero, glyphBottle)
end


function CBottleSystem:OnHeroSpawned( hero )
	if hero.BottleSystem.BottleShop == nil then
		local pID = hero:GetPlayerOwnerID()
		print(string.format("playerId: %d", pID))
		self._vBottleShops[pID]:AddHero(hero)
	end

	for i = 1, 2 do
		ApplyModifier(hero, hero, MODIFIER_STACKS_[i], {duration=-1})
		self:BottleAddCharges(hero, i, hero.BottleSystem[i].ChargesMax)
	end
end


function CBottleSystem:OnHeroInGame( hero )
	if hero:GetTeamNumber() ~= self._nTeam then
		return
	end

	hero.BottleSystem = {
		--Health Bottle
		{
			Charges = 0,
			ChargesMax = 100,
			ChargesCost = 25,
			Lvl = 1,
			Ability = hero:AddAbility(ABILITY_[1]),
			Think = {
				TimeLeft = 0,
				Healing = 0,
				HealInstant = 0,
				Hps = 0,
				Tickrate = 0.2,
				Timer = nil,

			},
			Glyph = nil,
		},
		--Mana Bottle
		{
			Charges = 0,
			ChargesMax = 100,
			ChargesCost = 25,
			Lvl = 1,
			Ability = hero:AddAbility(ABILITY_[2]),
			Think = {
				TimeLeft = 0,
				Healing = 0,
				HealInstant = 0,
				Hps = 0,
				Tickrate = 0.2,
				Timer = nil,
			},
			Glyph = nil,
		},

		BottleShop = nil
	}

	local pID = hero:GetPlayerOwnerID()

	self:InitBottleShop(pID)
	print("hero ingame")

	table.insert(self._vHeroes, hero)


end

function CBottleSystem:HeroUpdateBottle(hero, bottle)
	--if bottle ~= 1 then
	--	return
	--end

	local data = hero.BottleSystem.BottleShop:GetUpgradeLevels(bottle)

	hero.BottleSystem[bottle].ChargesMax = 100 + (data[6]-1) * 10
	hero.BottleSystem[bottle].ChargesCost = 20 - (data[5]-1) * 2

	if hero:HasAbility(ABILITY_[bottle]) then

		local pctCharges = hero.BottleSystem[bottle].Charges / hero.BottleSystem[bottle].ChargesMax

		if hero.BottleSystem[bottle].Charges < hero.BottleSystem[bottle].ChargesCost then
			if hero.BottleSystem[bottle].Ability:GetLevel() ~= 0 then
				hero.BottleSystem[bottle].Ability:SetLevel(0)
			end
		elseif pctCharges >= 1 then
			if hero.BottleSystem[bottle].Ability:GetLevel() ~= 4 then
				hero.BottleSystem[bottle].Ability:SetLevel(4)
			end
		elseif pctCharges >= 0.75 then
				if hero.BottleSystem[bottle].Ability:GetLevel() ~= 3 then
				hero.BottleSystem[bottle].Ability:SetLevel(3)
			end
		elseif pctCharges >= 0.5 then
			if hero.BottleSystem[bottle].Ability:GetLevel() ~= 2 then
				hero.BottleSystem[bottle].Ability:SetLevel(2)
			end
		elseif pctCharges >= 0.25 then
			if hero.BottleSystem[bottle].Ability:GetLevel() ~= 1 then
				hero.BottleSystem[bottle].Ability:SetLevel(1)
			end
		end
	end
end


function CBottleSystem:HeroUseBottle( hero, target, bottle )
	local bReturn = false

	if hero.BottleSystem[bottle].Glyph ~= nil then
		--print("glyph")
		hero.BottleSystem[bottle].Glyph:Activate()
		hero:RemoveAbility(GLYPH_ABILITY_[hero.BottleSystem[bottle].Glyph._nType])
		hero.BottleSystem[bottle].Glyph = nil
		hero.BottleSystem[bottle].Ability = hero:AddAbility(ABILITY_[bottle])

		bReturn = true
	else
		--print("no glyph")
		if hero.BottleSystem[bottle].Charges >= hero.BottleSystem[bottle].ChargesCost then
			self:BottleAddCharges(hero, bottle, -hero.BottleSystem[bottle].ChargesCost)
			self:BottleActivate(hero, target, bottle)
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

	if bottle == BOTTLE_HEALTH then

		local healTime = 		BOTTLE_HEALTH_DURATION_BASE + 1 * ( data[3] - 1 )
		local healPct = 		( 0.3 + ( data[1] - 1 ) * 0.1 ) * healTime / BOTTLE_HEALTH_DURATION_BASE
		local healPctInstant = 	(0.2 + ( data[2] - 1 ) * 0.05 ) * healPct
		local hps =				1 + ( data[4] - 1 ) * 0.1

		hero.BottleSystem[bottle].Think.HealInstant = healPctInstant
		hero.BottleSystem[bottle].Think.Healing = healPct * hps
		hero.BottleSystem[bottle].Think.TimeLeft = healTime
		hero.BottleSystem[bottle].Think.Hps = hero.BottleSystem[bottle].Think.Healing / healTime

	elseif bottle == BOTTLE_MANA then

		local healTime = 		BOTTLE_MANA_DURATION_BASE + 1 * ( data[3] - 1 )
		local healPct = 		( 0.3 + ( data[1] - 1 ) * 0.1 ) * healTime / BOTTLE_MANA_DURATION_BASE
		local healPctInstant = 	(0.2 + ( data[2] - 1 ) * 0.05) * healPct
		local hps =				1 + ( data[4] - 1 ) * 0.1

		hero.BottleSystem[bottle].Think.HealInstant = healPctInstant
		hero.BottleSystem[bottle].Think.Healing = healPct * hps
		hero.BottleSystem[bottle].Think.TimeLeft = healTime
		hero.BottleSystem[bottle].Think.Hps = hero.BottleSystem[bottle].Think.Healing / healTime
	end
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
	DebugDrawText(target:GetAbsOrigin() + Vector(0, 0, 450), string.format("inst: %f", heal), true, 2)

	target:RemoveModifierByName(MODIFIER_[bottle])
	target:RemoveModifierByName(MODIFIER_FX_[bottle])

	ApplyModifier(hero, target, MODIFIER_[bottle], {duration=hero.BottleSystem[bottle].Think.TimeLeft})
	ApplyModifier(hero, target, MODIFIER_FX_[bottle], {duration=hero.BottleSystem[bottle].Think.TimeLeft})

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

	if hero.BottleSystem[bottle].Think.TimeLeft > 0 then

		local heal = hero.BottleSystem[bottle].Think.Hps

		if target.BottleSystem.BottleShop ~= nil then
			local tHeal = target.BottleSystem[bottle].Think.Hps
			if heal > tHeal then
				local pctDiff = tHeal / heal
				heal = tHeal + (heal - tHeal) * pctDiff
			end
		end

		heal = heal * hero.BottleSystem[bottle].Think.Tickrate

		self:HeroBottleHeal(target, bottle, heal)
		DebugDrawText(target:GetAbsOrigin()+ Vector(0, 0, 400), string.format("h: %f", heal), true, 0.2)

		hero.BottleSystem[bottle].Think.TimeLeft = hero.BottleSystem[bottle].Think.TimeLeft - hero.BottleSystem[bottle].Think.Tickrate

		return hero.BottleSystem[bottle].Think.Tickrate
	end

	return nil
end


function IsBottleFull( hero, bottle )
	if hero.BottleSystem[bottle].Charges == hero.BottleSystem[bottle].ChargesMax then
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


function CBottleSystem:BottleAddCharges( hero, bottle, charges)

	if hero == nil or hero.BottleSystem == nil then
		return 0
	end

	local chargesUsed = 0

	if charges == 0 then
		return 0
	end

	if charges > 0 then
		if IsBottleFull(hero, bottle) then
			return 0
		end
		if hero.BottleSystem[bottle].Charges + charges < hero.BottleSystem[bottle].ChargesMax then
			hero.BottleSystem[bottle].Charges = hero.BottleSystem[bottle].Charges + charges
			chargesUsed = charges
		else
			chargesUsed = hero.BottleSystem[bottle].ChargesMax - hero.BottleSystem[bottle].Charges
			hero.BottleSystem[bottle].Charges = hero.BottleSystem[bottle].ChargesMax
		end
	else
		if hero.BottleSystem[bottle].Charges + charges > 0 then
			hero.BottleSystem[bottle].Charges = hero.BottleSystem[bottle].Charges + charges
			chargesUsed = charges
		else
			chargesUsed = -(hero.BottleSystem[bottle].ChargesMax - hero.BottleSystem[bottle].Charges)
			hero.BottleSystem[bottle].Charges = 0
		end
	end

	self:HeroUpdateBottle(hero, bottle)
	

	hero:SetModifierStackCount(MODIFIER_STACKS_[bottle], hero, math.floor(hero.BottleSystem[bottle].Charges))
	----print(string.format("charges: %f", hero.BottleSystem[bottle].Charges))
	----print(string.format("refilled: %f", chargesUsed))
	return chargesUsed
end


function CBottleSystem:Bottle( ... )
	-- body
end