gate_ability_fortify_toggle = class({})
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_toggle:CastFilterResultTarget( hTarget )
	return UF_SUCCESS
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_toggle:GetCustomCastErrorTarget( hTarget )
	return ""
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_toggle:GetCooldown( nLevel )
	return self.BaseClass.GetCooldown( self, nLevel )
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_toggle:OnSpellStart()

	local hCaster = self:GetCaster()
	local abilityName = self:GetAbilityName()

	if hCaster == nil then
		return
	end

	hCaster.BottleShop:OnSpellStart(abilityName)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------