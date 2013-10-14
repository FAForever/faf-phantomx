local meteorBrain = false
local meteorArmyName = "NEUTRAL_CIVILIAN"
local meteorArmyIdx = false
local meteorLauncherUnit = false
local scenarioMeteorDelay = 0
local scenarioMeteorDelayIncrement = 0
local assignmentTime = 8 * 60
local initialDelayAfterAssignment = 0
local armiesInGame = 0

local allowMeteorSpawn = 0

-----------------------------------------------------------------
--  MAIN FUNCTION
-----------------------------------------------------------------

function MafiaMeteorsThread()
	WaitSeconds(10)
	if ArmyExists(meteorArmyName) then
		LOG('MMT: Configuring Meteor Army.')
		ConfigureMeteorArmy()
		while true do
		
		end
	else
		LOG('MMT: Army with name ('..meteorArmyName..') not found!  Meteor thread cannot continue!  Exiting.')
	end
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
	
	meteorLauncherUnit = CreateUnitHPR("PCU1001", meteorArmyIdx,  -100, 0, -50,0,0,0)
	LOG('Meteor Army configured.')
end

-----------------------------------------------------------------
--  METEOR CREATION FUNCTIONS
-----------------------------------------------------------------

function MeteorStrikeC(data)	
	if meteorBrain then
		#Sync.pAlert = { "Orbital Observatory Report", "Meteors have been detected on a collision course!"}
		WaitSeconds(15)
		for i=1, data.count, 1 do
			local coord = GenerateRandomTargetOffset(data.posX, data.posZ, data.posY, data.radius)
			SpawnMeteor(coord[1], coord[2], coord[3], data)
			WaitSeconds(0.1)
		end
	end
end

function SetupMafiaMeteors(data)
	LOG("GLOBAL: allow_meteors: " .. import('/_test_code/MafiaSim.lua').allow_meteors)
	LOG("GLOBAL: meteor_count: " .. import('/_test_code/MafiaSim.lua').meteor_count)
	
	local strike_number = import('/_test_code/MafiaSim.lua').meteor_count
	
	local base_radius = 30
	local base_count = 4
	
	data.radius = base_radius + strike_number * 5 
	data.count = base_count + strike_number
	data.splash = 8 + strike_number
	data.dmg = 8000 + strike_number * 10000
	
	if tonumber(ScenarioInfo.Options.Mafia_Mod)==1 and import('/_test_code/MafiaSim.lua').allow_meteors==1 then
		ConfigureMeteorArmy()	
		LOG("in meteors.lua SpawnMafiaMeteors")
		ForkThread(MeteorStrikeC,data)
	end
end

function SpawnMeteor(posX, posY, posZ, data)
    LOG("spawning a new meteor")
	LOG(posX)
	LOG(posY)
	LOG(posZ)
	local meteorProj = meteorLauncherUnit:CreateProjectile('/projectiles/Meteor01/Meteor01_proj.bp', 0, 255, 0, nil, nil, nil)
    meteorProj:SetNewTargetGround({posX, 0, posZ})
    meteorProj:SetVelocity(0,-35,0)
    local dmgTable = GetMeteorDamageTable()
	dmgTable.DamageRadius = data.splash
	dmgTable.DamageAmount = data.dmg
  	meteorProj:PassDamageData(dmgTable)
  	Warp( meteorProj, Vector(posX, 500, posZ))
  	
  	--Create Target Decal
  	local targetTex = '/textures/ui/common/game/AreaTargetDecal/nuke_icon_small.dds'
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