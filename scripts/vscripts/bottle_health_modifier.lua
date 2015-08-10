bottle_health_modifier = class({})

--------------------------------------------------------------------------------
 
function bottle_health_modifier:OnIntervalThink()
	if IsServer() then
		self:StartIntervalThink( -1 )
	end
end
 
--------------------------------------------------------------------------------

function bottle_health_modifier:OnAbilityExecuted( params )
	if IsServer() then
		if params.unit == self:GetParent() then
 
			local hAbility = params.ability 
			if hAbility ~= nil and hAbility:GetName() == "bottle_health" then
				self:ForceRefresh()
 
				self:SetDuration( 2, true )
				self:StartIntervalThink( 2 )
			end
		end
	end

	return 0
end