modifier_boss_difficulty = class({})
LinkLuaModifier( "modifier_boss_difficulty", LUA_MODIFIER_MOTION_NONE )


function modifier_boss_difficulty:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_COOLDOWN_REDUCTION_CONSTANT,
		MODIFIER_PROPERTY_EXTRA_HEALTH_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT_SECONDARY,
	}
 
	return funcs
end
 
--------------------------------------------------------------------------------
 
function modifier_boss_difficulty:GetModifierDamageOutgoing_Percentage( params )
	return 10
end
 
--------------------------------------------------------------------------------
 
function modifier_boss_difficulty:GetModifierCooldownReduction_Constant( params )
	return 0.1
end

 --------------------------------------------------------------------------------
 
function modifier_boss_difficulty:GetModifierExtraHealthPercentage( params )
	return 100
end

 --------------------------------------------------------------------------------
 
function modifier_boss_difficulty:GetModifierAttackSpeedBonus_Constant_Secondary( params )
	return 0.5
end