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
-- markerMoveCommandEventHandler
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
   end 
end 


-- in case of testing, remove first previous handlers
mist.removeEventHandler(markerDetectMarkersEventHandler)

-- init markers event handlers
markerDetectMarkersEventHandler=mist.addEventHandler(marker.detectMarkers) 

