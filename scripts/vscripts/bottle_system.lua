require( "moonwell_system" )
require( "bottle_health" )
require( "bottle_shop")

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



function CBottleSystem:Init( gameMode, team )
	self._gameMode = gameMode
	self._nTeam = team
	self._vHeroes = {}
	self._vMoonwells = {}
	self._vBottleShops = {}
	self:InitMoonwells()

	Timers:CreateTimer(function()
		CBottleSystem:Update()

		return self:GetTickrate()
	end
	)
end

function CBottleSystem:InitBottleShop(hero)
	local id = hero:GetPlayerOwnerID()
	print(string.format("player owner: %d", id))

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

function CBottleSystem:OnHeroSpawned( hero )
	hero.BottleSystem[BOTTLE_HEALTH].BuffApplier:ApplyDataDrivenModifier(hero, hero, MODIFIER_STACKS_[BOTTLE_HEALTH], {duration=-1})
	--self:BottleAddCharges(hero, BOTTLE_HEALTH, hero.BottleSystem[BOTTLE_HEALTH].Charges)
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
			Ability = hero:AddAbility("bottle_health"),
			BuffApplier = CreateItem("item_bottle_health_applier", hero, hero),
			Think = {
				TimeLeft = 0,
				Healing = 0,
				HealInstant = 0,
				Hps = 0,
				Tickrate = 0.2,
			}
		},
		--Mana Bottle
		{
			Charges = 3,
			ChargesMax = 3,
			Lvl = 1,
		},
	}

	self:InitBottleShop(hero)

	table.insert(self._vHeroes, hero)

	hero.BottleSystem[BOTTLE_HEALTH].BuffApplier:ApplyDataDrivenModifier(hero, hero, MODIFIER_STACKS_[BOTTLE_HEALTH], {duration=-1})
	
	self:BottleAddCharges(hero, BOTTLE_HEALTH, 100)
end

function CBottleSystem:Update()
	--for _, h in pairs(self._vHeroes) do
	--	if h.
end


function CBottleSystem:HeroUseBottle( hero, target, bottle )
	if hero.BottleSystem[bottle].Charges >= hero.BottleSystem[bottle].ChargesCost then
		self:BottleAddCharges(hero, bottle, -hero.BottleSystem[bottle].ChargesCost)
		self:BottleActivate(hero, target, bottle)
		return true
	end
	return false
end


function CBottleSystem:BottleCalcThink( hero, bottle )
	hero.BottleSystem[bottle].Think.HealInstant = 500
	hero.BottleSystem[bottle].Think.Healing = 1000
	hero.BottleSystem[bottle].Think.TimeLeft = 4
	hero.BottleSystem[bottle].Think.Hps = hero.BottleSystem[bottle].Think.Healing / hero.BottleSystem[bottle].Think.TimeLeft
end


function CBottleSystem:BottleActivate(hero, target, bottle)

	self:BottleCalcThink(hero, bottle)
	self:HeroBottleHeal(target, bottle, hero.BottleSystem[bottle].Think.HealInstant)

	target:RemoveModifierByName(MODIFIER_[bottle])
	target:RemoveModifierByName(MODIFIER_FX_[bottle])

	hero.BottleSystem[bottle].BuffApplier:ApplyDataDrivenModifier(hero, target, MODIFIER_[bottle], {duration=hero.BottleSystem[bottle].Think.TimeLeft})
	hero.BottleSystem[bottle].BuffApplier:ApplyDataDrivenModifier(hero, target, MODIFIER_FX_[bottle], {duration=hero.BottleSystem[bottle].Think.TimeLeft})

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

	hero:SetModifierStackCount(MODIFIER_STACKS_[bottle], hero, math.floor(hero.BottleSystem[bottle].Charges))

	return chargesUsed
end


function CBottleSystem:Bottle( ... )
	-- body
end