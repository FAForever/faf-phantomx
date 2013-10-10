--*****************************************************************************
--* File: lua/modules/ui/game/economy.lua
--* Author: mead
--* Summary: Economy bar changes for Phantom-X UI
--*
--*****************************************************************************

--Phantom UI changes
local actual_bonus_mass = 0
local actual_bonus_energy = 0
local display_bonus_mass = 0
local display_bonus_energy = 0

function _BeatFunction()
    local econData = GetEconomyTotals()
    local simFrequency = GetSimTicksPerSecond()
    
    local function DisplayEconData(controls, tableID, viewPref)
        local function FormatRateString(RateVal, StoredVal, IncomeAvg, ActualAvg, RequestedAvg)
            local retRateStr = string.format('%+d', math.min(math.max(RateVal, -999999), 999999))
            local retEffVal = 0
            if RequestedAvg == 0 then
                retEffVal = math.ceil(IncomeAvg) * 100
            else
                if StoredVal > 0.5 then
                    retEffVal = math.ceil( (IncomeAvg / ActualAvg) * 100 )
                else
                    retEffVal = math.ceil( (IncomeAvg / RequestedAvg) * 100 )
                end    
            end
            return retRateStr, retEffVal
        end
        
        local maxStorageVal = econData["maxStorage"][tableID]
        local storedVal = econData["stored"][tableID]
        local incomeVal = econData["income"][tableID]
        local lastRequestedVal = econData["lastUseRequested"][tableID]
        local lastActualVal = econData["lastUseActual"][tableID]

    	--Phantom UI changes
    	local displayBonus = 0
    	local actualBonus = 0
		if tableID == 'MASS' then
			displayBonus = display_bonus_mass
			actualBonus = actual_bonus_mass
		elseif tableID == 'ENERGY' then
			displayBonus = display_bonus_energy
			actualBonus = actual_bonus_energy
		end

        local requestedAvg = math.min(lastRequestedVal * simFrequency, 999999)
        local actualAvg = math.min(lastActualVal * simFrequency, 999999)
        local incomeAvg = math.min(incomeVal * simFrequency - actualBonus + displayBonus, 999999)
        
        controls.storageBar:SetRange(0, maxStorageVal)
        controls.storageBar:SetValue(storedVal)
        controls.curStorage:SetText(math.ceil(storedVal))
        controls.maxStorage:SetText(math.ceil(maxStorageVal))
        
        controls.income:SetText(string.format("+%d", math.ceil(incomeAvg)))
        if storedVal > 0.5 then
            controls.expense:SetText(string.format("-%d", math.ceil(actualAvg)))
        else
            controls.expense:SetText(string.format("-%d", math.ceil(requestedAvg)))
        end
    
        local rateVal = 0
        if storedVal > 0.5 then
            rateVal = math.ceil(incomeAvg - actualAvg)
        else
            rateVal = math.ceil(incomeAvg - requestedAvg)
        end
        
        local rateStr, effVal = FormatRateString(rateVal, storedVal, incomeAvg, actualAvg, requestedAvg)
    -- CHOOSE RATE or EFFICIENCY STRING
        if States[viewPref] == 2 then
            controls.rate:SetText(string.format("%d%%", math.min(effVal, 100)))   
        else
            controls.rate:SetText(string.format("%+s", rateStr))
        end
    -- SET RATE/EFFICIENCY COLOR
        local rateColor
        if rateVal < 0 then
            if storedVal > 0 then
                rateColor = 'yellow'
            else
                rateColor = 'red'
            end
        else
            rateColor = 'ffb7e75f'
        end
        controls.rate:SetColor(rateColor)
        
    -- ECONOMY WARNINGS        
        if Prefs.GetOption('econ_warnings') and UIState then
            if storedVal / maxStorageVal < .2 then
                if effVal < 25 then
                    controls.warningBG:SetToState('red')
                elseif effVal < 75 then
                    controls.warningBG:SetToState('yellow')
                elseif effVal > 100 then
                    controls.warningBG:SetToState('hide')
                end
            else
                controls.warningBG:SetToState('hide')
            end
        else
            controls.warningBG:SetToState('hide')
        end
    end
    
    DisplayEconData(GUI.mass, 'MASS', 'massViewState')
    DisplayEconData(GUI.energy, 'ENERGY', 'energyViewState')
end


function UpdatePhantomEco(data)
	if data.doUpdate == true then
		display_bonus_mass = data.actualMass * data.tickRate
		display_bonus_energy = data.actualEnergy * data.tickRate
	end
	actual_bonus_mass = data.actualMass * data.tickRate
	actual_bonus_energy = data.actualEnergy * data.tickRate
end