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

  -- update change direction timer
  if stateData.changeDirectionTimer ~= nil then
    stateData.changeDirectionTimer = stateData.changeDirectionTimer - dt
    if stateData.changeDirectionTimer < 0 then
      stateData.changeDirectionTimer = nil
    end
  end
  
  -- move to current target
  local position = entity.position()
  if stateData.targetPosition ~= nil then
    local toTarget = world.distance(stateData.targetPosition, position)
    if world.magnitude(toTarget) < madtulipwanderState.moveToTargetMinDistance and
       math.abs(toTarget[1]) < madtulipwanderState.moveToTargetMinX then
      stateData.targetPosition = nil -- target reached
    else
      moveTo(stateData.targetPosition, dt) -- move towards target
      return false
    end
  end

--[[
TODO - rework
  -- Optionally, try not to get too far from spawn point
  local maxDistanceFromSpawnPoint = entity.configParameter("wander.maxDistanceFromSpawnPoint", nil)
  if maxDistanceFromSpawnPoint ~= nil and world.magnitude(position, storage.spawnPosition) > maxDistanceFromSpawnPoint then
    stateData.targetPosition = storage.spawnPosition
    return false
  end
]]

    -- select where to go now
	-- debug random
	
	stateData.targetPosition = madtulipwanderState.find_barracks_target();
	
	if stateData.targetPosition ~= nil then
		return false -- no target found
	else
		-- target found. start movement timer
		stateData.timer = entity.configParameter("wander.moveToTargetTime", stateData.timer) 
	end
--[[
	local target_type = math.random(3)
	if target_type == 1 then
		--entity.say("find_work_target()")
		world.logInfo("find_work_target()")
		madtulipwanderState.find_work_target();
	elseif target_type == 2 then
		--entity.say("find_barracks_target()")
		world.logInfo("find_barracks_target()")
		madtulipwanderState.find_barracks_target();
	else
		--entity.say("try_to_wander_arround()")
		world.logInfo("try_to_wander_arround()")
		madtulipwanderState.try_to_wander_arround();
	end
]]
--[[
	-- based on daytime
	local shouldBeAtHome = isTimeFor("wander.indoorTimeOfDayRanges")
	local shouldBeAtWork = isTimeFor("wander.AtWorkTimeOfDayRanges")
  
	if (shouldBeAtWork) then
		-- if its time to work we go there
		madtulipwanderState.find_work_target();
	elseif (shouldBeAtHome) then
		madtulipwanderState.find_barracks_target();
	else
		-- default case - wander around
		madtulipwanderState.try_to_wander_arround();
	end
]]
--[[
  -- Chat with other npcs in the way
  if chatState ~= nil then
    local chatDistance = entity.configParameter("wander.chatDistance", nil)
    if chatDistance ~= nil then
      if chatState.initiateChat(position, vec2.add({ chatDistance * stateData.direction, 0 }, position)) then
        return true
      end
    end
  end
]]
  -- Turn around if blocked by something over hip height
--[[
  local region = {
    math.floor(position[1] + 0.5) - 1 + stateData.direction, math.floor(position[2] + 0.5),
    math.floor(position[1] + 0.5) + 1 + stateData.direction, math.floor(position[2] + 0.5) + 1,
  }
  if world.rectCollision(region, true) then
    madtulipwanderState.changeDirection(stateData)
  end
]]
--[[
  -- Generally we don't want to spend a lot of time wandering up stairs, getting
  -- higher and higher in a building, so let's fall through platforms once in
  -- a while
  if math.random(100) < entity.configParameter("wander.dropDownChance", 100) then
    local groundSupportRegion = {
      region[1], region[2] - 4,
      region[3], region[2] - 3
    }
    if entity.onGround() and not world.rectCollision(groundSupportRegion, true) then
      entity.moveDown()
    end
  end
]]

--[[
  local moved, reason = move({ stateData.direction, 0 }, dt, {
    openDoorCallback = function(doorId)
      -- Don't open doors to the outside if we're staying inside
-- TODO: rework this part
      return not madtulipwanderState.isAtBarracks(position) or not shouldBeInside or not madtulipwanderState.isDoorToOutside(doorId)
    end
  })
  if not moved then
    if reason == "ledge" then
      -- Stop and admire the view for a bit
      return true
    else
      madtulipwanderState.changeDirection(stateData)
    end
  end
]]
  return false
end

function madtulipwanderState.find_barracks_target()
	local position = entity.position()
  
  world.logInfo("1")
	if madtulipwanderState.isAtBarracks(position) then
		-- Stay at barracks
		world.logInfo("Stay at barracks")
		local lookaheadPosition = vec2.add({ stateData.direction * entity.configParameter("wander.indoorLookaheadDistance"), 0 }, position)
		if not madtulipwanderState.isAtBarracks(lookaheadPosition) then
			-- no barracks ahead of me
			madtulipwanderState.changeDirection(stateData)

			-- get doors infront of me
			local doorIds = world.objectLineQuery(position, lookaheadPosition, { callScript = "hasCapability", callScriptArgs = { "door" } })
			-- close them all
			for _, doorId in pairs(doorIds) do
				world.callScriptedEntity(doorId, "closeDoor")
			end
		end
	else
		-- Go to barracks
		world.logInfo("Go to barracks")
		return madtulipwanderState.findBarracksPosition(position)
	end
end

function madtulipwanderState.find_work_target()
	local position = entity.position()

	if madtulipwanderState.isAtWork(position) then
		-- Stay at Work
		-- look ahead if thats also at work
		local lookaheadPosition = vec2.add({ stateData.direction * entity.configParameter("wander.indoorLookaheadDistance"), 0 }, position)
		if not madtulipwanderState.isAtWork(lookaheadPosition) then
			-- look ahead is not at work
			madtulipwanderState.changeDirection(stateData)

			-- close any doors in that direction
			local doorIds = world.objectLineQuery(position, lookaheadPosition, { callScript = "hasCapability", callScriptArgs = { "door" } })
			for _, doorId in pairs(doorIds) do
				world.callScriptedEntity(doorId, "closeDoor")
			end
		end
	else
		  -- Go to Work
		  stateData.targetPosition = madtulipwanderState.findAtWorkPosition(position)
	end
end

function madtulipwanderState.try_to_wander_arround()
	local position = entity.position()
  
	if madtulipwanderState.isAtBarracks(position) or madtulipwanderState.isAtWork(position) then
		-- Leave Barracks or Work
		return madtulipwanderState.findChilledPosition(position)
	else
		-- Stay outside
		local lookaheadPosition = vec2.add({ stateData.direction * entity.configParameter("wander.indoorLookaheadDistance"), 0 }, position)
		-- don`t go to work
		if madtulipwanderState.isAtBarracks(lookaheadPosition) then
			madtulipwanderState.changeDirection(stateData)
		end
	end
end

function madtulipwanderState.isAtBarracks(position)
-- TODO: make this work based on a list containing object names instead
  local TargetIDs = world.objectQuery(position,
                  entity.configParameter("wander.indoorSearchRadius"),
				  { callScript = "hasCapability",
				  callScriptArgs = { "barracks_atractor" },
				  order = "nearest" })
  local toTarget = {}
  for _, TargetID in pairs(TargetIDs) do
	local toTarget = world.distance( world.entityPosition(TargetID), position)
-- TODO: parameterize distance
	if world.magnitude(toTarget) < 5 then
		return true
	else
		return false
	end
  end
end

function madtulipwanderState.isAtWork(position)
-- TODO: make this work based on a list containing object names instead
  local TargetIDs = world.objectQuery(position,
                  entity.configParameter("wander.indoorSearchRadius"),
				  { callScript = "hasCapability",
				  callScriptArgs = { "work_atractor" },
				  order = "nearest" })
  local toTarget = {}
  for _, TargetID in pairs(TargetIDs) do
	local toTarget = world.distance( world.entityPosition(TargetID), position)
-- TODO: parameterize distance
	if world.magnitude(toTarget) < 5 then
		return true
	else
		return false
	end
  end
end

function madtulipwanderState.findBarracksPosition(position)
  local basePosition = position

  -- Prefer the original spawn position (i.e. the npc's home)
  if madtulipwanderState.isAtBarracks(storage.spawnPosition) then
    basePosition = storage.spawnPosition
  end
-- TODO: make this work based on a list containing object names instead
  local doorIds = world.objectQuery(basePosition,
                  entity.configParameter("wander.indoorSearchRadius"),
				  { callScript = "hasCapability",
				  callScriptArgs = { "barracks_atractor" },
				  order = "nearest" })
  for _, doorId in pairs(doorIds) do
    local doorPosition = world.entityPosition(doorId)
	local rightSide = vec2.add({ 3, 1.5 }, doorPosition)
	return rightSide
--[[
    local rightSide = vec2.add({ 3, 1.5 }, doorPosition)
    if madtulipwanderState.isAtBarracks(rightSide) then return rightSide end

    local leftSide = vec2.add({ -3, 1.5 }, doorPosition)
    if madtulipwanderState.isAtBarracks(leftSide) then return leftSide end
]]
  end

  return nil
end

function madtulipwanderState.findAtWorkPosition()
-- TODO: make this work based on a list containing object names instead
  local entityIds = world.objectQuery(position,
                    entity.configParameter("wander.indoorSearchRadius"),
					{ callScript = "hasCapability",
					callScriptArgs = { "work_atractor" },
					order = "nearest" })
  for _, entityId in pairs(entityIds) do
    local doorPosition = world.entityPosition(entityId)
	local rightSide = vec2.add({ 3, 1.5 }, doorPosition)
	return rightSide
--[[
    local rightSide = vec2.add({ 3, 1.5 }, doorPosition)
    if not madtulipwanderState.isAtBarracks(rightSide) and (maxDistanceFromSpawnPoint == nil or world.magnitude(position, rightSide) < maxDistanceFromSpawnPoint) then
      return rightSide
    end

    local leftSide = vec2.add({ -3, 1.5 }, doorPosition)
    if not madtulipwanderState.isAtBarracks(leftSide) and (maxDistanceFromSpawnPoint == nil or world.magnitude(position, leftSide) < maxDistanceFromSpawnPoint) then
	return leftSide	
    end
]]
  end

  return nil
end

function madtulipwanderState.findChilledPosition(position)
  local entityIds = world.objectQuery(position,
                    entity.configParameter("wander.indoorSearchRadius"),
					{ callScript = "hasCapability",
					callScriptArgs = { "door" },
					order = "nearest" })
  for _, entityId in pairs(entityIds) do
    local doorPosition = world.entityPosition(entityId)
	local rightSide = vec2.add({ 3, 1.5 }, doorPosition)
	return rightSide
--[[
    local rightSide = vec2.add({ 3, 1.5 }, doorPosition)
    if not madtulipwanderState.isAtBarracks(rightSide) and (maxDistanceFromSpawnPoint == nil or world.magnitude(position, rightSide) < maxDistanceFromSpawnPoint) then
      return rightSide
    end

    local leftSide = vec2.add({ -3, 1.5 }, doorPosition)
    if not madtulipwanderState.isAtBarracks(leftSide) and (maxDistanceFromSpawnPoint == nil or world.magnitude(position, leftSide) < maxDistanceFromSpawnPoint) then
      return leftSide
    end
]]
  end

  return nil
end

function madtulipwanderState.isDoorToOutside(doorId)
  local doorPosition = world.entityPosition(doorId)
  local rightSide = vec2.add({ 3, 1.5 }, doorPosition)
  local leftSide = vec2.add({ -3, 1.5 }, doorPosition)
  return madtulipwanderState.isAtBarracks(rightSide) ~= madtulipwanderState.isAtBarracks(leftSide)
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