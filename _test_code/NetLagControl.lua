#*************************************************************************************
#**
#**  File     :  /modules/NetLagControl.lua
#**  Author(s):  Duck_42
#**
#**  Summary  :  Automatically adjusts net_lag values based on in game pings
#**
#**  Change Log:
#**  2013.06.16: Initial Version.				                            Duck_42
#**  2013.06.30: Modified query logic to handle concurrency more reliably.  Duck_42
#**  2013.07.08: Re-wrote all the code for deciding net lag values.
#**              New code uses a client-server model instead of a
#**              decentralized approach.                                    Duck_42
#**  2013.07.11: Bugfix														Duck_42
#*************************************************************************************
local GameMain = import('/lua/ui/game/gamemain.lua')
local QuerySystem = import('/lua/UserPlayerQuery.lua')

--Configuration Values
local pollFrequency = 30 --Seconds (recommended that this not be less than 10 seconds)
local headroom = 50 -- buffer value (milliseconds).  This value is added to the highest ping to cover net spikes.
local maxInterval = 500 -- maximum net_lag value (milliseconds)
local minInterval = 50 -- minimum net_lag value (milliseconds)

--Operational Values
parent = false
local lastUpdate = -1000
local requestNumber = 0

local theValue = 500
local actualValue = 500

--Master Client control values
local isMasterClient = false
local ResponseTable = {}
local updatedThisCycle = false

function CreateModUI(isReplay, _parent)
	parent = _parent
	QuerySystem.AddQueryListener('NetLagUpdateRequest', ReceiveNetLagRequest)
	QuerySystem.AddQueryListener('NetLagUpdateCommand', ReceiveNetLagCommand)
	GameMain.AddBeatFunction(NetLagUIBeat)
end

function NetLagUIBeat()
	--Check for controller change according to the specified polling interval
	--If we are the controller, send a request for max ping values
	
	local t = CurrentTime()
	if t > lastUpdate + pollFrequency then
		local controller = ChooseMasterClient()
		if isMasterClient then
			ForkThread(SendNetLagRequest)
		end		
		lastUpdate = t	
	end
end


-----------------------------------Master Client Control Functions-----------------------------------
function SendNetLagRequest()
	--Clear the response table and increase the update sequence number
	requestNumber = requestNumber + 1
	ResponseTable = {}
	theValue = minInterval
	updatedThisCycle = false
	
	local armiesInfo = GetArmiesTable()    
	local f = armiesInfo.focusArmy
	LOG('AUTO NETLAG: Master sending net_lag requests with R value '..requestNumber)
	for armyIndex, armyData in armiesInfo.armiesTable do
		qd = { From = f, To = armyIndex, Name='NetLagUpdateRequest', RNumber=requestNumber}
		QuerySystem.Query(qd, ReceiveNetLagAnswer)
	end
end

function SendNetLagChange()
	local armiesInfo = GetArmiesTable()    
	local f = armiesInfo.focusArmy
	LOG('AUTO NETLAG: Master sending net_lag update command with R value '..requestNumber..' and UValue '..theValue)
	qd = { From = f, To = f, Name='NetLagUpdateCommand', RNumber=requestNumber, UValue=theValue}
	QuerySystem.Query(qd, ReceiveNetLagCommandAnswer)
end

function ReceiveNetLagAnswer(resultData)
	if resultData.RNumber == requestNumber and not HasClientResponded(resultData.From) then
		LOG('AUTO NETLAG: Received net_lag answer from client with id '.. resultData.From .. ', SValue '.. resultData.SValue..', and R value '.. resultData.RNumber)
		table.insert(ResponseTable, resultData.From)
		theValue = math.max(theValue, resultData.SValue)
	end
	
	if AllClientsResponded() and updatedThisCycle == false then
		updatedThisCycle = true
		ForkThread(SendNetLagChange)
	end
end

function ReceiveNetLagCommandAnswer()
end
-----------------------------------------------------------------------------------------------------


------------------------------------Slave Client Control Functions-----------------------------------
function DoNetLagChange()	
	WaitSeconds(2)
	LOG('AUTO NETLAG: Setting net_lag value: '..actualValue ..'ms.')
	ConExecute('net_Lag '..actualValue)
end



function ReceiveNetLagRequest(qd)
	local armiesInfo = GetArmiesTable()    
	local f = armiesInfo.focusArmy
	if qd.To == f then
		LOG('AUTO NETLAG: Received net_lag request from control client with id '.. qd.From .. ' and R value '.. qd.RNumber)
		local v = CalculatePreferredNetLag()
	
		ad = { From = f, To = qd.From, Name='NetLagUpdateRequest', SValue=v,  RNumber=qd.RNumber}
		LOG('AUTO NETLAG: Sending response with S value '.. v .. ' and R value '.. qd.RNumber)
		QuerySystem.SendResult(qd, ad)
	end
end

function ReceiveNetLagCommand(qd)
	LOG('AUTO NETLAG: Received net_lag command from player id '.. qd.From .. ' with U value '.. qd.UValue ..' and R number '..qd.RNumber)
	actualValue = qd.UValue
	ForkThread(DoNetLagChange)
end
-----------------------------------------------------------------------------------------------------

function HasClientResponded(armyId)
	for r in ResponseTable do
		if r == armyId then
			return true
		end
	end
	return false
end

function AllClientsResponded()
	local clients = GetSessionClients()
	local rCount = 0
	local cCount = 0
	
	for r in ResponseTable do
		rCount = rCount + 1
	end
	
	for i, clientInfo in clients do
		if clientInfo.connected then
			cCount = cCount + 1
		end
	end
	
	if cCount == rCount then
		return true
	else
		return false
	end
end

function ChooseMasterClient()
    local clients = GetSessionClients()
    local armiesInfo = GetArmiesTable()
    
    --Find player with the lowest uid
    local minId = -1
    local playerName = ''
    for i, clientInfo in clients do
    	if (minId == -1 or clientInfo.uid < minId) and clientInfo.connected then
    		minId = clientInfo.uid
    		playerName = clientInfo.name
    	end
    end
    
    --Find the army index associated with that player
    for armyIndex, armyData in armiesInfo.armiesTable do
    	if armyData.nickname == playerName then
    		if armyIndex ==  armiesInfo.focusArmy then
    			isMasterClient = true
    		else
    			isMasterClient = false
    		end
    		return armyIndex
    	end
    end
	
    return -1
end

function CalculatePreferredNetLag()
    local clients = GetSessionClients()
    local worst = 0
    for index,client in clients do
    	if client.connected then
    		if client.ping > worst then
    			worst = client.ping
    		end
    	end
    end
    
    return math.min(math.max(worst + headroom, minInterval), maxInterval)
end