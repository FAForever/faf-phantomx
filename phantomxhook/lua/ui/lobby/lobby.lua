--Lobby modifications for meteor map comptibility detection
--Duck42
local PX_oldRefreshOptionDisplayData = RefreshOptionDisplayData
function RefreshOptionDisplayData(scenarioInfo)
	PX_oldRefreshOptionDisplayData(scenarioInfo)
	if not MapHasCivilianArmy(scenarioInfo) then
		for i, v in formattedOptions do
			if v.tooltip == 'PhantomX_Meteor' or v.tooltip == 'PhantomX_Meteor' then
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


--******************************************************************************************************
-- CPU Benchmark Test Code
-- Author: Duck_42
-- Date: 2013.04.05
-- 
-- 2013.10.14 - Testing new CPU benchmark code.
--******************************************************************************************************

--CPU Status Bar Configuration
local t2_barMax = 450
local t2_barMin = 150
local t2_greenBarMax = 300
local t2_yellowBarMax = 375
local t2_scoreSkew1 = 0 --Skews all CPU scores up or down by the amount specified (0 = no skew)
local t2_scoreSkew2 = 1.0 --Skews all CPU scores specified coefficient (1.0 = no skew)

--Variables for CPU Test
local t2_benchTime
local t2_firstCPUTest = true

--------------------------------------------------
--  CPU Benchmarking Functions
--------------------------------------------------
function t2_CPUBenchmark()
    --This function gives the CPU some busy work to do.
    --CPU score is determined by how quickly the work is completed.
    local totalTime = 0
    local lastTime
    local currTime
    local countTime = 0    
    --Make everything a local variable
    --This is necessary because we don't want LUA searching through the globals as part of the benchmark
    local h
    local i
    local j
    local k
    local l
    local m
    for h = 1, 48, 1 do
        lastTime = GetSystemTimeSeconds()
        for i = 1.0, 25.0, 0.0008 do 
            --This instruction set should cover most LUA operators
            j = i + i   --Addition
            k = i * i   --Multiplication
            l = k / j   --Division 
            m = j - i   --Subtraction
            j = i ^ 4   --Power
            l = -i      --Negation
            m = {'One', 'Two', 'Three'} --Create Table
            table.insert(m, 'Four')     --Insert Table Value
            table.remove(m, 1)          --Remove Table Value           
            l = table.getn(m)           --Get Table Length
            k = i < j   --Less Than        
            k = i == j  --Equality
            k = i <= j  --Less Than or Equal to
            k = not k
        end
        currTime = GetSystemTimeSeconds()
        totalTime = totalTime + currTime - lastTime
        
        if totalTime > countTime then
            --This is necessary in order to make this 'thread' yield so other things can be done.
            countTime = totalTime + .125
            WaitSeconds(0)
        end
    end
    t2_benchTime = math.ceil(totalTime * 100)
end

--------------------------------------------------
--  CPU GUI Functions
--------------------------------------------------
function CreateCPUMetricUI()
    --This function handles creation of the CPU benchmark UI elements (statusbars, buttons, tooltips, etc)
    local StatusBar = import('/lua/maui/statusbar.lua').StatusBar
	
    if not singlePlayer then
        for i= 1, LobbyComm.maxPlayerSlots do
                GUI.slots[i].CPUSpeedBar = StatusBar(GUI.slots[i].pingGroup, barMin, barMax, false, false,
                    UIUtil.SkinnableFile('/game/unit_bmp/bar-back_bmp.dds'),
                    UIUtil.SkinnableFile('/game/unit_bmp/bar02_bmp.dds'),
                    true)
                LayoutHelpers.AtBottomIn(GUI.slots[i].CPUSpeedBar, GUI.slots[i].pingGroup, 1)
                LayoutHelpers.AtLeftIn(GUI.slots[i].CPUSpeedBar, GUI.slots[i].pingGroup, 0)
                LayoutHelpers.AtRightIn(GUI.slots[i].CPUSpeedBar, GUI.slots[i].pingGroup, 0)
                CPU_AddControlTooltip(GUI.slots[i].CPUSpeedBar, 0, i)
                GUI.slots[i].CPUSpeedBar.CPUActualValue = 450
                
				GUI.slots[i].CPUSpeedBar_t2 = StatusBar(GUI.slots[i].pingGroup, barMin, barMax, false, false,
                    UIUtil.SkinnableFile('/game/unit_bmp/bar-back_bmp.dds'),
                    UIUtil.SkinnableFile('/game/unit_bmp/bar-01_bmp.dds'),
                    true)
				LayoutHelpers.AtBottomIn(GUI.slots[i].CPUSpeedBar_t2, GUI.slots[i].pingGroup, 5)
                LayoutHelpers.AtLeftIn(GUI.slots[i].CPUSpeedBar_t2, GUI.slots[i].pingGroup, 0)
                LayoutHelpers.AtRightIn(GUI.slots[i].CPUSpeedBar_t2, GUI.slots[i].pingGroup, 0)
                t2_CPU_AddControlTooltip(GUI.slots[i].CPUSpeedBar_t2, 0, i)
                GUI.slots[i].CPUSpeedBar_t2.CPUActualValue = 450
        end

        GUI.rerunBenchmark.OnClick = function(self, modifiers)
            GUI.rerunBenchmark:Disable()
            ForkThread(function() t2_StressCPU(1) end)
        end
    end
end

function t2_CPU_AddControlTooltip(control, delay, slotNumber)
    --This function creates the benchmark tooltip for a slot along with necessary mouseover function.
    --It is called during the UI creation.
    --    control: The control to which the tooltip is to be added.
    --    delay: Amount of time to delay before showing tooltip.  See Tooltip.CreateMouseoverDisplay for info.
    --  slotNumber: The slot number associated with the control.
    if not control.oldHandleEvent then
        control.oldHandleEvent = control.HandleEvent
    end
    control.HandleEvent = function(self, event)
        if event.Type == 'MouseEnter' then
            local slot = slotNumber
            Tooltip.CreateMouseoverDisplay(self, {text='CPU Rating #2: '..GUI.slots[slot].CPUSpeedBar_t2.CPUActualValue_t2,
                                           body='0=Fastest, 450=Slowest'}, delay, true)
        elseif event.Type == 'MouseExit' then
            Tooltip.DestroyMouseoverDisplay()
        end
        return self.oldHandleEvent(self, event)
    end
end

function t2_StressCPU(waitTime)
    --This function instructs the PC to do a CPU score benchmark.
    --It handles the necessary UI updates during the benchmark, sends
    --the benchmark result to other players when finished, and it updates the local
    --user's UI with their new result.
    --    waitTime: The delay in seconds that this function should wait before starting the benchmark.

    for i = waitTime, 1, -1 do
        GUI.rerunBenchmark.label:SetText(i..'s')
        WaitSeconds(1)
    end

    --Get our last benchmark (if there was one)
    local currentBestBenchmark = FindBenchmarkForName(localPlayerName..'_t2')
    if currentBestBenchmark == false then
        currentBestBenchmark = 10000
    end

    --LOG('Beginning CPU benchmark')
    GUI.rerunBenchmark.label:SetText('. . .')

    --Run three benchmarks and keep the best one
    for i=1, 3, 1 do
        t2_benchTime = 0

        t2_CPUBenchmark()

        t2_benchTime = t2_scoreSkew2 * t2_benchTime + t2_scoreSkew1

        --LOG('CPU benchmark #'..i..' complete: '.. benchTime )

        --If this benchmark was better than our best so far...
        if t2_benchTime < currentBestBenchmark then
            --Make this our best benchmark
            currentBestBenchmark = t2_benchTime

            --Send it to the other players
            lobbyComm:BroadcastData( { Type = 'CPUBenchmark', PlayerName = localPlayerName..'_t2', Result = currentBestBenchmark} )

            --Add the benchmark to the local benchmark table
            AddPlayerBenchmark({PlayerName = localPlayerName..'_t2', Result = currentBestBenchmark})

            --Update the UI bar
            UpdateCPUBar(localPlayerName)
        end
    end

    --Set this flag so we'll know later
    t2_firstCPUTest = false

	orig_StressCPU(1)
end

orig_StressCPU = StressCPU

function StressCPU(waitTime)
	t2_StressCPU(waitTime)
end

function SetSlotCPUBar(slot, playerInfo)
    --This function updates the UI with a CPU benchmark bar for the specified slot/playerInfo.
    --    slot: a numbered slot (1-however many slots there are for this map)
    --    playerInfo: The corresponding playerInfo object from gameInfo.PlayerOptions[slot].

    if GUI.slots[slot].CPUSpeedBar then
        GUI.slots[slot].CPUSpeedBar:Hide()
        if playerInfo.Human then
            local b = FindBenchmarkForName(playerInfo.PlayerName)
            if b then
                -- For display purposes, the bar has a higher minimum that the actual barMin value.
                -- This is to ensure that the bar is visible for very small values
                local clampedResult =  math.max(math.min(b.Result, barMax), barMin + math.floor(.04 * (barMax - barMin)))
                GUI.slots[slot].CPUSpeedBar:SetValue(clampedResult)
                
                --For the tooltip, we use the actual clamped value
                GUI.slots[slot].CPUSpeedBar.CPUActualValue = b.Result
                GUI.slots[slot].CPUSpeedBar:Show()

                GUI.slots[slot].CPUSpeedBar._bar:SetTexture(UIUtil.SkinnableFile('/game/unit_bmp/bar02_bmp.dds'))

                -- if clampedResult <= greenBarMax then
                    -- GUI.slots[slot].CPUSpeedBar._bar:SetTexture(UIUtil.SkinnableFile('/game/unit_bmp/bar-02_bmp.dds'))
                -- elseif clampedResult <= yellowBarMax then
                    -- GUI.slots[slot].CPUSpeedBar._bar:SetTexture(UIUtil.SkinnableFile('/game/unit_bmp/bar-01_bmp.dds'))
                -- else
                    -- GUI.slots[slot].CPUSpeedBar._bar:SetTexture(UIUtil.SkinnableFile('/game/unit_bmp/bar-03_bmp.dds'))
                -- end
            end
        end
    end
	
	if GUI.slots[slot].CPUSpeedBar_t2 then
        GUI.slots[slot].CPUSpeedBar_t2:Hide()
        if playerInfo.Human then
            local b = FindBenchmarkForName(playerInfo.PlayerName..'_t2')
            if b then
                -- For display purposes, the bar has a higher minimum that the actual barMin value.
                -- This is to ensure that the bar is visible for very small values
                local clampedResult =  math.max(math.min(b.Result, barMax), barMin + math.floor(.04 * (barMax - barMin)))
                GUI.slots[slot].CPUSpeedBar_t2:SetValue(clampedResult)
                
                --For the tooltip, we use the actual clamped value
                GUI.slots[slot].CPUSpeedBar_t2.CPUActualValue_t2 = b.Result
                GUI.slots[slot].CPUSpeedBar_t2:Show()

                GUI.slots[slot].CPUSpeedBar_t2._bar:SetTexture(UIUtil.SkinnableFile('/game/unit_bmp/bar-01_bmp.dds'))
            end
        end
    end
end