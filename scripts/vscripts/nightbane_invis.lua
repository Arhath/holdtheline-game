function InvisTracker( event )
	local caster = event.caster

	if not caster:IsInvisible() and not caster:IsAttacking()  then
		caster:AddNewModifier(caster, nil, "modifier_invisible", {})	
	end


end