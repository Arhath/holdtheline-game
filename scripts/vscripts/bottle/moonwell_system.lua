--[[
	CHoldoutGameRound - A single round of Holdout
]]

if CMoonwell == nil then
	CMoonwell = class({})
end


function CMoonwell:CreateMoonwell(moonwell, water, bottleSystem)
	local moonwellObj = CMoonwell()
	if moonwellObj:Init(moonwell, water, trigger, bottleSystem) then
		return moonwellObj
	end
	
	return nil
end


function CMoonwell:Init(moonwell, water, trigger, bottleSystem)
	self._entMoonwell = Entities:FindByName(nil, moonwell)
	if self._entMoonwell == nil then
		print("moonwell not found")
		return nil
	end
	
	self._entWater = Entities:FindByName(nil, water)
	if self._entWater == nil then
		print("water not found")
		return nil
	end

	self._bottleSystem = bottleSystem
	self._TICKRATE = 0.25
	self._fManaReg = 7.0
	self._fRefillPerSecond = 20
	self._fTimeNextUpdate = GameRules:GetGameTime()
	self._fUpdateIntervall = 1.0
	self._bIsFull = false
	self._bShownFull = false
	self._fManaLastUpdate = self._entMoonwell:GetMana()

	self._fMaxDistRefill = 700.0
	self._bRefillOnHighground = false
	
	self._fMaxHeight = self._entWater:GetOrigin().z
	self._fHeightDiff = 47

	self._vBottleUnits = {}
	
	Timers:CreateTimer(function()
		
		return self:Think()
	end
	)
	return true
end

function CMoonwell:Think()
	--DebugDrawCircle(self._entMoonwell:GetAbsOrigin(), Vector(0,0,255), 0, self._fMaxDistRefill, true, self._TICKRATE)

	self._vBottleUnits = ListFilterWithFn(self._bottleSystem._gameMode._vHeroes,
	function(e)
		if not UnitAlive(e) then
			return false
		end

		local dist = (e:GetAbsOrigin() - self._entMoonwell:GetAbsOrigin()):Length2D()
		local heightDiff = 0

		if not self._bRefillOnHighground then
			heightDiff = (GetGroundHeight(self._entMoonwell:GetAbsOrigin(), nil) - GetGroundHeight(e:GetAbsOrigin(), nil))
		end

		return dist <= self._fMaxDistRefill and heightDiff >= 0
	end
	)

	self:AddMana(self._fManaReg * self._TICKRATE)
	if #self._vBottleUnits > 0 then
		self:RefillBottles()
	end
	self:UpdateMoonwell(true)
	
	return self._TICKRATE
end


function CMoonwell:RefillBottles()
	--print("refilling bottles")

	local refillTick = self._fRefillPerSecond * self._TICKRATE
	local manaToUse = math.min(refillTick, self:GetMana())
	local manaLeft = manaToUse

	while manaLeft > 0.01 do
		local BottleUnits = ListFilterWithFn(self._vBottleUnits,
										function(e)
											return not IsBottleFull(e)
										end
										)
		--print(#BottleUnits)

		if #BottleUnits <= 0 then
			break
		end


		local refillPerUnit = manaLeft / #BottleUnits

		for n, u in pairs(BottleUnits) do
			if u.BottleSystem ~= nil then

				local refillAmount = refillPerUnit

				refillAmount = refillAmount - self._bottleSystem:BottleAddCharges(u, refillAmount)
				--DebugDrawText(u:GetAbsOrigin() + Vector(0,0,100) , string.format(refillPerUnit - refillAmount), true, self._TICKRATE)

				manaLeft = manaLeft - (refillPerUnit - refillAmount)
			end
		end
	end

	self:AddMana(-(manaToUse - manaLeft), true)
end


function CMoonwell:GetMana()
	--print(string.format("moonwell get mana = %d", self._entMoonwell:GetMana()))
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
			PopupNumbers(self._entMoonwell, PATTACH_ABSORIGIN_FOLLOW, "gold", Vector(0, 0, 255), 1.0, math.ceil(math.abs(manaDiff)), POPUP_SYMBOL_PRE_PLUS, nil, -1)
		elseif manaDiff < 0 then
			PopupNumbers(self._entMoonwell, PATTACH_ABSORIGIN_FOLLOW, "gold", Vector(255, 0, 0), 1.0, math.ceil(math.abs(manaDiff)), POPUP_SYMBOL_PRE_MINUS, nil, -1)
		end
		
			if GameRules:GetGameTime() >= self._fTimeNextUpdate then
			self._fTimeNextUpdate = GameRules:GetGameTime() + self._fUpdateIntervall
			
			if not self._bShowedFull then
				if self._bIsFull then
					self._bShowedFull = true
				end
				PopupNumbers(self._entMoonwell, PATTACH_ABSORIGIN_FOLLOW, "gold", Vector(0, 255, 0), 1.0, math.floor(mana), POPUP_SYMBOL_POST_EXCLAMATION, nil, -1)
			end
		end
	end
	
	self._fManaLastUpdate = mana
end

function CMoonwell:AddBottleUnit( unit )
	--print("adding bottle unit")
	if unit.BottleSystem == nil then
		return
	end

	local bSetUnit = true

	for _, u in pairs(self._vBottleUnits) do
		if u == unit then
			bSetUnit = false
			break
		end
	end

	if bSetUnit then
		--print("inserting bottle unit into table")
		table.insert(self._vBottleUnits, unit)
	end
end

function CMoonwell:RemoveBottleUnit( unit )
	for n, u in pairs(self._vBottleUnits) do
		if u == unit then
			--print("removing bottle unit from table")
			table.remove(self._vBottleUnits, n)
			break
		end
	end
end