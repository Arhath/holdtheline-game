bottle_shop_ability_toggle = class({})
 
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

bottle_shop_ability_health_1 = class({})
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_health_1:CastFilterResultTarget( hTarget )
	return UF_SUCCESS
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_health_1:GetCustomCastErrorTarget( hTarget )
	return ""
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_health_1:GetCooldown( nLevel )
	return self.BaseClass.GetCooldown( self, nLevel )
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_health_1:OnSpellStart()
	
	local hCaster = self:GetCaster()
	local abilityName = self:GetAbilityName()

	if hCaster == nil then
		return
	end

	hCaster.BottleShop:OnSpellStart(abilityName)
end
 
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

bottle_shop_ability_health_2 = class({})
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_health_2:CastFilterResultTarget( hTarget )
	return UF_SUCCESS
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_health_2:GetCustomCastErrorTarget( hTarget )
	return ""
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_health_2:GetCooldown( nLevel )
	return self.BaseClass.GetCooldown( self, nLevel )
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_health_2:OnSpellStart()
	
	local hCaster = self:GetCaster()
	local abilityName = self:GetAbilityName()

	if hCaster == nil then
		return
	end

	hCaster.BottleShop:OnSpellStart(abilityName)
end
 
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

bottle_shop_ability_health_3 = class({})
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_health_3:CastFilterResultTarget( hTarget )
	return UF_SUCCESS
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_health_3:GetCustomCastErrorTarget( hTarget )
	return ""
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_health_3:GetCooldown( nLevel )
	return self.BaseClass.GetCooldown( self, nLevel )
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_health_3:OnSpellStart()
	
	local hCaster = self:GetCaster()
	local abilityName = self:GetAbilityName()

	if hCaster == nil then
		return
	end

	hCaster.BottleShop:OnSpellStart(abilityName)
end
 
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

bottle_shop_ability_health_4 = class({})
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_health_4:CastFilterResultTarget( hTarget )
	return UF_SUCCESS
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_health_4:GetCustomCastErrorTarget( hTarget )
	return ""
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_health_4:GetCooldown( nLevel )
	return self.BaseClass.GetCooldown( self, nLevel )
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_health_4:OnSpellStart()
	
	local hCaster = self:GetCaster()
	local abilityName = self:GetAbilityName()

	if hCaster == nil then
		return
	end

	hCaster.BottleShop:OnSpellStart(abilityName)
end
 
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

bottle_shop_ability_health_5 = class({})
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_health_5:CastFilterResultTarget( hTarget )
	return UF_SUCCESS
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_health_5:GetCustomCastErrorTarget( hTarget )
	return ""
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_health_5:GetCooldown( nLevel )
	return self.BaseClass.GetCooldown( self, nLevel )
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_health_5:OnSpellStart()
	
	local hCaster = self:GetCaster()
	local abilityName = self:GetAbilityName()

	if hCaster == nil then
		return
	end

	hCaster.BottleShop:OnSpellStart(abilityName)
end
 
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

bottle_shop_ability_health_6 = class({})
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_health_6:CastFilterResultTarget( hTarget )
	return UF_SUCCESS
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_health_6:GetCustomCastErrorTarget( hTarget )
	return ""
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_health_6:GetCooldown( nLevel )
	return self.BaseClass.GetCooldown( self, nLevel )
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_health_6:OnSpellStart()
	
	local hCaster = self:GetCaster()
	local abilityName = self:GetAbilityName()

	if hCaster == nil then
		return
	end

	hCaster.BottleShop:OnSpellStart(abilityName)
end
 
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

bottle_shop_ability_health_7 = class({})
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_health_7:CastFilterResultTarget( hTarget )
	return UF_SUCCESS
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_health_7:GetCustomCastErrorTarget( hTarget )
	return ""
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_health_7:GetCooldown( nLevel )
	return self.BaseClass.GetCooldown( self, nLevel )
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_health_7:OnSpellStart()
	
	local hCaster = self:GetCaster()
	local abilityName = self:GetAbilityName()

	if hCaster == nil then
		return
	end

	hCaster.BottleShop:OnSpellStart(abilityName)
end
 
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

bottle_shop_ability_mana_1 = class({})
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_mana_1:CastFilterResultTarget( hTarget )
	return UF_SUCCESS
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_mana_1:GetCustomCastErrorTarget( hTarget )
	return ""
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_mana_1:GetCooldown( nLevel )
	return self.BaseClass.GetCooldown( self, nLevel )
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_mana_1:OnSpellStart()
	
	local hCaster = self:GetCaster()
	local abilityName = self:GetAbilityName()

	if hCaster == nil then
		return
	end

	hCaster.BottleShop:OnSpellStart(abilityName)
end
 
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

bottle_shop_ability_mana_2 = class({})
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_mana_2:CastFilterResultTarget( hTarget )
	return UF_SUCCESS
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_mana_2:GetCustomCastErrorTarget( hTarget )
	return ""
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_mana_2:GetCooldown( nLevel )
	return self.BaseClass.GetCooldown( self, nLevel )
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_mana_2:OnSpellStart()
	
	local hCaster = self:GetCaster()
	local abilityName = self:GetAbilityName()

	if hCaster == nil then
		return
	end

	hCaster.BottleShop:OnSpellStart(abilityName)
end
 
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

bottle_shop_ability_mana_3 = class({})
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_mana_3:CastFilterResultTarget( hTarget )
	return UF_SUCCESS
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_mana_3:GetCustomCastErrorTarget( hTarget )
	return ""
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_mana_3:GetCooldown( nLevel )
	return self.BaseClass.GetCooldown( self, nLevel )
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_mana_3:OnSpellStart()
	
	local hCaster = self:GetCaster()
	local abilityName = self:GetAbilityName()

	if hCaster == nil then
		return
	end

	hCaster.BottleShop:OnSpellStart(abilityName)
end
 
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

bottle_shop_ability_mana_4 = class({})
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_mana_4:CastFilterResultTarget( hTarget )
	return UF_SUCCESS
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_mana_4:GetCustomCastErrorTarget( hTarget )
	return ""
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_mana_4:GetCooldown( nLevel )
	return self.BaseClass.GetCooldown( self, nLevel )
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_mana_4:OnSpellStart()
	
	local hCaster = self:GetCaster()
	local abilityName = self:GetAbilityName()

	if hCaster == nil then
		return
	end

	hCaster.BottleShop:OnSpellStart(abilityName)
end
 
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

bottle_shop_ability_mana_5 = class({})
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_mana_5:CastFilterResultTarget( hTarget )
	return UF_SUCCESS
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_mana_5:GetCustomCastErrorTarget( hTarget )
	return ""
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_mana_5:GetCooldown( nLevel )
	return self.BaseClass.GetCooldown( self, nLevel )
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_mana_5:OnSpellStart()
	
	local hCaster = self:GetCaster()
	local abilityName = self:GetAbilityName()

	if hCaster == nil then
		return
	end

	hCaster.BottleShop:OnSpellStart(abilityName)
end
 
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

bottle_shop_ability_mana_6 = class({})
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_mana_6:CastFilterResultTarget( hTarget )
	return UF_SUCCESS
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_mana_6:GetCustomCastErrorTarget( hTarget )
	return ""
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_mana_6:GetCooldown( nLevel )
	return self.BaseClass.GetCooldown( self, nLevel )
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_mana_6:OnSpellStart()
	
	local hCaster = self:GetCaster()
	local abilityName = self:GetAbilityName()

	if hCaster == nil then
		return
	end

	hCaster.BottleShop:OnSpellStart(abilityName)
end
 
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

bottle_shop_ability_mana_7 = class({})
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_mana_7:CastFilterResultTarget( hTarget )
	return UF_SUCCESS
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_mana_7:GetCustomCastErrorTarget( hTarget )
	return ""
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_mana_7:GetCooldown( nLevel )
	return self.BaseClass.GetCooldown( self, nLevel )
end
 
--------------------------------------------------------------------------------
 
function bottle_shop_ability_mana_7:OnSpellStart()
	
	local hCaster = self:GetCaster()
	local abilityName = self:GetAbilityName()

	if hCaster == nil then
		return
	end

	hCaster.BottleShop:OnSpellStart(abilityName)
end
 
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
