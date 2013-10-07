--*****************************************************************************
--* Summary: In game reveal dialog for Phantom-X mod.  Original code
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

controls = {}
savedParent = false

local sessionInfo = SessionGetScenarioInfo()
revealData = {}

local RevealComplete = false

--Variable for keeping track of the next army line index to use
local armyCount = 1

function CreateRevealUI(parent)
    savedParent = parent
    
    controls.bg = Group(savedParent)
    controls.bg.Depth:Set(10)
    
    controls.collapseArrow = Checkbox(savedParent)
    controls.collapseArrow.OnCheck = function(self, checked)
        ToggleRevealControl(not checked)
    end
    Tooltip.AddCheckboxTooltip(controls.collapseArrow, 'Phantom_RevealUI_Collapse')
    
    controls.bgTop = Bitmap(controls.bg)
    controls.bgBottom = Bitmap(controls.bg)
    controls.bgStretch = Bitmap(controls.bg)
    controls.armyGroup = Group(controls.bg)
    
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
    
    --SetupPlayerLines()
    controls.armyLines = {}
    
    controls.time = UIUtil.CreateText(controls.bgTop, '0', 14, UIUtil.bodyFont)
    --controls.time:SetColor('ff00dbff')
    controls.timeIcon = Bitmap(controls.bgTop)
    Tooltip.AddControlTooltip(controls.time, 'Phantom_RevealUI_Time')
    
    SetLayout()
    
    #Hide Panel
    controls.bg.Left:Set(savedParent.Left() - controls.bg.Width())
    controls.bg:Hide()
    
    #Hide CheckBox
    controls.collapseArrow:SetCheck(true, true)
    controls.collapseArrow:Hide()
end

function CreateArmyLine(data, armyIndex)
    local group = Group(controls.bgStretch)
    
    group.faction = Bitmap(group)
    if armyIndex != 0 then
        group.faction:SetTexture(UIUtil.UIFile(UIUtil.GetFactionIcon(data.faction)))
    else
        group.faction:SetTexture(UIUtil.UIFile('/widgets/faction-icons-alpha_bmp/observer_ico.dds'))
    end
    group.faction.Height:Set(14)
    group.faction.Width:Set(14)
    group.faction:DisableHitTest()
    LayoutHelpers.AtLeftTopIn(group.faction, group)
    
    group.color = Bitmap(group.faction)
    group.color:SetSolidColor(data.color)
    group.color.Depth:Set(function() return group.faction.Depth() - 1 end)
    group.color:DisableHitTest()
    LayoutHelpers.FillParent(group.color, group.faction)
    
    group.name = UIUtil.CreateText(group, data.nickname, 12, UIUtil.bodyFont)
    group.name:DisableHitTest()
    LayoutHelpers.AtLeftIn(group.name, group, 16)
    LayoutHelpers.AtVerticalCenterIn(group.name, group)
    group.name:SetColor('ffffffff')
    
    group.score = UIUtil.CreateText(group, '', 12, UIUtil.bodyFont)
    group.score:DisableHitTest()
    LayoutHelpers.AtRightIn(group.score, group)
    LayoutHelpers.AtVerticalCenterIn(group.score, group)
    group.score:SetColor('ffffffff')
    group.score:SetDropShadow(true)
    
    group.name.Right:Set(group.score.Left)
    group.name:SetClipToWidth(true)
    
    group.Height:Set(group.faction.Height)
    group.Width:Set(210)
    
    group.armyID = armyIndex
    
    group:DisableHitTest()
    
    return group
end

function UpdateUI()
	local armiesInfo = GetArmiesTable().armiesTable
	for index, player in revealData do
		for _, line in controls.armyLines do
	       if line.armyID == player.Id then
	           if line.OOG then break end
	           line.score:SetText(player.PlayerType)
	           
	           line.name:SetColor('ffffffff')
	           
	           line.score:SetColor('ffffffff')
	           if player.PlayerType == 'Phantom' then
	           		line.score:SetColor('ffdd0000')
	           elseif player.PlayerType == 'Paladin' then
	           		line.score:SetColor('ff00dd00')
	           end
	           line.name:SetFont(UIUtil.bodyFont, 14)
	           line.score:SetFont(UIUtil.bodyFont, 14)
	           
	           if armiesInfo[player.Id].outOfGame then
	               line.OOG = true
	               line.faction:SetTexture(UIUtil.UIFile('/game/unit-over/icon-skull_bmp.dds'))
	               line.color:SetSolidColor('ff000000')
	               line.name:SetColor('ffa0a0a0')
	               line.score:SetColor('ffa0a0a0')
	           end
	           break
	       end
	   end
	end
	LayoutArmyLines()
end


function AddRevealedPlayer(armyId, type)
	if IsAlreadyRevealed(armyId) == false then
		table.insert(revealData, {Id=armyId, PlayerType=type})
		local armyData = GetArmiesTable().armiesTable[armyId]
		controls.armyLines[armyCount] = CreateArmyLine(armyData, armyId)
		armyCount = armyCount + 1
		ShowBar()
	end
end

function IsAlreadyRevealed(armyId)
	for index, player in revealData do
		if player.Id == armyId then
			return true
		end
	end
	return false
end

function SetTimeText(value)
	controls.time:SetText(value)
end

function ProcessPostRevealLogic()
	ForkThread(function()
		WaitSeconds(30)
		HideBar()
		end)
end

function ToggleRevealControl(state)
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
		ToggleRevealControl(false)
	end
end

function ShowBar()
	if controls.bg:IsHidden() then
		ToggleRevealControl(true)
	end
end

function ShowCheckBox()
	controls.collapseArrow:Show()
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
    LayoutHelpers.AtLeftTopIn(controls.armyGroup, controls.bgTop, 10, 25)
    controls.armyGroup.Width:Set(210)
    
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
    
    controls.bgBottom.Top:Set(function() return math.max(controls.armyGroup.Bottom() - 14, controls.bgTop.Bottom()) end)
    controls.bgBottom.Right:Set(controls.bgTop.Right)
    controls.bgStretch.Top:Set(controls.bgTop.Bottom)
    controls.bgStretch.Bottom:Set(controls.bgBottom.Top)
    controls.bgStretch.Right:Set(function() return controls.bgTop.Right() - 0 end)
    
    controls.bg.Height:Set(function() return controls.bgBottom.Bottom() - controls.bgTop.Top() end)
    controls.armyGroup.Height:Set(function() 
        local totHeight = 0
        for _, line in controls.armyLines do
            totHeight = totHeight + line.Height()
        end
        return math.max(totHeight, 50)
    end)
    
    LayoutHelpers.AtLeftTopIn(controls.timeIcon, controls.bgTop, 10, 6)
    controls.timeIcon:SetTexture(UIUtil.UIFile('/game/unit_view_icons/time.dds'))
    LayoutHelpers.CenteredRightOf(controls.time, controls.timeIcon, 3)
    
    --Tweak Position
    --controls.time.Top:Set(controls.timeIcon.Top() - 2)
    --controls.time.Left:Set(controls.timeIcon.Right() + 3)
    
    controls.timeIcon.Height:Set(function() return controls.timeIcon.BitmapHeight() * .8 end)
    controls.timeIcon.Width:Set(function() return controls.timeIcon.BitmapWidth() * .8 end)        
    
    --Set initial text value
    SetTimeText('--:--')
    
    LayoutArmyLines()
end

function LayoutArmyLines()    
    for index, line in controls.armyLines do
        local i = index
        if i == 1 then
            LayoutHelpers.AtLeftTopIn(controls.armyLines[i], controls.armyGroup)
        else
            LayoutHelpers.Below(controls.armyLines[i], controls.armyLines[i-1])
        end
    end
end
    
function GetPanelBottom()
    local rtVal = 0
    if controls then
        if controls.armyGroup then
            rtVal =  controls.armyGroup.Bottom()
       end
    end
    return rtVal
end