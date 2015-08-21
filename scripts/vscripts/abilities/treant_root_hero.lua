function OnSpell(event)

	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local posTarget = target:GetAbsOrigin()
	local particle = event.particle
	caster.target = target or 0
	
	print("OnSpellSucess")
	local modifier_root = event.modifier_root
	local modifier_target = event.modifier_target
	
	-- Plant Root	
	caster.root = CreateUnitByName("treant_root", posTarget, false, nil, nil, caster:GetTeamNumber())
	
	--target.particle = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN, target)
	
	--Apply Debuff
	ability:ApplyDataDrivenModifier(caster, caster.root, modifier_root, {})
	ability:ApplyDataDrivenModifier(caster, target, modifier_target, {})
	
	--Kill root after 20 sec
	caster.root:AddNewModifier(caster, nil, "modifier_kill", {duration = 20})
end

function RootDeath(event)
	local modifier_target = event.modifier_target
	local caster = event.caster
	local target = event.target
	
	caster.target:RemoveModifierByName(modifier_target)
end

function TargetDeath( event )
	local caster = event.caster
	target = caster.target

	UTIL_RemoveImmediate(caster.root)
end