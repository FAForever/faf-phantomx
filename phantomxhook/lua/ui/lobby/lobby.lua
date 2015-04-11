--Lobby modifications for meteor map compatibility detection
--7/20/2013
--Mead/Duck42

local PX_oldRefreshOptionDisplayData = RefreshOptionDisplayData
function RefreshOptionDisplayData(scenarioInfo)
    PX_oldRefreshOptionDisplayData(scenarioInfo)
    if not MapHasCivilianArmy(scenarioInfo) then
        for i, v in formattedOptions do
            if v.tooltip == 'PhantomX_Meteor' then
                v.value = 'Incompatible Map'
            end
        end
		for i, v in nonDefaultFormattedOptions do
            if v.text == '<LOC phantomx_0260>P-X: Meteors' then
                v.value = 'Incompatible Map'
            end
        end
    end
    if GUI.OptionContainer.CalcVisible then
        GUI.OptionContainer:CalcVisible()
    end
end

function MapHasCivilianArmy(scenario)
    if scenario.Configurations.standard and scenario.Configurations.standard.customprops then
        local props = scenario.Configurations.standard.customprops
        if props.ExtraArmies then
            local armies = STR_GetTokens(props.ExtraArmies,' ')
            for i, armyName in armies do
                if armyName == 'NEUTRAL_CIVILIAN' then
                    return true
                end
            end
        end
    end
    return false
end

--Random, but not UEF faction option
FACTION_NAMES[6] = "random"

local RandomNoUEFFaction = {
        Key = 'randomNoUEF',
        DisplayName = "Random, but not UEF",        
        SmallIcon = "/faction_icon-sm/random_ico_no_uef.dds",
        TooltipID = 'lob_random_no_uef',
    }
	
table.insert(FactionData.Factions, RandomNoUEFFaction)

local LobbyManager_Original_CreateSlotsUI = CreateSlotsUI


local function GetRandomFactionIndex()
    local randomfaction = nil
    local counter = 50
    while counter > 0 do
        counter = (counter - 1)
        randomfaction = math.random(1, table.getn(FactionData.Factions)-1)
    end
    return randomfaction
end

function GetRandomFactionIndex_noUEF()
    local randomfaction
	local counter = 50
	
    --Loop 50 times (see LUA documentation on math.random)
	while counter > 0 do
		--Exclude UEF from selection range
        counter = (counter - 1)
        randomfaction = math.random(2, table.getn(FactionData.Factions)-1)
    end
    return randomfaction
end

local PX_oldAssignRandomFactions = AssignRandomFactions
function AssignRandomFactions()
    --Handle the "Random - No UEF" option
	local randomNoUEFFactionID = table.getn(FactionData.Factions)
    for index, player in gameInfo.PlayerOptions do
		if player.Faction == randomNoUEFFactionID then
            player.Faction = GetRandomFactionIndex_noUEF()
        end
    end
        
    --Handle the regular "Random" option
    --Note that by this point, any "Random - No UEF" players should have a faction and so, should not be assigned another
    PX_oldAssignRandomFactions()
end

--Help UI Changes
local PhantomX_Original_CreateUI = CreateUI

function CreateUI(maxPlayers)
	PhantomX_Original_CreateUI(maxPlayers)
	CreatePhantomLobbyUI()
end

function CreatePhantomLobbyUI()
	--This function handles creation of Phantom-X lobby UI elements (buttons, tooltips, etc)
	
    GUI.showPhantomXHelp = UIUtil.CreateButtonWithDropshadow(GUI.panel, '/BUTTON/medium/', 'How To Play')
	LayoutHelpers.AtLeftIn(GUI.showPhantomXHelp, GUI.chatPanel, 190)
    LayoutHelpers.AtVerticalCenterIn(GUI.showPhantomXHelp, GUI.launchGameButton, -6)
	
	GUI.showPhantomXHelp.OnClick = function(self, modifiers)
		import('/modules/help_ui.lua').ShowPhantomXHelpDialog(GUI.panel)
	end
end