bottle_health = class({})
 
--------------------------------------------------------------------------------
 
function bottle_health:CastFilterResultTarget( hTarget )
	--[[if self:GetCaster() == hTarget then
		return UF_FAIL_CUSTOM
	end
 
	if ( hTarget:IsCreep() and ( not self:GetCaster():HasScepter() ) ) or hTarget:IsAncient() then
		return UF_FAIL_CUSTOM
	end
 
	local nResult = UnitFilter( hTarget, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, self:GetCaster():GetTeamNumber() )
	if nResult ~= UF_SUCCESS then
		return nResult
	end]]
 
	return UF_SUCCESS
end
 
--------------------------------------------------------------------------------
 
function bottle_health:GetCustomCastErrorTarget( hTarget )
	--[[if self:GetCaster() == hTarget then
		return "#dota_hud_error_cant_cast_on_self"
	end
 
	if hTarget:IsAncient() then
		return "#dota_hud_error_cant_cast_on_ancient"
	end
 ]]
	--if hTarget:IsCreep() then
	--	return "#dota_hud_error_cant_cast_on_creep"
	--end
 
	return ""
end
 
--------------------------------------------------------------------------------
 
function bottle_health:GetCooldown( nLevel )
	return self.BaseClass.GetCooldown( self, nLevel )
end
 
--------------------------------------------------------------------------------
 
function bottle_health:OnSpellStart()
	--[[local hCaster = self:GetCaster()
	local hTarget = self:GetCursorTarget()
 
	if hCaster == nil or hTarget == nil or hTarget:TriggerSpellAbsorb( this ) then
		return
	end
 
	local vPos1 = hCaster:GetOrigin()
	local vPos2 = hTarget:GetOrigin()
 
	GridNav:DestroyTreesAroundPoint( vPos1, 300, false )
	GridNav:DestroyTreesAroundPoint( vPos2, 300, false )
 
	hCaster:SetOrigin( vPos2 )
	hTarget:SetOrigin( vPos1 )
 
	FindClearSpaceForUnit( hCaster, vPos2, true )
	FindClearSpaceForUnit( hTarget, vPos1, true )
 
	hTarget:Interrupt()
 
	local nCasterFX = ParticleManager:CreateParticle( "particles/units/heroes/hero_vengeful/vengeful_nether_swap.vpcf", PATTACH_ABSORIGIN_FOLLOW, hCaster )
	ParticleManager:SetParticleControlEnt( nCasterFX, 1, hTarget, PATTACH_ABSORIGIN_FOLLOW, nil, hTarget:GetOrigin(), false )
	ParticleManager:ReleaseParticleIndex( nCasterFX )
 
	local nTargetFX = ParticleManager:CreateParticle( "particles/units/heroes/hero_vengeful/vengeful_nether_swap_target.vpcf", PATTACH_ABSORIGIN_FOLLOW, hTarget )
	ParticleManager:SetParticleControlEnt( nTargetFX, 1, hCaster, PATTACH_ABSORIGIN_FOLLOW, nil, hCaster:GetOrigin(), false )
	ParticleManager:ReleaseParticleIndex( nTargetFX )
 
	EmitSoundOn( "Hero_VengefulSpirit.NetherSwap", hCaster )
	EmitSoundOn( "Hero_VengefulSpirit.NetherSwap", hTarget )
 
	hCaster:StartGesture( ACT_DOTA_CHANNEL_END_ABILITY_4 )
	]]

	local hCaster = self:GetCaster()
	local hTarget = self:GetCursorTarget()

	if hCaster == nil or hTarget == nil then
		return
	end

	if hCaster.BottleSystem == nil then
		return
	end

	local bUseBottle = GameRules.holdOut._bottleSystem:HeroUseBottle(hCaster, hTarget, BOTTLE_HEALTH)

	if bUseBottle then
		--hTarget:AddNewModifier(handle caster, handle optionalSourceAbility, string modifierName, handle modifierData)
		print("ability used health bottle !!!")
	end
end
 
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------