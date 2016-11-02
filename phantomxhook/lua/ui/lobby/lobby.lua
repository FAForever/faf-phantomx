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
FACTION_NAMES[5] = "randomNoUEF"
FACTION_NAMES[6] = "random"

local RandomNoUEFFaction = {
        Key = 'randomNoUEF',
        DisplayName = "Random, but not UEF",        
        SmallIcon = "/faction_icon-sm/random_ico_no_uef.dds",
        TooltipID = 'lob_random_no_uef',
    }
	
table.insert(FactionData.Factions, RandomNoUEFFaction)

function GetRandomFactionIndex(slotNumber)
    local randomfaction = nil
    local counter = 50
    local size = 0
    for _,faction in GUI.slots[slotNumber].AvailableFactions do
        if ( string.len(faction) < 6 or string.sub(faction,1,6) ~= 'random') then
            size = size + 1
        end
    end
    
    while counter > 0 do
        counter = (counter - 1)
        randomfaction = math.random(1, size)
    end
    return randomfaction
end

function GetRandomFactionIndex_noUEF(possibleFactions)
    local randomfaction
	local counter = 50
    local size = 0
    for _,_ in possibleFactions do
        size = size + 1
    end
	
    --Loop 50 times (see LUA documentation on math.random)
	while counter > 0 do
		--Exclude UEF from selection range
        counter = (counter - 1)
        randomfaction = math.random(1, size)
    end
    
    for faction,_ in possibleFactions do
        randomfaction = randomfaction - 1
        if randomfaction == 0 then
            return faction
        end
    end
end

local PX_oldAssignRandomFactions = AssignRandomFactions
local saveRandoms = {}
function AssignRandomFactions()
    local scenario = MapUtil.LoadScenario(gameInfo.GameOptions.ScenarioFile)
    local randomFactions = {}
    --Handle the "Random - No UEF" option
	
    for index, player in gameInfo.PlayerOptions do
        local randomNoUEFFactionID = -1
        for i,faction in GUI.slots[index].AvailableFactions do
            if faction == 'randomNoUEF' then
                randomNoUEFFactionID = i
            end
        end
		if player.Faction == randomNoUEFFactionID then
            local possibleFactions = {}
            if scenario.Configurations.standard.factions then
                addAllRandomNoUEFPossibilities(possibleFactions, scenario.Configurations.standard.factions[index])
                for _,faction in scenario.Configurations.standard.factions[index] do
                    if faction == 'randomNoUEF' then
                        addAllRandomNoUEFPossibilities(possibleFactions, FACTION_NAMES)
                    end
                end
            else
                addAllRandomNoUEFPossibilities(possibleFactions, FACTION_NAMES)
            end
            player.Faction = 1
            saveRandoms[index] = GetRandomFactionIndex_noUEF(possibleFactions)
        end
    end
        
    --Handle the regular "Random" option
    --Note that by this point, any "Random - No UEF" players should have a faction and so, should not be assigned another
    PX_oldAssignRandomFactions()
end

local oldFixFactionIndexes = FixFactionIndexes
function FixFactionIndexes()
    oldFixFactionIndexes()
    for index,player in gameInfo.PlayerOptions do
        if saveRandoms[index] then
            for i,faction in FACTION_NAMES do
                if saveRandoms[index] == faction then
                    player.Faction = i
                    break
                end
            end
        end
    end
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

local oldUpdateAvailableSlots = UpdateAvailableSlots
function UpdateAvailableSlots( numAvailStartSpots, scenario )
    
    local randomNoUEFList = { }
    for _,faction in FACTION_NAMES do
        -- add randomNoUEF based on availability of real factions that are not uef (so nothing that starts with random)
        if faction ~= 'uef' and ( string.len(faction) < 6 or string.sub(faction,1,6) ~= 'random') then
            randomNoUEFList[faction] = true
        end
    end
    
    if scenario.Configurations.standard.factions then
        for _,factionList in scenario.Configurations.standard.factions do
            local numbFactions = 0
            for _,faction in factionList do
                if randomNoUEFList[faction] then
                    numbFactions = numbFactions + 1
                end
                if faction == 'randomNoUEF' then
                    -- it's already in there, no need to add it
                    numbFactions = -1
                    break
                end
            end
            if numbFactions >= 2 then
                table.insert(factionList, 'randomNoUEF')
            end
        end
    end
    oldUpdateAvailableSlots( numAvailStartSpots, scenario)
end

function addAllRandomNoUEFPossibilities(resultList, factionList)
    for _,faction in factionList do
        -- add randomNoUEF based on availability of real factions that are not uef (so nothing that starts with random)
        if faction ~= 'uef' and ( string.len(faction) < 6 or string.sub(faction,1,6) ~= 'random') then
            resultList[faction] = true
        end
    end
end