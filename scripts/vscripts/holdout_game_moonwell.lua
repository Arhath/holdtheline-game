--[[
	CHoldoutGameRound - A single round of Holdout
]]

if CMoonwell == nil then
	CMoonwell = class({})
end

function CMoonwell:CreateMoonwell(moonwell, water, trigger, gameMode)
	local moonwellObj = CMoonwell()
	if moonwellObj:Init(moonwell, water, trigger, gameMode) then
		return moonwellObj
	end
	
	return nil
end

function CMoonwell:Init(moonwell, water, trigger, gameMode)
	self._entMoonwell = Entities:FindByName(nil, moonwell)
	if self._entMoonwell == nil then
		print("Moonwell not found")
		return nil
	end
	
	self._entWater = Entities:FindByName(nil, water)
	if self._entWater == nil then
		print("Water not found")
		return nil
	end
	self._strTrigger = trigger
	self._gameMode = gameMode
	self._TICKRATE = 0.25
	self._fManaReg = 7.0
	self._fTimeNextUpdate = GameRules:GetGameTime()
	self._fUpdateIntervall = 1.0
	self._bIsFull = false
	self._bShownFull = false
	self._fManaLastUpdate = self._entMoonwell:GetMana()
	
	self._fMaxHeight = self._entWater:GetOrigin().z
	self._fHeightDiff = 55
	
	Timers:CreateTimer(function()
		
		return self:Think()
	end
	)
	return true
end

function CMoonwell:Think()
	self:AddMana(self._fManaReg * self._TICKRATE)
	self:UpdateMoonwell(true)
	
	return self._TICKRATE
end

function CMoonwell:GetMana()
	return self._entMoonwell:GetMana()
end

function CMoonwell:AddMana(n, show)
	local maxMana = self._entMoonwell:GetMaxMana()
	local mana = self._entMoonwell:GetMana()
	
	if mana + n >= maxMana then
		self._entMoonwell:SetMana(maxMana)
	else
		self._entMoonwell:SetMana(mana + n)
	end
	
	self:UpdateMoonwell(show)
end

function CMoonwell:SetMana(n, show)
	local maxMana = self._entMoonwell:GetMaxMana()
	local mana = self._entMoonwell:GetMana()
	
	if n >= maxMana then
		self._entMoonwell:SetMana(maxMana)
	else
		self._entMoonwell:SetMana(n)
	end
	
	self:UpdateMoonwell(show)
end

function CMoonwell:UpdateMoonwell(show)
	local maxMana = self._entMoonwell:GetMaxMana()
	local mana = self._entMoonwell:GetMana()
	local manaPercent = mana / maxMana
	local manaDiff = mana - self._fManaLastUpdate
	
	local heightDiff = self._fHeightDiff * (1 - manaPercent)
	local newHeight = self._fMaxHeight - heightDiff
	local newOrigin = self._entWater:GetOrigin()
	newOrigin.z = newHeight
	
	self._entWater:SetOrigin(newOrigin)
	
	if manaPercent < 1.0 then
		self._bIsFull = false
		self._bShowedFull = false
	else
		self._bIsFull = true
	end
	
	if show then
		if manaDiff > 0 then
			PopupNumbers(self._entMoonwell, "gold", Vector(0, 0, 255), 1.0, math.abs(manaDiff), POPUP_SYMBOL_PRE_PLUS, nil)
		elseif manaDiff < 0 then
			PopupNumbers(self._entMoonwell, "gold", Vector(255, 0, 0), 1.0, math.abs(manaDiff), POPUP_SYMBOL_PRE_MINUS, nil)
		end
		
			if GameRules:GetGameTime() >= self._fTimeNextUpdate then
			self._fTimeNextUpdate = GameRules:GetGameTime() + self._fUpdateIntervall
			
			if not self._bShowedFull then
				if self._bIsFull then
					self._bShowedFull = true
				end
				PopupNumbers(self._entMoonwell, "gold", Vector(0, 255, 0), 1.0, math.ceil(mana), POPUP_SYMBOL_POST_EXCLAMATION, nil)
			end
		end
	end
	
	self._fManaLastUpdate = mana
end