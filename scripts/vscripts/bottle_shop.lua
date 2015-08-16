if CBottleShop == nil then
	CBottleShop = class({})
end


function CBottleShop:CreateBottleShop(pedestal, bottle, hero, bottleSystem)
	local shopObj = CBottleShop()
	if shopObj:Init(pedestal, bottle, hero, bottleSystem) then
		return shopObj
	end
	
	return nil
end


function CBottleShop:Init(pedestal, bottle, hero, bottleSystem)
	self._TICKRATE = 0.04

	self._entPedestal = Entities:FindByName(nil, pedestal)
	if self._entPedestal == nil then
		print("Pedestal not found")
		return nil
	end
	
	self._entBottle = Entities:FindByName(nil, bottle)
	if self._entBottle == nil then
		print("Bottle not found")
		return nil
	end

	self._bottleSystem = bottleSystem

	self._fMinHeigth = self._entBottle:GetOrigin().z
	self._fHeigthDiff = 70.0
	self._fStartHeigth = self._fMinHeigth + self._fHeigthDiff / 2
	self._fAnimationDuration = 4.0
	self._fAnimationClock = 0
	self._fLastAnimationFrame = GameRules:GetGameTime()

	self._hero = hero
	
	Timers:CreateTimer(function()
		
		return self:Think()
	end
	)
	return true
end


function CBottleShop:Think()
	self:AnimateShop()
	
	return self._TICKRATE
end


function CBottleShop:AnimateShop()
	local timePassed = GameRules:GetGameTime() - self._fLastAnimationFrame
	local newHeigth = self._fStartHeigth + self._fHeigthDiff * math.sin(math.rad(90 * self._fAnimationClock))

	self._fLastAnimationFrame = GameRules:GetGameTime()
	self._fAnimationClock = self._fAnimationClock + timePassed

	if self._fAnimationClock > self._fAnimationDuration then
		self._fAnimationClock = self._fAnimationClock - self._fAnimationDuration
	end

	print(self._fAnimationClock)


	local pos = self._entBottle:GetOrigin()
	pos.z = newHeigth

	self._entBottle:SetOrigin(pos)
end