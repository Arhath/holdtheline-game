function DestroyTree(event)	
	local target = event.target
	local treeClass = target:GetClassname()
	local caster = event.caster
	
	if treeClass == "ent_dota_tree" then
		target:CutDown(caster:GetTeamNumber())
	else
		UTIL_RemoveImmediate( target )
	end
end