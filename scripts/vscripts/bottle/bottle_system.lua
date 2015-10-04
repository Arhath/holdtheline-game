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



function CBottleSystem:Init( gameMode, team )
	self._gameMode = gameMode
	self._nTeam = team
	self._vHeroes = {}
	self._vMoonwells = {}
	self._vBottleShops = {}
	self:InitMoonwells()

	self._vGlyphs = {}

	--Timers:CreateTimer(function()
		--CBottleSystem:Update()

		----return self:GetTickrate()
	--end
	--)
end

function CBottleSystem:InitBottleShop(hero)
	local id = hero:GetPlayerOwnerID()
	--print(string.format("player owner: %d", id))

	if Entities:FindByName(nil, "BottleShopPedestal" .. id) ~= nil then
		local bottleShopObj = CBottleShop:CreateBottleShop("BottleShopPedestal" .. id, "BottleShopBottle" .. id, hero, self)
		table.insert(self._vBottleShops, bottleShopObj)
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
	print("try pickup")

	if item ~= nil then
		print("item exists")
	end

	local glyph = self:GetGlyph(item)

	if glyph ~= nil then
		print("picking up")
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

	print("spawning glyph")

	local glyphObj = CGlyphObj:CreateGlyph(nType, lvl, self)

	if glyphObj == nil then
		return
	end

	table.insert(self._vGlyphs, glyphObj)

	print("glyph created")

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
			},
			Glyph = nil,
		},

		BottleShop = nil
	}

	self:InitBottleShop(hero)
	

	table.insert(self._vHeroes, hero)

	for i = 1, 2 do
		ApplyModifier(hero, hero, MODIFIER_STACKS_[i], {duration=-1})

		self:BottleAddCharges(hero, i, 100)
	end
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
		print("glyph")
		hero.BottleSystem[bottle].Glyph:Activate()
		hero:RemoveAbility(GLYPH_ABILITY_[hero.BottleSystem[bottle].Glyph._nType])
		hero.BottleSystem[bottle].Glyph = nil
		hero.BottleSystem[bottle].Ability = hero:AddAbility(ABILITY_[bottle])

		bReturn = true
	else
		print("no glyph")
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

		local healTime = 		4 + 1 * ( data[3] - 1 )
		local healPct = 		( 0.3 + ( data[1] - 1 ) * 0.1 ) * healTime / 4
		local healPctInstant = 	0.2 + ( data[2] - 1 ) * 0.5 * healPct
		local hps =				1 + ( data[4] - 1 ) * 0.1

		hero.BottleSystem[bottle].Think.HealInstant = hero:GetMaxHealth() * healPctInstant
		hero.BottleSystem[bottle].Think.Healing = hero:GetMaxHealth() * healPct * hps
		hero.BottleSystem[bottle].Think.TimeLeft = healTime
		hero.BottleSystem[bottle].Think.Hps = hero.BottleSystem[bottle].Think.Healing / healTime

	elseif bottle == BOTTLE_MANA then

		local healTime = 		4 + 1 * ( data[3] - 1 )
		local healPct = 		( 0.3 + ( data[1] - 1 ) * 0.1 ) * healTime / 4
		local healPctInstant = 	0.2 + ( data[2] - 1 ) * 0.5 * healPct
		local hps =				1 + ( data[4] - 1 ) * 0.1

		hero.BottleSystem[bottle].Think.HealInstant = hero:GetMaxMana() * healPctInstant
		hero.BottleSystem[bottle].Think.Healing = hero:GetMaxMana() * healPct * hps
		hero.BottleSystem[bottle].Think.TimeLeft = healTime
		hero.BottleSystem[bottle].Think.Hps = hero.BottleSystem[bottle].Think.Healing / healTime
	end
end


function CBottleSystem:BottleActivate(hero, target, bottle)

	self:BottleCalcThink(hero, bottle)
	self:HeroBottleHeal(target, bottle, hero.BottleSystem[bottle].Think.HealInstant)

	target:RemoveModifierByName(MODIFIER_[bottle])
	target:RemoveModifierByName(MODIFIER_FX_[bottle])

	ApplyModifier(hero, target, MODIFIER_[bottle], {duration=hero.BottleSystem[bottle].Think.TimeLeft})
	ApplyModifier(hero, target, MODIFIER_FX_[bottle], {duration=hero.BottleSystem[bottle].Think.TimeLeft})

	Timers:CreateTimer(function()
		return CBottleSystem:BottleThink(hero, target, bottle)
	end
	)
end

function CBottleSystem:BottleThink( hero, target, bottle )
	if hero.BottleSystem[bottle].Think.TimeLeft > 0 then

		local healing = hero.BottleSystem[bottle].Think.Hps * hero.BottleSystem[bottle].Think.Tickrate

		self:HeroBottleHeal(target, bottle, healing)

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
		if hero:GetHealth() + amount < hero:GetMaxHealth() then
			hero:SetHealth(hero:GetHealth() + amount)
		else
			hero:SetHealth(hero:GetMaxHealth())
		end
	elseif bottle == BOTTLE_MANA then
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
	--print(string.format("charges: %f", hero.BottleSystem[bottle].Charges))
	--print(string.format("refilled: %f", chargesUsed))
	return chargesUsed
end


function CBottleSystem:Bottle( ... )
	-- body
end