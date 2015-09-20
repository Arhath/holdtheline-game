gate_ability_fortify = class({})
 
--------------------------------------------------------------------------------
 
function gate_ability_fortify:CastFilterResultTarget( hTarget )
	return UF_SUCCESS
end
 
--------------------------------------------------------------------------------
 
function gate_ability_fortify:GetCustomCastErrorTarget( hTarget )
	return ""
end
 
--------------------------------------------------------------------------------
 
function gate_ability_fortify:GetCooldown( nLevel )
	return self.BaseClass.GetCooldown( self, nLevel )
end
 
--------------------------------------------------------------------------------
 
function gate_ability_fortify:OnSpellStart()

	local hCaster = self:GetCaster()
	local abilityName = self:GetAbilityName()

	if hCaster == nil then
		return
	end

	hCaster.Gate:Fortifie()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------