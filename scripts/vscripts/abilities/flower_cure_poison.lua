function OnTakeDamage( event )
	
	print("hey ho lets go")
	local target = event.attacker
	local ability = event.ability
	local ability_level = ability:GetLevel() - 1

	local cure_count = ability:GetLevelSpecialValueFor("cure_count", ability_level) 
	local modifier_debuff = event.modifier_debuff

	local modifier = target:FindModifierByName("modifier_corrosive_skin_debuff")

	if modifier then
		local nStacks = target:GetModifierStackCount("modifier_corrosive_skin_debuff", target)
		print(nstacks)
		if nStacks <= cure_count then
			target:RemoveModifierByName("modifier_corrosive_skin_debuff")
		else
			target:SetModifierStackCount("modifier_corrosive_skin_debuff", target, nStacks - cure_count)
		end
	end

end