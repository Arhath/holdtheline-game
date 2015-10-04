function OnTakeDamage( event )

	local caster = event.caster
	local target = event.attacker
	local ability = event.ability
	local ability_level = ability:GetLevel() - 1

	local duration = ability:GetLevelSpecialValueFor("duration", ability_level)
	local dps = ability:GetLevelSpecialValueFor("damage", ability_level) 
	local stunning_stacks = ability:GetLevelSpecialValueFor("stunning_stacks", ability_level) 

	-- Modifiers
	local modifier_debuff = event.modifier_debuff
	local modifier_stun = event.modifier_stun

	if not target:HasModifier(modifier_debuff) then
		local modifier = ability:ApplyDataDrivenModifier(caster, target, modifier_debuff, { Duration = duration} )

		Timers:CreateTimer(function()
			local nStacks = target:GetModifierStackCount(modifier_debuff, caster)

			local damageTable = {
				victim = target,
				attacker = caster,
				damage = nStacks * dps ,
				damage_type = DAMAGE_TYPE_MAGICAL,
			}

			ApplyDamage(damageTable)

			if nStacks >= stunning_stacks and not target:HasModifier(modifier_stun) then
				ability:ApplyDataDrivenModifier(caster, target, modifier_stun, {Duration = -1} )
			elseif nStacks < stunning_stacks then
				target:RemoveModifierByName(modifier_stun)
			end

			local hMod = target:FindModifierByName(modifier_debuff)

			if hMod and modifier == hMod then
				return 1
			else
				return nil
			end
		end
		)
	end 
	
	local nStacks = target:GetModifierStackCount(modifier_debuff, caster)
	local modifier = target:FindModifierByName(modifier_debuff)

	target:SetModifierStackCount(modifier_debuff, caster, nStacks + 1)
	
	modifier:ForceRefresh()	
end
