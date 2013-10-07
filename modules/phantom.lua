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
local MeteorUI = import('/modules/meteor_ui.lua')

local declare = 8 * 60

local sessionInfo = SessionGetScenarioInfo()

local reveal1
local reveal2
local reveal3
local revealTo
local revealWho
local death_reveal
local mark_base_cost
local meteorsAreEnabled

local voteDialog = nil
local volunteerDialog = nil
local markDialog = nil
local dialogMarkCostText = nil

local revealIsDisabled --This variable is used to control the reveal UI behavior
local revealIsDone     --This variable is used to control the reveal UI behavior

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
alreadyMarked = {}


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
		
	pUI.box.bonus = UIUtil.CreateText(pUI.box, '', 14, UIUtil.bodyFont)
	pUI.box.bonus:SetDropShadow(true)
	
    pUI.box.mass = UIUtil.CreateText(pUI.box, '+0', 10, UIUtil.bodyFont)
    pUI.box.mass:SetDropShadow(true)
    pUI.box.energy = UIUtil.CreateText(pUI.box, '+0', 10, UIUtil.bodyFont)
    pUI.box.energy:SetDropShadow(true)

    pUI.box.kills = UIUtil.CreateText(pUI.box, '0/0', 14, UIUtil.bodyFont)
    pUI.box.kills:SetDropShadow(true)
    
    pUI.box.killIcon = Bitmap(pUI.box)
        
	pUI.box.massBtn = Button(pUI.box,
		UIUtil.SkinnableFile(modPath..'/textures/resources/mass_btn_up_ph.dds'),
		UIUtil.SkinnableFile(modPath..'/textures/resources/mass_btn_down_ph.dds'),
		UIUtil.SkinnableFile(modPath..'/textures/resources/mass_btn_over_ph.dds'),
		UIUtil.SkinnableFile(modPath..'/textures/resources/mass_btn_dis_ph.dds'), 
		'', '')
	#Tooltip.AddButtonTooltip(pUI.box.massBtn, Tooltip.CreateExtendedToolTip(pUI.box.massBtn, 'Dump Mass', 'Dumps 90% of your mass reserve to prevent looking suspicious'))

	pUI.box.energyBtn = Button(pUI.box,
		UIUtil.SkinnableFile(modPath..'/textures/resources/energy_btn_up_ph.dds'),
		UIUtil.SkinnableFile(modPath..'/textures/resources/energy_btn_down_ph.dds'),
		UIUtil.SkinnableFile(modPath..'/textures/resources/energy_btn_over_ph.dds'),
		UIUtil.SkinnableFile(modPath..'/textures/resources/energy_btn_dis_ph.dds'), 
		'', '')	
		
	pUI.box.markBtn = Button(pUI.box,
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

	# Mass
	# Phantom Special Options
	LayoutHelpers.AtTopIn(pUI.box.mass, pUI.box, 10)
	LayoutHelpers.AtRightIn(pUI.box.mass, pUI.box, 20)
	pUI.box.mass:SetColor('ffb7e75f')
	pUI.box.mass:Hide()

	# Energy
	LayoutHelpers.AtTopIn(pUI.box.energy, pUI.box, 22)
	LayoutHelpers.AtRightIn(pUI.box.energy, pUI.box, 20)
	pUI.box.energy:SetColor('fff7c70f')
	pUI.box.energy:Hide()
	
	# Bonus Percentage
	LayoutHelpers.AtLeftTopIn(pUI.box.bonus, pUI.box, 140, 14)
	pUI.box.bonus:SetColor('ffb7e75f')
	pUI.box.bonus:Hide()
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
	pUI.box.massBtn.Width:Set(36)
	pUI.box.massBtn.Height:Set(36)
	LayoutHelpers.AtLeftTopIn(pUI.box.massBtn, pUI.box, 245, 32)
	pUI.box.massBtn.Depth:Set(function() return pUI.box.Depth() + 10 end)
	pUI.box.massBtn:Hide()
	
	pUI.box.energyBtn.Width:Set(36)
	pUI.box.energyBtn.Height:Set(36)
	LayoutHelpers.AtLeftTopIn(pUI.box.energyBtn, pUI.box, 276, 32)
	pUI.box.energyBtn.Depth:Set(function() return pUI.box.Depth() + 10 end)
	pUI.box.energyBtn:Hide()
	
	pUI.box.markBtn.Width:Set(36)
	pUI.box.markBtn.Height:Set(36)
	LayoutHelpers.AtLeftTopIn(pUI.box.markBtn, pUI.box, 214, 32)
	pUI.box.markBtn.Depth:Set(function() return pUI.box.Depth() + 10 end)
	pUI.box.markBtn:Hide()
	
	# Hide panel
	pUI.box:Hide()
	ShowHidePhantomElements(false)
	pUI.arrow:SetCheck(true, true)
	pUI.box.Left:Set(parent.Left()-pUI.box.Width())

end

function InitializeGameOptions()
	#Initialize Reveal Times
	reveal1 =(tonumber(sessionInfo.Options.PhantomRevealTime1) * 60)
	reveal2 =(tonumber(sessionInfo.Options.PhantomRevealTime2) * 60)
	reveal3 =(tonumber(sessionInfo.Options.PhantomRevealTime3) * 60)
	
	revealTo = (tonumber(sessionInfo.Options.PhantomRevealTo))
	revealWho = (tonumber(sessionInfo.Options.PhantomRevealWho))
	
    death_reveal = (tonumber(sessionInfo.Options.Phantom_DeathReveal))
    mark_base_cost = 5000
    
    meteorsAreEnabled = (tonumber(sessionInfo.Options.Phantom_Meteor))==1    

	#Test Code
	#reveal1 = 35 * 60
	#reveal2 = 1 * 60
	#reveal3 = 1 * 60
    #death_reveal = 1
	#End Test Code
	
	
	# BugFix 3: This code corrects a problem that would cause the countdown timer to
	#			count down for phantoms that will not be revealed.
	#			This only happened if Phantom 1 or 2 are set to never and phantom 2 or 3 are set to some number
	#			This fix sets reveal2 and/or reveal 3 to "never" if the preceding reveal time is also "never"
	
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
    GameMain.AddBeatFunction(MeteorCountdownUIBeat)

	pUI.box.OnDestroy = function(self)
		GameMain.RemoveBeatFunction(PhantomUIBeat)
		GameMain.RemoveBeatFunction(RevealCountdownUIBeat)
        GameMain.RemoveBeatFunction(MeteorCountdownUIBeat)
	end

	# Button Actions
	pUI.arrow.OnCheck = function(self, checked)
		TogglePhantomPanel()
	end

	pUI.box.massBtn.OnClick = function(self, checked)
		pMassBtnClick()
	end

	pUI.box.energyBtn.OnClick = function(self, checked)
		pEnergyBtnClick()
	end	
	
	pUI.box.markBtn.OnClick = function(self, checked)
		pMarkBtnClick()
	end	
end

function SetPhantomsRevealed(data)
	if data.phant1 then
		RevealUI.AddRevealedPlayer(data.phant1, 'Phantom')
	end
	
	if data.phant2 then
		RevealUI.AddRevealedPlayer(data.phant2, 'Phantom')
	end
	
	if data.phant3 then
		RevealUI.AddRevealedPlayer(data.phant3, 'Phantom')
	end
	
	if data.pal1 then
		RevealUI.AddRevealedPlayer(data.pal1, 'Paladin')
	end
	
	if data.pal2 then
		RevealUI.AddRevealedPlayer(data.pal2, 'Paladin')
	end
	
	if data.pal3 then
		RevealUI.AddRevealedPlayer(data.pal3, 'Paladin')
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

function MeteorCountdownUIBeat()
    local t = GetGameTimeSeconds()
    if meteorsAreEnabled and t > declare then
        MeteorUI.UpdateUI()
    end
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

	#local phantoms = 'Phantoms: '
	#for index, army in pData.phantom_armies do
	#	phantoms = phantoms .. GetArmiesTable().armiesTable[army].nickname .. ', '
	#end
	#print(phantoms)
	#local innocents = 'Innocents: '
	#for index, army in pData.innocent_armies do
	#	innocents = innocents .. GetArmiesTable().armiesTable[army].nickname .. ', '
	#end
	#print(innocents)

	
	# Remove unnessessary countdown heartbeat
	GameMain.RemoveBeatFunction(PhantomUIBeat)
	
	#Make Reveal UI Visible
	if revealIsDisabled == false then
		RevealUI.ShowCheckBox()
		RevealUI.ShowBar()
        
        --If Reveal is visible, put meteor panel under it
        MeteorUI.SetTop(RevealUI.GetPanelBottom() + 20)
	end
    if meteorsAreEnabled then
		MeteorUI.ShowCheckBox()
		MeteorUI.ShowBar()
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

function SetPhantomEco(pEco)
	if pData.isPhantom or pData.isPaladin then
		pUI.box.mass:SetText("+" .. pEco.mass)
		pUI.box.energy:SetText("+" .. pEco.energy)
	end
	if pData.isPhantom then
		pUI.box.bonus:SetText("Bonus: " .. pEco.bonus .. "%")
	end	
end

function pMassBtnClick()
	data = {
		From = GetFocusArmy(),
		To = -1,
		Name = "PhantomDumpResources",
		Args = "MASS"
	}
	import('/lua/UserPlayerQuery.lua').Query( data, QueryResult )
end

function pEnergyBtnClick()
	data = {
		From = GetFocusArmy(),
		To = -1,
		Name = "PhantomDumpResources",
		Args = "ENERGY"
	}
	import('/lua/UserPlayerQuery.lua').Query( data, QueryResult )	
end

function pMarkBtnClick()
	if markDialog == nil then
		ShowMarkPanel()
	end
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
	pUI.box.mass:Hide()
	pUI.box.energy:Hide()
	pUI.box.bonus:Hide()
	pUI.box.massBtn:Hide()
	pUI.box.energyBtn:Hide()
	pUI.box.markBtn:Hide()
	pUI.box.kills:Hide()
	pUI.box.killIcon:Hide()
	
	RevealUI.CreateRevealUI(parent)
    MeteorUI.CreateMeteorUI(parent)
	
	GameMain.RemoveBeatFunction(InitPhantomPanel)
end

function ShowHidePhantomElements(show) 
	if show then
		if pData.isPhantom then
			pUI.box.mass:Show()
			pUI.box.energy:Show()
			pUI.box.bonus:Show()
			
			pUI.box.massBtn:Show()
			pUI.box.energyBtn:Show()
			
			if pData.paladin_mark_count > 0 then
				pUI.box.markBtn:Show()
			end
		elseif pData.isPaladin then
			pUI.box.mass:Show()
			pUI.box.energy:Show()
			pUI.box.bonus:Show()
		else
			pUI.box.mass:Hide()
			pUI.box.energy:Hide()
			pUI.box.massBtn:Hide()
			pUI.box.energyBtn:Hide()
			pUI.box.bonus:Hide()
			pUI.box.markBtn:Hide()	
		end
		if table.getn(pData.phantom_armies) > 0 and death_reveal == 1 then
			pUI.box.kills:Show()
			pUI.box.killIcon:Show()		
		else
			pUI.box.kills:Hide()
			pUI.box.killIcon:Hide()		
		end
		
	else
		pUI.box.mass:Hide()
		pUI.box.energy:Hide()
		pUI.box.bonus:Hide()
		pUI.box.massBtn:Hide()
		pUI.box.energyBtn:Hide()
		pUI.box.kills:Hide()
		pUI.box.killIcon:Hide()
		pUI.box.markBtn:Hide()	
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
	
		local dialogTitle = UIUtil.CreateText(volunteerDialog, "Volunteer to be Phantom", 16, UIUtil.titleFont )
		dialogTitle:SetColor( UIUtil.dialogCaptionColor )
		LayoutHelpers.RelativeTo(dialogTitle, volunteerDialog, layout, "title", "panel")
	
		local text = "Do you want to increase your chances to be Phantom?"
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
		one.OnClick = MakeClickCallback(1)
		
		local two = UIUtil.CreateDialogButtonStd(volunteerDialog, "/dialogs/standard_btn/standard", "No", 12)
		LayoutHelpers.RelativeTo(two, volunteerDialog, layout, "btn_two", "panel")
		two.OnClick = MakeClickCallback(0)
	end
end

function ShowPhantomVote()
	if not SessionIsReplay() then
		local layout =  UIUtil.SkinnableFile(modPath..'/modules/layout/vote.lua')
		local worldView = import('/lua/ui/game/worldview.lua').view
		
		voteDialog = Bitmap(worldView, UIUtil.SkinnableFile('/dialogs/diplomacy-team-alliance/team-panel_bmp.dds'))
		voteDialog:SetRenderPass(UIUtil.UIRP_PostGlow)  -- just in case our parent is the map
		voteDialog:SetName("Phantom Vote")
	
		LayoutHelpers.AtCenterIn(voteDialog,worldView)
	
		local dialogTitle = UIUtil.CreateText(voteDialog, "Phantom Vote", 18, UIUtil.titleFont )
		dialogTitle:SetColor( UIUtil.dialogCaptionColor )
		LayoutHelpers.RelativeTo(dialogTitle, voteDialog, layout, "title", "panel")
	
		local text = "Select the number of players to be designated Phantoms"
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

function SetVolunteerVote(choice)
	data = {
		From = GetFocusArmy(),
		To = -1,
		Name = "VolunteerVote",
		#Args = { ID = GetArmiesTable().armiesTable[GetFocusArmy()], Volunteered = 1 }
		Args = { ID = GetFocusArmy(), Volunteered = choice }
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

function ShowMarkPanel()
	local layout =  UIUtil.SkinnableFile(modPath..'/modules/layout/SelectMark.lua')
	local worldView = import('/lua/ui/game/worldview.lua').view
	
	markDialog = Bitmap(worldView, UIUtil.SkinnableFile('/dialogs/diplomacy/diplomacy-panel_bmp.dds'))
	markDialog:SetRenderPass(UIUtil.UIRP_PostGlow)  -- just in case our parent is the map
	markDialog:SetName("Select Paladin")

	LayoutHelpers.AtCenterIn(markDialog,worldView)

	local dialogTitle = UIUtil.CreateText(markDialog, "Mark Paladin", 16, UIUtil.titleFont )
	dialogTitle:SetColor( UIUtil.dialogCaptionColor )
	LayoutHelpers.RelativeTo(dialogTitle, markDialog, layout, "title", "panel")
	
	#Remaining Marks
	local dialogMarksRemaining = UIUtil.CreateText(markDialog, "Available Marks: "..pData.paladin_mark_count, 14, UIUtil.bodyFont )
	LayoutHelpers.RelativeTo(dialogMarksRemaining, markDialog, layout, "remaining-marks", "panel")
	
	#Mark Cost
	dialogMarkCostText = UIUtil.CreateText(markDialog, "Mark Cost (Mass): ", 14, UIUtil.bodyFont )
	LayoutHelpers.RelativeTo(dialogMarkCostText, markDialog, layout, "mark-cost", "panel")

	local function MakeClickCallback(target)
		return function(self, modifiers)
			GameMain.RemoveBeatFunction(UpdateMarkCost)
			markDialog:Destroy()
			markDialog = nil
			MarkPaladin(target)
		end
	end
	
	local armyList = GetArmiesTable()
	for index, army in armyList.armiesTable do		
		if not (GetFocusArmy() == index) and not army.civilian then		
			#Build name text
			local playerNameText =  UIUtil.CreateText(markDialog, army.nickname, 12, UIUtil.bodyFont )
			LayoutHelpers.RelativeTo(playerNameText, markDialog, layout, "player-1-name", "panel", (index-1) * 25, 0)

			#Build button
			local markButton = UIUtil.CreateCheckboxStd(markDialog, '/dialogs/check-box_btn/radio')
	        markButton.row = index
	        LayoutHelpers.RelativeTo(markButton, markDialog, layout, "player-1-btn", "panel", (index-1) * 25, 0)
	        markButton.OnCheck = MakeClickCallback(index)
	        if pData.paladin_mark_count <= 0 or IsAlreadyMarked(index) then
				markButton:Disable()
			end
		end
	end
	
	#Close Button
	local function CloseCallback()
		return function(self, modifiers)
			GameMain.RemoveBeatFunction(UpdateMarkCost)
			markDialog:Destroy()
			markDialog = nil
		end
	end
	
	local button = UIUtil.CreateDialogButtonStd(markDialog, "/dialogs/standard_btn/standard", "Close", 10)
	LayoutHelpers.RelativeTo(button, markDialog, layout, "close-button", "panel")
	button.OnClick = CloseCallback()

	GameMain.AddBeatFunction(UpdateMarkCost)
end

function MarkPaladin(target)
	if pData.paladin_mark_count > 0 then
		pData.paladin_mark_count = pData.paladin_mark_count - 1
		if pData.paladin_mark_count <= 0 then
			pUI.box.markBtn:Hide()
		end
	
		#Record that we're using a mark on this player (for UI purposes)
		table.insert(alreadyMarked, target)
		
		#Send mark action back to sim
		data = {
			From = GetFocusArmy(),
			To = -1,
			Name = "PaladinPlayerMarked",
			Args = { MarkedArmy = target}
		}
		import('/lua/UserPlayerQuery.lua').Query( data, QueryResult )
	end
end

#This function returns a value indicating whether or not a mark has been attempted against the specified player
#by the current player. It does not indicate that the specified player IS actually a marked Paladin.
function IsAlreadyMarked(army)
	if table.getn(alreadyMarked) == 0 then
		return false
	else
		for index, p in alreadyMarked do
			if p == army then
				return true
			end
		end
		return false
	end
end
function UpdateMarkCost()
	local luckyGuessProbability = pStats.paladin_count / (pStats.innocent_count + pStats.paladin_count)
	local massCost = (1.0 / luckyGuessProbability) *  mark_base_cost
	local maxMassCost = 100000
	local currGameTime = (GetGameTimeSeconds() - declare) / 60
	local slopeCoeff = 0.05
		
	local markCost = math.floor((massCost + maxMassCost * math.atan( slopeCoeff * currGameTime )) * luckyGuessProbability)
	dialogMarkCostText:SetText('Mark Cost (Mass): '..markCost)
end

function UpdateAssignmentTime(newTime)
	declare = newTime 
end