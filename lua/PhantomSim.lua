--****************************************************************************
--**
--**  File     :  /lua/PhantomSim.lua
--**  Author(s):  novaprim3
--**
--**  Summary  :  Multi-Phantom Mod for Forged Alliance
--**
--**  Change Log:
--**  2012.06.02: Fixed multiple problems with phantom reveal code.  Duck_42
--**  2012.06.03: Fixed pAlert syntax, and added phantom numbering.  Duck_42
--**  2012.06.08: Fixed pAlert syntax (correctly) and other bugs.    Duck_42
--**  2012.06.10: Added delay before final announcement blurb.       Duck_42
--**  2012.07.07: Added phantom bonus info to UI callback.           Duck_42
--**  2012.07.17: Modified phantom bonus caluclations to use actual 
--**              number of live Phantoms instead of the starting
--**              number, Reduced Phantom bonuses slightly, Added
--**				 mass and energy storage boost for Phantoms.        Duck_42
--**  2012.07.28: Added code for paladin assignment.                 Duck_42
--**  2012.07.31: Added code for performing paladin UI tasks, added
--**              "Reveal To", "RevealWho", and bonus multiplier 
--**              configuration options.								Duck_42
--**  2012.08.16: Added code and lobby option to allow hiding a 
--**			     players assigment after his death					mead
--**  2012.10.13: Added code to support marking Paladins				Duck_42
--**  2012.10.20: Added code to obfuscate bonus amounts
--**  			 (only updated every 30 seconds).  This will help
--**				 prevent phantoms and paladins from easily 
--**				 identifying each other                             mead
--**  2012.10.20: Added code to allow players to volunteer to be 
--**  			 phantom. Volunteering does not gurrantee that a 
--**				 player will be selected, but it does greatly
--**				 increase the odds.                                 mead
--**  2013.01.23: Added code for rudimentary autoteam-balacing 		mead
--**  2013.02.01: autobalancing now selects the first Phantom 
--**				 randomly and the other deliberately based on 
--**				 that choice 										mead
--**  2013.02.01: Added code to allow allying after death            Duck_42
--**  2013.02.01: Removed Paladin bonus % indicator from UI          mead
--**  2013.02.24: Changed reveal code to support new UI.             Duck_42
--**  2013 	   : Added lobby cpu benchmark							Duck_42
--**  2013 	   : Integrated the automatic nuke ping mod				Duck_42
--**  2013 	   : the faction icon in the score table UI part now	Duck_42	
--**				 flashes if a player pings
--**	 2013.04.01: Surprise.											mead	
--**  2013.07.12: Added code for better netlag handling				Duck_42 & mead
--**				 Added code for meteors			
--** 			 small change to volunteering effect
--**				 Added lobby option to choose number of phantoms
--**				 Added faction selector for "random, but not uef"				 
--****************************************************************************
local modPath = 'Phantom-X'

local cur = {
	innocents = {},
	phantoms = {},
	paladins = {}, --Paladin armies are stored here (paladin armies are also stored in innocents array)
	marked_paladins = {}, --Paladins that have been marked by a Phantom are stored here (as well as in paladin and innocent arrays)
	delta = { mass = {}, energy = {} }, 
	phantom_war = false,
	trash = nil,
	config = {
		balance_multiplier = 1.0,    --This variable is used to globally adjust the phantom/paladin bonus up or down (for balancing)
		vote = 6 * 60,
		volunteer = 7 * 60,
		declare = 8 * 60,
		reveal1 = 35 * 60,
		reveal2 = 1 * 60,
		reveal3 = 1 * 60,
		revealto = 3,			 			--0-Everyone, 1-Phantoms Only, 2-Paladins Only, 3-Phantoms and Paladins Only
		revealwho = 0,			   			--0-Phantoms, 1-Paladins, 2-Phantoms and Paladins
		phantom_coefficient = 1/3, 
		paladin_coefficient = 3/5, 			--For every one phantom there will be three fifths of a paladin (rounded down)
		paladin_bonus = 0.45,      			--Paladins get 45% of the Phantom Bonus
		paladin_marks = 2,		  			--Number of paladin marks given to Phantoms
		paladin_mark_base_mass_cost = 4000, --Base mass cost for using a Paladin mark
		death_reveal= 1,          			--After a player dies, his assigment is revealed to the others
		phantom_economy = {},
		allow_volunteers = 0,     			--1-Yes, 0-No
		volunteer_bias = 5,					--The number of tokens given to a player who volunteers
		autobalance = 1,
		phantnumber = 2
	},
	phantom_bonus = { mass = 0, energy = 0 },
	stats = {
		phantom_count = 0,
		innocent_count = 0,
		paladin_count = 0,
		phantoms_dead = 0,
		innocents_dead = 0,
		paladins_dead = 0
	},
	votes = {},
	volunteers = {},
	marksRemaining = {},
	resourceTransferOffset = {
		energy = 0,
		mass = 0
	}
}

function ChangeAssignmentTime(offset)
	cur.config.volunteer = cur.config.volunteer + offset
	cur.config.declare = cur.config.declare + offset
	cur.config.vote = cur.config.vote + offset
	
	import('/mods/faf-phantomx/modules/meteors.lua').UpdateAssignmentTime(offset)
	
	Sync.pModifyAssignmentTime = cur.config.declare
end

function PhantomMainThread()
--	cur.config.declare = ScenarioInfo.Options.PhantomDeclareTime
--	cur.config.vote = cur.config.declare - (1 * 60)
	
	--Bugfix #1: Removed cummulative addition of reveal times
	
	--Remove these comments for SCD version...
	cur.config.reveal1 = (tonumber(ScenarioInfo.Options.PhantomRevealTime1) * 60)
	cur.config.reveal2 = (tonumber(ScenarioInfo.Options.PhantomRevealTime2) * 60)
	cur.config.reveal3 = (tonumber(ScenarioInfo.Options.PhantomRevealTime3) * 60)
	cur.config.revealto = (tonumber(ScenarioInfo.Options.PhantomRevealTo))
	cur.config.revealwho = (tonumber(ScenarioInfo.Options.PhantomRevealWho))
	cur.config.balance_multiplier = (tonumber(ScenarioInfo.Options.PhantomBonusMultiplier))/100.0
	cur.config.paladin_bonus = (tonumber(ScenarioInfo.Options.PhantomPaladinBonus))/100.0
	cur.config.paladin_coefficient = (tonumber(ScenarioInfo.Options.PhantomPaladinCoefficient))
    cur.config.death_reveal = (tonumber(ScenarioInfo.Options.Phantom_DeathReveal))
    cur.config.paladin_marks = (tonumber(ScenarioInfo.Options.Phantom_PaladinMarks))
	cur.config.autobalance = (tonumber(ScenarioInfo.Options.Phantom_AutoBalance))
	cur.config.phantnumber = (tonumber(ScenarioInfo.Options.Phantom_PhantNumber))
	
	-- Map coefficient values
	if cur.config.paladin_coefficient == 0 then
		cur.config.paladin_coefficient = 0.0
	elseif cur.config.paladin_coefficient == 1 then
		cur.config.paladin_coefficient = 1.0
	elseif cur.config.paladin_coefficient == 2 then
		cur.config.paladin_coefficient = 0.5
	elseif cur.config.paladin_coefficient == 3 then
		cur.config.paladin_coefficient = 0.3334
	elseif cur.config.paladin_coefficient == 4 then
		cur.config.paladin_coefficient = 0.6667
	end
	--End Comments
	
	
	--Special Case 1 - Phantom 2 or Phantom 3 reveal time set to "Same as..."
	--Lobby wouldn't take fractional values for minutes, so had to do this here
	if(cur.config.reveal2 == 60) then
		cur.config.reveal2 = 12
	end
	if(cur.config.reveal3 == 60) then
		cur.config.reveal3 = 12
	end
		
	LOG("reveal1: " .. cur.config.reveal1)
	LOG("reveal2: " .. cur.config.reveal2)
	LOG("reveal3: " .. cur.config.reveal3)

	cur.config.phantom_economy[0] = { ally = 0.00, mix = 0.00, enemy = 0.00, phantom_war = 1.0, vampire = 0.0 }
	cur.config.phantom_economy[1] = { ally = 0.20, mix = 0.24, enemy = 0.28, phantom_war = 1.0, vampire = 0.0 }
	cur.config.phantom_economy[2] = { ally = 0.10, mix = 0.14, enemy = 0.18, phantom_war = 1.3, vampire = 0.3 }
	cur.config.phantom_economy[3] = { ally = 0.08, mix = 0.10, enemy = 0.14, phantom_war = 1.2, vampire = 0.3 }
	cur.votes[1] = 0
	cur.votes[2] = 0
	cur.votes[3] = 0
	
	ApplyBalanceMultiplier()

	cur.trash = TrashBag()

	import('/lua/SimPlayerQuery.lua').AddQueryListener("PhantomDumpResources", dumpResources)
	import('/lua/SimPlayerQuery.lua').AddQueryListener("PhantomVote", vote)
	import('/lua/SimPlayerQuery.lua').AddQueryListener("VolunteerVote", volunteer)
	import('/lua/SimPlayerQuery.lua').AddQueryListener("PaladinPlayerMarked", HandleMarkPaladin)

	Sync.pSkin = true
	
	for army1, brain1 in ArmyBrains do
		if ArmyIsCivilian(army1) == false and ArmyIsOutOfGame(army1) == false then
			SetAlliedVictory(army1, false)
			brain1:SetResourceSharing(false)
			brain1.CalculateScore = PhantomCalculateScore
			for army2, brain2 in ArmyBrains do
				if ArmyIsCivilian(army2) == false and ArmyIsOutOfGame(army2) == false and army1 != army2 then
					SetAlliance(army1, army2, 'Ally')
				end
			end
		end
	end
	
	Sync.PAssignment = "Phantom Assignment Pending"
	WaitSeconds(cur.config.vote)
	if cur.config.phantnumber == 0 then
		Sync.pVote = true
	end
	WaitSeconds(cur.config.volunteer - cur.config.vote)
	
	

	--Show Volunteer Dialog (if configured options allow it)
	if cur.config.autobalance == 1 then
		Sync.pVolunteer = true	
	end
	if cur.config.autobalance == 2 then
		Sync.pAlert = { "Automatic team balancing is enabled"}
	end

	WaitSeconds(cur.config.declare - cur.config.volunteer)
	
	-- Move all eligible players to the innocents table
	for army, brain in ArmyBrains do
		if ArmyIsCivilian(army) == false and ArmyIsOutOfGame(army) == false then
			table.insert(cur.innocents, army)
		end
	end
	
	-- Count innocents and determine how many we will move to the phantom table
	-- Check votes for a phantom count, this should select the lower of two even votes
	
	local voteMax = 0
	local voteIndex = 0
	
	if cur.config.phantnumber == 0 then
		for key, val in cur.votes do
			if val > voteMax then
				voteMax = val
				voteIndex = key
			end
		end
	else 
		voteIndex = cur.config.phantnumber
	end
		
	if voteIndex > 0 then
		cur.stats.phantom_count = voteIndex
		if cur.stats.phantom_count >= table.getn(cur.innocents) then
			cur.stats.phantom_count = table.getn(cur.innocents) - 1
		end
		
	else
		cur.stats.phantom_count = math.ceil(table.getn(cur.innocents) * cur.config.phantom_coefficient)
	end
	cur.stats.innocent_count = table.getn(cur.innocents) - cur.stats.phantom_count
	
	--Determine number of Paladins
	cur.stats.paladin_count = math.floor(cur.config.paladin_coefficient * cur.stats.phantom_count)
	cur.stats.paladin_count = math.min(cur.stats.paladin_count,cur.stats.innocent_count)
	
	--Determine number of Paladin Marks
	if cur.config.paladin_marks == 1 then --Same as number of Paladins
		cur.config.paladin_marks = cur.stats.paladin_count
	elseif cur.config.paladin_marks == 2 then --One for each phantom
		cur.config.paladin_marks = cur.stats.phantom_count
	elseif cur.config.paladin_marks == 3 then --Two for each phantom
		cur.config.paladin_marks = 2 * cur.stats.phantom_count
	elseif cur.config.paladin_marks == 0 then --Zero
		cur.config.paladin_marks = 0
	elseif cur.config.paladin_marks == 4 then --One
		cur.config.paladin_marks = 1
	elseif cur.config.paladin_marks == 5 then --Two
		cur.config.paladin_marks = 2
	elseif cur.config.paladin_marks == 6 then --Three
		cur.config.paladin_marks = 3
	elseif cur.config.paladin_marks == 7 then --Four
		cur.config.paladin_marks = 4
	end	
	
	
	----------------------------------------
	
	if cur.config.autobalance == 2 and cur.stats.phantom_count==2 then
	
	
		--Fill score{} for all players
		local score = {}
		local total_score = 0
		local list = {}	
		local counter = 0
		
		for army1, brain1 in ArmyBrains do
			if ArmyIsCivilian(army1) == false and ArmyIsOutOfGame(army1) == false then
				--brain1.CalculateScore = EcoCalculateScore
				counter = counter + 1
				score[counter] = EcoCalculateScore(brain1)
				total_score = total_score + score[counter]
				LOG("LOG: player " .. army1 .. " score: " .. score[counter])
				table.insert(list, army1)
			end
		end
		
		LOG("LOG: total score is " .. total_score)
		LOG("LOG: counter is at " .. counter)
		
		-- randomly select a Phantom
		local ok = false
		local p = 0
		repeat
			ok = true
			p = math.random(table.getn(list))
			for index, army in cur.phantoms do
				if list[p] == army then
					ok = false
				end
			end
		until ok == true		
		table.insert(cur.phantoms, list[p])
		-- Disable resource sharing for phantoms (in-case anyone reenabled it)
		ArmyBrains[list[p]]:SetResourceSharing(false)
			
		--LOG("LOG: randomly chose player " .. p .. " as Phantom")	
			
		--Give Additional Storage to Phantom(s)
		--Had to do this by way of a custom storage unit since GiveStorage function is bugged.
		--This unit should be spawned off of the map so no one can see it.
		--Storage values are in the unit blueprint file.
		local unitLoc = -100 - 1*10
		CreateUnitHPR("PCU1000", list[p], unitLoc, unitLoc, 0,0,0,0)
			
		--Assign Paladin Marks
		cur.marksRemaining[GetPhantomArmyNumber(list[p])] = CalculateStartingPaladinMarks()
		
		local minscore = 100
		local phant_score
		phants = {}
	
		-- Find best pairing:
		local playernumber = table.getn(score)
		
		LOG("LOG: number of active players is " .. playernumber)
		LOG("LOG: number of phantoms is " .. cur.stats.phantom_count)
		LOG("LOG: number of innocents is " .. cur.stats.innocent_count)
		LOG("LOG: number of paladins is " .. cur.stats.paladin_count)
		
		--chose 2nd Phantom depending on the first one
		for j=1,playernumber do
			if (p!=j) then
				phant_score = score[p]+score[j]
				inno_score = total_score - phant_score
				phant_score_multiplier = (playernumber - cur.stats.phantom_count) / cur.stats.phantom_count
				phant_score = phant_score * phant_score_multiplier
				scorefraction = math.abs(1 - phant_score / inno_score)
				if (scorefraction < minscore) then
					minscore = scorefraction
					phants[1]=p
					phants[2]=j
				end
			end
		end
		
		--LOG("LOG: minscore is " .. minscore)
		--LOG("LOG: best match for for players " .. phants[1] .. " and " .. phants[2])
		

		--assign phantom status to player phants[2]
		
		local k=2
		table.insert(cur.phantoms, phants[k])
		
		-- Disable resource sharing for phantoms (in-case anyone reenabled it)
		ArmyBrains[phants[k]]:SetResourceSharing(false)
			
		--Give Additional Storage to Phantom(s)
		--Had to do this by way of a custom storage unit since GiveStorage function is bugged.
		--This unit should be spawned off of the map so no one can see it.
		--Storage values are in the unit blueprint file.
		local unitLoc = -100 - k*10
		CreateUnitHPR("PCU1000", phants[k], unitLoc, unitLoc, 0,0,0,0)
		
		--Assign Paladin Marks
		cur.marksRemaining[GetPhantomArmyNumber(phants[k])] = CalculateStartingPaladinMarks()
		
	else	
		
		--Build unweighted list (should be the same as the innocents table)
		local list = {}	
		for army, brain in ArmyBrains do
			if ArmyIsCivilian(army) == false and ArmyIsOutOfGame(army) == false then
				table.insert(list, army)
				LOG(army)
			end
		end
		
		--Now build the weighted list (based on who volunteered)
		for army, armyIdx in cur.innocents do
			if cur.volunteers[armyIdx] > 1 and ArmyIsCivilian(armyIdx) == false and ArmyIsOutOfGame(armyIdx) == false then
				LOG("LOG: a player volunteered.")
				--For each "token", add the player to the list
				for j=1,cur.volunteers[armyIdx] do 
					table.insert(list, armyIdx)
				end
			end
		end
		
		--LOG("LOG Volunteering list: ")
		--for i=1,table.getn(list) do
		--	LOG("LOG: "..list[p])
		--end
		
		-- Move a few innocents over to phantoms	
		for i=1,cur.stats.phantom_count do
			-- This is pretty messy, but I couldn't get table.remove working the way I wanted it to
			local ok = false
			local p = 0
			repeat
				ok = true
				p = math.random(table.getn(list))
				for index, army in cur.phantoms do
					if list[p] == army then
						ok = false
					end
				end
			until ok == true		
			table.insert(cur.phantoms, list[p])
			-- Disable resource sharing for phantoms (in-case anyone reenabled it)
			ArmyBrains[list[p]]:SetResourceSharing(false)
			
			--Give Additional Storage to Phantom(s)
			--Had to do this by way of a custom storage unit since GiveStorage function is bugged.
			--This unit should be spawned off of the map so no one can see it.
			--Storage values are in the unit blueprint file.
			local unitLoc = -100 - i*10
			CreateUnitHPR("PCU1000", list[p], unitLoc, unitLoc, 0,0,0,0)
			
			--Assign Paladin Marks
			cur.marksRemaining[GetPhantomArmyNumber(list[p])] = CalculateStartingPaladinMarks()
		end
	
	end
	
	-- Select Paladins (if applicable)
	for i=1,cur.stats.paladin_count do
		-- This is pretty messy, but I couldn't get table.remove working the way I wanted it to
		local ok = false
		local p = 0
		repeat
			ok = true
			p = math.random(table.getn(cur.innocents))
			for index, army in cur.paladins do
				if cur.innocents[p] == army then
					ok = false
				end
			end
			for index, army in cur.phantoms do
				if cur.innocents[p] == army then
					ok = false
				end
			end
		until ok == true
		table.insert(cur.paladins, cur.innocents[p])
	end
	
	-- Remove phantoms from the innocents table
	for i=1,table.getn(cur.innocents) do
		for index, army in cur.phantoms do
			if cur.innocents[i] == army then
				cur.innocents[i] = nil
			end
		end
	end
	
	-- Prepare data to send to the UI
	pData = {
		phantom_armies = {}, 
		innocent_armies = {}, 
		paladin_armies = {},
		isPhantom = false,
		isPaladin = false,
		paladin_mark_count = 0
	}
	if IsPhantom(GetFocusArmy()) then
		Sync.pAlert = { "Designation: PHANTOM", "Kill Everyone" }
		Sync.PAssignment = "Phantom"
		pData.isPhantom = true
		pData.paladin_mark_count = cur.marksRemaining[GetPhantomArmyNumber(GetFocusArmy())]
	elseif IsPaladin(GetFocusArmy()) then
		Sync.pAlert = { "Designation: Paladin", "Kill All Phantoms" }
		Sync.PAssignment = "Paladin"
		pData.isPaladin = true
	else
		Sync.pAlert = { "Designation: INNOCENT", "Kill All Phantoms" }
		Sync.PAssignment = "Innocent"
	end
	
	pData.phantom_armies = cur.phantoms
	pData.innocent_armies = cur.innocents
	pData.paladin_armies = cur.paladins
	Sync.pData = pData
	
	-- Fire up the eco thread
	cur.trash:Add(ForkThread(PhantomXResourceThread))

	-- Newness: add the reveal thread
	cur.trash:Add(ForkThread(PhantomXRevealThread))
	
	-- Main loop
	local end_game = false
	local stats_changed = true
	while end_game == false do
		WaitSeconds(0.1)

		local innocents_dead = 0
		local phantoms_dead = 0
		local paladins_dead = 0
		for index, army in cur.phantoms do
			if ArmyIsOutOfGame(army) then
				phantoms_dead = phantoms_dead + 1
			end
		end
		for index, army in cur.innocents do
			if ArmyIsOutOfGame(army) then
				innocents_dead = innocents_dead + 1
			end
		end
		
		for index, army in cur.paladins do
			if ArmyIsOutOfGame(army) then
				paladins_dead = paladins_dead + 1
			end
		end
		
		-- Phantom killed
		if phantoms_dead > cur.stats.phantoms_dead then
			local remain = cur.stats.phantom_count - phantoms_dead
			local txt = remain
			if remain > 1 then
				txt = txt .. " phantoms remain"
			else
				if remain == 0 then
					txt = "All phantoms killed"
				else
					txt = txt .. " phantom remains"
				end
			end
			WaitSeconds(2)
			if cur.config.death_reveal == 1 then 
				Sync.pAlert = { "Phantom Assassinated", txt }
			end	
			WaitSeconds(2)
			stats_changed = true
		end

		-- Innocent killed
		if innocents_dead > cur.stats.innocents_dead then
			local remain = cur.stats.innocent_count - innocents_dead
			local txt = remain
			if remain > 1 then
				txt = txt .. " innocents remain"
			else
				if remain == 0 then
					txt = "All innocents killed"
				else
					txt = txt .. " innocent remains"
				end
			end
			WaitSeconds(2)
			if cur.config.death_reveal == 1 then
				Sync.pAlert = { "Innocent Assassinated", txt }
			end	
			WaitSeconds(2)
			stats_changed = true
			
			-- All innocents are dead, multiple phantoms alive - pitch them at each other
			local pAlive = cur.stats.phantom_count - phantoms_dead
			if innocents_dead == cur.stats.innocent_count and pAlive > 1 then
				Sync.pAlert = { "Phantom War", "Vampire rules now in effect" }
				cur.phantom_war = true
				-- All phantoms declare war
				for index1, army1 in cur.phantoms do
					SetAlliedVictory(army1, false)
					for index2, army2 in cur.phantoms do
						if ArmyIsOutOfGame(army1) == false and ArmyIsOutOfGame(army2) == false and army1 != army2 then
							SetAlliance(army1, army2, 'Enemy')
						end
					end
				end
			end

		end
		
		cur.stats.phantoms_dead = phantoms_dead
		cur.stats.innocents_dead = innocents_dead
		cur.stats.paladins_dead = paladins_dead
		
		-- Send stats to the UI
		if stats_changed then
			stats_changed = false
			Sync.pStats = cur.stats
		end
				
		-- All phantoms dead (innocent victory)
		if cur.stats.innocents_dead < cur.stats.innocent_count and cur.stats.phantoms_dead == cur.stats.phantom_count then
			Sync.pAlert = { "Innocents Win", false }
			-- Ally all innocents and set allied victory to true
			for index1, army1 in cur.innocents do
				SetAlliedVictory(army1, true)
				for index2, army2 in cur.innocents do
					if ArmyIsOutOfGame(army1) == false and ArmyIsOutOfGame(army2) == false and army1 != army2 then
						SetAlliance(army1, army2, 'Ally')
					end
				end
			end
			end_game = true
		end

		-- One phantom remains (phantom victory)
		local pAlive = cur.stats.phantom_count - cur.stats.phantoms_dead
		if cur.stats.innocents_dead == cur.stats.innocent_count and pAlive == 1 then
			-- not really much to do here, only one man alive
			Sync.pAlert = { "Phantom Victory", false }
			end_game = true
		end
		
		-- Everyone fails
		if cur.stats.innocents_dead == cur.stats.innocent_count and cur.stats.phantoms_dead == cur.stats.phantom_count then
			Sync.pAlert = { "Nobody Wins", false }
			end_game = true
		end
		
	end
	cur.trash:Destroy()
end

function CalculateStartingPaladinMarks()
	local armyNum = GetPhantomArmyNumber(GetFocusArmy())
	local rtVal = math.floor(cur.config.paladin_marks / cur.stats.phantom_count)
	local remainder = cur.config.paladin_marks - (rtVal * cur.stats.phantom_count)
	if armyNum <= remainder then
		rtVal = rtVal + 1
	end
	return rtVal
end

-- This function changes the way the score works
function PhantomCalculateScore(self)
	local massValueDestroyed = self:GetArmyStat("Enemies_MassValue_Destroyed",0.0).Value
	local massValueLost = self:GetArmyStat("Units_MassValue_Lost",0.0).Value
	local energyValueDestroyed = self:GetArmyStat("Enemies_EnergyValue_Destroyed",0.0).Value
	local energyValueLost = self:GetArmyStat("Units_EnergyValue_Lost",0.0).Value

	local energyValueCoefficient = 0.02
	return math.floor((massValueDestroyed - massValueLost) + (energyValueDestroyed - energyValueLost) * energyValueCoefficient)
end

function EcoCalculateScore(self)
    local massSpent = self:GetArmyStat("Economy_TotalConsumed_Mass",0.0).Value
    local massProduced = self:GetArmyStat("Economy_TotalProduced_Mass",0.0).Value -- not currently being used
    local energySpent = self:GetArmyStat("Economy_TotalConsumed_Energy",0.0).Value
    local energyProduced = self:GetArmyStat("Economy_TotalProduced_Energy",0.0).Value -- not currently being used
    local massValueDestroyed = self:GetArmyStat("Enemies_MassValue_Destroyed",0.0).Value
    local massValueLost = self:GetArmyStat("Units_MassValue_Lost",0.0).Value
    local energyValueDestroyed = self:GetArmyStat("Enemies_EnergyValue_Destroyed",0.0).Value
    local energyValueLost = self:GetArmyStat("Units_EnergyValue_Lost",0.0).Value

        -- helper variables to make equation more clear
    local excessMassProduced = massProduced - massSpent -- not currently being used
    local excessEnergyProduced = energyProduced - energySpent -- not currently being used
    local energyValueCoefficient = 20

        -- score components calculated
    local resourceProduction = ((massSpent) + (energySpent / energyValueCoefficient)) / 2
    local battleResults = (((massValueDestroyed - massValueLost) + ((energyValueDestroyed - energyValueLost) / energyValueCoefficient)) / 2)
    if battleResults < 0 then
        battleResults = 0
    end

        -- score calculated
    local score = math.floor(resourceProduction)    
	-- + battleResults)
    return score
end

-- This functions gives the resource bonus to the phantoms and paladins
function PhantomXResourceThread()
	pEco = {
		mass = 0,
		energy = 0
	}
	local lastPaladinMassBonus = 0
	local lastPaladinEnergyBonus = 0
	
	local counter = 0
	cur.resourceTransferOffset.mass = 0
	cur.resourceTransferOffset.energy = 0
	local errorCheck = false
	
	while true do
		WaitSeconds(0.1)
		
		
		
		--Determine the number of live Phantoms
		local remaining_live_phantoms = cur.stats.phantom_count - cur.stats.phantoms_dead
		local remaining_live_paladins = cur.stats.paladin_count - cur.stats.paladins_dead
		
		if cur.phantom_war == false then
			counter = counter + 1
			----------------------------------------------------------------------------------------------------------------------
			-- Normal Conditions, phantoms get bonus as per normal
			----------------------------------------------------------------------------------------------------------------------
			
			-- Work out innocents combined incomes
			local mass = 0
			local energy = 0
			for index, army in cur.innocents do
				if ArmyIsOutOfGame(army) == false then
					brain = ArmyBrains[army]
					mass = mass + brain:GetEconomyIncome('MASS')
					energy = energy + brain:GetEconomyIncome('ENERGY')
				end
			end
			
			-- What alliance status do we have, all allied, mixed or all out war?
			local allied = false
			local enemy = false
			for pindex, parmy in cur.phantoms do
				if ArmyIsOutOfGame(parmy) == false then
					for iindex, iarmy in cur.innocents do
						if ArmyIsOutOfGame(iarmy) == false then
							if IsAlly(parmy, iarmy) then
								allied = true
							else
								enemy = true
							end
						end
					end
				end
			end

			local bonus = 0
			-- All phantoms allied with all innocents
			if allied == true and enemy == false then
				bonus = cur.config.phantom_economy[remaining_live_phantoms].ally
			end

			-- Mixed alliances
			if allied == true and enemy == true then
				bonus = cur.config.phantom_economy[remaining_live_phantoms].mix
			end

			-- All out war, max bonus
			if allied == false and enemy == true then
				bonus = cur.config.phantom_economy[remaining_live_phantoms].enemy
			end

			--Filter out the resource feedback loop
			for index, army in cur.paladins do
				if ArmyIsOutOfGame(army) == false and IsMarkedPaladin(army) == false then
					mass = mass - lastPaladinMassBonus
					energy = energy - lastPaladinEnergyBonus
				end
			end
			
			--Handle Mass/Energy Transfers (so phantoms don't get an additional bonus from gifts)
			if(cur.resourceTransferOffset.mass > 0) then
				--LOG('Mass transfer detected.  Mass total ('..mass..')reduced by '..cur.resourceTransferOffset.mass..' mass.')
				mass = mass - cur.resourceTransferOffset.mass
				if mass < 0 then
					mass = 0
					errorCheck = true
				end
				cur.resourceTransferOffset.mass = 0
			end
			
			if(cur.resourceTransferOffset.energy > 0) then
				--LOG('Energy transfer detected.  Energy total ('..energy..') reduced by '..cur.resourceTransferOffset.energy..' energy.')
				energy = energy - cur.resourceTransferOffset.energy
				if energy < 0 then
					energy = 0
					errorCheck = true
				end
				cur.resourceTransferOffset.energy = 0
			end
			
			-- Give bonus to phantoms
			for index1, army1 in cur.phantoms do
				if ArmyIsOutOfGame(army1) == false then
					local phantom_war = false
					for index2, army2 in cur.phantoms do
						if ArmyIsOutOfGame(army2) == false and army1 != army2 and IsAlly(army1, army2) == false and allied == true then
							phantom_war = true
							break
						end
					end
					local player_coeffiecient = bonus
					if phantom_war then
						player_coeffiecient = player_coeffiecient * cur.config.phantom_economy[remaining_live_phantoms].phantom_war
					end
					player_mass = mass * player_coeffiecient
					player_energy = energy * player_coeffiecient

					brain = ArmyBrains[army1]
					brain:GiveResource('MASS', player_mass)
					brain:GiveResource('ENERGY', player_energy)

					if army1 == GetFocusArmy() then
						--Pass Phantom Eco to Phantom UI
						if counter - math.floor(counter/300)*300 == 0 then
							pEco.mass = math.ceil(player_mass * 10)
							pEco.energy = math.ceil(player_energy * 10)
							pEco.bonus = math.ceil(player_coeffiecient * 100)
							Sync.pEco = pEco
						end
						
						--Pass Phantom Eco to Economy display
						local ecoData = {
							actualMass = 0,
							actualEnergy = 0,
							tickRate = 10, --Number of times this runs per second
							doUpdate = false
							}
						ecoData.actualMass = player_mass
						ecoData.actualEnergy = player_energy
						if counter - math.floor(counter/300)*300 == 0 then
							ecoData.doUpdate = true
						end
						
						Sync.pEcoObfuscate = ecoData
					end
				end
			end
			
			
			-- Give bonus to paladins
			local paladin_bonus_amount = bonus * cur.config.paladin_bonus
			local paladin_mass = mass * paladin_bonus_amount
			local paladin_energy = energy * paladin_bonus_amount
			
			for index1, army1 in cur.paladins do
				if ArmyIsOutOfGame(army1) == false then
					if IsMarkedPaladin(army1) then
						if army1 == GetFocusArmy() then
							-- Sync with UI
							pEco.mass = 0
							pEco.energy = 0
							pEco.bonus = 0
							Sync.pEco = pEco
						end
					else
						brain = ArmyBrains[army1]
						brain:GiveResource('MASS', paladin_mass)
						brain:GiveResource('ENERGY', paladin_energy)

						if army1 == GetFocusArmy() then
							if counter - math.floor(counter/300)*300 == 0 then 		-- do this only every 5 seconds
								pEco.mass = math.ceil(paladin_mass * 10)
								pEco.energy = math.ceil(paladin_energy * 10)
								pEco.bonus = math.ceil(paladin_bonus_amount * 100)
								Sync.pEco = pEco
							end
						
							--Pass Phantom Eco to Economy display
							local ecoData = {
								actualMass = 0,
								actualEnergy = 0,
								tickRate = 10, --Number of times this runs per second
								doUpdate = false
								}
							ecoData.actualMass = paladin_mass
							ecoData.actualEnergy = paladin_energy
							if counter - math.floor(counter/300)*300 == 0 then
								ecoData.doUpdate = true
							end
							
							Sync.pEcoObfuscate = ecoData
						end	
					end
				end
			end

			if counter - math.floor(counter/300)*300 == 0 then 		-- do this only every 30 seconds
				counter=0
			end

			lastPaladinMassBonus = paladin_mass
			lastPaladinEnergyBonus = paladin_energy
		else
			----------------------------------------------------------------------------------------------------------------------
			-- Phantom War (Vampire) conditions (only phantoms remain)
			----------------------------------------------------------------------------------------------------------------------
			for index, army in cur.phantoms do
				if ArmyIsOutOfGame(army) == false then
					brain = ArmyBrains[army]
					local mass = brain:GetArmyStat("Enemies_MassValue_Destroyed",0.0).Value
					local energy = brain:GetArmyStat("Enemies_EnergyValue_Destroyed",0.0).Value
					if cur.delta.mass[army] > 0 then
						local deltaMass = (mass - cur.delta.mass[army]) * cur.config.phantom_economy[remaining_live_phantoms].vampire
						local deltaEnergy = (energy - cur.delta.energy[army]) * cur.config.phantom_economy[remaining_live_phantoms].vampire
						
						brain:GiveResource('MASS', deltaMass)
						brain:GiveResource('ENERGY', deltaEnergy)

						if army == GetFocusArmy() then
							-- Sync with UI
							pEco.mass = math.ceil(deltaMass)
							pEco.energy = math.ceil(deltaEnergy)
							pEco.bonus = math.ceil(cur.config.phantom_economy[remaining_live_phantoms].vampire * 100)
							Sync.pEco = pEco
						end
					end
					cur.delta.mass[army] = mass
					cur.delta.energy[army] = energy
				end
			end
		end
	end
	
	if errorCheck then
		WARN('An error occurred in the phantom-x bonus calculation thread.  The error was handled, but should be researched and corrected')
	end
end

-- Determines if an army is an innocent
function IsInnocent(army)
	for index, p in cur.innocents do
		if p == army then
			return true
		end
	end
	
	return false
end

-- Determines if an army is a phantom
function IsPhantom(army)
	if table.getn(cur.phantoms) == 0 then
		return false
	else
		for index, p in cur.phantoms do
			if p == army then
				return true
			end
		end
		return false
	end
end

-- Determines if an army is a paladin
function IsPaladin(army)
	if table.getn(cur.paladins) == 0 then
		return false
	else
		for index, p in cur.paladins do
			if p == army then
				return true
			end
		end
		return false
	end
end

-- Determines if an army is a paladin
function IsMarkedPaladin(army)
	if table.getn(cur.marked_paladins) == 0 then
		return false
	else
		for index, p in cur.marked_paladins do
			if p == army then
				return true
			end
		end
		return false
	end
end

function GetPhantomArmyNumber(army)
	if table.getn(cur.phantoms) == 0 then
		return -1
	else
		for index, p in cur.phantoms do
			if p == army then
				return index
			end
		end
		return -1
	end
end

-- Dump Resources (from UI)
function dumpResources(data)
	brain = ArmyBrains[data.From]
	brain:TakeResource(data.Args, math.floor(brain:GetEconomyStored(data.Args) * 0.9))	
end

-- Vote (from UI)
function vote(data)
	cur.votes[data.Args.Vote] = cur.votes[data.Args.Vote] + 1
	if data.Args.Vote == 1 then
		print(data.Args.Nick.." voted for a single phantom")
	else
		print(data.Args.Nick.." voted for "..data.Args.Vote.." phantoms")
	end
end

function volunteer(data)
	-- array index represents player ID, value represents number of tokens for that player
	if data.Args.Volunteered == 1 then
		cur.volunteers[data.Args.ID] = cur.config.volunteer_bias
	else
		cur.volunteers[data.Args.ID] = 1
	end
end


--Handle UI user side query
--Necessary because WaitSeconds isn't allowed on query callbacks
function HandleMarkPaladin(data)
	cur.trash:Add(ForkThread(MarkPaladin, data))
end

-- MarkPaladin (so that he loses the bonus)
function MarkPaladin(data)
	--Check to see if this Phantom is still alive...
	if not ArmyIsOutOfGame(data.From) then
		--Determine Mark Cost...
		local luckyGuessProbability = cur.stats.paladin_count / (cur.stats.innocent_count + cur.stats.paladin_count)
		local massCost = (1.0 / luckyGuessProbability) *  cur.config.paladin_mark_base_mass_cost
		local maxMassCost = 100000
		local currGameTime = (GetGameTimeSeconds() - cur.config.declare) / 60
		local slopeCoeff = 0.05
			
		local markCost = math.floor((massCost + maxMassCost * math.atan( slopeCoeff * currGameTime )) * luckyGuessProbability)
		local amountPaid = 0
		
		--Consume all stored mass units every .1 seconds until we pay off mark cost
		while amountPaid < markCost do
			local difference = markCost - amountPaid
			brain = ArmyBrains[data.From]
			local chargeAmount = math.min(brain:GetEconomyStored('MASS'), difference)
			brain:TakeResource('MASS', chargeAmount)
			amountPaid = amountPaid + chargeAmount
			WaitSeconds(0.1)
		end
		
		
		--Determine if player is paladin and not already marked
		if IsPaladin(data.Args.MarkedArmy) then		
			if not IsMarkedPaladin(data.Args.MarkedArmy) then
				table.insert(cur.marked_paladins, data.Args.MarkedArmy)
				if data.Args.MarkedArmy == GetFocusArmy() then
					Sync.pAlert = {"You have been marked by a Phantom.", "You will no longer receive a Paladin bonus."}
				elseif IsPhantom(GetFocusArmy()) then
					Sync.pAlert = {ArmyBrains[data.Args.MarkedArmy].Nickname.." has been marked as a Paladin!", "Victory is now a step closer."}
				else
					Sync.pAlert = {"A Paladin has been marked!", "The marked Paladin will no longer receive bonus income."}
				end
			else
				if data.From == GetFocusArmy() then
					Sync.pAlert = {"The mark has no effect!", "That Paladin has already been marked."}
				else
					Sync.pAlert = {"A Paladin mark has been used.", "However, the targeted Paladin has already been marked."}
				end
			end
		else
			if data.From == GetFocusArmy() then
				Sync.pAlert = {"The mark has no effect!", "You may want to work on your Paladin detection skills."}
			else
				Sync.pAlert = {"A Paladin mark has been used.", "However, the targeted player is unaffected."}
			end
		end
	end
end

--This function applies the balance multiplier to the phantom bonus table
function ApplyBalanceMultiplier()
	for i=0,table.getn(cur.config.phantom_economy) do
		cur.config.phantom_economy[i].ally = cur.config.phantom_economy[i].ally * cur.config.balance_multiplier
		cur.config.phantom_economy[i].mix = cur.config.phantom_economy[i].mix * cur.config.balance_multiplier
		cur.config.phantom_economy[i].enemy = cur.config.phantom_economy[i].enemy * cur.config.balance_multiplier
		cur.config.phantom_economy[i].vampire = cur.config.phantom_economy[i].vampire * cur.config.balance_multiplier
	end
end

function DoneRevealing(remainingPlayers, indexNumber)
	WaitSeconds(12)
	
	
	--If we got here on the first Phantom, it means none will be revealed
	if(indexNumber == 1) then
		Sync.pAlert = {"Nothing will be revealed.", "Trust your instincts."}
	else
		if(remainingPlayers == 0) then
			Sync.pAlert = {"The players have been revealed.", "Let the games begin."}
		end
		if(remainingPlayers == 1) then
			Sync.pAlert = {"Nothing more will be revealed.", "One more player lurks in the shadows."}
		else
			Sync.pAlert = {"Nothing more will be revealed.", remainingPlayers.." more players lurk in the shadows."}
		end
	end
end

function PhantomXRevealThread()
	LOG('starting phantom reveal thread')
--	WaitSeconds(cur.config.reveal1)

	pRevealed = {
		phant1 = nil,
		phant2 = nil,
		phant3 = nil,
		pal1 = nil,
		pal2 = nil,
		pal3 = nil,
	}
	
	local maxPhants = table.getn(cur.phantoms)
	local maxPaladins = table.getn(cur.paladins)
	local playersToBeRevealed = 0
	local playersRevealed = 0
	
	--Calculate player totals
	if(cur.config.revealwho == 0 or cur.config.revealwho == 2) then
		playersToBeRevealed = playersToBeRevealed + maxPhants
	end
	if(cur.config.revealwho == 1 or cur.config.revealwho == 2) then
		playersToBeRevealed = playersToBeRevealed + maxPaladins
	end

	--BugFix 2:		Rearranged reveal logic to correctly handle all scenarios
	--Assumptions:	Once we encounter a reveal time of zero, it is assumed that all revelations are done.  
	--			 	i.e. If phantom 1's reveal time is Never, then phantoms 2 and 3 will not be revealed either.
	
	--Build a table to use in our loop
	local revealtimes = {}
	revealtimes[1] = cur.config.reveal1
	revealtimes[2] = cur.config.reveal2
	revealtimes[3] = cur.config.reveal3
	
	--Fork a thread to sync name placeholders.
	cur.trash:Add(ForkThread(ShowNamePlaceHolders))
	
	for i=1, table.getn(revealtimes) do
		if(revealtimes[i] == 0) then
			DoneRevealing(maxPhants + maxPaladins - playersRevealed, i)
			do return end
		elseif(playersRevealed < playersToBeRevealed) then
			WaitSeconds(revealtimes[i])
			cur.trash:Add(ForkThread(DoReveal, i))
			playersRevealed = playersRevealed + 1
			
			--Make sure to count paladin if they're going to be revealed
			if((cur.config.revealwho == 1 or cur.config.revealwho == 2) and (i <= cur.stats.paladin_count)) then
				playersRevealed = playersRevealed + 1
			end
		end
	end
	
	WaitSeconds(10)
	Sync.pAlert = {"The players have been revealed.", "Let the games begin."}
end

function ShowNamePlaceHolders()
	--Make initial synchronization call so that name place holders are displayed
	WaitSeconds(5)
	Sync.pRevealed = pRevealed
	LOG('syncing from sim')
end

function DoReveal(idx)
	if(cur.config.revealwho == 0 or cur.config.revealwho == 2) then
		RevealPhantom(cur.phantoms[idx], idx)
	end
	Sync.pRevealed = pRevealed
	LOG('syncing from sim')
	
	if((cur.config.revealwho == 1 or cur.config.revealwho == 2) and (idx <= cur.stats.paladin_count)) then
		WaitSeconds(6)
		RevealPaladin(cur.paladins[idx], idx)
	end
	
	Sync.pRevealed = pRevealed
	LOG('syncing from sim')
end

--Checks the current player type and reveal config to determine whether or not player will see reveal
function CheckRevealConfigForThisPlayer()
	local revealToPlayer = false
	
	if cur.config.revealto == 0 then 
		revealToPlayer = true
	elseif cur.config.revealto == 1 and IsPhantom(GetFocusArmy()) then
		revealToPlayer = true
	elseif cur.config.revealto == 2 and IsPaladin(GetFocusArmy()) then
		revealToPlayer = true
	elseif cur.config.revealto == 3 and (IsPaladin(GetFocusArmy()) or IsPhantom(GetFocusArmy())) then
		revealToPlayer = true
	end
	
	return revealToPlayer
end

function RevealPhantom(army, index)
	if CheckRevealConfigForThisPlayer() == true then
		Sync.pAlert = { ArmyBrains[army].Nickname.." is a phantom!", false}
		LOG('revealed phantom: ', ArmyBrains[army].Nickname)
		if(index == 1) then
			pRevealed.phant1 = army
		elseif(index == 2) then
			pRevealed.phant2 = army
		elseif(index == 3) then
			pRevealed.phant3 = army
		end
	end
end

function RevealPaladin(army, index)
	if CheckRevealConfigForThisPlayer() == true then
		Sync.pAlert = { ArmyBrains[army].Nickname.." is a paladin!", false}
		LOG('revealed paladin: ', ArmyBrains[army].Nickname)
		if(index == 1) then
			pRevealed.pal1 = army
		elseif(index == 2) then
			pRevealed.pal2 = army
		elseif(index == 3) then
			pRevealed.pal3 = army
		end
	end
end

function HandleResourceTransfer(from, to, massTaken, energyTaken)
	--Determine if 'to' is an innocent...
	if IsInnocent(to) then
		--If so, add resource transfer amount into a variable so it can be subtracted from the income totals later.
		cur.resourceTransferOffset.mass = cur.resourceTransferOffset.mass + massTaken
		cur.resourceTransferOffset.energy = cur.resourceTransferOffset.energy + energyTaken
	end
end
