bottle_health = class({})
 
--------------------------------------------------------------------------------
 
function bottle_health:CastFilterResultTarget( hTarget )
	return UF_SUCCESS
end
 
--------------------------------------------------------------------------------
 
function bottle_health:GetCustomCastErrorTarget( hTarget )
	return ""
end
 
--------------------------------------------------------------------------------
 
function bottle_health:GetCooldown( nLevel )
	return self.BaseClass.GetCooldown( self, nLevel )
end
 
--------------------------------------------------------------------------------
 
function bottle_health:OnSpellStart()

	local hCaster = self:GetCaster()
	local hTarget = self:GetCursorTarget()

	if hCaster == nil or hTarget == nil then
		return
	end

	if hCaster.BottleSystem == nil then
		return
	end

	local bUseBottle = GameRules.holdOut._bottleSystem:HeroUseBottle(hCaster, hTarget, BOTTLE_HEALTH)

	if bUseBottle then
		print("ability used health bottle !!!")
	end
end
 
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------