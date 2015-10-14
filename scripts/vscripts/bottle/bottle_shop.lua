if CBottleShop == nil then
	CBottleShop = class({})
end

BOTTLE_HEALTH = 1
BOTTLE_MANA = 2


SHOP_ABILITY_LIST_ = {
	{
			"bottle_shop_ability_health_1",
			"bottle_shop_ability_health_2",
			"bottle_shop_ability_health_3",
			"bottle_shop_ability_health_4",
			"bottle_shop_ability_health_5",
			"bottle_shop_ability_health_6",
			"bottle_shop_ability_toggle",
	},

	{
			"bottle_shop_ability_mana_1",
			"bottle_shop_ability_mana_2",
			"bottle_shop_ability_mana_3",
			"bottle_shop_ability_mana_4",
			"bottle_shop_ability_mana_5",
			"bottle_shop_ability_mana_6",
			"bottle_shop_ability_toggle",
	},
}


function CBottleShop:CreateBottleShop(pedestal, bottle, pID, bottleSystem)
	local shopObj = CBottleShop()
	if shopObj:Init(pedestal, bottle, pID, bottleSystem) then
		return shopObj
	end
	
	return nil
end

function CBottleShop:AddHero( hero )
	self._vHeroes[hero:entindex()] = hero
	hero.BottleSystem.BottleShop = self
end

function CBottleShop:RemoveHero( hero )
	self._vHeroes[hero:entindex()] = nil
	hero.BottleSystem.BottleShop = nil
end


function CBottleShop:Init(pedestal, bottle, pID, bottleSystem)
	self._TICKRATE = 0.04

	self._entPedestal = Entities:FindByName(nil, pedestal)
	if self._entPedestal == nil then
		--print("Pedestal not found")
		return nil
	end
	
	self._entBottle = Entities:FindByName(nil, bottle)
	if self._entBottle == nil then
		--print("Bottle not found")
		return nil
	end

	self._playerID = pID
	self._vHeroes = {}

	self._entBottle:AddNewModifier( self._entBottle, nil, "modifier_invulnerable", {} )
	self._bottleSystem = bottleSystem

	self._fMinHeigth = self._entBottle:GetOrigin().z
	self._fHeigthDiff = 70.0
	self._fStartHeigth = self._fMinHeigth + self._fHeigthDiff / 2
	self._fAnimationDuration = 4.0
	self._fAnimationClock = 0
	self._fLastAnimationFrame = GameRules:GetGameTime()
	self._shopToggleState = BOTTLE_HEALTH
	self._state = BOTTLE_MANA

	self._vAbilityLevels = {
		{
			1,
			1,
			1,
			1,
			1,
			1,
			1,
		},

		{
			1,
			1,
			1,
			1,
			1,
			1,
			1,
		},
	}

	self._vAbilityLevelsMax = {
		{
			10,
			10,
			10,
			10,
			10,
			10,
			10,
		},

		{
			10,
			10,
			10,
			10,
			10,
			10,
			10,
		},
	}
	
	self._vAbilities = {
		{
		},

		{
		},
	}

	self._entBottle.BottleShop = self

	self:UpdateShop()

	self._entBottle:SetControllableByPlayer(pID, true)

	Timers:CreateTimer(function()
		return self:Think()
	end
	)

	return self
end


function CBottleShop:TestCall()
 --print("testcall")
end


function CBottleShop:Think()
	self:AnimateShop()
	
	return self._TICKRATE
end


function CBottleShop:OnSpellStart( name )
	if name == "bottle_shop_ability_toggle" then
		self:ToggleAbilities()
	else
		--print(name)
		local state = self:GetToggledState()

		for i, ability in pairs(SHOP_ABILITY_LIST_[state]) do
			--print(ability)
			if ability == name then
				if self._vAbilityLevels[state][i] + 1 <= self._vAbilityLevelsMax[state][i] then
					self._vAbilityLevels[state][i] = self._vAbilityLevels[state][i] + 1

					self:UpdateShop()
					break
				end
			end
		end
	end
end


function CBottleShop:GetToggledState()
	if self._shopToggleState == BOTTLE_HEALTH then
		return BOTTLE_MANA
	elseif self._shopToggleState == BOTTLE_MANA then
		return BOTTLE_HEALTH
	end
end


function CBottleShop:GetUpgradeLevels(bottle)
	local copy = shallowcopy(self._vAbilityLevels[bottle])
	return copy
end


function CBottleShop:UpdateShop()
	local state = self._shopToggleState
	local counterState = self:GetToggledState()

	--print(string.format("shopstate: %d", self._shopToggleState))
	--print(string.format("counterState: %d", counterState))

	if state ~= self._state then
		for _, ability in pairs(SHOP_ABILITY_LIST_[state]) do
			self._entBottle:RemoveAbility(ability)
			self._vAbilities = {}
		end

		for i, ability in pairs(SHOP_ABILITY_LIST_[counterState]) do
			local spell = self._entBottle:AddAbility(ability)
			----print(ability)
			if ability ~= "bottle_shop_ability_toggle" then
				--print(string.format("abilitylevel: %d", self._vAbilityLevels[counterState][i]))
				--print(string.format("abilitylevel max: %d", self._vAbilityLevelsMax[counterState][i]))

				spell:SetLevel(self._vAbilityLevels[counterState][i])
				table.insert(self._vAbilities, spell)
			else
				spell:SetLevel(1)
			end
		end

		self._state = self._shopToggleState
	else
		----print("just setting levels")
		for i, ability in pairs(self._vAbilities) do
			ability:SetLevel(self._vAbilityLevels[counterState][i])
		end
	end

	for _, unit in pairs(self._vHeroes) do
		self._bottleSystem:HeroUpdateBottle(unit, counterState)
	end
end


function CBottleShop:ToggleAbilities()
	self._shopToggleState = self:GetToggledState()
	self:UpdateShop()
end


function CBottleShop:AnimateShop()
	local timePassed = GameRules:GetGameTime() - self._fLastAnimationFrame
	local newHeigth = self._fStartHeigth + self._fHeigthDiff * math.sin(math.rad(90 * self._fAnimationClock))

	self._fLastAnimationFrame = GameRules:GetGameTime()
	self._fAnimationClock = self._fAnimationClock + timePassed

	if self._fAnimationClock > self._fAnimationDuration then
		self._fAnimationClock = self._fAnimationClock - self._fAnimationDuration
	end

	----print(self._fAnimationClock)


	local pos = self._entBottle:GetOrigin()
	pos.z = newHeigth

	self._entBottle:SetOrigin(pos)
end