function OnEnterEnergyGate(trigger)
	local u = trigger.activator
	GameRules.holdOut:OnUnitEntersEnergyGate(u)
	print("Cleansing Water")
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

function RefillBottle(event)
	local unit = event.activator
	findItemOnUnit( unit, itemname, false)
	end
end

--a function that finds an item on a unit by name
function findItemOnUnit( unit, itemname, searchStash )
    --check if the unit has the item at all
    if not unit:HashItemInInventory( itemname ) then
        return nil
    end
    
    --set a search range depending on if we want to search the stach or not
    local lastSlot = 5
    if searchStash then
        lastSlot = 11
    end
    
    --go past all slots to see if the item is there
    for slot= 0, lastSlot, 1 do
        local item = unit:GetItemInSlot( slot )
        if item:GetAbilityName() == itemname then
            return item
        end
    end
    
    --if the item is not found, return nil (happens if the item is in stash and you are not looking in stash)
    return nil
end