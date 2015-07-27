modifier_netherworld_buff = class({})
LinkLuaModifier( "modifier_netherworld_buff", LUA_MODIFIER_MOTION_NONE )


function modifier_netherworld_buff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE	,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT_SECONDARY,
	}
 
	return funcs
end
 
--------------------------------------------------------------------------------
 
function modifier_netherworld_buff:GetModifierDamageOutgoing_Percentage( params )
	return 20
end
 
--------------------------------------------------------------------------------
 
function modifier_netherworld_buff:GetModifierAttackRangeBonus( params )
	return 150
end

 --------------------------------------------------------------------------------
 
function modifier_netherworld_buff:GetModifierIncomingDamage_Percentage( params )
	return 0.8
end

 --------------------------------------------------------------------------------
 
function modifier_netherworld_buff:GetModifierAttackSpeedBonus_Constant_Secondary( params )
	return 20.0
end