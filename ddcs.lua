------------------------------------------------------------------------------
-- Dynamic DCS
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- Requirements
-- need to comment those lines into your DCS/Scripts/MissionScripting.lua file
-- --sanitizeModule('io')
-- --sanitizeModule('lfs')
-- (this change needs DCS restart)
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- todo
-- when player crash or quit the game or change slot: reset
-- advert player when arriving in a drop zone (or pickup zone)
-- advert player when exiting a drop zone (or pickup zone)
-- load previous mission state at startup
-- load current mission state before mission restart (and every x minutes) + backup
------------------------------------------------------------------------------

ddcs = {}

-- initial documents positions
ddcs.documents = {
	pickup = {
		["test1"] = {
			to_send=5,
			sent=0,
		} ,
		["FARP Amtkel"] = {
			to_send=50,
			sent=0,
		} ,
	},
	drop = {
		["test2"] = {
			to_receive=5,
			received=0,
		} ,
		["FARP Teberda"] = {
			to_receive=3,
			received=0,
		} ,
		["FARP KN77"] = {
			to_receive=3,
			received=0,
		} ,
		["FARP Aryz"] = {
			to_receive=3,
			received=0,
		} ,
	}
}

-- players status
-- documents
--   onBoard
--   transported
ddcs.players = {}

-- aicrafts allowed to transport documents
ddcs.documentsAllowedTransporters = {
    ["Yak-52"] = true,
}

-- aicrafts allowed to transport troups
ddcs.troupsAllowedTransporters = {
}

-- aicrafts allowed to transport menu
ddcs.allowedTransporters = {
}

------------------------------------------------------------------------------
-- Build main DDCS menu 
------------------------------------------------------------------------------
function ddcs.buildMenu()

	-- prepare full transporters list
	for name, player in pairs(mist.DBs.humansByName) do
		if ddcs.documentsAllowedTransporters[player.type] ~= nil then
			ddcs.allowedTransporters[player.type]=true
		end
	end

	-- build transport menu
	for name, player in pairs(mist.DBs.humansByName) do
		-- allowed to transport things ?
		if ddcs.allowedTransporters[player.type] ~= nil then
			_tansportPath = missionCommands.addSubMenuForGroup(player.groupId, 'Transport')

			-- allowed to transport documents ?
			if ddcs.documentsAllowedTransporters[player.type] ~= nil then			
				_tansportDocumentsPath = missionCommands.addSubMenuForGroup(player.groupId, 'Documents', _tansportPath)

				missionCommands.addCommandForGroup(player.groupId, 'Status', _tansportDocumentsPath, ddcs.transportStatus, player)
				missionCommands.addCommandForGroup(player.groupId, 'Pickup', _tansportDocumentsPath, ddcs.transportPickupDocument, player)
				missionCommands.addCommandForGroup(player.groupId, 'Drop', _tansportDocumentsPath, ddcs.transportDropDocument, player)
				missionCommands.addCommandForGroup(player.groupId, 'Debug', _tansportDocumentsPath, ddcs.transportDebug, player)
			end
		end
		
	end

	-- during developpement phase
	_missionPath = missionCommands.addSubMenu('Mission')

	-- allowed to transport documents ?
	_missionFilePath = missionCommands.addSubMenu('File', _missionPath)

	missionCommands.addCommand('Status', _missionFilePath, ddcs.missionFileStatus)
	missionCommands.addCommand('Load', _missionFilePath, ddcs.missionFileLoad)
	missionCommands.addCommand('Save', _missionFilePath, ddcs.missionFileSave)
	
end

------------------------------------------------------------------------------
-- DDCS simple status transport documents
-- @param UnitGroup player
------------------------------------------------------------------------------
function ddcs.transportStatus(player)

	trigger.action.outText('Transport Documents Status', 10)

	for zoneName, document in pairs(ddcs.documents.pickup) do
	
		local msg = 'Pickup zone: ' .. zoneName .. '\n'
		.. 'To send: ' .. document.to_send .. '\n'
		.. 'Already sent: ' .. document.sent .. '\n'

		trigger.action.outText(msg , 10)	  
	end

	for zoneName, document in pairs(ddcs.documents.drop) do

		local pct = mist.utils.round(100*document.received/(document.to_receive+document.received),0)
		local msg='Drop zone: ' .. zoneName .. ' ' .. pct .. '%\n'
		.. 'To receive: ' .. document.to_receive .. '\n'
		.. 'Already received: ' .. document.received .. '\n'

		trigger.action.outText(msg , 10)	  
	end
	
	-- player status
	trigger.action.outText('Documents on board: ' .. ddcs.players[player.unitName].documents.onBoard , 10)
end

------------------------------------------------------------------------------
-- DDCS Try to pickup a document
-- @param UnitGroup player
-- Needs:
--  # be in a pickup zone
--  # remaining documents
--  # on ground level
--  # stopped (speed <1)
--  # aircraft could transport documents
--  # aircraft has not already a document on board
------------------------------------------------------------------------------
function ddcs.transportPickupDocument(player)

	for zoneName, document in pairs(ddcs.documents.pickup) do
		trigger.action.outText(zoneName .. ' ' .. player.unitName, 10)
		local u = mist.getUnitsInZones(mist.makeUnitTable({player.unitName}), {zoneName})
		-- unit found in this zone ?
		if #u == 1 then
			ddcs.transportPickupDocumentAction(document, player)
			return
		end
	end

	-- here ? we are not in a zone
	trigger.action.outTextForGroup(player.groupId, 'you are not in a valid picking zone', 10)
end


------------------------------------------------------------------------------
-- DDCS Try to drop a document
-- Needs:
--  # be in a drop zone
--  # with a document on board for this drop zone
--  # on ground level
--  # stopped (speed <1)
------------------------------------------------------------------------------
function ddcs.transportDropDocument(player)

	for zoneName, document in pairs(ddcs.documents.drop) do
		trigger.action.outText(zoneName .. ' ' .. player.unitName, 10)
		local u = mist.getUnitsInZones(mist.makeUnitTable({player.unitName}), {zoneName})
		-- unit found in this zone ?
		if #u == 1 then
			ddcs.transportDropDocumentAction(document, player)
			return
		end
	end

	-- here ? we are not in a zone
	trigger.action.outTextForGroup(player.groupId, 'you are not in a valid drop zone', 10)
end

------------------------------------------------------------------------------
-- DDCS simple debug transport documents
-- @param UnitGroup player
------------------------------------------------------------------------------
function ddcs.transportDebug(player)
	--missionCommands.removeItem({'Tasking', 'Transport', 'Request cargo load'})
	trigger.action.outText('Transport debug ... ' .. player.groupName, 10)
	for zoneName, document in pairs(ddcs.documents.pickup) do
		local msg='Pickup zone: ' .. zoneName .. '\n'
		.. 'To send: ' .. document.to_send .. '\n'
		.. 'Already sent: ' .. document.sent .. '\n'

		trigger.action.outText(msg , 10)	  
	end
	for zoneName, document in pairs(ddcs.documents.drop) do
		local msg='Drop zone: ' .. zoneName .. '\n'
		.. 'To receive: ' .. document.to_receive .. '\n'
		.. 'Already received: ' .. document.received .. '\n'

		trigger.action.outText(msg , 10)	  
	end
	
	-- player status
	trigger.action.outText('Documents on board: ' .. ddcs.players[player.unitName].documents.onBoard , 10)
end

------------------------------------------------------------------------------
-- DDCS Try to pickup a document
-- @param UnitGroup player
-- Needs:
--  # be in a pickup zone: OK
--  # remaining documents: OK
--  # on ground level
--  # stopped (speed <1)
--  # aircraft could transport documents: OK
--  # aircraft has not already a document on board: OK
------------------------------------------------------------------------------
function ddcs.transportPickupDocumentAction(document, player)

	local playerUnit = Unit.getByName(player.unitName)

	if playerUnit:inAir() then
		trigger.action.outTextForGroup(player.groupId, 'You needs to be on ground to pickup documents', 10)
		return
	end

	velocity = mist.utils.get3DDist({x=0,y=0,z=0}, playerUnit:getVelocity())

	if velocity > 1 then
		trigger.action.outTextForGroup(player.groupId, 'You needs to be stopped on ground to pickup documents', 10)
		return
	end
		
	if document.to_send <= 0 then
		trigger.action.outTextForGroup(player.groupId, 'no remaining documents in this pickup zone', 10)
		return
	end
	if ddcs.players[player.unitName].documents.onBoard > 0 then
		trigger.action.outTextForGroup(player.groupId, 'you have already a document on board', 10)
		return
	end	

	document.to_send = document.to_send -1
	document.sent = document.sent +1
	ddcs.players[player.unitName].documents.onBoard = 1

	local msg = 'you picked a document, transport it to a drop zone'

	trigger.action.outTextForGroup(player.groupId, msg, 10)
end

------------------------------------------------------------------------------
-- DDCS Try to drop a document
-- @param UnitGroup player
-- Needs:
--  # be in a drop zone: OK
--  # remaining documents: OK
--  # on ground level
--  # stopped (speed <1)
--  # aircraft could transport documents: OK
--  # aircraft has not already a document on board: OK
------------------------------------------------------------------------------
function ddcs.transportDropDocumentAction(document, player)

	local playerUnit = Unit.getByName(player.unitName)

	if playerUnit:inAir() then
		trigger.action.outTextForGroup(player.groupId, 'You needs to be stopped on ground to drop documents', 10)
		return
	end
	
	velocity = mist.utils.get3DDist({x=0,y=0,z=0}, playerUnit:getVelocity())

	if velocity > 1 then
		trigger.action.outTextForGroup(player.groupId, 'You needs to be stopped on ground to drop documents', 10)
		return
	end
	
	if document.to_receive <= 0 then
		trigger.action.outTextForGroup(player.groupId, 'drop zone don\'t need any more documents', 10)
		return
	end
	if ddcs.players[player.unitName].documents.onBoard <= 0 then
		trigger.action.outTextForGroup(player.groupId, 'you don\'t have a document on board', 10)
		return
	end

	document.to_receive = document.to_receive - 1
	document.received = document.received + 1
	ddcs.players[player.unitName].documents.onBoard = 0

	trigger.action.outTextForGroup(player.groupId, 'you delivered a document', 10)
	
	-- @todo what appends when all needed documents are here ?
	trigger.action.outText(player.groupName .. ' has just delivered a document', 10)
end

------------------------------------------------------------------------------
-- DDCS reset previous menu
------------------------------------------------------------------------------
function ddcs.resetMenu()
	-- clear previous menu
	missionCommands.removeItem('Transport')
end

------------------------------------------------------------------------------
-- handle events
-- the entry point for DDCS events
------------------------------------------------------------------------------
function ddcs.handleEvents(event)
	
	-- player spawn ?
	if event.id == world.event.S_EVENT_PLAYER_ENTER_UNIT then 
		--trigger.action.outText('S_EVENT_PLAYER_ENTER_UNIT', 10)
		--ddcs.initPlayer(world.player)
	-- player dead ?
	elseif event.id == world.event.S_EVENT_PILOT_DEAD then 
		--trigger.action.outText('S_EVENT_PILOT_DEAD', 10)
		--trigger.action.outText(mist.utils.serialize(event), 10)
	-- player leave ?
	elseif event.id == world.event.S_EVENT_PLAYER_LEAVE_UNIT then 
		--trigger.action.outText('S_EVENT_PLAYER_LEAVE_UNIT', 10)
		--trigger.action.outText(mist.utils.serialize(event), 10)
	-- birth ?
	elseif event.id == world.event.S_EVENT_BIRTH then 
		--trigger.action.outText('S_EVENT_BIRTH', 10)
		ddcs.initUnit(event.initiator:getName())
		--ddcs.debugEvent=event
		--trigger.action.outText(mist.utils.serialize(event), 10)
	end
end 

------------------------------------------------------------------------------
-- DDCS Init
------------------------------------------------------------------------------
function ddcs.init()

	mist.removeEventHandler(ddcsEventHandler)

	ddcs.resetMenu()
	ddcs.buildMenu()
	
	-- build transport menu
	for name, player in pairs(mist.DBs.humansByName) do
		ddcs.initUnit(name)
	end

	ddcsEventHandler = mist.addEventHandler(ddcs.handleEvents) 
	
end

------------------------------------------------------------------------------
-- DDCS Init a player unit
------------------------------------------------------------------------------
function ddcs.initUnit(playerName)

	ddcs.players[playerName]={
		documents = {
			onBoard = 0,
			transported = 0,
		}
	}

end

------------------------------------------------------------------------------
-- DDCS missionFileStatus
------------------------------------------------------------------------------
function ddcs.missionFileStatus()
	trigger.action.outText('@todo missionFileStatus', 10)
end

------------------------------------------------------------------------------
-- DDCS missionFileLoad
------------------------------------------------------------------------------
function ddcs.missionFileLoad()
	trigger.action.outText('starting missionFileLoad', 10)
	ddcs.load()
	trigger.action.outText('mission loaded', 10)
end

------------------------------------------------------------------------------
-- DDCS missionFileLoad
------------------------------------------------------------------------------
function ddcs.missionFileSave()
	trigger.action.outText('starting missionFileSave', 10)
	ddcs.save()
	trigger.action.outText('mission saved', 10)
end

------------------------------------------------------------------------------
-- DDCS Load previous game state
------------------------------------------------------------------------------
function ddcs.load()
	dofile(lfs.writedir() .. 'logs/documents.lua')
	ddcs.documents = documents
end

------------------------------------------------------------------------------
-- DDCS Save current game state
------------------------------------------------------------------------------
function ddcs.save()
	mist.debug.writeData(mist.utils.serialize,{'documents', ddcs.documents}, 'documents.lua')	
end


-- start DDCS
ddcs.init()
