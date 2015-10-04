if CQuestGiver == nil then
	CQuestGiver = class({})
end

function CQuestGiver:CreateQuestGiver( giver, trigger, questSystem )
	local questGiver = CQuestGiver()
	if questGiver:Init(giver, trigger, questSystem) then
		return questGiver
	end
	
	return nil
end

function CQuestGiver:Init( giver, trigger, questSystem )
	self._entGiver = Entities:FindByName(nil, giver)
	if self._entGiver == nil then
		print("giver not found")
		return nil
	end

	self._entTrigger = Entities:FindByName(nil, trigger)
	if self._entTrigger == nil then
		print("trigger not found")
		return nil
	end

	self._entGiver:AddNewModifier( self._entGiver, nil, "modifier_invulnerable", {} )

	self._entTrigger.Giver = self
	self._QuestSystem = questSystem
	self._nCurrentQuest = 0
	self._vQuestTaker = {}
	self._TICKRATE = 0.25

	Timers:CreateTimer(function()	
		return self:Think()
	end

	return self
end

function CQuestGiver:Think()
	if not self._vQuestTaker:IsNull() then
		self._entGiver:SetControllableByPlayer(self.vQuestTaker[1]:GetPlayerOwnerID(), true)
	else
		-- lose all Control
	end

	return self._TICKRATE
end

function CQuestGiver:AddQuestTaker( unit )
	print("adding QuestTaker")
	if unit.QuestSystem == nil then
		return
	end

	local bSetUnit = true

	for _, u in pairs(self._vQuestTaker) do
		if u == unit then
			bSetUnit = false
			break
		end
	end

	if bSetUnit then
		print("inserting QuestTaker into table")
		table.insert(self._vQuestTaker, unit)
	end
end

function CQuestGiver:RemoveQuestTaker( unit )
	for n, u in pairs(self._vQuestTaker) do
		if u == unit then
			print("removing QuestTaker from table")
			table.remove(self._vQuestTaker, n)
			break
		end
	end
end