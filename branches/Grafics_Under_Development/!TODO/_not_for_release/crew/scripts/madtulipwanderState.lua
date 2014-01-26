wanderState = {
  moveToTargetMinDistance = 3,
  moveToTargetMinX = 1
}

function wanderState.enter()
  return {
    timer = entity.randomizeParameterRange("wander.timeRange"),
    direction = util.toDirection(math.random(100) - 50)
  }
end

function wanderState.update(dt, stateData)
  stateData.timer = stateData.timer - dt
  if stateData.timer < 0 then
    return true, entity.configParameter("wander.cooldown", nil)
  end

  if stateData.changeDirectionTimer ~= nil then
    stateData.changeDirectionTimer = stateData.changeDirectionTimer - dt
    if stateData.changeDirectionTimer < 0 then
      stateData.changeDirectionTimer = nil
    end
  end

  local position = entity.position()
  local inside = wanderState.isAtHome(position)

  if stateData.targetPosition ~= nil then
    local toTarget = world.distance(stateData.targetPosition, position)
    if world.magnitude(toTarget) < wanderState.moveToTargetMinDistance and
       math.abs(toTarget[1]) < wanderState.moveToTargetMinX then
      stateData.targetPosition = nil
    else
      moveTo(stateData.targetPosition, dt)
      return false
    end
  end

  -- Optionally, try not to get too far from spawn point
  local maxDistanceFromSpawnPoint = entity.configParameter("wander.maxDistanceFromSpawnPoint", nil)
  if maxDistanceFromSpawnPoint ~= nil and world.magnitude(position, storage.spawnPosition) > maxDistanceFromSpawnPoint then
    stateData.targetPosition = storage.spawnPosition
    return false
  end

  -- select where to go now
  local shouldBeAtHome = isTimeFor("wander.indoorTimeOfDayRanges")
  local shouldBeAtWork = isTimeFor("wander.AtWorkTimeOfDayRanges")
  
	if (shouldBeAtWork) then
		-- if its time to work we go there
		wanderState.try_to_go_to_work();
	elseif (shouldBeAtHome) then
		wanderState.try_to_go_home();
	else
		-- default case - wander around
		wanderState.try_to_wander_arround();
	end

  -- Chat with other npcs in the way
  if chatState ~= nil then
    local chatDistance = entity.configParameter("wander.chatDistance", nil)
    if chatDistance ~= nil then
      if chatState.initiateChat(position, vec2.add({ chatDistance * stateData.direction, 0 }, position)) then
        return true
      end
    end
  end

  -- Turn around if blocked by something over hip height
  local region = {
    math.floor(position[1] + 0.5) - 1 + stateData.direction, math.floor(position[2] + 0.5),
    math.floor(position[1] + 0.5) + 1 + stateData.direction, math.floor(position[2] + 0.5) + 1,
  }
  if world.rectCollision(region, true) then
    wanderState.changeDirection(stateData)
  end

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

  local moved, reason = move({ stateData.direction, 0 }, dt, {
    openDoorCallback = function(doorId)
      -- Don't open doors to the outside if we're staying inside
      return not inside or not shouldBeInside or not wanderState.isDoorToOutside(doorId)
    end
  })
  if not moved then
    if reason == "ledge" then
      -- Stop and admire the view for a bit
      return true
    else
      wanderState.changeDirection(stateData)
    end
  end

  return false
end

function wanderState.try_to_go_to_work(shouldBeAtWork)
	local position = entity.position()
	local AtWork = isAtWork(position)

	if AtWork then
		-- Stay at Work
		local lookaheadPosition = vec2.add({ stateData.direction * entity.configParameter("wander.indoorLookaheadDistance"), 0 }, position)
		if not isAtWork(lookaheadPosition) then
			wanderState.changeDirection(stateData)

			-- Close any doors to the outside
			local doorIds = world.objectLineQuery(position, lookaheadPosition, { callScript = "hasCapability", callScriptArgs = { "door" } })
			for _, doorId in pairs(doorIds) do
				world.callScriptedEntity(doorId, "closeDoor")
			end
		end
	else
		  -- Go to Work
		  stateData.targetPosition = wanderState.findAtWorkPosition(position)
		  if stateData.targetPosition ~= nil then
				return false
		  else
				stateData.timer = entity.configParameter("wander.moveToTargetTime", stateData.timer)
		  end
	end
end

function wanderState.isAtWork()
end

function wanderState.findAtWorkPosition()
end

function wanderState.try_to_go_home()
  local position = entity.position()
  local at_home = wanderState.isAtHome(position)
  
	if at_home then
		-- Stay at home
		local lookaheadPosition = vec2.add({ stateData.direction * entity.configParameter("wander.indoorLookaheadDistance"), 0 }, position)
		if not wanderState.isAtHome(lookaheadPosition) then
			wanderState.changeDirection(stateData)

			-- Close any doors to the outside
			local doorIds = world.objectLineQuery(position, lookaheadPosition, { callScript = "hasCapability", callScriptArgs = { "door" } })
			for _, doorId in pairs(doorIds) do
				world.callScriptedEntity(doorId, "closeDoor")
			end
		end
	else
		  -- Go home
		  stateData.targetPosition = wanderState.findInsidePosition(position)
		  if stateData.targetPosition ~= nil then
				return false
		  else
				stateData.timer = entity.configParameter("wander.moveToTargetTime", stateData.timer)
		  end
	end

end

function wanderState.isAtHome()
end

function wanderState.try_to_wander_arround()
	local position = entity.position()
	local inside = wanderState.isAtHome(position)
  
	if inside then
		  -- Go outside
		  stateData.targetPosition = wanderState.findOutsidePosition(position, maxDistanceFromSpawnPoint)
		  if stateData.targetPosition ~= nil then
				return false
		  else
				stateData.timer = entity.configParameter("wander.moveToTargetTime", stateData.timer)
		  end
	else
			-- Stay outside
		  local lookaheadPosition = vec2.add({ stateData.direction * entity.configParameter("wander.indoorLookaheadDistance"), 0 }, position)
		  if wanderState.isAtHome(lookaheadPosition) then
				wanderState.changeDirection(stateData)
		  end
	end
end

function wanderState.findInsidePosition(position)
  local basePosition = position

  -- Prefer the original spawn position (i.e. the npc's home)
  if wanderState.isAtHome(storage.spawnPosition) then
    basePosition = storage.spawnPosition
  end

  local doorIds = world.objectQuery(basePosition, entity.configParameter("wander.indoorSearchRadius"), { callScript = "hasCapability", callScriptArgs = { "door" }, order = "nearest" })
  for _, doorId in pairs(doorIds) do
    local doorPosition = world.entityPosition(doorId)

    local rightSide = vec2.add({ 3, 1.5 }, doorPosition)
    if wanderState.isAtHome(rightSide) then return rightSide end

    local leftSide = vec2.add({ -3, 1.5 }, doorPosition)
    if wanderState.isAtHome(leftSide) then return leftSide end
  end

  return nil
end

function wanderState.isDoorToOutside(doorId)
  local doorPosition = world.entityPosition(doorId)
  local rightSide = vec2.add({ 3, 1.5 }, doorPosition)
  local leftSide = vec2.add({ -3, 1.5 }, doorPosition)
  return wanderState.isAtHome(rightSide) ~= wanderState.isAtHome(leftSide)
end

function wanderState.findOutsidePosition(position, maxDistanceFromSpawnPoint)
  local entityIds = world.objectQuery(position, entity.configParameter("wander.indoorSearchRadius"), { callScript = "hasCapability", callScriptArgs = { "door" }, order = "nearest" })
  for _, entityId in pairs(entityIds) do
    local doorPosition = world.entityPosition(entityId)

    local rightSide = vec2.add({ 3, 1.5 }, doorPosition)
    if not wanderState.isAtHome(rightSide) and (maxDistanceFromSpawnPoint == nil or world.magnitude(position, rightSide) < maxDistanceFromSpawnPoint) then
      return rightSide
    end

    local leftSide = vec2.add({ -3, 1.5 }, doorPosition)
    if not wanderState.isAtHome(leftSide) and (maxDistanceFromSpawnPoint == nil or world.magnitude(position, leftSide) < maxDistanceFromSpawnPoint) then
      return leftSide
    end
  end

  return nil
end

function wanderState.changeDirection(stateData)
  if stateData.changeDirectionTimer == nil then
    stateData.direction = -stateData.direction
    stateData.changeDirectionTimer = entity.configParameter("wander.changeDirectionCooldown", nil)
    return true
  else
    return false
  end
end