#****************************************************************************
#**	Mafia Submod	 
#****************************************************************************

local modPath = 'Phantom-X'


allow_meteors = 0
meteor_count = 0
toggle_sync = 0

local cur = {
	innocents = {},
	phantoms = {},
	paladins = {}, #Paladin armies are stored here (paladin armies are also stored in innocents array)
	marked_paladins = {}, #Paladins that have been marked by a Phantom are stored here (as well as in paladin and innocent arrays)
	delta = { mass = {}, energy = {} }, 
	phantom_war = false,
	trash = nil,
	config = {
		balance_multiplier = 1.0,    #This variable is used to globally adjust the phantom/paladin bonus up or down (for balancing)
		vote = 6 * 60,
		volunteer = 7 * 60,
		declare = 8 * 60,
		reveal1 = 35 * 60,
		reveal2 = 1 * 60,
		reveal3 = 1 * 60,
		revealto = 3,			 			#0-Everyone, 1-Phantoms Only, 2-Paladins Only, 3-Phantoms and Paladins Only
		revealwho = 0,			   			#0-Phantoms, 1-Paladins, 2-Phantoms and Paladins
		phantom_coefficient = 1/3, 
		paladin_coefficient = 3/5, 			#For every one phantom there will be three fifths of a paladin (rounded down)
		paladin_bonus = 0.45,      			#Paladins get 45% of the Phantom Bonus
		paladin_marks = 2,		  			#Number of paladin marks given to Phantoms
		paladin_mark_base_mass_cost = 4000, #Base mass cost for using a Paladin mark 
		death_reveal= 1,          			#After a player dies, his assigment is revealed to the others
		phantom_economy = {},
		allow_volunteers = 0,     			#1-Yes, 0-No
		autobalance = 1,
		phantnumber = 2,
		mafia = 0
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
	marksRemaining = {}
}


function PhantomMainThread()
	
	toggle_sync=1
	
	cur.config.mafia = (tonumber(ScenarioInfo.Options.Mafia_Mod))
	
	cur.config.phantnumber = 0
	cur.config.death_reveal = 0
	cur.config.revealto = 1
	cur.config.revealwho = 0
	cur.config.reveal1 = 1 * 60
	cur.config.reveal2 = 1 * 60
	cur.config.reveal3 = 1 * 60
	cur.config.autobalance = 1
	cur.config.paladin_marks = 0
	
	# Map coefficient values
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
	#End Comments
	
	
	#Special Case 1 - Phantom 2 or Phantom 3 reveal time set to "Same as..."
	#Lobby wouldn't take fractional values for minutes, so had to do this here
	if(cur.config.reveal2 == 60) then
		cur.config.reveal2 = 12
	end
	if(cur.config.reveal3 == 60) then
		cur.config.reveal3 = 12
	end
		
	LOG("reveal1: " .. cur.config.reveal1)
	LOG("reveal2: " .. cur.config.reveal2)
	LOG("reveal3: " .. cur.config.reveal3)

	cur.votes[1] = 0
	cur.votes[2] = 0
	cur.votes[3] = 0
		
	cur.trash = TrashBag()

	import('/lua/SimPlayerQuery.lua').AddQueryListener("PhantomVote", vote)
	import('/lua/SimPlayerQuery.lua').AddQueryListener("VolunteerVote", volunteer)
	import('/lua/SimPlayerQuery.lua').AddQueryListener("PlayerInvestigated", HandleInvestigatePlayer)
	
	LOG("Usersync: supposed to call SetLayout:")
	Sync.mSkin = true
	LOG("done.")
	
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
	
	LOG("Usersync: supposed to call SetAssignment:")
	Sync.mAssignment = "Mafia Assignment Pending"
	
	WaitSeconds(cur.config.vote)
	if cur.config.phantnumber == 0 then
		LOG("Usersync: supposed to call ShowPhantomVote:")
		Sync.mVote = true
	end
	WaitSeconds(cur.config.volunteer - cur.config.vote)
	
	LOG("Usersync: supposed to call ShowVolunteerVote:")
	Sync.mVolunteer = true	

	WaitSeconds(cur.config.declare - cur.config.volunteer)
	
	# Move all eligible players to the innocents table
	for army, brain in ArmyBrains do
		if ArmyIsCivilian(army) == false and ArmyIsOutOfGame(army) == false then
			table.insert(cur.innocents, army)
		end
	end
	
	# Count innocents and determine how many we will move to the phantom table
	# Check votes for a phantom count, this should select the lower of two even votes
	
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
	
	cur.stats.paladin_count = cur.stats.phantom_count
	if cur.stats.paladin_count == 3 then
		cur.stats.paladin_count = 2
	end

	####################
	
	#Build unweighted list (should be the same as the innocents table)
	local list = {}	
	for army, brain in ArmyBrains do
		if ArmyIsCivilian(army) == false and ArmyIsOutOfGame(army) == false then
			table.insert(list, army)
			LOG(army)
		end
	end
	
	#Now build the weighted list (based on who volunteered)
	for army, armyIdx in cur.innocents do
		if cur.volunteers[armyIdx] > 1 and ArmyIsCivilian(armyIdx) == false and ArmyIsOutOfGame(armyIdx) == false then
			LOG("LOG: a player volunteered.")
			#For each "token", add the player to the list
			for j=1,cur.volunteers[armyIdx] do 
				table.insert(list, armyIdx)
			end
		end
	end
	
	#LOG("LOG Volunteering list: ")
	#for i=1,table.getn(list) do
	#	LOG("LOG: "..list[p])
	#end
	
	# Move a few innocents over to phantoms	
	for i=1,cur.stats.phantom_count do
		# This is pretty messy, but I couldn't get table.remove working the way I wanted it to
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
		# Disable resource sharing for phantoms (in-case anyone reenabled it)
		ArmyBrains[list[p]]:SetResourceSharing(false)
		
			
		if cur.config.mafia == 0 then
			#Give Additional Storage to Phantom(s)
			#Had to do this by way of a custom storage unit since GiveStorage function is bugged.
			#This unit should be spawned off of the map so no one can see it.
			#Storage values are in the unit blueprint file.
			local unitLoc = -100 - i*10
			CreateUnitHPR("PCU1000", list[p], unitLoc, unitLoc, 0,0,0,0)
		end
			
	end
	
	
	# Select Paladins (if applicable)
	for i=1,cur.stats.paladin_count do
		# This is pretty messy, but I couldn't get table.remove working the way I wanted it to
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
	
	# Remove phantoms from the innocents table
	for i=1,table.getn(cur.innocents) do
		for index, army in cur.phantoms do
			if cur.innocents[i] == army then
				cur.innocents[i] = nil
			end
		end
	end
	
	# Prepare data to send to the UI
	mData = {
		phantom_armies = {}, 
		innocent_armies = {}, 
		paladin_armies = {},
		isPhantom = false,
		isPaladin = false,
		paladin_mark_count = 0
	}
	
	if IsPhantom(GetFocusArmy()) then
		Sync.mAlert = { "Designation: MAFIA", "Kill all innocents." }
		Sync.mAssignment = "Mafia"
		mData.isPhantom = true
		mData.paladin_mark_count = cur.marksRemaining[GetPhantomArmyNumber(GetFocusArmy())]
	elseif IsPaladin(GetFocusArmy()) then
		Sync.mAlert = { "Designation: Detective", "Find the Mafiosi and kill them." }
		Sync.mAssignment = "Detective"
		mData.isPaladin = true
		mData.paladin_mark_count = cur.marksRemaining[GetPhantomArmyNumber(GetFocusArmy())]
	else
		Sync.mAlert = { "Designation: INNOCENT", "Kill the Mafiosi." }
		Sync.mAssignment = "Innocent"
	end

	mData.phantom_armies = cur.phantoms
	mData.innocent_armies = cur.innocents
	mData.paladin_armies = cur.paladins
	Sync.mData = mData
	
	# Newness: add the reveal thread
	cur.trash:Add(ForkThread(PhantomXRevealThread))
	
	cur.trash:Add(ForkThread(MafiaMeteors))
	
	# Main loop
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
		
		# Phantom killed
		if phantoms_dead > cur.stats.phantoms_dead then
			stats_changed = true
		end

		# Innocent killed
		if innocents_dead > cur.stats.innocents_dead then
			local remain = cur.stats.innocent_count - innocents_dead
			WaitSeconds(2)
			WaitSeconds(2)
			stats_changed = true
			
				
			# All innocents are dead, multiple phantoms alive - pitch them at each other
			local pAlive = cur.stats.phantom_count - phantoms_dead
			
			if innocents_dead == cur.stats.innocent_count and pAlive > 1 then
				Sync.mAlert = { "Mafiosi win", false }
				# Ally all mafiosi and set allied victory to true
				for index1, army1 in cur.phantoms do
					SetAlliedVictory(army1, true)
					for index2, army2 in cur.phantoms do
						if ArmyIsOutOfGame(army1) == false and ArmyIsOutOfGame(army2) == false and army1 != army2 then
							SetAlliance(army1, army2, 'Ally')
						end
					end
				end
				end_game = true
			end	
		end
		
		cur.stats.phantoms_dead = phantoms_dead
		cur.stats.innocents_dead = innocents_dead
		cur.stats.paladins_dead = paladins_dead
		
		# Send stats to the UI
		if stats_changed then
			stats_changed = false
			Sync.mStats = cur.stats
		end
				
		# All phantoms dead (innocent victory)
		if cur.stats.innocents_dead < cur.stats.innocent_count and cur.stats.phantoms_dead == cur.stats.phantom_count then
			Sync.mAlert = { "Innocents Win", false }
			# Ally all innocents and set allied victory to true
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

		# One phantom remains (phantom victory)
		local pAlive = cur.stats.phantom_count - cur.stats.phantoms_dead
		if cur.stats.innocents_dead == cur.stats.innocent_count and pAlive == 1 then
			# not really much to do here, only one man alive
			Sync.mAlert = { "Mafia Victory", false }
			end_game = true
		end
		
		# Everyone fails
		if cur.stats.innocents_dead == cur.stats.innocent_count and cur.stats.phantoms_dead == cur.stats.phantom_count then
			Sync.mAlert = { "Nobody Wins", false }
			end_game = true
		end
		
	end
	cur.trash:Destroy()
end


# This function changes the way the score works
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
	# + battleResults)
    return score
end


# Determines if an army is a phantom
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

# Determines if an army is a paladin
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

# Vote (from UI)
function vote(data)
	cur.votes[data.Args.Vote] = cur.votes[data.Args.Vote] + 1
	if data.Args.Vote == 1 then
		print(data.Args.Nick.." voted for a single Mafioso")
	else
		print(data.Args.Nick.." voted for "..data.Args.Vote.." Mafiosi")
	end
end

function volunteer(data)
	# array index represents player ID, value represents number of tokens for that player
	cur.volunteers[data.Args.ID] = data.Args.Token
end

#Handle UI user side query
#Necessary because WaitSeconds isn't allowed on query callbacks

function HandleInvestigatePlayer(data)
	cur.trash:Add(ForkThread(InvestigatePlayer, data))
end



function MafiaMeteors()
	LOG("Started MeteorCooldown Thread")
	WaitSeconds(4 * 60)
	local interval = 5 * 60	
	meteor_count = 0
	while true do
		LOG("running")
		allow_meteors = 0
		local army = GetFocusArmy()
		
		LOG(army)
		LOG(IsPhantom(army))
		
		allow_meteors = 1
		
		LOG("Sync.mMeteors")
		#Sync.mMeteors = 1
		if IsPhantom(army) then
			Sync.mMeteors = 1
			Sync.mAlert = {"You may now call down a meteor strike."}
		end	
		WaitSeconds(interval)
		allow_meteors = 0
		meteor_count = meteor_count + 1
		interval = interval * 0.9
	end
end

function InvestigatePlayer(data)
	#Check to see if this Phantom is still alive...
	if not ArmyIsOutOfGame(data.From) then
		#Determine Mark Cost...
		local luckyGuessProbability = cur.stats.paladin_count / (cur.stats.innocent_count + cur.stats.paladin_count)
		local massCost = (1.0 / luckyGuessProbability) *  cur.config.paladin_mark_base_mass_cost
		local maxMassCost = 100000
		local currGameTime = (GetGameTimeSeconds() - cur.config.declare) / 60
		local slopeCoeff = 0.05
			
		local markCost = math.floor((massCost + maxMassCost * math.atan( slopeCoeff * currGameTime )) * luckyGuessProbability)
		local amountPaid = 0
		markCost = 10000
		
		
		#Consume all stored mass units every .1 seconds until we pay off mark cost
		while amountPaid < markCost do
			local difference = markCost - amountPaid
			brain = ArmyBrains[data.From]
			local chargeAmount = math.min(brain:GetEconomyStored('MASS'), difference)
			brain:TakeResource('MASS', chargeAmount)
			amountPaid = amountPaid + chargeAmount
			WaitSeconds(0.1)
		end
				
		#Determine if player is paladin and not already marked
		if IsPaladin(data.Args.MarkedArmy) or IsPhantom(data.Args.MarkedArmy) then		
			if data.From == GetFocusArmy() then
				Sync.mAlert = {"SUSPICOIUS activity detected!", "The player you investigated is not a simple citizen."}
			else
				#Sync.mAlert = {"A player has been investigated."}
			end
		else
			if data.From == GetFocusArmy() then
				Sync.mAlert = {"Investigation has found nothing.", "The player you investigated is clearly INNOCENT."}
			else
				#Sync.mAlert = {"A player has been investigated."}
			end
		end
	end
end


function DoneRevealing(remainingPlayers, indexNumber)
end

function PhantomXRevealThread()
	LOG('starting phantom reveal thread')
#	WaitSeconds(cur.config.reveal1)

	mRevealed = {
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
	
	#Calculate player totals
	if(cur.config.revealwho == 0 or cur.config.revealwho == 2) then
		playersToBeRevealed = playersToBeRevealed + maxPhants
	end
	if(cur.config.revealwho == 1 or cur.config.revealwho == 2) then
		playersToBeRevealed = playersToBeRevealed + maxPaladins
	end

	#BugFix 2:		Rearranged reveal logic to correctly handle all scenarios
	#Assumptions:	Once we encounter a reveal time of zero, it is assumed that all revelations are done.  
	#			 	i.e. If phantom 1's reveal time is Never, then phantoms 2 and 3 will not be revealed either.
	
	#Build a table to use in our loop
	local revealtimes = {}
	revealtimes[1] = cur.config.reveal1
	revealtimes[2] = cur.config.reveal2
	revealtimes[3] = cur.config.reveal3
	
	#Fork a thread to sync name placeholders.
	cur.trash:Add(ForkThread(ShowNamePlaceHolders))
	
	for i=1, table.getn(revealtimes) do
		if(revealtimes[i] == 0) then
			DoneRevealing(maxPhants + maxPaladins - playersRevealed, i)
			do return end
		elseif(playersRevealed < playersToBeRevealed) then
			WaitSeconds(revealtimes[i])
			cur.trash:Add(ForkThread(DoReveal, i))
			playersRevealed = playersRevealed + 1
			
			#Make sure to count paladin if they're going to be revealed
			if((cur.config.revealwho == 1 or cur.config.revealwho == 2) and (i <= cur.stats.paladin_count)) then
				playersRevealed = playersRevealed + 1
			end
		end
	end
end

function ShowNamePlaceHolders()
	#Make initial synchronization call so that name place holders are displayed
	WaitSeconds(5)
	Sync.mRevealed = mRevealed
	LOG('syncing from sim')
end

function DoReveal(idx)
	if(cur.config.revealwho == 0 or cur.config.revealwho == 2) then
		RevealPhantom(cur.phantoms[idx], idx)
	end
	Sync.mRevealed = mRevealed
	LOG('syncing from sim')
	
	if((cur.config.revealwho == 1 or cur.config.revealwho == 2) and (idx <= cur.stats.paladin_count)) then
		WaitSeconds(6)
		RevealPaladin(cur.paladins[idx], idx)
	end
	
	Sync.mRevealed = mRevealed
	LOG('syncing from sim')
end

#Checks the current player type and reveal config to determine whether or not player will see reveal
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
		Sync.mAlert = { ArmyBrains[army].Nickname.." is a Mafioso!", false}
		
		LOG('revealed phantom: ', ArmyBrains[army].Nickname)
		if(index == 1) then
			mRevealed.phant1 = army
		elseif(index == 2) then
			mRevealed.phant2 = army
		elseif(index == 3) then
			mRevealed.phant3 = army
		end
	end
end

function RevealPaladin(army, index)
	if CheckRevealConfigForThisPlayer() == true then
		Sync.mAlert = { ArmyBrains[army].Nickname.." is a paladin!", false}
		LOG('revealed paladin: ', ArmyBrains[army].Nickname)
		if(index == 1) then
			mRevealed.pal1 = army
		elseif(index == 2) then
			mRevealed.pal2 = army
		elseif(index == 3) then
			mRevealed.pal3 = army
		end
	end
end