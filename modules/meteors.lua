local meteorBrain = false
local meteorArmyName = "NEUTRAL_CIVILIAN"
local meteorArmyIdx = false
local meteorLauncherUnit = false
local scenarioMeteorDelay = 0
local scenarioMeteorDelayIncrement = 0
local massDelayAmount = 60
local assignmentTime = 8 * 60
local initialDelayAfterAssignment = 0
local armiesInGame = 0

local massDestroyed = 0
local massProduced = 0
local timeRemaining = 1000000
local meteorsDone = false
local numberOfLiveArmies = 0
local massPercentThreshold = 100
local delta = { mass = {}, energy = {} }
local thresholdPercent = 1.0
local massDelayCount = 0
-----------------------------------------------------------------
--  MAIN FUNCTION
-----------------------------------------------------------------
function MeteorsThread()
	WaitSeconds(10)
	if ArmyExists(meteorArmyName) then
		--Set configuration
		initialDelayAfterAssignment = (tonumber(ScenarioInfo.Options.PhantomMeteorDelayTime) * 60)
		scenarioMeteorDelay = (tonumber(ScenarioInfo.Options.PhantomSubseqMeteorDelayTime) * 60)
		--scenarioMeteorDelayIncrement = (tonumber(ScenarioInfo.Options.PhantomMeteorDelayTime) * 60)
		
		ConfigureMeteorArmy()
		WaitSeconds(assignmentTime - 12)
        
        armiesInGame = LiveArmyCount()

        ForkThread(CalculateMetricsThread)
        WaitSeconds(2)
		
		while meteorsDone == false do
			if ShouldLaunchMeteors() then
				local interval = 15
				Sync.pAlert = { "Orbital Observatory Report", "Meteors have been detected on a collision course!"}
				while ShouldLaunchMeteors() do
					WaitSeconds(interval)
					local position = GetRandomMapCoordinates()
		   
					ForkThread(function() MeteorStrikeB() end)
					interval = interval - math.floor(0.15*math.random(interval))
					if (interval < 3) then
						interval = 3
					end
				end
                if meteorsDone then
                    Sync.pAlert = { "Orbital Observatory Report", "Meteors showers have permanently stopped."}
                else
                    if massDestroyed/massProduced > thresholdPercent then
                        --Then we stopped for mass destroyed delay
                        massDelayCount = massDelayCount + 1
                    end
                    Sync.pAlert = { "Orbital Observatory Report", "Meteors showers have stopped...for now!"}
                end
                WaitSeconds(5)
            else
                --If time before meteors is less than two minutes and the mass threshold is reached, then delay meteors
                if massDestroyed/massProduced > thresholdPercent and timeRemaining < massDelayAmount then                    
                    massDelayCount = massDelayCount + 1
                end
			end
			WaitSeconds(1)
		end
	else
		LOG('Army with name ('..meteorArmyName..') not found!  Meteor thread cannot continue!  Exiting.')
	end
end

function CalculateMetricsThread()
    local massIncomeList = List.new()
    local massDestroyedList = List.new()
    
    while meteorsDone == false do
        WaitSeconds(0.1)
        
        numberOfLiveArmies = LiveArmyCount()
        thresholdPercent = 2.0 / numberOfLiveArmies
        meteorsDone = numberOfLiveArmies <= 2    
        timeRemaining = ComputeMeteorStartTime() - GetGameTimeSeconds()
        
        local massDestroyedThisBeat = 0
        local massIncomeThisBeat = 0
        for army, brain in ArmyBrains do
            if ArmyIsOutOfGame(army) == false then
                local m = brain:GetArmyStat("Units_MassValue_Lost",0.0).Value
                if delta.mass[army] > 0 then
                    massDestroyedThisBeat = massDestroyedThisBeat + m - delta.mass[army]
                end
                delta.mass[army] = m
                
                massIncomeThisBeat = massIncomeThisBeat + brain:GetEconomyIncome('MASS')
            end
        end
        
        List.pushright(massIncomeList, massIncomeThisBeat)
        massProduced = massProduced + massIncomeThisBeat
        if List.getlength(massIncomeList) > 1200 then
            massProduced = massProduced - List.popleft(massIncomeList)
        end
        
        List.pushright(massDestroyedList, massDestroyedThisBeat)
        massDestroyed = massDestroyed + massDestroyedThisBeat
        if List.getlength(massDestroyedList) > 1200 then
            massDestroyed = massDestroyed - List.popleft(massDestroyedList)
        end
        
        Sync.pMeteorData = {MassDestroyedPercent = 100*(massDestroyed/massProduced), TimeRemaining = timeRemaining, MeteorsDone = meteorsDone, ThresholdPercent=thresholdPercent}
    end
end

function LiveArmyCount()
	local total = 0
	for index, army in ArmyBrains do
		if ArmyIsCivilian(index) == false and ArmyIsOutOfGame(index) == false then
			total = total + 1
		end
	end
	return total
end

function ComputeMeteorStartTime()
    local deadPlayers = armiesInGame - numberOfLiveArmies
    
    --Otherwise, compute the start time and compare that to where we are now...
    local meteorStartTime = 0
    --Base delay
    meteorStartTime = assignmentTime + initialDelayAfterAssignment

    --Add base additional time for each dead player
    meteorStartTime = meteorStartTime + deadPlayers * scenarioMeteorDelay 

    --Add additional increment time for subsequent dead players
    meteorStartTime = meteorStartTime + math.max(deadPlayers - 1, 0) * scenarioMeteorDelayIncrement
    
    --Add additional increment time for mass delays
    meteorStartTime = meteorStartTime + massDelayCount * massDelayAmount
    
    return meteorStartTime
end

function ShouldLaunchMeteors()
	local result = true
	local deadPlayers = armiesInGame - numberOfLiveArmies
	
	--If we have two players left...
	if meteorsDone then
		--then meteors stop for the final duel to the death
		result = false
	elseif timeRemaining > 0 then
        result = false
    elseif massDestroyed/massProduced > thresholdPercent then
        result = false
	end
	
	return result
end

-----------------------------------------------------------------
--  SETUP FUNCTIONS
-----------------------------------------------------------------
function ConfigureMeteorArmy()	
	for army, brain in ArmyBrains do
		if not (brain.Name == meteorArmyName) then
			if brain.BrainType == 'Human' then
				--Set Civilian as enemy to all human players
				SetAlliance(brain.Name, "NEUTRAL_CIVILIAN", 'Enemy')
			end
		else
			--Setup the civilian army
			meteorArmyIdx = army
			meteorBrain = brain
			brain:SetResourceSharing(false)
	 	end
	end
	
    --Create the launcher unit on map and THEN warp it off map.
    --Apparently, spawning a unit off map can corrupt the entire heightmap.
    local posY = math.max(GetSurfaceHeight(32, 32), GetTerrainHeight(32, 32))
	meteorLauncherUnit = CreateUnitHPR("PCU1001", meteorArmyIdx,  32, posY, 32,0,0,0)
    posY = math.max(GetSurfaceHeight(-60, -70), GetTerrainHeight(-60, -70))
    Warp( meteorLauncherUnit, Vector(-60, posY, -70))
end

-----------------------------------------------------------------
--  METEOR CREATION FUNCTIONS
-----------------------------------------------------------------
function MeteorStrikeA(posX, posY, posZ)	
	if meteorBrain then    	
    	local meteorCount = 50
    	for i=1, meteorCount, 1 do
    		local coord = GenerateRandomTargetOffset(posX, posY, posZ, 300)
    		SpawnMeteor(coord[1], coord[2], coord[3])
    		WaitSeconds(0.2)
    	end
	end
end

function MeteorStrikeB()	
	if meteorBrain then    	
    	local meteorCount = 50
    	for i=1, meteorCount, 1 do
    		local coord = GenerateRandomTargetOnMap()
    		SpawnMeteor(coord[1], coord[2], coord[3])
    		WaitSeconds(0.2)
    	end
	end
end

function SpawnMeteor(posX, posY, posZ)
    local meteorProj = meteorLauncherUnit:CreateProjectile('/projectiles/Meteor01/Meteor01_proj.bp', 0, 255, 0, nil, nil, nil)
    meteorProj:SetNewTargetGround({posX, 0, posZ})
    meteorProj:SetVelocity(0,-35,0)
    local dmgTable = GetMeteorDamageTable()
  	meteorProj:PassDamageData(dmgTable)
  	Warp( meteorProj, Vector(posX, 500, posZ))
  	
  	--Create Target Decal
  	local targetTex = '/mods/faf-phantomx/textures/ui/common/game/AreaTargetDecal/nuke_icon_small.dds'
  	local targetHndl = CreateDecal({posX, posY, posZ}, 0, targetTex, '', 'Water Albedo', dmgTable.DamageRadius * 2, dmgTable.DamageRadius * 2, 600, 8.7, -1)
end

function GetMeteorDamageTable()
    local damageTable = {}
    damageTable.DamageRadius = 12
    damageTable.DamageAmount = 12000
    damageTable.DamageType = 'Normal'
    damageTable.DamageFriendly = true
    damageTable.CollideFriendly = true
    return damageTable
end

-----------------------------------------------------------------
--  UTILITY FUNCTIONS
-----------------------------------------------------------------
function IsOnMap(posX, posY, posZ)
	if posX > 0 and posX <= ScenarioInfo.size[1] and posZ > 0 and posZ <= ScenarioInfo.size[2] then
		return true
	end
	return false
end

function GetRandomMapCoordinates()
	local possibleVictims = GetStartPositions()
	local unluckyVictim = math.random(table.getn(possibleVictims))
    local targetStartLocation = possibleVictims[unluckyVictim]
	
	
	local targetFinalLocation = GenerateRandomTargetOffset(targetStartLocation[1], targetStartLocation[2], targetStartLocation[3], 200)
	
    while not IsOnMap(targetFinalLocation[1], targetFinalLocation[2], targetFinalLocation[3]) do
		targetFinalLocation = GenerateRandomTargetOffset(targetStartLocation[1], targetStartLocation[2], targetStartLocation[3], 200)
	end
	
	local x = targetFinalLocation[1]
	local z = targetFinalLocation[3]
	local y = GetSurfaceHeight(x,z)
	return Vector(x, y, z)
end

function GenerateRandomTargetOffset(posX, posY, posZ, maxDist)
	local vectorLength = math.random(maxDist)
	local vectorDirection = math.random(314159) / 50000
	
	local rtVal = {0,0,0}
	rtVal[1] = posX + vectorLength * math.cos(vectorDirection)
	rtVal[2] = 0
	rtVal[3] = posZ + vectorLength * math.sin(vectorDirection)
	return rtVal
end

function GenerateRandomTargetOnMap()
	local posX =  math.random(ScenarioInfo.size[1])
	local posZ =  math.random(ScenarioInfo.size[2])
	local posY = math.max(GetSurfaceHeight(posX, posZ), GetTerrainHeight(posX, posZ))
	
	local rtVal = {0,0,0}
	rtVal[1] = posX
	rtVal[2] = posY
	rtVal[3] = posZ
	return rtVal
end

function ArmyExists(armyName)
	for army, brain in ArmyBrains do
		if brain.Name == armyName then
			return true
		end
	end
	return false
end

function GetStartPositions()
    local armyPositions = {}
    local realArmyPositions = {}

    -- try new data first
    if ScenarioInfo.Configurations.standard and ScenarioInfo.Configurations.standard.teams then
        -- find the "FFA" team
        for index, teamConfig in ScenarioInfo.Configurations.standard.teams do
            if teamConfig.name and (teamConfig.name == 'FFA') then
                for armyIndex, armyName in teamConfig.armies do
                    armyPositions[armyName] = {}
                end
                break
            end
        end
    end

    -- try old data if nothing added to army positions
    if table.getsize(armyPositions) == 0 then
        -- figure out all the armies in this map
        -- make sure old data is there
        if ScenarioInfo.Games then
            for index, game in ScenarioInfo.Games do
                for k, army in game do
                    armyPositions[army] = {}
                end
            end
        end
    end

    -- if we found armies, then get the positions
    if table.getsize(armyPositions) > 0 then
        for army, position in armyPositions do
            if Scenario.MasterChain['_MASTERCHAIN_'].Markers[army] then
                pos = Scenario.MasterChain['_MASTERCHAIN_'].Markers[army].position
                -- x and z value are of interest so ignore y (index 2)
                position[1] = pos[1]
                position[2] = pos[2]
                position[3] = pos[3]
                table.insert(realArmyPositions, position)
            end
        end
    end

    return realArmyPositions
end

function UpdateAssignmentTime(offset)
	--Note: this must be called within the first 10 seconds of the game.  Otherwise, it may not work correctly
	assignmentTime = assignmentTime + offset
end

-----------------------------------------------------------------
-- QUEUE FUNCTIONS
-----------------------------------------------------------------
List = {}
function List.new ()
    return {first = 0, last = -1}
end

function List.getlength(list)
    return list.last - list.first + 1
end

function List.pushright (list, value)
  local last = list.last + 1
  list.last = last
  list[last] = value
end

function List.popleft (list)
  local first = list.first
  if first > list.last then error("list is empty") end
  local value = list[first]
  list[first] = nil        -- to allow garbage collection
  list.first = first + 1
  return value
end

