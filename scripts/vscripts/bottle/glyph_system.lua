GLYPH_TYPE_ =
{
	MANA = 1,
}

GLYPH_BOTTLE_TYPE_ =
{
	BOTTLE_HEALTH,
}

GLYPH_ITEM_NAME_ =
{
	"item_glyph_mana",
}

GLYPH_ABILITY_ =
{
	"glyph_ability_mana",
}

GLYPH_MODIFIER_SHOW_ =
{
	"modifier_glyph_mana_show",
}

GLYPH_MODIFIER_ =
{
	"modifier_glyph_mana",
}

GLYPH_MODIFIER_STACKS_ =
{
	{
		5,
	},

	{
		9,
	},

	{
		17,
	}
}

GLYPH_DURATION_ =
{
	{
		10,
	},

	{
		15,
	},

	{
		20,
	}
}

GLYPH_RADIUS_ =
{
	{
		500,
	},

	{
		1000,
	},

	{
		1500,
	}
}

function IsValidGlyph(nType)
	for _, glyph in pairs(GLYPH_TYPE_) do
		if glyph == nType then
			return true
		end
	end

	return false
end


function IsGLyph( item )
	for _, str in pairs(GLYPH_ITEM_NAME_) do
		if str == item:GetName() then
			return true
		end
	end

	return false
end



if CGlyphObj == nil then
	CGlyphObj = class({})
end


function CGlyphObj:CreateGlyph(nType, lvl, system)
	local glyphObj = CGlyphObj()

	if glyphObj:Init(nType, lvl, system) then
		return glyphObj
	else

		return nil
	end
end


function CGlyphObj:Init(nType, lvl, system)
	if not IsValidGlyph(nType) then
		return false
	end

	--print(GLYPH_ITEM_NAME_[nType])
	self._entGlyph = CreateItem(GLYPH_ITEM_NAME_[nType], nil, nil)

	if self._entGlyph == nil then
		--print("couldnt create item")
		return false
	end
	--print("created item")
	self._entGlyphIndex = self._entGlyph:entindex()
	self._bottleSystem = system
	self._nType = nType
	self._nBottleType = GLYPH_BOTTLE_TYPE_[nType]
	self._entOwner = nil
	self._nLevel = lvl

	self._posSpawn = nil
	self._fSpawnTime = nil

	self._strModifier = GLYPH_MODIFIER_[self._nType]
	self._fDuration = GLYPH_DURATION_[self._nLevel][self._nType]
	self._nStacks = GLYPH_MODIFIER_STACKS_[self._nLevel][self._nType]

	self._fTimer = 0
	self._fLastTick = 0
	self._nTargets = 0

	return true
end


function CGlyphObj:PickUp( hero )
	self._entOwner = hero
	ApplyModifier(self._entOwner, self._entOwner, GLYPH_MODIFIER_SHOW_[GLYPH_BOTTLE_TYPE_[self._nType]], {Duration = -1}, true)
end


function CGlyphObj:GetAbility()
	return GLYPH_ABILITY_[self.nType]
end

function CGlyphObj:GetLevel()
	return self._nLevel
end


function CGlyphObj:Activate()
	DebugDrawText(self._entOwner:GetAbsOrigin(), "glyph activated", true, 4)
	self._entOwner:RemoveModifierByName(GLYPH_MODIFIER_SHOW_[GLYPH_BOTTLE_TYPE_[self._nType]])
	
	local teamEnemy = DOTA_TEAM_BADGUYS

	if self._entOwner:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
		teamEnemy = DOTA_TEAM_BADGUYS
	end

	local targets = FindUnitsInRadius(teamEnemy, self._entOwner:GetAbsOrigin(), nil, GLYPH_RADIUS_[self._nLevel][self._nType], self._entOwner:GetTeamNumber(), DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)
	self._nTargets = #targets

	for _, target in pairs(targets) do
		--target:RemoveModifierByName(GLYPH_MODIFIER_[self._nType])
		local stacks = target:GetModifierStackCount(self._strModifier, self._entOwner)
		target:RemoveModifierByName(self._strModifier)
		ApplyModifier(self._entOwner, target, self._strModifier, {Duration=self._fDuration})
		target:SetModifierStackCount(self._strModifier, self._entOwner, stacks + self._nStacks)
	end

	self._fLastTick = GameRules:GetGameTime()
	Timers:CreateTimer(function()
		return self:GlyphThink(targets)
	end
	)
end


function CGlyphObj:GlyphThink( targets )
	local timePassed = GameRules:GetGameTime() - self._fLastTick
	self._fLastTick = GameRules:GetGameTime()

	for _, target in pairs(targets) do

		if target.BottleSystem ~= nil and self._fTimer <= self._fDuration then
			--print("hasmodifier mana")
			local reg = self._nStacks * math.min(self._fDuration - self._fTimer, timePassed)
			DebugDrawText(target:GetAbsOrigin(), string.format("reg: %f dur: %f / %f stacks: %d", reg, self._fDuration, self._fTimer, self._nStacks), true, timePassed)

			if self._nType == 1 then
				self._bottleSystem:BottleAddCharges(target, BOTTLE_HEALTH, reg)
				self._bottleSystem:BottleAddCharges(target, BOTTLE_MANA, reg)
			end

		else

			--print("no modifier mana")
			local stacks = target:GetModifierStackCount(self._strModifier, self._entOwner)

			DebugDrawText(target:GetAbsOrigin(), string.format("stacks: %d", stacks), true, 7)

			if stacks > self._nStacks then
				target:SetModifierStackCount(self._strModifier, self._entOwner, stacks - self._nStacks)
			else
				target:RemoveModifierByName(self._strModifier)
			end

			self._nTargets = self._nTargets - 1

		end
	end

		if self._nTargets == 0 then
				self._fTimer = 0

			for i, glyph in pairs(self._bottleSystem._vGlyphs) do
				if glyph == self then
					if glyph._entGlyph ~= nil and not glyph._entGlyph:IsNull() then
						UTIL_Remove(glyph._entGlyph)
					end

					if glyph._entItem3D ~= nil and not glyph._entItem3D:IsNull() then
						UTIL_Remove(glyph._entItem3D)
					end

					table.remove(self._bottleSystem._vGlyphs, i)
					print("removingGlyph")
					print(#self._bottleSystem._vGlyphs)
				end
			end

			return nil
		else
			self._fTimer = self._fTimer + timePassed

			return self:GetTickrate()
		end
end


function CGlyphObj:GetBottleType()
	--print(string.format("bottle type: %d", self._nBottleType))
	return self._nBottleType
end


function CGlyphObj:SpawnOnPosition(pos)
	self._entItem3D = CreateItemOnPositionSync(pos, self._entGlyph)
	self._fSpawnTime = GameRules:GetGameTime()
	--self._entGlyph:LaunchLootInitialHeight(true, 3000, 3000, 4, pos + RandomVector( RandomFloat( 50, 200 ) ))--LaunchLoot( true, 0, 1.0, pos + RandomVector( RandomFloat( 0, 0 ) ) )
end


function CGlyphObj:GetTickrate()
	return 0.25
end