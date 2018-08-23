------------------------------------------------------------------------------
-- marker_command.lua
-- use markers on map to move units on
-- namespace: "marker"
-- documentation: see doc/marker.md
------------------------------------------------------------------------------

marker = {}

-- a simple flag, set markerDebug = true
marker.debug = false

------------------------------------------------------------------------------
-- marker.moveCommandEventHandler
-- ingame marker command: MOVE(groupName,speed)
-- ex ingame: MOVE(CVN,10)
------------------------------------------------------------------------------
function marker.moveCommandEventHandler(event)

	-- parse the command: MOVE(groupName,speed)
	-- params[1]: MOVE
	-- params[2]: groupName
	-- params[3]: speed
	params = {}
	for v in string.gmatch(event.text, '([^,\(\)]+)') do
		params[#params+1] = v
	end
	
	local command=params[1]
	local groupName=params[2]
	local speed=params[3]
	
	-- not really a MOVE command ?
	if command ~= "MOVE" then
		-- just exit, skipping this event
		return
	end

	-- new route point
	local newWaypoint = {
		["action"] = "Turning Point",
		["alt"] = 0,
		["alt_type"] = "BARO",
		["form"] = "Turning Point",
		["speed"] = speed,
		["type"] = "Turning Point",
		["x"] = event.pos.z,
		["y"] = event.pos.x
	}

	-- prepare LatLong message
	local vec3={x=event.pos.z, y=event.pos.y, z=event.pos.x}
	lat, lon = coord.LOtoLL(vec3)
	llString = mist.tostringLL(lat, lon, 2)
	
	-- order group to new waypoint
	mist.goRoute(groupName, {newWaypoint})
	
	-- and advise players that the group is moving to a new position
	trigger.action.outText(groupName .. ' moving to ' .. llString .. ' at speed ' .. speed .. ' m/s' , 10)

end

------------------------------------------------------------------------------
-- marker.tankerAction
-- @param string groupName 
-- @param float fromPositionX
-- @param float fromPositionY
-- @param float speed in knots
-- @param float hdg heading (0-359)
-- @param float distance in Nm
-- @param float alt in feet
-- ex: marker.tankerAction("RED-Tanker ARCO", -198019, 578648, 320, 0 , 30, 20000)
------------------------------------------------------------------------------
function marker.tankerAction(groupName, fromPositionX, fromPositionY, speed, hdg ,distance,alt)

	local unitGroup = Group.getByName(groupName)
	if unitGroup == nil then
		trigger.action.outText(groupName .. ' not found for TANKER tasking' , 10)
		return
	end

	-- prepare LatLong message
	local fromVec3={x=fromPositionX, y=0, z=fromPositionY}
	lat, lon = coord.LOtoLL(fromVec3)
	fromllString = mist.tostringLL(lat, lon, 2)

	-- starting position
	local fromPosition = {
		["x"] = fromPositionX,
		["y"] = fromPositionY,
	}

	-- ending position
	local toPosition = {
		["x"] = fromPositionX + distance * 1000 * 0.539957 * math.cos(mist.utils.toRadian(hdg)),
		["y"] = fromPositionY + distance * 1000 * 0.539957 * math.sin(mist.utils.toRadian(hdg)),
	}
	
	local mission = { 
		id = 'Mission', 
		params = { 
			["communication"] = true,
			["start_time"] = 0,
			--["frequency"] = 253,
			--["radioSet"] = true,
			["task"] = "Refueling",
			route = { 
				points = { 
					-- first point
					[1] = { 
						["type"] = "Turning Point",
						["action"] = "Turning Point",
						["x"] = fromPosition.x,
						["y"] = fromPosition.y,
						["alt"] = alt * 0.3048, -- in meters
						["alt_type"] = "BARO", 
						["speed"] = speed/1.94384,  -- speed in m/s
						["speed_locked"] = boolean, 
						["task"] = 
						{
							["id"] = "ComboTask",
							["params"] = 
							{
								["tasks"] = 
								{
									[1] = 
									{
										["enabled"] = true,
										["auto"] = true,
										["id"] = "Tanker",
										["number"] = 1,
									}, -- end of [1]
									[2] = 
									{
										["enabled"] = true,
										["auto"] = true,
										["id"] = "WrappedAction",
										["number"] = 2,
										["params"] = 
										{
											["action"] = 
											{
												["id"] = "ActivateBeacon",
												["params"] = 
												{
													["type"] = 4,
													["AA"] = true,
													["callsign"] = "TKR",
													["modeChannel"] = "Y",
													["channel"] = 1, -- TACAN channel
													["system"] = 4, -- System = TACAN
													["bearing"] = true,
													["frequency"] = 1088000000,
												}, -- end of ["params"]
											}, -- end of ["action"]
										}, -- end of ["params"]
									}, -- end of [2]
								}, -- end of ["tasks"]
							}, -- end of ["params"]
						}, -- end of ["task"]
					}, -- enf of [1]
					[2] = 
					{
						["type"] = "Turning Point",
						["alt"] = alt * 0.3048, -- in meters
						["action"] = "Turning Point",
						["alt_type"] = "BARO",
						["speed"] = speed/1.94384,
						["speed_locked"] = true,
						["x"] = toPosition.x,
						["y"] = toPosition.y,
						["task"] = 
						{
							["id"] = "ComboTask",
							["params"] = 
							{
								["tasks"] = 
								{
									[1] = 
									{
										["enabled"] = true,
										["auto"] = false,
										["id"] = "WrappedAction",
										["number"] = 1,
										["params"] = 
										{
											["action"] = 
											{
												["id"] = "SwitchWaypoint",
												["params"] = 
												{
													["goToWaypointIndex"] = 1,
													["fromWaypointIndex"] = 2,
												}, -- end of ["params"]
											}, -- end of ["action"]
										}, -- end of ["params"]
									}, -- end of [1]
								}, -- end of ["tasks"]
							}, -- end of ["params"]
						}, -- end of ["task"]
					}, -- end of [2]
				}, 
			} 
		} 
	}

	-- replace whole mission
	unitGroup:getController():setTask(mission)
	
	-- but start immediately tanker tasking
	local taskTanker = {
							["enabled"] = true,
							["auto"] = true,
							["id"] = "Tanker",
							["number"] = 1,
						};

	--unitGroup:getController():pushTask(taskTanker)

	trigger.action.outText(groupName .. ' starting tanker mission ' .. fromllString .. ' hdg ' .. hdg .. ', distance ' .. distance .. ' Nm ' .. alt .. ' ft, speed ' .. math.floor(speed) .. ' knots' , 10)

end

------------------------------------------------------------------------------
-- marker.tankerCommandEventHandler
-- ingame marker command: TANKER(groupName,speed,hdg,distance,alt)
-- ex ingame: TANKER(ARCO)
-- ex ingame: TANKER(ARCO,320)
-- ex ingame: TANKER(RED-Tanker ARCO, 320, 0 , 30, 20000)
------------------------------------------------------------------------------
function marker.tankerCommandEventHandler(event)

	-- parse the command: TANKER(groupName,speed,hdg,distance,alt)
	-- params[1]: TANKER
	-- params[2]: groupName
	-- params[3]: speed
	-- params[3]: hdg
	-- params[3]: distance
	-- params[3]: alt
	params = {
		[1]=nil,
		[2]=nil,
		[3]=320,   -- in knots
		[4]=270,   -- in degrees 0-359
		[5]=20,    -- in Nm
		[6]=20000, -- in feet
	}
	for v in string.gmatch(event.text, '([^,\(\)]+)') do
		params[#params+1] = v
	end
	
	local command=params[1]
	local groupName=params[2]
	local speed=params[3]
	local hdg=params[4]
	local distance=params[5]
	local alt=params[6]
	
	-- not really a TANKER command ?
	if command ~= "TANKER" then
		-- just exit, skipping this event
		return
	end

	marker.tankerAction(groupName,event.pos.z, event.pos.x, speed, hdg, distance, alt)

end

------------------------------------------------------------------------------
-- markerDebugEvent
-- @param Event event : the marker event
-- display debug informations about this marker event
------------------------------------------------------------------------------
function marker.debugEvent(event)
	vec3={x=event.pos.z, y=event.pos.y, z=event.pos.x}

	mgrs = coord.LLtoMGRS(coord.LOtoLL(vec3))
	mgrsString = mist.tostringMGRS(mgrs, 3)   

	lat, lon = coord.LOtoLL(vec3)
	llString = mist.tostringLL(lat, lon, 2)

	-- display debug information
	msg='Marker changed: \'' .. event.text ..'\' on this position \n' 
		.. 'LL: '.. llString .. '\n'
		.. 'UTM: '.. mgrsString
	trigger.action.outText(msg, 10)
end

------------------------------------------------------------------------------
-- markerDetectMarkers
-- the entry point for marker events
------------------------------------------------------------------------------
function marker.detectMarkers(event)

	-- if a marker has changed
	if event.id == world.event.S_EVENT_MARK_CHANGE then 
   
		-- display debug information
		if marker.debug then
			marker.debugEvent(event)
		end

		-- handle MOVE command (need to be improved)
		if event.text~=nil and event.text:find('MOVE') then
			marker.moveCommandEventHandler(event)			
		end 

		-- handle TANKER command (need to be improved)
		if event.text~=nil and event.text:find('TANKER') then
			marker.tankerCommandEventHandler(event)			
		end 
		
	end 
end 

-- in case of testing, remove first previous handlers
mist.removeEventHandler(markerDetectMarkersEventHandler)

-- init markers event handlers
markerDetectMarkersEventHandler=mist.addEventHandler(marker.detectMarkers) 

