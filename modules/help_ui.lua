--*****************************************************************************
--* Summary: Lobby and In game quick help for Phantom-X mod.  Original code
--*          from eula.lua.  Modifications by Duck_42.
--*
--* Version History:
--* 	Initial Version - Duck_42									5/16/2014
--*****************************************************************************
local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Button = import('/lua/maui/button.lua').Button
local Group = import('/lua/maui/group.lua').Group
local Text = import('/lua/maui/text.lua').Text
local ItemList = import('/lua/maui/itemlist.lua').ItemList
local MenuCommon = import('/lua/ui/menus/menucommon.lua')
local Popup = import('/lua/ui/controls/popups/popup.lua').Popup

--local dialog = false

local helpText = 'The Players\n\n'
helpText = helpText..'-Phantoms\n'
helpText = helpText..'A phantom\'s goal is to kill everyone else in the game (including the other phantom).  Phantoms receive bonus mass and energy income (a percentage of the total innocent player income), which enables them to build at an accelerated rate. Phantoms frequently team up near the beginning of the game, but a good phantom will always have a plan for killing the other phantom(s) once the innocents have been dealt with.\n\n'

helpText = helpText..'Possible signs of a Phantom:\n'
helpText = helpText..'-Aggressive behavior (Phantoms get an additional resource bonus if they break an alliance).\n'
helpText = helpText..'-Rapid early advancement (Phantoms may outpace everyone else due to the mass and energy bonus).\n'
helpText = helpText..'-Not enough energy to support base output. (Some phantoms rely on the bonus instead of their own production).\n\n'
helpText = helpText..' -Innocents\n'
helpText = helpText..'    An innocent player\'s goal is to kill all phantoms. Innocents must typically rely on teamwork to take on and defeat the phantoms. Since the phantoms will often team up, the innocents must be very vigilant early in the game or risk being quickly overwhelmed by a team phantom rush.\n\n'
helpText = helpText..' -Paladins\n'
helpText = helpText..'    Paladins are a special class of innocent players. Like the phantoms, they receive bonus resources. Although, the paladin bonus is substantially less (varies from 25% to 65% of phantom bonus depending on the configured lobby option). A paladin\'s goal is the same as any other innocent (i.e. kill all phantoms).\n\n\n'
helpText = helpText..'The Scenario\n\n'
helpText = helpText..'At 7 minutes into the game, all players are given a chance to vote for one, two, or three phantoms (the game host can disable this option). The option with the most votes determines the number of phantoms. If there\'s a tie, the lower number is used.\n\n'
helpText = helpText..'At 8 minutes into the game, the selected number of phantoms are randomly chosen. The players not chosen as phantoms are designated as innocents.\n\n\n'
helpText = helpText..'Special Game Settings\n\n'
helpText = helpText..'-Reveal/No Reveal\n'
helpText = helpText..'If playing with no reveal, players will be on their own in determining who the phantoms are. This is the most challenging way to play Phantom. However, games with no reveal can sometimes last a long time. Some hosts may elect to set a reveal timer. Once the reveal timer expires, a phantom and/or paladin will be revealed (who sees this reveal can be controlled by the game host via a lobby option). The game host may use additional reveal timers to reveal additional players.\n\n'
helpText = helpText..'-Meteors\n'
helpText = helpText..'Some hosts may use meteors to ensure a game will not go on forever (usually, this only makes sense in no reveal games).  When meteors are enabled, the game starts with a set amount of time (as configured by the host) on the "meteor clock". The initial amount of time is controlled by the "Initial Meteor Delay" lobby option.'
helpText = helpText..'  If the meteor clock goes below zero, meteors (Mavor shells) will start falling from the sky. The meteors will increase in frequency as long as the clock stays below zero.'
helpText = helpText..'  To add time back to the meteor clock, a player must be killed. The amount of time added back to the clock is also configured by the host under the "Subsequent Meteor Delay" lobby option.'
helpText = helpText..'  Meteors can also be delayed indefinitely by war, as long as a sufficient amount of mass is being destroyed. The "Mass destroyed percentage" indicator displays the amount of mass destroyed divided by the amount of mass produced for the last two minutes. As long as the indicator is green or yellow, the meteors will not start.'
helpText = helpText..'  If only two players remain, the meteors stop (at that point, the players should be fighting anyway).\n\n'
helpText = helpText..'-No Reveal After Death\n'
helpText = helpText..'This option does pretty much what you\'d think.  When enabled, the game does not reveal a player\'s affiliation (phantom or innocent) when they die. This was created as a hardcore phantom option and was intended for use in no reveal games. As in normal phantom, the game will end when all phantoms are dead or when the last phantom kills off the other remaining player. As you might expect, this option can lead to some pretty paranoid game play.\n\n\n'
helpText = helpText..'Other Rules\n\n'
helpText = helpText..' -Engineer Trading\n'
helpText = helpText..'    Although not often explicitly stated, engineer trading is usually prohibited in phantom games. If you plan on trading engineers, be sure to check with the host about whether or not trading is permitted.  Stealing (capturing) engineers is usually allowed as long as it\'s not just a disguised trade.\n'

function ShowPhantomXHelpDialog(inParent)
	local dialogContent = Group(inParent)
    dialogContent.Width:Set(700)
    dialogContent.Height:Set(450)
	
	local popup = Popup(inParent, dialogContent)
	
	local function doCancel()
        popup:Close()
    end

    popup.OnShadowClicked = doCancel
    popup.OnEscapePressed = doCancel
	
	local exitButton = UIUtil.CreateButtonWithDropshadow(dialogContent, '/BUTTON/medium/', "<LOC _Close>")
	LayoutHelpers.AtBottomIn(exitButton, dialogContent, 25)
    LayoutHelpers.AtHorizontalCenterIn(exitButton, dialogContent)
	
    exitButton.OnClick = doCancel
	
	local title = UIUtil.CreateText(dialogContent, "Phantom-X Help", 20)
    LayoutHelpers.AtHorizontalCenterIn(title, dialogContent)
    LayoutHelpers.AtTopIn(title, dialogContent, 12)
	
    LayoutHelpers.AtBottomIn(exitButton, dialogContent, 10)
    LayoutHelpers.AtHorizontalCenterIn(exitButton, dialogContent)
	
	local helpBody = ItemList(dialogContent)
    LayoutHelpers.AtLeftTopIn(helpBody, dialogContent, 19, 50)
    helpBody.Height:Set(340)
    helpBody.Width:Set(662)
	helpBody:SetColors(UIUtil.fontColor, "00000000", UIUtil.fontColor, "00000000")
    helpBody:SetFont(UIUtil.bodyFont, 12)
    UIUtil.CreateLobbyVertScrollbar(helpBody, -15, 0, 0)
	UIUtil.SurroundWithBorder(helpBody, '/scx_menu/lan-game-lobby/frame/')
    
    local textBoxWidth = helpBody.Width() - 25

    local tempTable = import('/lua/maui/text.lua').WrapText(LOC(helpText), textBoxWidth,
    function(text)
        return helpBody:GetStringAdvance(text)
    end)
    
    for i, v in tempTable do
        helpBody:AddItem(v)
    end
end

--[[
function ShowPhantomXHelpDialog(inParent)
    local parent = Group(inParent)
    LayoutHelpers.FillParent(parent, inParent)
    parent.Depth:Set(GetFrame(0):GetTopmostDepth() + 10)
    
    local worldCover = UIUtil.CreateWorldCover(parent, '00000000')
    
    local bg = Bitmap(parent, UIUtil.UIFile('/scx_menu/eula/eula.dds'))
    LayoutHelpers.AtCenterIn(bg, parent)
    
    bg.brackets = UIUtil.CreateDialogBrackets(bg, 40, 25, 40, 24)
    
    local exitButton = UIUtil.CreateButtonStd(bg, '/scx_menu/small-btn/small', "<LOC _Close>", 16, 2)
    exitButton.OnClick = function(self)
        parent:Destroy()
    end
    
    UIUtil.MakeInputModal(parent, function() exitButton.OnClick(exitButton) end, function() exitButton.OnClick(exitButton) end)
    
    local title = UIUtil.CreateText(bg, "Phantom-X Help", 20)
    LayoutHelpers.AtHorizontalCenterIn(title, bg)
    LayoutHelpers.AtTopIn(title, bg, 35)

    LayoutHelpers.AtBottomIn(exitButton, bg, 25)
    LayoutHelpers.AtHorizontalCenterIn(exitButton, bg)
    
    local helpBody = ItemList(bg)
    LayoutHelpers.AtLeftTopIn(helpBody, bg, 30, 84)
    helpBody.Height:Set(402)
    helpBody.Width:Set(630)
    helpBody:SetColors(UIUtil.consoleFGColor(), UIUtil.consoleTextBGColor(), UIUtil.consoleFGColor(), UIUtil.consoleTextBGColor()) -- we don't really want selection here so don't differentiate colors
    helpBody:SetFont(UIUtil.bodyFont, 12)
    UIUtil.CreateVertScrollbarFor(helpBody)
    
    local textBoxWidth = helpBody.Width()

    local tempTable = import('/lua/maui/text.lua').WrapText(LOC(helpText), textBoxWidth,
    function(text)
        return helpBody:GetStringAdvance(text)
    end)
    
    for i, v in tempTable do
        helpBody:AddItem(v)
    end
end
--]]

--[[
function ShowPhantomXHelpDialog(parent)
    -- Dialog already showing? Don't show another one
    if dialog then return end

    dialog = Bitmap(parent, UIUtil.UIFile('/scx_menu/panel-brd/panel_brd_m.dds'), "Phantom-X Help Dialog")
    dialog.Depth:Set(GetFrame(0):GetTopmostDepth() + 10)
    UIUtil.CreateWorldCover(dialog)
    
    LayoutHelpers.AtCenterIn(dialog, parent)
    
    local border = CreateBorder(dialog)
    local brackets = UIUtil.CreateDialogBrackets(dialog, 106, 110, 110, 108, true)
     
    dialog.Width:Set(475)
    dialog.Height:Set(550)
    
    local label = UIUtil.CreateText(border.tm, 'Phantom-X Help', 20)
    LayoutHelpers.AtTopIn(label, border.tm, 12)
    LayoutHelpers.AtHorizontalCenterIn(label, dialog)
    
    
      
    local closeBtn = UIUtil.CreateButtonStd(dialog, '/scx_menu/small-btn/small', '<LOC _Close>', 16, 2)
    LayoutHelpers.AtTopIn(closeBtn, border.bm, -20)
    LayoutHelpers.AtHorizontalCenterIn(closeBtn, dialog)
       
    closeBtn.OnClick = function(self, modifiers)
        dialog:Destroy()
        dialog = false
    end
    
    local helpBox = MultiLineText(dialog, UIUtil.bodyFont, 14, UIUtil.fontColor)
    LayoutHelpers.AtLeftTopIn(helpBox, dialog, -50, 0)
    helpBox.Height:Set(450)
    helpBox.Width:Set(550)
    helpBox:SetText(helpText)
    
    local sb = UIUtil.CreateVertScrollbarFor(helpText)

    dialog:SetNeedsFrameUpdate(true)
end

function CreateBorder(parent)
    local tbl = {}
    tbl.tl = Bitmap(parent, UIUtil.UIFile('/scx_menu/panel-brd/panel_brd_ul.dds'))
    tbl.tm = Bitmap(parent, UIUtil.UIFile('/scx_menu/panel-brd/panel_brd_horz_um.dds'))
    tbl.tr = Bitmap(parent, UIUtil.UIFile('/scx_menu/panel-brd/panel_brd_ur.dds'))
    tbl.l = Bitmap(parent, UIUtil.UIFile('/scx_menu/panel-brd/panel_brd_vert_l.dds'))
    tbl.r = Bitmap(parent, UIUtil.UIFile('/scx_menu/panel-brd/panel_brd_vert_r.dds'))
    tbl.bl = Bitmap(parent, UIUtil.UIFile('/scx_menu/panel-brd/panel_brd_ll.dds'))
    tbl.bm = Bitmap(parent, UIUtil.UIFile('/scx_menu/panel-brd/panel_brd_lm.dds'))
    tbl.br = Bitmap(parent, UIUtil.UIFile('/scx_menu/panel-brd/panel_brd_lr.dds'))
    
    tbl.tl.Bottom:Set(parent.Top)
    tbl.tl.Right:Set(parent.Left)
    
    tbl.tr.Bottom:Set(parent.Top)
    tbl.tr.Left:Set(parent.Right)
    
    tbl.tm.Bottom:Set(parent.Top)
    tbl.tm.Right:Set(parent.Right)
    tbl.tm.Left:Set(parent.Left)
    
    tbl.l.Bottom:Set(parent.Bottom)
    tbl.l.Top:Set(parent.Top)
    tbl.l.Right:Set(parent.Left)
    
    tbl.r.Bottom:Set(parent.Bottom)
    tbl.r.Top:Set(parent.Top)
    tbl.r.Left:Set(parent.Right)
    
    tbl.bl.Top:Set(parent.Bottom)
    tbl.bl.Right:Set(parent.Left)
    
    tbl.br.Top:Set(parent.Bottom)
    tbl.br.Left:Set(parent.Right)
    
    tbl.bm.Top:Set(parent.Bottom)
    tbl.bm.Right:Set(parent.Right)
    tbl.bm.Left:Set(parent.Left)
    
    tbl.tl.Depth:Set(function() return parent.Depth() - 1 end)
    tbl.tm.Depth:Set(function() return parent.Depth() - 1 end)
    tbl.tr.Depth:Set(function() return parent.Depth() - 1 end)
    tbl.l.Depth:Set(function() return parent.Depth() - 1 end)
    tbl.r.Depth:Set(function() return parent.Depth() - 1 end)
    tbl.bl.Depth:Set(function() return parent.Depth() - 1 end)
    tbl.bm.Depth:Set(function() return parent.Depth() - 1 end)
    tbl.br.Depth:Set(function() return parent.Depth() - 1 end)
    
    return tbl
end
--]]
