--Lobby modifications for meteor map comptibility detection
--Duck42
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

--Lobby modifications for meteor map comptibility detection
--7/20/2013
--Mead/Duck42
table.insert(factionBmps, "/faction_icon-sm/random_ico_no_uef.dds")
table.insert(factionTooltips, 'lob_random_no_uef')

function GetRandomFactionIndex_noUEF()
    local randomfaction
    --Loop 50 times (see LUA documentation on math.random)
    for i = 1, 50 do
        --Exclude UEF from selection range
        randomfaction = math.random(2, table.getn(FactionData.Factions))
    end
    return randomfaction
end

local PX_oldAssignRandomFactions = AssignRandomFactions
function AssignRandomFactions(gameInfo)	
    --Handle the "Random - No UEF" option
    local randomFactionID_noUEF = table.getn(FactionData.Factions) + 2
    
    for index, player in gameInfo.PlayerOptions do
        if player.Faction >= randomFactionID_noUEF then
            player.Faction = GetRandomFactionIndex_noUEF()
        end
    end
        
    --Handle the regular "Random" option
    --Note tha by this point, any "Random - No UEF" players should have a faction and so, should not be assigned another
    PX_oldAssignRandomFactions(gameInfo)
end

--Help UI Changes
local PhantomX_Original_CreateUI = CreateUI

function CreateUI(maxPlayers)
	PhantomX_Original_CreateUI(maxPlayers)
	CreatePhantomLobbyUI()
end

function CreatePhantomLobbyUI()
	--This function handles creation of Phantom-X lobby UI elements (buttons, tooltips, etc)
    GUI.showPhantomXHelp = UIUtil.CreateButtonStd(GUI.panel, '/BUTTON/small/', 'About Phantom-X', 9, 0)
	LayoutHelpers.AtLeftTopIn(GUI.showPhantomXHelp, GUI.panel, GUI.panel.Width()-218, 320)
	
	GUI.showPhantomXHelp.OnClick = function(self, modifiers)
		import('/modules/help_ui.lua').ShowPhantomXHelpDialog(GUI.panel)
	end
end