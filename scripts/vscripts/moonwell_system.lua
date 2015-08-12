--[[
	CHoldoutGameRound - A single round of Holdout
]]

if CMoonwell == nil then
	CMoonwell = class({})
end


function CMoonwell:CreateMoonwell(moonwell, water, trigger, bottleSystem)
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

	self._entTrigger = Entities:FindByName(nil, trigger)
	if self._entWater == nil then
		print("trigger not found")
		return nil
	end

	self._entTrigger.Moonwell = self

	self._bottleSystem = bottleSystem
	self._TICKRATE = 0.1
	self._fManaReg = 7.0
	self._fRefillPerSecond = 20
	self._fTimeNextUpdate = GameRules:GetGameTime()
	self._fUpdateIntervall = 1.0
	self._bIsFull = false
	self._bShownFull = false
	self._fManaLastUpdate = self._entMoonwell:GetMana()
	
	self._fMaxHeight = self._entWater:GetOrigin().z
	self._fHeightDiff = 55

	self._vBottleUnits = {}
	
	Timers:CreateTimer(function()
		
		return self:Think()
	end
	)
	return true
end


function CMoonwell:Think()
	self:AddMana(self._fManaReg * self._TICKRATE)
	if #self._vBottleUnits > 0 then
		self:RefillBottles()
	end
	self:UpdateMoonwell(true)
	
	return self._TICKRATE
end

function CMoonwell:RefillBottles()
	print("refilling bottles")
	local BottleUnits = shallowcopy(self._vBottleUnits)
	local refillTick = self._fRefillPerSecond * self._TICKRATE
	local manaToUse = math.min(refillTick, self:GetMana())
	local manaUsed = 0

	while manaToUse - manaUsed > 0 and #BottleUnits > 0 do
		for n, u in pairs(BottleUnits) do
			if IsBottleFull(u, BOTTLE_HEALTH) then --and self._bottleSystem:IsBottleFull(u, BOTTLE_MANA) then
				table.remove(BottleUnits, n)
			end
		end

		local refillAmount = manaToUse - manaUsed / #BottleUnits

		for n, u in pairs(BottleUnits) do
			if u.BottleSystem ~= nil then
				manaUsed = manaUsed + self._bottleSystem:BottleAddCharges(u, BOTTLE_HEALTH, refillAmount)

					--manaLeft = refillUnit - self._bottleSystem:BottleAddCharges(u, BOTTLE_MANA, manaLeft)
			end
		end
	end

	self:AddMana(-manaUsed, true)
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
			PopupNumbers(self._entMoonwell, "gold", Vector(0, 0, 255), 1.0, math.ceil(math.abs(manaDiff)), POPUP_SYMBOL_PRE_PLUS, nil)
		elseif manaDiff < 0 then
			PopupNumbers(self._entMoonwell, "gold", Vector(255, 0, 0), 1.0, math.ceil(math.abs(manaDiff)), POPUP_SYMBOL_PRE_MINUS, nil)
		end
		
			if GameRules:GetGameTime() >= self._fTimeNextUpdate then
			self._fTimeNextUpdate = GameRules:GetGameTime() + self._fUpdateIntervall
			
			if not self._bShowedFull then
				if self._bIsFull then
					self._bShowedFull = true
				end
				PopupNumbers(self._entMoonwell, "gold", Vector(0, 255, 0), 1.0, math.floor(mana), POPUP_SYMBOL_POST_EXCLAMATION, nil)
			end
		end
	end
	
	self._fManaLastUpdate = mana
end

function CMoonwell:AddBottleUnit( unit )
	print("adding bottle unit")
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
		print("inserting bottle unit into table")
		table.insert(self._vBottleUnits, unit)
	end
end

function CMoonwell:RemoveBottleUnit( unit )
	for n, u in pairs(self._vBottleUnits) do
		if u == unit then
			print("removing bottle unit from table")
			table.remove(self._vBottleUnits, n)
			break
		end
	end
end


function CMoonwell:RefillBottle(unit, trigger)
	for _,moonwell in pairs(self._vMoonwells) do
		if trigger:GetName() == moonwell._strTrigger then
			--local bottle = findItemOnUnit( unit, "item_bottle", false)

			if unit.BottleSystem == nil then
				print("bottle system not found")
				return
			end
	
			if unit.BottleSystem[1].Charges < unit.BottleSystem[1].ChargesMax then
				----print("refreshing bottle")
				----print(bottle:GetCurrentCharges())
				if moonwell:GetMana() >= 20 then
					----print("add bottle charge")
					--bottle:SetCurrentCharges(bottle:GetCurrentCharges() + 1)
					self._bottleSystem:BottleAddCharges(unit, BOTTLE_HEALTH, 20)
					moonwell:AddMana(-20, true)
					PopupNumbers(unit, "gold", Vector(255, 0, 255), 1.0, 1, POPUP_SYMBOL_POST_EXCLAMATION, nil)
				end
			else
				----print("no bottle found")
			end
		end
	end
end