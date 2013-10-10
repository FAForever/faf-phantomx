#****************************************************************************
#**
#**  File     :  /modules/phantom.lua
#**  Author(s):  novaprim3
#**
#**  Summary  :  Multi-Phantom Mod for Forged Alliance
#**
#**  Change Log:
#**  2012.06.03: Fixed countdown timer problem.                       Duck_42
#**  2012.07.07: Added phantom bonus info to UI.                      Duck_42
#****************************************************************************
local modPath = ''

local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Button = import('/lua/maui/button.lua').Button
local Checkbox = import('/lua/maui/checkbox.lua').Checkbox
local StatusBar = import('/lua/maui/statusbar.lua').StatusBar
local GameMain = import('/lua/ui/game/gamemain.lua')
local Tooltip = import('/lua/ui/game/tooltip.lua')
local Prefs = import('/lua/user/prefs.lua')
local RevealUI = import('/modules/reveal_ui.lua')

local declare = 8 * 60

local sessionInfo = SessionGetScenarioInfo()

local reveal1
local reveal2
local reveal3
local revealTo
local revealWho
local death_reveal
local mark_base_cost

local voteDialog = nil
local volunteerDialog = nil
local markDialog = nil
local dialogMarkCostText = nil

local InvDialog = nil
local dialogInvCostText = nil


local revealIsDisabled --This variable is used to control the reveal UI behavior
local revealIsDone     --This variable is used to control the reveal UI behavior

local volunteer_tokens = 5				#number of tokens you get for volunteering

pUI = {
	arrow = false,
	box = false
}

pData = {
	phantom_armies = {},
	innocent_armies = {},
	paladin_armies = {},
	isPhantom = false,
	isPaladin = false,
	paladin_mark_count = 0
}

pStats = {
	phantom_count = 0,
	innocent_count = 0,
	paladin_count = 0,
	phantoms_dead = 0,
	innocents_dead = 0,
	paladins_dead = 0
}

 #This table stores indices of previously "marked" players.
 #It is used on the Paladin Mark UI panel to filter out previously selected players
 #(for the rare case when a Phantom has two marks to use)
alreadyInvestigated = {}


parent = false
function CreateModUI(isReplay, _parent)
	parent = _parent
	
	BuildUI()
	SetLayout()
	CommonLogic()
end

function BuildUI()

	# Create arrow checkbox
	pUI.arrow = Checkbox(parent)

	# Create group for main UI
	pUI.box = Group(parent)
	
	# Create main UI objects
	pUI.box.panel = Bitmap(pUI.box)
	pUI.box.leftBracket = Bitmap(pUI.box)
	pUI.box.leftBracketGlow = Bitmap(pUI.box)

	pUI.box.rightGlowTop = Bitmap(pUI.box)
	pUI.box.rightGlowMiddle = Bitmap(pUI.box)
	pUI.box.rightGlowBottom = Bitmap(pUI.box)
	
	pUI.box.title = UIUtil.CreateText(pUI.box, '', 18, UIUtil.bodyFont)
	pUI.box.title:SetDropShadow(true)
	
	pUI.box.countdown = UIUtil.CreateText(pUI.box, '', 14, UIUtil.bodyFont)
	pUI.box.countdown:SetDropShadow(true)
		
    pUI.box.kills = UIUtil.CreateText(pUI.box, '0/0', 14, UIUtil.bodyFont)
    pUI.box.kills:SetDropShadow(true)
    
    pUI.box.killIcon = Bitmap(pUI.box)
        
	pUI.box.detBtn = Button(pUI.box,
		UIUtil.SkinnableFile(modPath..'/textures/resources/mark_btn_up_ph.dds'),
		UIUtil.SkinnableFile(modPath..'/textures/resources/mark_btn_down_ph.dds'),
		UIUtil.SkinnableFile(modPath..'/textures/resources/mark_btn_over_ph.dds'),
		UIUtil.SkinnableFile(modPath..'/textures/resources/mark_btn_dis_ph.dds'), 
		'', '')		
		
	pUI.box.meteorBtn = Button(pUI.box,
		UIUtil.SkinnableFile(modPath..'/textures/resources/mark_btn_up_ph.dds'),
		UIUtil.SkinnableFile(modPath..'/textures/resources/mark_btn_down_ph.dds'),
		UIUtil.SkinnableFile(modPath..'/textures/resources/mark_btn_over_ph.dds'),
		UIUtil.SkinnableFile(modPath..'/textures/resources/mark_btn_dis_ph.dds'), 
		'', '')		
		
end

function SetLayout()
	# Assign layout info to arrow checkbox
	pUI.arrow:SetTexture(UIUtil.UIFile('/game/tab-l-btn/tab-close_btn_up.dds'))
	pUI.arrow:SetNewTextures(UIUtil.UIFile('/game/tab-l-btn/tab-close_btn_up.dds'),
		UIUtil.UIFile('/game/tab-l-btn/tab-open_btn_up.dds'),
		UIUtil.UIFile('/game/tab-l-btn/tab-close_btn_over.dds'),
		UIUtil.UIFile('/game/tab-l-btn/tab-open_btn_over.dds'),
		UIUtil.UIFile('/game/tab-l-btn/tab-close_btn_dis.dds'),
		UIUtil.UIFile('/game/tab-l-btn/tab-open_btn_dis.dds'))
		
	LayoutHelpers.AtLeftTopIn(pUI.arrow, GetFrame(0), -3, 172)
	pUI.arrow.Depth:Set(function() return pUI.box.Depth() + 10 end)

	# Assign layout info to main UI
	pUI.box.panel:SetTexture(UIUtil.UIFile('/game/resource-panel/resources_panel_bmp.dds'))
	LayoutHelpers.AtLeftTopIn(pUI.box.panel, pUI.box)

	pUI.box.Height:Set(pUI.box.panel.Height)
	pUI.box.Width:Set(pUI.box.panel.Width)
	LayoutHelpers.AtLeftTopIn(pUI.box, parent, 16, 153)
	
	pUI.box:DisableHitTest()

	pUI.box.leftBracket:SetTexture(UIUtil.UIFile('/game/filter-ping-panel/bracket-left_bmp.dds'))
	pUI.box.leftBracketGlow:SetTexture(UIUtil.UIFile('/game/filter-ping-panel/bracket-energy-l_bmp.dds'))

	pUI.box.leftBracket.Right:Set(function() return pUI.box.panel.Left() + 10 end)
	pUI.box.leftBracketGlow.Left:Set(function() return pUI.box.leftBracket.Left() + 12 end)

	pUI.box.leftBracket.Depth:Set(pUI.box.panel.Depth)
	pUI.box.leftBracketGlow.Depth:Set(function() return pUI.box.leftBracket.Depth() - 1 end)

	LayoutHelpers.AtVerticalCenterIn(pUI.box.leftBracket, pUI.box.panel)
	LayoutHelpers.AtVerticalCenterIn(pUI.box.leftBracketGlow, pUI.box.panel)

	pUI.box.rightGlowTop:SetTexture(UIUtil.UIFile('/game/bracket-right-energy/bracket_bmp_t.dds'))
	pUI.box.rightGlowMiddle:SetTexture(UIUtil.UIFile('/game/bracket-right-energy/bracket_bmp_m.dds'))
	pUI.box.rightGlowBottom:SetTexture(UIUtil.UIFile('/game/bracket-right-energy/bracket_bmp_b.dds'))

	pUI.box.rightGlowTop.Top:Set(function() return pUI.box.Top() + 2 end)
	pUI.box.rightGlowTop.Left:Set(function() return pUI.box.Right() - 12 end)
	pUI.box.rightGlowBottom.Bottom:Set(function() return pUI.box.Bottom() - 2 end)
	pUI.box.rightGlowBottom.Left:Set(pUI.box.rightGlowTop.Left)
	pUI.box.rightGlowMiddle.Top:Set(pUI.box.rightGlowTop.Bottom)
	pUI.box.rightGlowMiddle.Bottom:Set(function() return math.max(pUI.box.rightGlowTop.Bottom(), pUI.box.rightGlowBottom.Top()) end)
	pUI.box.rightGlowMiddle.Right:Set(function() return pUI.box.rightGlowTop.Right() end)

	LayoutHelpers.AtLeftTopIn(pUI.box.title, pUI.box, 15, 10)
	pUI.box.title:SetColor('ffb7e75f')
	
	LayoutHelpers.AtLeftTopIn(pUI.box.countdown, pUI.box, 15, 41)
	pUI.box.countdown:SetColor('ffb7e75f')		

	# Kills
	LayoutHelpers.AtTopIn(pUI.box.kills, pUI.box, 14)
	LayoutHelpers.AtRightIn(pUI.box.kills, pUI.box, 50)
	pUI.box.kills:SetColor('fff30017')
	pUI.box.kills:Hide()

	pUI.box.killIcon:SetTexture(UIUtil.UIFile('/game/unit-over/icon-skull_bmp.dds'))
	LayoutHelpers.AtTopIn(pUI.box.killIcon, pUI.box, 11)
	LayoutHelpers.AtRightIn(pUI.box.killIcon, pUI.box, 70)
	pUI.box.killIcon:Hide()

	# Buttons
	pUI.box.detBtn.Width:Set(36)
	pUI.box.detBtn.Height:Set(36)
	LayoutHelpers.AtLeftTopIn(pUI.box.detBtn, pUI.box, 214, 32)
	pUI.box.detBtn.Depth:Set(function() return pUI.box.Depth() + 10 end)
	pUI.box.detBtn:Hide()
	
	pUI.box.meteorBtn.Width:Set(36)
	pUI.box.meteorBtn.Height:Set(36)
	LayoutHelpers.AtLeftTopIn(pUI.box.meteorBtn, pUI.box, 214, 32)
	pUI.box.meteorBtn.Depth:Set(function() return pUI.box.Depth() + 10 end)
	pUI.box.meteorBtn:Hide()
	
	# Hide panel
	pUI.box:Hide()
	ShowHidePhantomElements(false)
	pUI.arrow:SetCheck(true, true)
	pUI.box.Left:Set(parent.Left()-pUI.box.Width())

end

function InitializeGameOptions()
	#Initialize Reveal Times
	
	reveal1 = 1 * 60
	reveal2 = 1 * 60
	reveal3 = 1 * 60
		
	revealTo = 1
	revealWho = 0
		
	death_reveal = 0
	mark_base_cost = 15000
	

	# Check and correct reveal times
	revealIsDisabled = false
	
	if reveal1 == 0 then
		# i.e. Reveal 1 is never...
		reveal2 = reveal1
		reveal3 = reveal1
		revealIsDisabled = true
	end
	if reveal2 == 0 then
		# i.e. Reveal 2 is never...
		reveal3 = reveal2
	end
	#End BugFix 3
	
	#Special Case 1 - Phantom 2 or Phantom 3 reveal time set to "Same as..."
	#Lobby wouldn't take fractional values for minutes, so had to do this here
	if(reveal2 == 60) then
		reveal2 = 12
	end
	if(reveal3 == 60) then
		reveal3 = 12
	end
	
	reveal1 = reveal1 + declare
	reveal2 = reveal1 + reveal2
	reveal3 = reveal2 + reveal3
	
	#Done Initializing Reveal Times
	
	revealIsDone = false
end

function CommonLogic()
	InitializeGameOptions()	
	
	# Add heartbeat
	GameMain.AddBeatFunction(PhantomUIBeat)
	GameMain.AddBeatFunction(InitPhantomPanel)
	GameMain.AddBeatFunction(RevealCountdownUIBeat)

	pUI.box.OnDestroy = function(self)
		GameMain.RemoveBeatFunction(PhantomUIBeat)
		GameMain.RemoveBeatFunction(RevealCountdownUIBeat)
	end

	# Button Actions
	pUI.arrow.OnCheck = function(self, checked)
		TogglePhantomPanel()
	end

	pUI.box.detBtn.OnClick = function(self, checked)
		pDetBtnClick()
	end	
	
	pUI.box.meteorBtn.OnClick = function(self, checked)
		pMeteorBtnClick()
	end	
	
end

function SetPhantomsRevealed(data)

	if data.phant1 then
		RevealUI.AddRevealedPlayer(data.phant1, 'Mafioso')
	end
	
	if data.phant2 then
		RevealUI.AddRevealedPlayer(data.phant2, 'Mafioso')
	end
	
	if data.phant3 then
		RevealUI.AddRevealedPlayer(data.phant3, 'Mafioso')
	end
	
	if data.pal1 then
		RevealUI.AddRevealedPlayer(data.pal1, 'Detective')
	end
	
	if data.pal2 then
		RevealUI.AddRevealedPlayer(data.pal2, 'Detective')
	end
	
	if data.pal3 then
		RevealUI.AddRevealedPlayer(data.pal3, 'Detective')
	end
end

# gets the total number of phantoms in this game
function GetPhantomCount()
	local maxIndex = 0
	for index, army in pData.phantom_armies do
		maxIndex = maxIndex + 1
	end
	return maxIndex
end

# gets the total number of phantoms in this game
function GetPaladinCount()
	local maxIndex = 0
	for index, army in pData.paladin_armies do
		maxIndex = maxIndex + 1
	end
	return maxIndex
end

# updates the countdown timer for the "next phantom revealed" text
function RevealCountdownUIBeat()
	if revealIsDisabled == false then
		local clock = GetGameTimeSeconds()
		if clock > declare then
			local time = 0
			time = reveal1 - clock
			#LOG('reveal countdown ui beat - ',time)
	
			if time < 0 then
				if GetPhantomCount() > 1 then
					time = reveal2 - clock
				end
			end
			if time < 0 then
				if GetPhantomCount() > 2 then
					time = reveal3 - clock
				end
			end
	
			if time < 0 then
				RevealFinished()
				RevealUI.SetTimeText('--:--')
			else
				RevealUI.SetTimeText(string.format("Next reveal in:  %02d:%02d", math.floor(time / 60), math.mod(time, 60)))
			end
			RevealUI.UpdateUI()
		end
	end
end

--This function will run one time after all reveal timers have expired
function RevealFinished()
	if revealIsDone == false then
		revealIsDone = true
		
		--Decide whether or not we want hide the reveal panel now...
		if pData.isPhantom and revealTo == 2 then
			RevealUI.HideBar()
		elseif pData.isPaladin and revealTo == 1 then
			RevealUI.HideBar()
		elseif pData.isPaladin == false and pData.isPhantom == false and revealTo > 0 then
			RevealUI.HideBar()
		end
		
		--Kick off post reveal function in UI (will auto hide the reveal panel after 30 seconds)
		RevealUI.ProcessPostRevealLogic()
	end
end

function PhantomUIBeat()
	#LOG('phantom UI beat')
	phantomSeconds = declare
	if table.getn(pData.phantom_armies) == 0 then
		timeLeft = phantomSeconds - GetGameTimeSeconds()
		if timeLeft < 0 then timeLeft = 0 end
		pUI.box.countdown:SetText(string.format("Time until assignment:  %02d:%02d", math.floor(timeLeft / 60), math.mod(timeLeft, 60)))
	end
end

function SetAssignment(assignment)
	pUI.box.title:SetText(assignment)
end

function SetPhantomData(data)
	if voteDialog then
		voteDialog:Destroy()
		voteDialog = nil
	end

	pData.isPhantom = data.isPhantom
	pData.isPaladin = data.isPaladin
	pData.paladin_mark_count = data.paladin_mark_count
	pData.phantom_armies = data.phantom_armies
	pData.innocent_armies = data.innocent_armies
	pData.paladin_armies = data.paladin_armies
	
	ShowHidePhantomElements(true)

	# Remove unnessessary countdown heartbeat
	GameMain.RemoveBeatFunction(PhantomUIBeat)
	
	#Make Reveal UI Visible
	if revealIsDisabled == false then
		RevealUI.ShowCheckBox()
		RevealUI.ShowBar()
	end
end

function SetPhantomStats(stats)
	pStats = stats
	if pData.isPhantom then
		# Show innocent kills
		pUI.box.kills:SetText(pStats.innocents_dead..'/'..pStats.innocent_count)
	else
		# Show phantom kills
		pUI.box.kills:SetText(pStats.phantoms_dead..'/'..pStats.phantom_count)
	end
	
	# Show player statuses
	local pRemain = pStats.phantom_count - pStats.phantoms_dead
	
	#number of innocents (excluding paladins, dead or otherwise)
	local iRemain = pStats.innocent_count - pStats.paladin_count - pStats.innocents_dead + pStats.paladins_dead
	
	local palRemain = pStats.paladin_count - pStats.paladins_dead
	if death_reveal == 1 then
		local statusText = "Alive: "
		statusText = statusText .. iRemain
		statusText = statusText .. " INNO, "
	
		#if iRemain > 1 or iRemain == 0 then
		#	statusText = statusText .. " innocents, "
		#else
		#	statusText = statusText .. " innocent, "
	
		#end
		statusText = statusText .. palRemain
		statusText = statusText .. " PLDN, "
	
		statusText = statusText .. pRemain
		statusText = statusText .. " PHTM"
		#if pRemain > 1 or pRemain == 0 then
		#	statusText = statusText .. " phantoms"
		#else
		#	statusText = statusText .. " phantom"
		#end
		pUI.box.countdown:SetText(statusText)
	else
		local statusText = "Remaining player counts disabled."
		pUI.box.countdown:SetText(statusText)
	end
	
end

function pDetBtnClick()
	if InvDialog == nil then
		ShowDetectivePanel()
	end
end

function pMeteorBtnClick()
	LOG("Meteor Button clicked.")
	CallMeteorStrike()
	LOG("Hiding Meteor Button")
	pUI.box.meteorBtn:Hide()
end

function ShowMeteorBtn(allow)
	LOG("Calling ShowMeteorButton")
	if allow == 1 then
		LOG("Showing Meteor Button")
		pUI.box.meteorBtn:Show()
	end
end

function CallMeteorStrike()
	LOG("CallMeteorStrike")
	local cmdMode = import('/lua/ui/game/commandmode.lua')
	
	local modeData = {
		name = "RULEUCC_Script",
		AbilityName="MafiaMeteors",
		Taskname="MafiaMeteors",
	}
			
	#local modeData = {
    #    cursor = "RULEUCC_Attack",
    #    pingtype = 'attack',
    #    pingLocation=false,
    #}
	
    cmdMode.StartCommandMode("order", modeData)
end
	
function TogglePhantomPanel(state)
	if import('/lua/ui/game/gamemain.lua').gameUIHidden and state != nil then
		return
	end

	if UIUtil.GetAnimationPrefs() then
		if state or pUI.box:IsHidden() then
			PlaySound(Sound({Cue = "UI_Score_Window_Open", Bank = "Interface"}))
			pUI.box:Show()
			ShowHidePhantomElements(true)
			pUI.box:SetNeedsFrameUpdate(true)
			pUI.box.OnFrame = function(self, delta)
				local newLeft = self.Left() + (1000*delta)
				if newLeft > parent.Left()+14 then
					newLeft = parent.Left()+14
					self:SetNeedsFrameUpdate(false)
				end
				self.Left:Set(newLeft)
			end
			pUI.arrow:SetCheck(false, true)
		else
			PlaySound(Sound({Cue = "UI_Score_Window_Close", Bank = "Interface"}))
			pUI.box:SetNeedsFrameUpdate(true)
			pUI.box.OnFrame = function(self, delta)
				local newLeft = self.Left() - (1000*delta)
				if newLeft < parent.Left()-self.Width() then
					newLeft = parent.Left()-self.Width()
					self:SetNeedsFrameUpdate(false)
					self:Hide()
					ShowHidePhantomElements(false)
				end
				self.Left:Set(newLeft)
			end
			pUI.arrow:SetCheck(true, true)
		end
	else
		if state or pUI.box:IsHidden() then
			pUI.box:Show()
			ShowHidePhantomElements(true)
			pUI.arrow:SetCheck(false, true)
		else
			pUI.box:Hide()
			ShowHidePhantomElements(false)
			pUI.arrow:SetCheck(true, true)
		end
	end
end

function InitPhantomPanel()
	if import('/lua/ui/game/gamemain.lua').gameUIHidden then
		return
	end
	
	if UIUtil.GetAnimationPrefs() then
		pUI.box:Show()
		pUI.box:SetNeedsFrameUpdate(true)
		pUI.box.OnFrame = function(self, delta)
			local newLeft = self.Left() + (1000*delta)
			if newLeft > parent.Left()+14 then
				newLeft = parent.Left()+14
				self:SetNeedsFrameUpdate(false)
			end
			self.Left:Set(newLeft)
		end
		pUI.arrow:SetCheck(false, true)

	else
		pUI.box:Show()
		pUI.arrow:SetCheck(false, true)	
	end
	pUI.box.detBtn:Hide()
	pUI.box.meteorBtn:Hide()

	pUI.box.kills:Hide()
	pUI.box.killIcon:Hide()
	
	RevealUI.CreateRevealUI(parent)
	
	GameMain.RemoveBeatFunction(InitPhantomPanel)
end

function ShowHidePhantomElements(show) 
	if show then
		if pData.isPhantom then
			pUI.box.meteorBtn:Hide()
		elseif pData.isPaladin then
			pUI.box.detBtn:Show()
			pUI.box.meteorBtn:Hide()
		else
			pUI.box.meteorBtn:Hide()
			pUI.box.detBtn:Hide()	
		end
		if table.getn(pData.phantom_armies) > 0 and death_reveal == 1 then
			pUI.box.kills:Show()
			pUI.box.killIcon:Show()		
		else
			pUI.box.kills:Hide()
			pUI.box.killIcon:Hide()		
		end
		
	else

		pUI.box.kills:Hide()
		pUI.box.killIcon:Hide()
		pUI.box.detBtn:Hide()
		pUI.box.meteorBtn:Hide()
	end
end

function ShowAlert(args)
	import('/lua/ui/game/announcement.lua').CreateAnnouncement(args[1], pUI.arrow, args[2])
end

function QueryResult(data)
	# Nothing needed
end

function ShowVolunteerVote()
	if not SessionIsReplay() then
		
		local layout =  UIUtil.SkinnableFile(modPath..'/modules/layout/volunteer.lua')
		local worldView = import('/lua/ui/game/worldview.lua').view
		
		volunteerDialog = Bitmap(worldView, UIUtil.SkinnableFile('/dialogs/diplomacy-team-alliance/team-panel_bmp.dds'))
		volunteerDialog:SetRenderPass(UIUtil.UIRP_PostGlow)  -- just in case our parent is the map
		volunteerDialog:SetName("Volunteer Vote")
		LayoutHelpers.AtCenterIn(volunteerDialog,worldView)
		local dialogTitle = UIUtil.CreateText(volunteerDialog, "Volunteer to be a Mafioso", 16, UIUtil.titleFont )
		dialogTitle:SetColor( UIUtil.dialogCaptionColor )
		LayoutHelpers.RelativeTo(dialogTitle, volunteerDialog, layout, "title", "panel")
		local text = "Do you want to increase your chances to be Mafioso?"
		local message = UIUtil.CreateText(volunteerDialog, text, 12, UIUtil.bodyFont )
		LayoutHelpers.RelativeTo(message, volunteerDialog, layout, "text", "panel")
		LayoutHelpers.AtHorizontalCenterIn(message,volunteerDialog)
		
		local function MakeClickCallback(result)
			return function(self, modifiers)
				volunteerDialog:Destroy()
				volunteerDialog = nil
				SetVolunteerVote(result)
			end
		end
				local one = UIUtil.CreateDialogButtonStd(volunteerDialog, "/dialogs/standard_btn/standard", "Yes", 12)
		LayoutHelpers.RelativeTo(one, volunteerDialog, layout, "btn_one", "panel")
		one.OnClick = MakeClickCallback(volunteer_tokens)     #for testing only
		
		local two = UIUtil.CreateDialogButtonStd(volunteerDialog, "/dialogs/standard_btn/standard", "No", 12)
		LayoutHelpers.RelativeTo(two, volunteerDialog, layout, "btn_two", "panel")
		two.OnClick = MakeClickCallback(1)
		
	end
end

function ShowPhantomVote()
	if not SessionIsReplay() then
		
			local layout =  UIUtil.SkinnableFile(modPath..'/modules/layout/vote.lua')
			local worldView = import('/lua/ui/game/worldview.lua').view
			
			voteDialog = Bitmap(worldView, UIUtil.SkinnableFile('/dialogs/diplomacy-team-alliance/team-panel_bmp.dds'))
			voteDialog:SetRenderPass(UIUtil.UIRP_PostGlow)  -- just in case our parent is the map
			voteDialog:SetName("Mafia Vote")
		
			LayoutHelpers.AtCenterIn(voteDialog,worldView)
		
			local dialogTitle = UIUtil.CreateText(voteDialog, "Mafia Vote", 18, UIUtil.titleFont )
			dialogTitle:SetColor( UIUtil.dialogCaptionColor )
			LayoutHelpers.RelativeTo(dialogTitle, voteDialog, layout, "title", "panel")
		
			local text = "Select the number of players to be designated Mafiosi"
			local message = UIUtil.CreateText(voteDialog, text, 12, UIUtil.bodyFont )
			LayoutHelpers.RelativeTo(message, voteDialog, layout, "text", "panel")
			LayoutHelpers.AtHorizontalCenterIn(message,voteDialog)
		
			local function MakeClickCallback(result)
				return function(self, modifiers)
					voteDialog:Destroy()
					voteDialog = nil
					SetVote(result)
				end
			end
		
			local one = UIUtil.CreateDialogButtonStd(voteDialog, "/dialogs/standard_btn/standard", "One", 12)
			LayoutHelpers.RelativeTo(one, voteDialog, layout, "btn_one", "panel")
			one.OnClick = MakeClickCallback(1)
		
			local two = UIUtil.CreateDialogButtonStd(voteDialog, "/dialogs/standard_btn/standard", "Two", 12)
			LayoutHelpers.RelativeTo(two, voteDialog, layout, "btn_two", "panel")
			two.OnClick = MakeClickCallback(2)
		
			local three = UIUtil.CreateDialogButtonStd(voteDialog, "/dialogs/standard_btn/standard", "Three", 12)
			LayoutHelpers.RelativeTo(three, voteDialog, layout, "btn_three", "panel")
			three.OnClick = MakeClickCallback(3)
	end
end

function SetVolunteerVote(vote)
	data = {
		From = GetFocusArmy(),
		To = -1,
		Name = "VolunteerVote",
		#Args = { ID = GetArmiesTable().armiesTable[GetFocusArmy()], Token = vote }
		Args = { ID = GetFocusArmy(), Token = vote }
	}
	import('/lua/UserPlayerQuery.lua').Query( data, QueryResult )	
end

function SetVote(vote)
	data = {
		From = GetFocusArmy(),
		To = -1,
		Name = "PhantomVote",
		Args = { Nick = GetArmiesTable().armiesTable[GetFocusArmy()].nickname, Vote = vote }
	}
	import('/lua/UserPlayerQuery.lua').Query( data, QueryResult )	
end

function ShowDetectivePanel()
	local layout =  UIUtil.SkinnableFile(modPath..'/modules/layout/SelectMark.lua')
	local worldView = import('/lua/ui/game/worldview.lua').view
	
	InvDialog = Bitmap(worldView, UIUtil.SkinnableFile('/dialogs/diplomacy/diplomacy-panel_bmp.dds'))
	InvDialog:SetRenderPass(UIUtil.UIRP_PostGlow)  -- just in case our parent is the map
	InvDialog:SetName("Investigate Player")

	LayoutHelpers.AtCenterIn(InvDialog,worldView)

	local dialogTitle = UIUtil.CreateText(InvDialog, "Investigate Player", 16, UIUtil.titleFont )
	dialogTitle:SetColor( UIUtil.dialogCaptionColor )
	LayoutHelpers.RelativeTo(dialogTitle, InvDialog, layout, "title", "panel")
	
	#Remaining Marks
	#local dialogMarksRemaining = UIUtil.CreateText(InvDialog, "Available Uses: "..pData.paladin_mark_count, 14, UIUtil.bodyFont )
	#LayoutHelpers.RelativeTo(dialogMarksRemaining, InvDialog, layout, "remaining-marks", "panel")
	
	#Mark Cost
	dialogInvCostText = UIUtil.CreateText(InvDialog, "Investigation Cost (Mass): ", 14, UIUtil.bodyFont )
	LayoutHelpers.RelativeTo(dialogInvCostText, InvDialog, layout, "mark-cost", "panel")

	local function MakeClickCallback(target)
		return function(self, modifiers)
			GameMain.RemoveBeatFunction(UpdateDetectiveCost)
			InvDialog:Destroy()
			InvDialog = nil
			InvestigatePlayer(target)
		end
	end
	
	local armyList = GetArmiesTable()
	for index, army in armyList.armiesTable do		
		if not (GetFocusArmy() == index) and not army.civilian then		
			#Build name text
			local playerNameText =  UIUtil.CreateText(InvDialog, army.nickname, 12, UIUtil.bodyFont )
			LayoutHelpers.RelativeTo(playerNameText, InvDialog, layout, "player-1-name", "panel", (index-1) * 25, 0)

			#Build button
			local markButton = UIUtil.CreateCheckboxStd(InvDialog, '/dialogs/check-box_btn/radio')
	        markButton.row = index
	        LayoutHelpers.RelativeTo(markButton, InvDialog, layout, "player-1-btn", "panel", (index-1) * 25, 0)
	        markButton.OnCheck = MakeClickCallback(index)
		end
	end
	
	#Close Button
	local function CloseCallback()
		return function(self, modifiers)
			GameMain.RemoveBeatFunction(UpdateDetectiveCost)
			InvDialog:Destroy()
			InvDialog = nil
		end
	end
	
	local button = UIUtil.CreateDialogButtonStd(InvDialog, "/dialogs/standard_btn/standard", "Close", 10)
	LayoutHelpers.RelativeTo(button, InvDialog, layout, "close-button", "panel")
	button.OnClick = CloseCallback()

	GameMain.AddBeatFunction(UpdateDetectiveCost)
end

function InvestigatePlayer(target)
	#table.insert(alreadyInvestigated, target)
	#Send mark action back to sim
	data = {
		From = GetFocusArmy(),
		To = -1,
		Name = "PlayerInvestigated",
		Args = { MarkedArmy = target}
	}
	import('/lua/UserPlayerQuery.lua').Query( data, QueryResult )
end

function UpdateDetectiveCost()
	local luckyGuessProbability = pStats.paladin_count / (pStats.innocent_count + pStats.paladin_count)
	local massCost = (1.0 / luckyGuessProbability) *  mark_base_cost
	local maxMassCost = 100000
	local currGameTime = (GetGameTimeSeconds() - declare) / 60
	local slopeCoeff = 0.05
		
	local markCost = math.floor((massCost + maxMassCost * math.atan( slopeCoeff * currGameTime )) * luckyGuessProbability)
	markCost = 10000
	dialogInvCostText:SetText('Investigation Cost (Mass): '..markCost)
end