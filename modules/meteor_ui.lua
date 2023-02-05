--*****************************************************************************
--* Summary: In game meteor dialog for Phantom-X mod.  Original code
--*          from score.lua.  Modifications by Duck_42.
--*
--* Version History:
--* 	Initial Version - Duck_42									2/24/2013
--*****************************************************************************

--TODO:
-- *Come up with a way to handle various reveal config scenarios gracefully.

local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local GameMain = import('/lua/ui/game/gamemain.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Checkbox = import('/lua/maui/checkbox.lua').Checkbox
local Text = import('/lua/maui/text.lua').Text
local Grid = import('/lua/maui/Grid.lua').Grid
local Prefs = import('/lua/user/prefs.lua')
local Tooltip = import('/lua/ui/game/tooltip.lua')

local sessionInfo = SessionGetScenarioInfo()

controls = {}
savedParent = false

local massDestroyedPercent = 0
local timeRemaining = 0
local meteorsDone = false

local massThreshhold = 80

local runOnce = true

function CreateMeteorUI(parent)
    savedParent = parent
    
    controls.bg = Group(savedParent)
    controls.bg.Depth:Set(10)
    
    controls.collapseArrow = Checkbox(savedParent)
    controls.collapseArrow.OnCheck = function(self, checked)
        ToggleMeteorControl(not checked)
    end
    Tooltip.AddCheckboxTooltip(controls.collapseArrow, 'Phantom_MeteorUI_Collapse')
    
    controls.bgTop = Bitmap(controls.bg)
    controls.bgBottom = Bitmap(controls.bg)
    controls.bgStretch = Bitmap(controls.bg)
    controls.infoPanel = Group(controls.bg)
    
    controls.leftBracketMin = Bitmap(controls.bg)
    controls.leftBracketMax = Bitmap(controls.bg)
    controls.leftBracketMid = Bitmap(controls.bg)
    
    controls.rightBracketMin = Bitmap(controls.bg)
    controls.rightBracketMax = Bitmap(controls.bg)
    controls.rightBracketMid = Bitmap(controls.bg)
    
    controls.leftBracketMin:DisableHitTest()
    controls.leftBracketMax:DisableHitTest()
    controls.leftBracketMid:DisableHitTest()
    controls.rightBracketMin:DisableHitTest()
    controls.rightBracketMax:DisableHitTest()
    controls.rightBracketMid:DisableHitTest()
    
    controls.bg:DisableHitTest(true)
    
    controls.time = UIUtil.CreateText(controls.bgTop, '0', 14, UIUtil.bodyFont)
    --controls.time:SetColor('ff00dbff')
    controls.timeIcon = Bitmap(controls.bgTop)
    Tooltip.AddControlTooltip(controls.time, 'Phantom_MeteorUI_Time')
    
    controls.meteorIcon = Bitmap(controls.infoPanel)
    controls.massDestroyedLabel = UIUtil.CreateText(controls.infoPanel, '0', 14, UIUtil.bodyFont)
    controls.percentMassDestroyed = UIUtil.CreateText(controls.infoPanel, '0', 14, UIUtil.bodyFont)
    controls.meteorStatus = UIUtil.CreateText(controls.infoPanel, '0', 14, UIUtil.bodyFont)
    controls.meteorStatusLabel = UIUtil.CreateText(controls.infoPanel, '0', 14, UIUtil.bodyFont)
    
    
    SetLayout()
    
    --Hide Panel
    controls.bg.Left:Set(savedParent.Left() - controls.bg.Width())
    controls.bg:Hide()
    
    --Hide CheckBox
    controls.collapseArrow:SetCheck(true, true)
    controls.collapseArrow:Hide()
    
end

function SyncData(data)
    massDestroyedPercent = data.MassDestroyedPercent
    timeRemaining = data.TimeRemaining
    meteorsDone = data.MeteorsDone
    massThreshhold = 100 * data.ThresholdPercent
    
    if runOnce and meteorsDone then
        ProcessPostMeteorLogic()
        runOnce = false
    end
end

local flashCounter = 0

function UpdateUI()
    if timeRemaining >= 0 then
        controls.time:SetText(string.format("Meteor ETA:  %02d:%02d", math.floor(timeRemaining / 60), math.mod(timeRemaining, 60)))
    else
        controls.time:SetText(string.format("Meteor Deficit:  %02d:%02d", math.floor(-timeRemaining / 60), math.mod(-timeRemaining, 60)))
    end
    
    controls.percentMassDestroyed:SetText(math.floor(massDestroyedPercent)..'%')
    if massDestroyedPercent > (massThreshhold + massThreshhold * .25) then
        controls.percentMassDestroyed:SetColor('ff00dd00')
    elseif massDestroyedPercent > massThreshhold then
        controls.percentMassDestroyed:SetColor('ffdddd00')
    else
        controls.percentMassDestroyed:SetColor('ffdd0000')
    end
    
    if meteorsDone then
        controls.meteorStatus:SetText('Not a Threat')
        controls.meteorStatus:SetColor('ffdddddd')
        controls.percentMassDestroyed:SetColor('ffdddddd')
        controls.percentMassDestroyed:SetText('N/A')
        controls.time:SetText('--:--')
    elseif massDestroyedPercent > massThreshhold and timeRemaining < 0 then
        controls.meteorStatus:SetColor('ffdd0000')
        controls.meteorStatus:SetText('Imminent')
    elseif massDestroyedPercent < massThreshhold and timeRemaining < 0 then
        controls.meteorStatus:SetText('!!Danger!!')
        controls.meteorStatus:SetColor('ffdd0000')
        flashCounter = flashCounter + 1
        if flashCounter < 20 and flashCounter > 10 then
            controls.meteorStatus:SetColor('ff222222')
        elseif flashCounter > 20 then
            controls.meteorStatus:SetColor('ffdd0000')
            flashCounter = 0
        end
    elseif timeRemaining < 60 then
        controls.meteorStatus:SetText('Imminent')
        controls.meteorStatus:SetColor('ffdd0000')
    elseif timeRemaining < 300 then
        controls.meteorStatus:SetText('Probable')
        controls.meteorStatus:SetColor('ffdd7700')
    elseif timeRemaining < 600 then
        controls.meteorStatus:SetText('Possible')
        controls.meteorStatus:SetColor('ffdddd00')
    elseif timeRemaining > 600 then
        controls.meteorStatus:SetColor('ff00dd00')
        controls.meteorStatus:SetText('Monitoring')
    end
end

function SetTimeText(value)
	controls.time:SetText(value)
end

function ProcessPostMeteorLogic()
	ForkThread(function()
		WaitSeconds(10)
		HideBar()
		end)
end

function ToggleMeteorControl(state)
    # disable when in Screen Capture mode
    if import('/lua/ui/game/gamemain.lua').gameUIHidden then
        return
    end
    
    if UIUtil.GetAnimationPrefs() then
        if state or controls.bg:IsHidden() then
            local sound = Sound({Cue = "UI_Score_Window_Open", Bank = "Interface",})
            PlaySound(sound)
            controls.collapseArrow:SetCheck(false, true)
            controls.bg:Show()
            controls.bg:SetNeedsFrameUpdate(true)
            controls.bg.OnFrame = function(self, delta)
                local newLeft = self.Left() + (1000*delta)
                if newLeft > savedParent.Left() + 3 then
                    self.Left:Set(function() return savedParent.Left() + 18 end)
                    self:SetNeedsFrameUpdate(false)
                else
                    self.Left:Set(newLeft)
                end
            end
        else
            local sound = Sound({Cue = "UI_Score_Window_Close", Bank = "Interface",})
            PlaySound(sound)
            controls.bg:SetNeedsFrameUpdate(true)
            controls.bg.OnFrame = function(self, delta)
                local newLeft = self.Left() - (1000*delta)
                if newLeft < savedParent.Left() - self.Width() then
                    self.Left:Set(function() return savedParent.Left() - self.Width() end)
                    self:Hide()
                    self:SetNeedsFrameUpdate(false)
                else
                    self.Left:Set(newLeft)
                end
            end
            controls.collapseArrow:SetCheck(true, true)
        end
    else
        if state or controls.bg:IsHidden() then
            controls.bg:Show()
            local sound = Sound({Cue = "UI_Score_Window_Open", Bank = "Interface",})
            PlaySound(sound)
            controls.collapseArrow:SetCheck(false, true)
        else           
            local sound = Sound({Cue = "UI_Score_Window_Close", Bank = "Interface",})
            PlaySound(sound)
            controls.bg:Hide()
            controls.collapseArrow:SetCheck(true, true)
        end
    end
end

function HideBar()
	if controls.bg:IsHidden() == false then
		ToggleMeteorControl(false)
	end
end

function ShowBar()
	if controls.bg:IsHidden() then
		ToggleMeteorControl(true)
	end
end

function ShowCheckBox()
	controls.collapseArrow:Show()
end

function SetTop(newTop)
    local mapGroup = savedParent
    LayoutHelpers.AtLeftTopIn(controls.collapseArrow, mapGroup, -3, newTop + 14)
    LayoutHelpers.AtLeftTopIn(controls.bg, mapGroup, 18, newTop)
end

function SetLayout()
    local mapGroup = savedParent
    controls.collapseArrow:SetTexture(UIUtil.UIFile('/game/tab-l-btn/tab-close_btn_up.dds'))
    controls.collapseArrow:SetNewTextures(UIUtil.UIFile('/game/tab-l-btn/tab-close_btn_up.dds'),
        UIUtil.UIFile('/game/tab-l-btn/tab-open_btn_up.dds'),
        UIUtil.UIFile('/game/tab-l-btn/tab-close_btn_over.dds'),
        UIUtil.UIFile('/game/tab-l-btn/tab-open_btn_over.dds'),
        UIUtil.UIFile('/game/tab-l-btn/tab-close_btn_dis.dds'),
        UIUtil.UIFile('/game/tab-l-btn/tab-open_btn_dis.dds'))
    LayoutHelpers.AtLeftTopIn(controls.collapseArrow, mapGroup, -3, 249)
    controls.collapseArrow.Depth:Set(function() return controls.bg.Depth() + 10 end)
    
    LayoutHelpers.AtLeftTopIn(controls.bg, mapGroup, 18, 235)
    controls.bg.Width:Set(controls.bgTop.Width)
    
    LayoutHelpers.AtRightTopIn(controls.bgTop, controls.bg, 3)
    LayoutHelpers.AtLeftTopIn(controls.infoPanel, controls.bgTop, 10, 25)
    controls.infoPanel.Width:Set(210)
    
    controls.leftBracketMin:SetTexture(UIUtil.UIFile('/game/bracket-left/bracket_bmp_t.dds'))
    controls.leftBracketMin.Top:Set(function() return controls.bg.Top() - 5 end)
    controls.leftBracketMin.Left:Set(function() return controls.bg.Left() - 18 end)
    
    controls.leftBracketMax:SetTexture(UIUtil.UIFile('/game/bracket-left/bracket_bmp_b.dds'))
    controls.leftBracketMax.Bottom:Set(function()
    		return math.max(controls.bg.Bottom() + 4, controls.leftBracketMin.Bottom() + controls.leftBracketMax.Height()) end)
    controls.leftBracketMax.Left:Set(controls.leftBracketMin.Left)
    
    controls.leftBracketMid:SetTexture(UIUtil.UIFile('/game/bracket-left/bracket_bmp_m.dds'))
    controls.leftBracketMid.Top:Set(controls.leftBracketMin.Bottom)
    controls.leftBracketMid.Bottom:Set(controls.leftBracketMax.Top)
    controls.leftBracketMid.Left:Set(function() return controls.leftBracketMin.Left() + 7 end)
    
    controls.rightBracketMin:SetTexture(UIUtil.UIFile('/game/bracket-right-energy/bracket_bmp_t.dds'))
    controls.rightBracketMin.Top:Set(function() return controls.bg.Top() - 1 end)
    controls.rightBracketMin.Right:Set(function() return controls.bg.Right() end)
    
    controls.rightBracketMax:SetTexture(UIUtil.UIFile('/game/bracket-right-energy/bracket_bmp_b.dds'))
    controls.rightBracketMax.Bottom:Set(function() 
            return controls.bg.Bottom() + 1
        end)
    controls.rightBracketMax.Right:Set(controls.rightBracketMin.Right)
    
    controls.rightBracketMid:SetTexture(UIUtil.UIFile('/game/bracket-right-energy/bracket_bmp_m.dds'))
    controls.rightBracketMid.Top:Set(controls.rightBracketMin.Bottom)
    controls.rightBracketMid.Bottom:Set(controls.rightBracketMax.Top)
    controls.rightBracketMid.Right:Set(function() return controls.rightBracketMin.Right() end)
    
    controls.bgTop:SetTexture(UIUtil.UIFile('/game/score-panel/panel-score_bmp_t.dds'))
    controls.bgBottom:SetTexture(UIUtil.UIFile('/game/score-panel/panel-score_bmp_b.dds'))
    controls.bgStretch:SetTexture(UIUtil.UIFile('/game/score-panel/panel-score_bmp_m.dds'))
    
    controls.bgBottom.Top:Set(function() return math.max(controls.infoPanel.Bottom() - 14, controls.bgTop.Bottom()) end)
    controls.bgBottom.Right:Set(controls.bgTop.Right)
    controls.bgStretch.Top:Set(controls.bgTop.Bottom)
    controls.bgStretch.Bottom:Set(controls.bgBottom.Top)
    controls.bgStretch.Right:Set(function() return controls.bgTop.Right() - 0 end)
    
    controls.bg.Height:Set(function() return controls.bgBottom.Bottom() - controls.bgTop.Top() end)
    controls.infoPanel.Height:Set(61)
    
    LayoutHelpers.AtLeftTopIn(controls.timeIcon, controls.bgTop, 10, 6)
    controls.timeIcon:SetTexture(UIUtil.UIFile('/game/unit_view_icons/time.dds'))
    LayoutHelpers.CenteredRightOf(controls.time, controls.timeIcon, 3)
    
    --Tweak Position
    --controls.time.Top:Set(controls.timeIcon.Top() - 2)
    --controls.time.Left:Set(controls.timeIcon.Right() + 3)
    
    controls.timeIcon.Height:Set(function() return controls.timeIcon.BitmapHeight() * .8 end)
    controls.timeIcon.Width:Set(function() return controls.timeIcon.BitmapWidth() * .8 end)
    
    
    controls.meteorIcon:SetTexture(UIUtil.UIFile('/mods/faf-phantomx/textures/resources/meteor_icon.dds'))
    controls.meteorIcon.Height:Set(57)
    controls.meteorIcon.Width:Set(59)
	LayoutHelpers.AtRightTopIn(controls.meteorIcon, controls.infoPanel, -60, 1)
    
    LayoutHelpers.AtLeftTopIn(controls.massDestroyedLabel, controls.infoPanel, 5, 1)
    controls.massDestroyedLabel:SetText('Mass Percentage: ')
    
    LayoutHelpers.RightOf(controls.percentMassDestroyed, controls.massDestroyedLabel)
    controls.percentMassDestroyed:SetText('0%')
    
    LayoutHelpers.AtLeftTopIn(controls.meteorStatusLabel, controls.infoPanel, 5, controls.massDestroyedLabel.Height() + 2)
    controls.meteorStatusLabel:SetText('Meteor Status: ')
    
    LayoutHelpers.RightOf(controls.meteorStatus, controls.meteorStatusLabel)
    controls.meteorStatus:SetText('Unknown')
    
    --Set initial text value
    SetTimeText('--:--')
end


    
