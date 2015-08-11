function OnEnterEnergyGate(trigger)
	local u = trigger.activator
	GameRules.holdOut:OnUnitEntersEnergyGate(u)
	--print("Cleansing Water")
end

function OnLeaveCleansingWater(trigger)
	local u = trigger.activator
	GameRules.holdOut:OnUnitLeavesCleansingWater(u)
end

function OnRadiantGoalEnter(trigger)
	print(trigger.activator)
	local u = trigger.activator
	GameRules.holdOut:OnUnitEntersGoal(u, DOTA_TEAM_GOODGUYS)
end

function OnRadiantTeleportLeft(event)
	local unit = event.activator


	local ent = Entities:FindByName( nil, "RadiantTeleportMarkLeft")
	local point = ent:GetAbsOrigin() 

	event.activator:SetAbsOrigin(point)
	FindClearSpaceForUnit(unit, point, false)
	unit:Stop()
end

function OnRadiantTeleportLeftFar(event)
	local unit = event.activator


	local ent = Entities:FindByName( nil, "RadiantTeleportMarkLeftFar")
	local point = ent:GetAbsOrigin() 

	event.activator:SetAbsOrigin(point)
	FindClearSpaceForUnit(unit, point, false)
	unit:Stop()
end

function OnRadiantTeleportRight(event)
	local unit = event.activator


	local ent = Entities:FindByName( nil, "RadiantTeleportMarkRight")
	local point = ent:GetAbsOrigin() 

	event.activator:SetAbsOrigin(point)
	FindClearSpaceForUnit(unit, point, false)
	unit:Stop()
end

function OnRadiantTeleportRightFar(event)
	local unit = event.activator


	local ent = Entities:FindByName( nil, "RadiantTeleportMarkRightFar")
	local point = ent:GetAbsOrigin() 

	event.activator:SetAbsOrigin(point)
	FindClearSpaceForUnit(unit, point, false)
	unit:Stop()
end



function BottleWaterEnter(event)
	local unit = event.activator
	local trigger = thisEntity
	
	print(trigger:GetName())
	
	--print(string.format("moonwellid: %d", moonwell))
	if unit ~= nil and unit:IsRealHero() then
		if trigger.Moonwell ~= nil then
			print("moonwell enter")
			trigger.Moonwell:AddBottleUnit(unit)
		end
	end
end

function BottleWaterLeave(event)
	local unit = event.activator
	local trigger = thisEntity
	
	if unit ~= nil and unit:IsRealHero() then
		if trigger.Moonwell ~= nil then
			print("moonwell leave")
			trigger.Moonwell:RemoveBottleUnit(unit)
		end
	end
end