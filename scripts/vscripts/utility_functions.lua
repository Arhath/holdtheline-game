--[[ utility_functions.lua ]]

---------------------------------------------------------------------------
-- Handle messages
---------------------------------------------------------------------------
function BroadcastMessage( sMessage, fDuration )
    local centerMessage = {
        message = sMessage,
        duration = fDuration
    }
    FireGameEvent( "show_center_message", centerMessage )
end


function PickRandomShuffle( reference_list, bucket )
    if ( #reference_list == 0 ) then
        return nil
    end
    
    if ( #bucket == 0 ) then
        -- ran out of options, refill the bucket from the reference
        for k, v in pairs(reference_list) do
            bucket[k] = v
        end
    end

    -- pick a value from the bucket and remove it
    local pick_index = RandomInt( 1, #bucket )
    local result = bucket[ pick_index ]
    table.remove( bucket, pick_index )
    return result
end


function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end


function ShuffledList( orig_list )
	local list = shallowcopy( orig_list )
	local result = {}
	local count = #list
	for i = 1, count do
		local pick = RandomInt( 1, #list )
		result[ #result + 1 ] = list[ pick ]
		table.remove( list, pick )
	end
	return result
end


function TableCount( t )
	local n = 0
	for _ in pairs( t ) do
		n = n + 1
	end
	return n
end


function TableFindKey( table, val )
	if table == nil then
		print( "nil" )
		return nil
	end

	for k, v in pairs( table ) do
		if v == val then
			return k
		end
	end
	return nil
end


function GetAngleBetweenPoints(p1, p2)
    local dX = p2.x - p1.x
    local dY = p2.y - p1.y

    return math.atan2(dY, dX) * (180 / math.pi)
end


function GetAngleBetweenVectors(v1, v2)
    v1.z = 0
    v2.z = 0
    
    dot = v1.x * v2.x + v1.y * v2.y

    return math.acos(dot / (v1:Length() * v2:Length())) * (180 / math.pi)
end


function CountdownTimer()
    nCOUNTDOWNTIMER = nCOUNTDOWNTIMER - 1
    local t = nCOUNTDOWNTIMER
    --print( t )
    local minutes = math.floor(t / 60)
    local seconds = t - (minutes * 60)
    local m10 = math.floor(minutes / 10)
    local m01 = minutes - (m10 * 10)
    local s10 = math.floor(seconds / 10)
    local s01 = seconds - (s10 * 10)
    local broadcast_gametimer = 
        {
            timer_minute_10 = m10,
            timer_minute_01 = m01,
            timer_second_10 = s10,
            timer_second_01 = s01,
        }
    CustomGameEventManager:Send_ServerToAllClients( "countdown", broadcast_gametimer )
    if t <= 120 then
        CustomGameEventManager:Send_ServerToAllClients( "time_remaining", broadcast_gametimer )
    end
end

function SetTimer( cmdName, time )
    print( "Set the timer to: " .. time )
    nCOUNTDOWNTIMER = time
end


--a function that finds an item on a unit by name
function findItemOnUnit( unit, itemname, searchStash )
    --check if the unit has the item at all
    if not unit:HasItemInInventory( itemname ) then
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




POPUP_SYMBOL_PRE_PLUS = 0
POPUP_SYMBOL_PRE_MINUS = 1
POPUP_SYMBOL_PRE_SADFACE = 2
POPUP_SYMBOL_PRE_BROKENARROW = 3
POPUP_SYMBOL_PRE_SHADES = 4
POPUP_SYMBOL_PRE_MISS = 5
POPUP_SYMBOL_PRE_EVADE = 6
POPUP_SYMBOL_PRE_DENY = 7
POPUP_SYMBOL_PRE_ARROW = 8

POPUP_SYMBOL_POST_EXCLAMATION = 0
POPUP_SYMBOL_POST_POINTZERO = 1
POPUP_SYMBOL_POST_MEDAL = 2
POPUP_SYMBOL_POST_DROP = 3
POPUP_SYMBOL_POST_LIGHTNING = 4
POPUP_SYMBOL_POST_SKULL = 5
POPUP_SYMBOL_POST_EYE = 6
POPUP_SYMBOL_POST_SHIELD = 7
POPUP_SYMBOL_POST_POINTFIVE = 8


-- e.g. when healed by an ability
function PopupHealing(target, amount)
    PopupNumbers(target, "heal", Vector(0, 255, 0), 1.0, amount, POPUP_SYMBOL_PRE_PLUS, nil)
end


-- e.g. the popup you get when you suddenly take a large portion of your health pool in damage at once
function PopupDamage(target, amount)
    PopupNumbers(target, "damage", Vector(255, 0, 0), 1.0, amount, nil, POPUP_SYMBOL_POST_DROP)
end


-- e.g. when dealing critical damage
function PopupCriticalDamage(target, amount)
    PopupNumbers(target, "crit", Vector(255, 0, 0), 1.0, amount, nil, POPUP_SYMBOL_POST_LIGHTNING)
end


-- e.g. when taking damage over time from a poison type spell
function PopupDamageOverTime(target, amount)
    PopupNumbers(target, "poison", Vector(215, 50, 248), 1.0, amount, nil, POPUP_SYMBOL_POST_EYE)
end

-- e.g. when blocking damage with a stout shield
function PopupDamageBlock(target, amount)
    PopupNumbers(target, "block", Vector(255, 255, 255), 1.0, amount, POPUP_SYMBOL_PRE_MINUS, nil)
end


-- e.g. when last-hitting a creep
function PopupGoldGain(target, amount)
    PopupNumbers(target, "gold", Vector(255, 200, 33), 1.0, amount, POPUP_SYMBOL_PRE_PLUS, nil)
end


-- e.g. when missing uphill
function PopupMiss(target)
    PopupNumbers(target, "miss", Vector(255, 0, 0), 1.0, nil, POPUP_SYMBOL_PRE_MISS, nil)
end


-- Customizable version.
function PopupNumbers(target, pfx, color, lifetime, number, presymbol, postsymbol)
    local pfxPath = string.format("particles/msg_fx/msg_%s.vpcf", pfx)
    local pidx = ParticleManager:CreateParticle(pfxPath, PATTACH_ABSORIGIN_FOLLOW, target) -- target:GetOwner()

    local digits = 0
    if number ~= nil then
        digits = #tostring(number)
    end
    if presymbol ~= nil then
        digits = digits + 1
    end
    if postsymbol ~= nil then
        digits = digits + 1
    end

    ParticleManager:SetParticleControl(pidx, 1, Vector(tonumber(presymbol), tonumber(number), tonumber(postsymbol)))
    ParticleManager:SetParticleControl(pidx, 2, Vector(lifetime, digits, 0))
    ParticleManager:SetParticleControl(pidx, 3, color)
end


function CHoldoutGameSpawner:StatusReport()
	print( string.format( "** Spawner %s", self._szNPCClassName ) )
	print( string.format( "%d of %d spawned", self._nUnitsSpawnedThisRound, self._nTotalUnitsToSpawn ) )
end


function TestSpawn(name, spawner, player, team)
	local entSpawn = Entities:FindByName(nil, spawner)

	if entSpawn ~= nil then
		local point = entSpawn:GetOrigin()
		local unit = CreateUnitByName(name, point, true, nil, nil, team)
		unit:SetControllableByPlayer(player, false)
	else 
		print("Error: No Spawner found!")
	end
end


function SetPhasing(unit, time)
    if unit:IsNull() or not unit:IsAlive() then
        return
    end
    
    if time == 0 then

        unit:RemoveModifierByName("modifier_phasing_passive")
    else
        
        if unit.phasingApplier == nil then
            unit.phasingApplier = CreateItem("item_phasing_applier", unit, unit)
        end

        unit.phasingApplier:ApplyDataDrivenModifier(unit, unit, "modifier_phasing_passive", {duration=time})
    end
end