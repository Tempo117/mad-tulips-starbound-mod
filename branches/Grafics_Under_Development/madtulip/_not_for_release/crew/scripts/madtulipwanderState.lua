madtulipwanderState = {}

function madtulipwanderState.enter()
	-- declare variables
	madtulipwanderState.ROI = {}
	madtulipwanderState.ROI.anchor_pos = nil -- {x,y} of ROI anchor
	madtulipwanderState.ROI.BB = nil -- {x1,y1,x2,y2} boundary box around anchor of ROI
	madtulipwanderState.ROI.pathable_positions = nil -- table of {x,y} block coordinates we could walk to inside this ROI
	madtulipwanderState.ROI.pathable_positions_size = nil -- size of above table
	
	madtulipwanderState.Movement = {}
	madtulipwanderState.Movement.Target = nil -- current movement target block
	madtulipwanderState.Movement.Switch_Target_Inside_ROI_Timer = nil -- time to pass between targets inside the same ROI
	
	-- constants
	madtulipwanderState.Movement.Min_XY_Dist_required_to_reach_target = 3 -- radius
	madtulipwanderState.Movement.Min_X_Dist_required_to_reach_target  = 1 -- X Axis only
	
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
	
	if (madtulipwanderState.ROI.anchor_pos == nil) then
		-- no region of interest to walk to determined -> get one
		madtulipwanderState.find_ROI_around(entity.position())
	else
		-- we have a ROI
		if madtulipwanderState.Movement.Target == nil then
			-- we have no target inside the ROI to move to
			if not madtulipwanderState.Movement.Switch_Target_Inside_ROI_Timer then
				--> get next target inside current ROI (short movement)
				madtulipwanderState.set_next_target_inside_ROI()
				madtulipwanderState.Movement.Switch_Target_Inside_ROI_Timer = entity.randomizeParameterRange("wander.Move_Inside_ROI_Time")
			end
		else
			-- move
			local toTarget = world.distance(madtulipwanderState.Movement.Target, entity.position())
			if world.magnitude(toTarget) < madtulipwanderState.Movement.Min_XY_Dist_required_to_reach_target and
			   math.abs(toTarget[1]) < madtulipwanderState.Movement.Min_X_Dist_required_to_reach_target then
					-- target reached -> clear movement target
					madtulipwanderState.Movement.Target = nil
			else
				-- still moving
				moveTo(madtulipwanderState.Movement.Target, dt)
				return false
			end
		end
	end
	
--[[
	-- Try not to get too far from spawn point
	-- Disabled if maxDistanceFromSpawnPoint is not defined
	local maxDistanceFromSpawnPoint = entity.configParameter("wander.maxDistanceFromSpawnPoint", nil)
	if maxDistanceFromSpawnPoint ~= nil and world.magnitude(entity.position(), storage.spawnPosition) > maxDistanceFromSpawnPoint then
		stateData.targetPosition = storage.spawnPosition
		return false
	end
]]
	-- find a new stateData.targetPosition to walk to
	local is_wandering_around = false
	local is_going_to_barracks = false
	local is_going_to_work = false

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

function madtulipwanderState.find_ROI_around(position)
	-- find all close by job attractors
	local AttractorID_Data = madtulipwanderState.Work_AttratorQuerry(position,entity.configParameter("wander.Work_Attractor_Search_Radius", nil),Data.Occupation)
	--world.logInfo("AttractorID_Data.size=" .. tostring(AttractorID_Data.size))
	if (AttractorID_Data.size == 0) then return false end
	
	-- use the position of a random one of them as new ROI anchor
	local tmp_ROI_anchor = world.entityPosition(AttractorID_Data.AttractorIDs[math.random (AttractorID_Data.size)])
	if (tmp_ROI_anchor == nil) then return false end
	
	-- shift the anchor down to walkable floor in case the attractor objects anchor is above floor
	local max_distance = 10; -- maximum depth under anchor to search for walkable floor
	tmp_ROI_anchor = madtulipwanderState.Find_Block_above_floor(tmp_ROI_anchor,max_distance)
	-- check if floor could be found, else return
	if (tmp_ROI_anchor == nil) then return false end
	--world.logInfo("ROI anchor found")

	-- define boundary box around the anchor
	local BB_X_size = entity.configParameter("wander.Work_ROI_BB_X_size",nil)
	local tmp_BB = {}
	tmp_BB[1] = tmp_ROI_anchor[1] + BB_X_size[1]
	tmp_BB[2] = tmp_ROI_anchor[2] + 0
	tmp_BB[3] = tmp_ROI_anchor[1] + BB_X_size[2]
	tmp_BB[4] = tmp_ROI_anchor[2] + 3 -- 4 is hight of a player
	
	-- assure the [1],[2] location is bottom left
	--tmp_BB = madtulipwanderState.World_Wrap_Correct_BB(tmp_BB)
	
	-- check all positions in the BB for locations that we could walk to without colliding while just standing there
	local Standable_Positions_Data = madtulipwanderState.Find_Standable_Positions_in_BB(tmp_BB)
	if (Standable_Positions_Data.size < 1) then return false end
	--world.logInfo("Pathable positions found")	

	-- now the player doesnt want to target the floor where he can stand, but an offset in hip hight instead,
	-- so we shift them all up by the correct ammount
	local Pathable_Positions = {}
	local Pathable_Positions_size = Standable_Positions_Data.size -- just rename it
	for idx_cur_Standable_Position = 1,Standable_Positions_Data.size,1 do
		Pathable_Positions[idx_cur_Standable_Position] = madtulipwanderState.Shift_Standable_to_Pathable_Position(Standable_Positions_Data.Standable_Positions[idx_cur_Standable_Position])
	end
	
	-- We found possible targets -> set state global region of interest
	--world.logInfo("ROI found")
	madtulipwanderState.ROI.anchor_pos = tmp_ROI_anchor
	madtulipwanderState.ROI.BB = tmp_BB
	madtulipwanderState.ROI.pathable_positions = Pathable_Positions
	madtulipwanderState.ROI.pathable_positions_size = Pathable_Positions_size
	
	-- pick one of the possible targets as the current one to move towards
	madtulipwanderState.set_next_target_inside_ROI()
	
	return true
end

function madtulipwanderState.set_next_target_inside_ROI()
	madtulipwanderState.Movement.Target = madtulipwanderState.ROI.pathable_positions[math.random (madtulipwanderState.ROI.pathable_positions_size)]
end

function madtulipwanderState.Shift_Standable_to_Pathable_Position(position)
	-- just add the offset over gound that an NPC needs to target in order to walk there instead of crawling or jumping
	return vec2.add(position,{0,2})
end

function madtulipwanderState.Find_Standable_Positions_in_BB(BB)
	-- a player can stand at a location with this box around him beeing free of foreground blocks
	-- we want to check every position in BB against this box

	-- find all those positions in the BB which have a floor under them and are without foreground block themselves
	local size = 0
	local Positions_with_Floor_under_them = {}
	for X = BB[1], BB[3], 1 do
		for Y = BB[2], BB[4], 1 do
			--world.logInfo("X:" .. X .. "Y:" .. Y)
			if (madtulipwanderState.Find_Block_above_floor({X,Y},0) ~= nil) then
				size = size +1
				Positions_with_Floor_under_them[size] = {X,Y}
				--world.logInfo("cur_position above floor X:" .. Positions_with_Floor_under_them[size][1] .. "Y:" .. Positions_with_Floor_under_them[size][2])
			end
		end
	end
	--world.logInfo("NR_Positions_with_Floor_under_them = " .. size)	
	
	local BB_in_which_a_player_fits = {}
	BB_in_which_a_player_fits[1] = -1
	BB_in_which_a_player_fits[2] = 0
	BB_in_which_a_player_fits[3] = 1
	BB_in_which_a_player_fits[4] = 4	
	
	-- under those positions where you could stand because it has a floor,
	-- we want to check for open space above the floor now.
	local Standable_Positions = {}
	local Standable_Positions_size = 0
	local cur_position = {};
	for idx_cur_pos = 1, size, 1 do
	--world.logInfo("----")	
		cur_position[1] = Positions_with_Floor_under_them[idx_cur_pos][1]
		cur_position[2] = Positions_with_Floor_under_them[idx_cur_pos][2]
		--world.logInfo("cur_position:" .. cur_position[1] .. "," .. cur_position[2])
		local cur_position_is_standable = true
		for X = BB_in_which_a_player_fits[1], BB_in_which_a_player_fits[3], 1 do
			for Y = BB_in_which_a_player_fits[2], BB_in_which_a_player_fits[4], 1 do
				--world.logInfo("X:" .. X .. "Y:" .. Y)
				-- check for foreground at this position
				if (world.material(vec2.add(cur_position,{X,Y}),"foreground") ~= nil) then
					--world.logInfo("BLOCKED: " .. world.material(vec2.add(cur_position,{X,Y}),"foreground"))
					cur_position_is_standable = false
				end
			end
		end
		if (cur_position_is_standable) then
			-- add it to the list
			Standable_Positions_size = Standable_Positions_size + 1;
			Standable_Positions[Standable_Positions_size] = Positions_with_Floor_under_them[idx_cur_pos]
			--world.logInfo("Standable_Positions: X:" .. Standable_Positions[Standable_Positions_size][1] .. " Y:" .. Standable_Positions[Standable_Positions_size][2])
		end
	end
	--world.logInfo("Standable_Positions_size = " .. Standable_Positions_size)	
	
	return {
		Standable_Positions = Standable_Positions,
		size = Standable_Positions_size
		}
end

function madtulipwanderState.Find_Block_above_floor(position,max_distance)
	-- starts at position and searches down until something was found or max_distance reached
	-- searched for a file that has foreground under it and no foreground AT its position
	-- (a tile one could stand on)
	-- returns the position above the block to stand on
	
	--world.logInfo("Find_Block_above_floor(position[" .. position[1] .. "," .. position[2] .. "],max_distance[" .. max_distance .. "])")
	local offset = {0,0}
	local below_offset = {0,0}
	local mat_at_offset = nil
	local mat_at_belowoffset = nil
	for cur_y_offset = 0,max_distance,1 do
		offset[2] = -cur_y_offset
		below_offset[2] = offset[2] -1
		-- world.logInfo("cur_y_offset:" .. cur_y_offset .. " offset[" .. offset[1] .. "," .. offset[2] .. "]")
		mat_at_offset      = world.material((vec2.add(position,offset)),"foreground")
		mat_at_belowoffset = world.material((vec2.add(position,below_offset)),"foreground")
		--if (mat_at_offset ~= nil) then      world.logInfo("mat_at_offset" .. mat_at_offset) end
		--if (mat_at_belowoffset ~= nil) then world.logInfo("mat_at_belowoffset" .. mat_at_belowoffset) end
		
		if mat_at_offset == nil and mat_at_belowoffset ~= nil then
			-- we have found a block above floor
			-- return its coordinates
			return vec2.add(position,offset)
		end
	end
	-- no floor could be found
	return nil
end

function madtulipwanderState.Work_AttratorQuerry(Position,Radius,Occupation)
	--world.logInfo("Work_AttratorQuerry(Position[" .. Position[1] .. "," .. Position[2] .. "],Radius[" .. Radius .. "],Occupation[" .. Occupation .. "])")
	local AttractorNames = nil
	local size = 0
	local AttractorIDs = {}
	local ObjectIds = nil
	
	-- get list of interesting object names for this occupation
	if Occupation == "Deckhand" then
		AttractorNames =  entity.configParameter("wander.deckhand_attractors", nil)
	elseif Occupation == "Engineer" then
		AttractorNames =  entity.configParameter("wander.engineer_attractors", nil)
	elseif Occupation == "Marine" then
		AttractorNames =  entity.configParameter("wander.marine_attractors", nil)
	elseif Occupation == "Medic" then
		AttractorNames =  entity.configParameter("wander.medic_attractors", nil)
	elseif Occupation == "Scientist" then
		AttractorNames =  entity.configParameter("wander.scientist_attractors", nil)
	end
	
	-- find instances of those attractors in the vicinity
	--world.logInfo("for AttractorNames")
	for AttractorName_Nr, AttractorName in pairs(AttractorNames) do
		--world.logInfo("Attractor_Nr: " .. tostring(AttractorName_Nr))
		--world.logInfo("AttractorName: " .. AttractorName)
		ObjectIds = world.objectQuery (Position, Radius,{name = AttractorName})
		for ObjectId_Nr, ObjectId in pairs(ObjectIds) do
			--world.logInfo("ObjectId_Nr: " .. tostring(ObjectId_Nr))
			--world.logInfo("ObjectId: " .. tostring(ObjectId))
			size = size + 1;
			AttractorIDs[size] = ObjectId;
		end
	end	
	
	return {
		AttractorIDs = AttractorIDs,
		size = size
	}
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
  return madtulipwanderState.is_At_current_Work(rightSide) ~= madtulipwanderState.is_At_current_Work(leftSide)
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
	
	if madtulipwanderState.Movement.Switch_Target_Inside_ROI_Timer ~= nil then
		madtulipwanderState.Movement.Switch_Target_Inside_ROI_Timer = madtulipwanderState.Movement.Switch_Target_Inside_ROI_Timer - dt
		if madtulipwanderState.Movement.Switch_Target_Inside_ROI_Timer < 0 then
			madtulipwanderState.Movement.Switch_Target_Inside_ROI_Timer = nil
		end
	end
end