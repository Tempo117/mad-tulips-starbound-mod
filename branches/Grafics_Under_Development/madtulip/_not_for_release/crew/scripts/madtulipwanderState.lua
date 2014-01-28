madtulipwanderState = {
  moveToTargetMinDistance = 3,
  moveToTargetMinX = 1
}

function madtulipwanderState.enter()
  return {
    timer = entity.randomizeParameterRange("wander.timeRange"),
    direction = util.toDirection(math.random(100) - 50)
  }
end

function madtulipwanderState.update(dt, stateData)
	-- return if wander is on cooldown
	stateData.timer = stateData.timer - dt
	if stateData.timer < 0 then
		return true, entity.configParameter("wander.cooldown", nil)
	end

	madtulipwanderState.update_timers(stateData,dt)
	
	-- if we have a target, set moveTo
	if stateData.targetPosition ~= nil then
		local toTarget = world.distance(stateData.targetPosition, entity.position())
		if world.magnitude(toTarget) < madtulipwanderState.moveToTargetMinDistance and
			-- target reached
			math.abs(toTarget[1]) < madtulipwanderState.moveToTargetMinX then
			stateData.targetPosition = nil
		else
			-- still moving
			moveTo(stateData.targetPosition, dt)
			return false
		end
	end

	-- Try not to get too far from spawn point
	-- Disabled if maxDistanceFromSpawnPoint is not defined
	local maxDistanceFromSpawnPoint = entity.configParameter("wander.maxDistanceFromSpawnPoint", nil)
	if maxDistanceFromSpawnPoint ~= nil and world.magnitude(entity.position(), storage.spawnPosition) > maxDistanceFromSpawnPoint then
		stateData.targetPosition = storage.spawnPosition
		return false
	end

	-- find a new stateData.targetPosition to walk to
	local is_wandering_around = false
	local is_going_to_barracks = false
	local is_going_to_work = true

	if (is_going_to_work) then
		-- in this mode we try to go to work
		local update_return
		
		update_return = madtulipwanderState.head_for_work_targets(stateData)
		if (update_return ~= nil) then return update_return end
		
		update_return = madtulipwanderState.start_chats_on_the_way()
		if (update_return ~= nil) then return update_return end
		
		madtulipwanderState.turn_if_blocks_over_hip_hight_on_the_way (stateData)
		
		madtulipwanderState.occasionaly_moveDown(stateData)

		-- execute movement		
		local moved, reason = move(
			{ stateData.direction, 0 }, dt,
			{openDoorCallback = function(doorId)
				-- Don't open doors to the outside if we're staying inside
				-- return true -> open doors while moving
				-- return false -> do not open doors while moving
				return not madtulipwanderState.isDoorToOutside_of_Work(doorId);
			end}
			)
		-- react of move results
		if not moved then
			if reason == "ledge" then
				-- Stop and admire the view for a bit
				return true
			else
				madtulipwanderState.changeDirection(stateData)
			end
		end
	end
	
	if (is_wandering_around) then
		-- in this mode we try to go:
		--- indoor while "indoorTimeOfDayRanges"
		--- outdoor else
		-- its the default free wandering.
		local update_return

		update_return = madtulipwanderState.head_for_wandering_targets(stateData)
		if (update_return ~= nil) then return update_return end

		update_return = madtulipwanderState.start_chats_on_the_way()
		if (update_return ~= nil) then return update_return end

		madtulipwanderState.turn_if_blocks_over_hip_hight_on_the_way (stateData)

		madtulipwanderState.occasionaly_moveDown(stateData)

		-- execute movement		
		local moved, reason = move(
			{ stateData.direction, 0 }, dt,
			{openDoorCallback = function(doorId)
				-- Don't open doors to the outside if we're staying inside
				-- return true -> open doors while moving
				-- return false -> do not open doors while moving
				return not isInside(entity.position())
		            or not isTimeFor("wander.indoorTimeOfDayRanges")
					or not madtulipwanderState.isDoorToOutside(doorId);
			end}
			)
			
		-- react on move results
		if not moved then
			if reason == "ledge" then
				-- Stop and admire the view for a bit
				return true
			else
				madtulipwanderState.changeDirection(stateData)
			end
		end
	end
	-- default return : we are not done
	return false
end

function madtulipwanderState.head_for_work_targets (stateData)	
	local position = entity.position()
	local At_Work = madtulipwanderState.is_At_Work(position)
	if At_Work then
		-- Stay At_Work
		local lookaheadPosition = vec2.add({ stateData.direction * entity.configParameter("wander.indoorLookaheadDistance"), 0 }, position)
		if not madtulipwanderState.is_At_Work(lookaheadPosition) then
			madtulipwanderState.changeDirection(stateData)

			-- Close any doors to out of work areas
			local doorIds = world.objectLineQuery(position, lookaheadPosition, { callScript = "hasCapability", callScriptArgs = { "door" } })
			for _, doorId in pairs(doorIds) do
				world.callScriptedEntity(doorId, "closeDoor")
			end
		end
	else
		-- Go to At_Work
		stateData.targetPosition = madtulipwanderState.find_At_Work_Position(position)
		if stateData.targetPosition ~= nil then
			-- stop update function so we can start walking next call
			entity.say ("Am at X:" .. position[1] .. "Y:" .. position[2] .. "Going to work at X:" .. stateData.targetPosition[1] .. ",Y:" .. stateData.targetPosition[2])
			return false
		else
			stateData.timer = entity.configParameter("wander.moveToTargetTime", stateData.timer)
		end
	end

	-- continue update function
	return nil
end

function madtulipwanderState.is_At_Work(position)
	-- get list of interesting objects for this crew members occupation
	local attractors = get_Attrators()
	
	-- find instances of those attractors in the vicinity
	local Nr_Attractors_found = 0
	local All_IDs_of_Attractors_found = {}
	local ObjectIds = {}
	--world.logInfo("for attractors")
	for AttractorName_Nr, AttractorName in pairs(attractors) do
		--world.logInfo("Attractor_Nr: " .. tostring(AttractorName_Nr))
		--world.logInfo("AttractorName: " .. AttractorName)
		ObjectIds = world.objectQuery (position, entity.configParameter("wander.Is_At_Work_Radius", nil),{name = AttractorName})
		for ObjectId_Nr, ObjectId in pairs(ObjectIds) do
			--world.logInfo("ObjectId_Nr: " .. tostring(ObjectId_Nr))
			--world.logInfo("ObjectId: " .. tostring(ObjectId))
			Nr_Attractors_found = Nr_Attractors_found + 1;
			All_IDs_of_Attractors_found[Nr_Attractors_found] = ObjectId;
		end
	end	
	if (Nr_Attractors_found < 1) then
		return false
	else
		return true
	end
end

function madtulipwanderState.find_At_Work_Position(position)
	-- get list of interesting objects for this crew members occupation
	--world.logInfo("get_Attrators()")
	local attractors = get_Attrators()
	
	-- find instances of those attractors in the vicinity
	local Nr_Attractors_found = 0
	local All_IDs_of_Attractors_found = {}
	local ObjectIds = {}
	--world.logInfo("for attractors")
	for AttractorName_Nr, AttractorName in pairs(attractors) do
		--world.logInfo("Attractor_Nr: " .. tostring(AttractorName_Nr))
		--world.logInfo("AttractorName: " .. AttractorName)
		ObjectIds = world.objectQuery (position, entity.configParameter("wander.Work_Attractor_Search_Radius", nil),{name = AttractorName})
		for ObjectId_Nr, ObjectId in pairs(ObjectIds) do
			--world.logInfo("ObjectId_Nr: " .. tostring(ObjectId_Nr))
			--world.logInfo("ObjectId: " .. tostring(ObjectId))
			Nr_Attractors_found = Nr_Attractors_found + 1;
			All_IDs_of_Attractors_found[Nr_Attractors_found] = ObjectId;
		end
	end	
	if (Nr_Attractors_found < 1) then return nil end
	
	-- for now just take the first best one.
	-- TODO: sort or randomize among the available attractors.
	--return vec2.add({ math.random(5)-3 , 2.5 }, world.entityPosition(All_IDs_of_Attractors_found[1]))
	return vec2.add({ 0 , 2.5 }, world.entityPosition(All_IDs_of_Attractors_found[1]))
end

function get_Attrators()
	-- get list of interesting objects for this occupation
	local attractors = {}
	if Data.Occupation == "Deckhand" then
		attractors =  entity.configParameter("wander.deckhand_attractors", nil)
	elseif Data.Occupation == "Engineer" then
		attractors =  entity.configParameter("wander.engineer_attractors", nil)
	elseif Data.Occupation == "Marine" then
		attractors =  entity.configParameter("wander.marine_attractors", nil)
	elseif Data.Occupation == "Medic" then
		attractors =  entity.configParameter("wander.medic_attractors", nil)
	elseif Data.Occupation == "Scientist" then
		attractors =  entity.configParameter("wander.scientist_attractors", nil)
	else
		-- coundt find
		return nil
	end

	return attractors
end

function madtulipwanderState.head_for_wandering_targets (stateData)	
	local position = entity.position()
	local inside = isInside(position)
	local shouldStayInsideAnyRoom = isTimeFor("wander.indoorTimeOfDayRanges")
	if shouldStayInsideAnyRoom then
		if inside then
			-- Stay inside
			local lookaheadPosition = vec2.add({ stateData.direction * entity.configParameter("wander.indoorLookaheadDistance"), 0 }, position)
			if not isInside(lookaheadPosition) then
				madtulipwanderState.changeDirection(stateData)

				-- Close any doors to the outside
				local doorIds = world.objectLineQuery(position, lookaheadPosition, { callScript = "hasCapability", callScriptArgs = { "door" } })
				for _, doorId in pairs(doorIds) do
					world.callScriptedEntity(doorId, "closeDoor")
				end
			end
		else
			-- Go inside
			stateData.targetPosition = madtulipwanderState.findInsidePosition(position)
			if stateData.targetPosition ~= nil then
				-- stop update function
				return false
			else
				stateData.timer = entity.configParameter("wander.moveToTargetTime", stateData.timer)
			end
		end
	else
		if inside then
			-- Go outside
			stateData.targetPosition = madtulipwanderState.findOutsidePosition(position, maxDistanceFromSpawnPoint)
			if stateData.targetPosition ~= nil then
				-- stop update function
				return false
			else
				stateData.timer = entity.configParameter("wander.moveToTargetTime", stateData.timer)
			end
		else
			-- Stay outside
			local lookaheadPosition = vec2.add({ stateData.direction * entity.configParameter("wander.indoorLookaheadDistance"), 0 }, position)
			if isInside(lookaheadPosition) then
				madtulipwanderState.changeDirection(stateData)
			end
		end
	end
	-- continue update function
	return nil
end

function madtulipwanderState.findInsidePosition(position)
  local basePosition = position

  -- Prefer the original spawn position (i.e. the npc's home)
  if isInside(storage.spawnPosition) then
    basePosition = storage.spawnPosition
  end

  local doorIds = world.objectQuery(basePosition, entity.configParameter("wander.indoorSearchRadius"), { callScript = "hasCapability", callScriptArgs = { "door" }, order = "nearest" })
  for _, doorId in pairs(doorIds) do
    local doorPosition = world.entityPosition(doorId)

    local rightSide = vec2.add({ 3, 1.5 }, doorPosition)
    if isInside(rightSide) then return rightSide end

    local leftSide = vec2.add({ -3, 1.5 }, doorPosition)
    if isInside(leftSide) then return leftSide end
  end

  return nil
end

function madtulipwanderState.isDoorToOutside_of_Work(doorId)
  local doorPosition = world.entityPosition(doorId)
  local rightSide = vec2.add({ 3, 1.5 }, doorPosition)
  local leftSide = vec2.add({ -3, 1.5 }, doorPosition)
  return madtulipwanderState.is_At_Work(rightSide) ~= madtulipwanderState.is_At_Work(leftSide)
end

function madtulipwanderState.isDoorToOutside(doorId)
  local doorPosition = world.entityPosition(doorId)
  local rightSide = vec2.add({ 3, 1.5 }, doorPosition)
  local leftSide = vec2.add({ -3, 1.5 }, doorPosition)
  return isInside(rightSide) ~= isInside(leftSide)
end

function madtulipwanderState.findOutsidePosition(position, maxDistanceFromSpawnPoint)
  local entityIds = world.objectQuery(position, entity.configParameter("wander.indoorSearchRadius"), { callScript = "hasCapability", callScriptArgs = { "door" }, order = "nearest" })
  for _, entityId in pairs(entityIds) do
    local doorPosition = world.entityPosition(entityId)

    local rightSide = vec2.add({ 3, 1.5 }, doorPosition)
    if not isInside(rightSide) and (maxDistanceFromSpawnPoint == nil or world.magnitude(position, rightSide) < maxDistanceFromSpawnPoint) then
      return rightSide
    end

    local leftSide = vec2.add({ -3, 1.5 }, doorPosition)
    if not isInside(leftSide) and (maxDistanceFromSpawnPoint == nil or world.magnitude(position, leftSide) < maxDistanceFromSpawnPoint) then
      return leftSide
    end
  end

  return nil
end

function madtulipwanderState.changeDirection(stateData)

  if stateData.changeDirectionTimer == nil then
    stateData.direction = -stateData.direction
    stateData.changeDirectionTimer = entity.configParameter("wander.changeDirectionCooldown", nil)
    return true
  else
    return false
  end
end

function madtulipwanderState.start_chats_on_the_way ()
	-- Chat with other NPCs in the way
	if chatState ~= nil then
		local chatDistance = entity.configParameter("wander.chatDistance", nil)
		if chatDistance ~= nil then
			if chatState.initiateChat(position, vec2.add({ chatDistance * stateData.direction, 0 }, position)) then
				return true
			end
		end
	end
end

function madtulipwanderState.occasionaly_moveDown(stateData)
	-- Generally we don't want to spend a lot of time wandering up stairs, getting
	-- higher and higher in a building, so let's fall through platforms once in
	-- a while
	local position = entity.position()
	local region = {math.floor(position[1] + 0.5) - 1 + stateData.direction, math.floor(position[2] + 0.5),
					math.floor(position[1] + 0.5) + 1 + stateData.direction, math.floor(position[2] + 0.5) + 1,} -- <- BUG ? comma	
	
	if math.random(100) < entity.configParameter("wander.dropDownChance", 100) then
		local groundSupportRegion = {region[1], region[2] - 4,
									 region[3], region[2] - 3}
		if entity.onGround() and not world.rectCollision(groundSupportRegion, true) then
			entity.moveDown()
		end
	end
end

function madtulipwanderState.turn_if_blocks_over_hip_hight_on_the_way (stateData)
	local position = entity.position()
	-- Turn around if blocked by something over hip height
	local region = {math.floor(position[1] + 0.5) - 1 + stateData.direction, math.floor(position[2] + 0.5),
					math.floor(position[1] + 0.5) + 1 + stateData.direction, math.floor(position[2] + 0.5) + 1,} -- <- BUG ? comma
	if world.rectCollision(region, true) then
		madtulipwanderState.changeDirection(stateData)
	end
end

function madtulipwanderState.update_timers(stateData,dt)
	-- update change direction timer
	if stateData.changeDirectionTimer ~= nil then
		stateData.changeDirectionTimer = stateData.changeDirectionTimer - dt
		if stateData.changeDirectionTimer < 0 then
			stateData.changeDirectionTimer = nil
		end
	end
end