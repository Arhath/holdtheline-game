--[[ utility_functions.lua ]]

---------------------------------------------------------------------------
-- Handle messages
---------------------------------------------------------------------------


function ApplyModifier(source, target, modifier_name, modifierArgs, overwrite)
    if not overwrite and target:HasModifier(modifier_name) then
        return nil
    end

    if source.ModifierApplier == nil then
        source.ModifierApplier = CreateItem("item_modifier_applier", source, source)
    end
    
    source.ModifierApplier:ApplyDataDrivenModifier(source, target, modifier_name, modifierArgs)
end


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


function ListFilterWithFn( t, fn )

    if not t then
        return {}
    end

    local result = {}

    for i = 1, #t do
        if fn( t[i] ) then
            table.insert( result, t[i] )
        end
    end

    return result
end


function ExistsInList( list, entity )
    for i = 1, #list do
        if list[i] == entity then
            return true
        end
    end

    return false
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

function GetMidpointBetweenPoints( v1, v2 )
    local v3 = Vector((v1.x + v2.x) / 2, (v1.y + v2.y) / 2, 0)

    return v3
end

function GetAllMidpointsWithMinMaxDist(list, min, max)
    local vec = {}

    for n1 = 1, #list - 1 do
        for n2 = n1 + 1, #list do
            local p1 = list[n1]
            local p2 = list[n2]
            local length = (p2 - p1):Length()
            
            if length >= min and length <= max then
                local p3 = GetMidpointBetweenPoints(p1, p2)
                table.insert(vec, p3)
            end
        end
    end

    return vec
end



function UnitTeleportToPosition( unit, pos, stop )
    unit:SetAbsOrigin(pos)
    FindClearSpaceForUnit(unit, pos, false)

    if stop then
      unit:Stop()
    end
end


function UnitIsDead( unit )
	if unit:IsNull() then
		return true
	else
		return not unit:IsAlive()
	end
end



function SafeSpawnCreature(name, pos, aoe, height, npcOwner, unitOwner, team)
    local spawn = pos

    repeat
        local bSpawn = true

        if aoe > 0 then
            spawn = GetRandomPointInAoe(pos, aoe)
        end

        if height >= 0 then
            local posHeight = GetGroundHeight(pos, nil)

            if posHeight ~= height then
                bSpawn = false
            end
        end

        if bSpawn then
             local hullsize = 35
             local vUnits = FindUnitsInRadius( DOTA_TEAM_GOODGUYS, spawn, nil, hullsize, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, 0, 0, false )

             if #vUnits ~= 0 then
                 bSpawn = false
             end
        end
    until bSpawn

    local unit = CreateUnitByName( name, spawn, true, npcOwner, unitOwner, team )

    return unit
end


function GetRandomPointInAoe( pos, aoe )
	local u = RandomFloat(0, 1)
	local v = RandomFloat(0, 1)

	local w = aoe * math.sqrt(u)
  	local t = 2 * math.pi * v
 	local x = w * math.cos(t) 
  	local y = w * math.sin(t)

    return pos + Vector(x, y, 0)
end


function UnitGetBestRetreatPositionInAoe( unit, aoe )
    local vUnits = FindUnitsInRadius( unit:GetTeamNumber(), unit:GetOrigin(), nil, aoe, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, 0, false )
    local resultVec = unit:GetAbsOrigin()

    for n, u in pairs(vUnits) do
        local vec = unit:GetAbsOrigin() -  u:GetAbsOrigin()
        --vec = vec * aoe / (aoe - vec:Length() + 1)
        resultVec = resultVec + vec
        DebugDrawLine(unit:GetAbsOrigin(), u:GetAbsOrigin(), 255, 255, 255, true, 1)

       -- if n == #vUnits then
            --resultVec = resultVec / n
       -- end
    end

    return resultVec
end


function Roate2DVector ( vec, angle )
  local result = Vector(0, 0 ,0)
  angle = math.rad(angle)

  result.x = math.cos(angle) - vec.y * math.sin(angle);
  result.y = math.sin(angle) + vec.y * math.cos(angle);

  return result;
end


function GetPointWithPolarOffset( pos, angle, offset )
    local result = Vector(0, 0, 0)
    angle = math.rad(angle)

    result.x = pos.x + math.cos(angle) * offset
    result.y = pos.y + math.sin(angle) * offset
    --print("point with offset")

    return result
end


function UnitFindBestTargetPositionInAoe(unit, search, aoeMax, aoeMin, team, who)
    local diaMax = aoeMax * 2
    local diaMin = aoeMin * 2
    local vEnemyPos = {}
    local vMidpoints = {}
    local bestPoint = nil
    local bestNumUnits = -1
    local vUnits = FindUnitsInRadius( unit:GetTeamNumber(), unit:GetOrigin(), nil, search, team, who, 0, 0, false )

    if #vUnits == 1 then
        return vUnits[1]:GetAbsOrigin()
    end

    for _, u in pairs(vUnits) do
        table.insert(vEnemyPos, u:GetAbsOrigin())
    end

    for i = 0, 3 do
        local mPoints = GetAllMidpointsWithMinMaxDist(vEnemyPos, diaMin, diaMax)
        for k = 1, #mPoints do
            table.insert(vMidpoints, mPoints[k])
        end
    end

    for _, p in pairs(vMidpoints) do
        unitsInAoe = FindUnitsInRadius( unit:GetTeamNumber(), p, nil, aoeMax, team, who, 0, 0, false )

        if #unitsInAoe >= bestNumUnits then
            bestPoint = p
            bestNumUnits = #unitsInAoe
        end
    end

    return bestPoint
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
        ApplyModifier(unit, unit, "modifier_phasing_passive", {duration=time})
    end
end