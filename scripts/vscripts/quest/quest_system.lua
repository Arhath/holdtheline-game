require( "misc/utility_functions" )
require( "quest/quest_giver" )
require( "quest/quests")

if CQuestSystem == nil then
	CQuestSystem = class({})
end

-- QUESTS:

QUEST_LAB_POTION = {"quest_lab_potion_red", "quest_lab_potion_blue"}							-- 1
QUEST_TRAP = {"quest_trap_", "quest_trap_"}														-- 2
QUEST_EXTRA_WAVE = {"quest_extra_wave_", "quest_extra_wave_"}										-- 3
QUEST_TRANSPORT_MISSION = {"quest_transport_mission_forward", "quest_transport_mission_backward"}	-- 4

QUEST_LIST = {QUESTS_LAB_POTION, QUESTS_TRAP, QUESTS_EXTRA_WAVE, QUESTS_TRANSPORT_MISSION}


function CQuestSystem:Init( gameMode, team )
	self._gameMode = gameMode
	self._nTeam = team
	self._vQuestGiver = {}
	self._nCurrentQuest = 0

	self:InitQuestGiver()
end

function CQuestSystem:InitQuestGiver( ... )
	local i = 1
	while Entities:FindByName(nil, "quest_giver" .. i) ~= nil do
		local questGiver = CQuestGiver:CreateQuestGiver("quest_giver" .. i, "quest_giver_trigger" .. i, self)
		CQuestSystem:SetQuest(questGiver, 0)
		table.insert(self._vQuestGiver, questGiver)
		i = i + 1
	end
end


function CQuestSystem:SetQuest( nQuest )
	for n, u in pairs(self._vQuestGiver) do
		u:AddAbility(QUEST_LIST[nQuest][n])
	end
end

function CQuestSystem:StartQuest( nQuest )

	for n, u in pairs(self._vQuestGiver) do
		u:RemoveAbility(QUEST_LIST[nQuest][n])
	end
end

function CQuestSystem:EndQuest( )
	-- body
end
