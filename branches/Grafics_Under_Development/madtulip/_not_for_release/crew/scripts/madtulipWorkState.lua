madtulipWorkState = {}

function madtulipWorkState.enter()
	-- declare variables
	madtulipWorkState.ROI = {}
	madtulipWorkState.ROI.anchor_pos = nil -- {x,y} of ROI anchor
	madtulipWorkState.ROI.BB = nil -- {x1,y1,x2,y2} boundary box around anchor of ROI
	madtulipWorkState.ROI.pathable_positions = nil -- table of {x,y} block coordinates we could walk to inside this ROI
	madtulipWorkState.ROI.pathable_positions_size = nil -- size of above table
	
	madtulipWorkState.Movement = {}
	madtulipWorkState.Movement.Target = nil -- current movement target block
	madtulipWorkState.Movement.Switch_Target_Inside_ROI_Timer = nil -- time to pass between targets inside the same ROI
	
	-- constants
	madtulipWorkState.Movement.Min_XY_Dist_required_to_reach_target = 3 -- radius
	madtulipWorkState.Movement.Min_X_Dist_required_to_reach_target  = 1 -- X Axis only
	
  return {
    timer = entity.randomizeParameterRange("wander.timeRange"),
    direction = util.toDirection(math.random(100) - 50)
  }
end

function madtulipWorkState.update(dt, stateData)
	-- return if wander is on cooldown
	stateData.timer = stateData.timer - dt
	if stateData.timer < 0 then
		return true, entity.configParameter("wander.cooldown", nil)
	end

	madtulipWorkState.update_timers(stateData,dt)
	
	if (madtulipWorkState.ROI.anchor_pos == nil) then
		-- no region of interest to walk to determined -> get one
		madtulipWorkState.find_ROI_around(entity.position())
	else
		-- we have a ROI
		if madtulipWorkState.Movement.Target == nil then
			-- we have no target inside the ROI to move to
			if not madtulipWorkState.Movement.Switch_Target_Inside_ROI_Timer then
				--> get next target inside current ROI (short movement)
				madtulipWorkState.set_next_target_inside_ROI()
				madtulipWorkState.Movement.Switch_Target_Inside_ROI_Timer = entity.randomizeParameterRange("wander.Move_Inside_ROI_Time")
			end
		else
			-- move
			local toTarget = world.distance(madtulipWorkState.Movement.Target, entity.position())
			if world.magnitude(toTarget) < madtulipWorkState.Movement.Min_XY_Dist_required_to_reach_target and
			   math.abs(toTarget[1]) < madtulipWorkState.Movement.Min_X_Dist_required_to_reach_target then
					-- target reached -> clear movement target
					madtulipWorkState.Movement.Target = nil
			else
				-- still moving
				moveTo(madtulipWorkState.Movement.Target, dt)
				return false
			end
		end
	end

	-- default return : we are not done
	return false
end

function madtulipWorkState.find_ROI_around(position)
	-- find all close by job attractors
	local AttractorID_Data = madtulipWorkState.Work_AttratorQuerry(position,entity.configParameter("wander.Work_Attractor_Search_Radius", nil),Data.Occupation)
	--world.logInfo("AttractorID_Data.size=" .. tostring(AttractorID_Data.size))
	if (AttractorID_Data.size == 0) then return false end
	
	-- use the position of a random one of them as new ROI anchor
	local tmp_ROI_anchor = world.entityPosition(AttractorID_Data.AttractorIDs[math.random (AttractorID_Data.size)])
	if (tmp_ROI_anchor == nil) then return false end
	
	-- shift the anchor down to walkable floor in case the attractor objects anchor is above floor
	local max_distance = 10; -- maximum depth under anchor to search for walkable floor
	tmp_ROI_anchor = madtulipWorkState.Find_Block_above_floor(tmp_ROI_anchor,max_distance)
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
	--tmp_BB = madtulipWorkState.World_Wrap_Correct_BB(tmp_BB)
	
	-- check all positions in the BB for locations that we could walk to without colliding while just standing there
	local Standable_Positions_Data = madtulipWorkState.Find_Standable_Positions_in_BB(tmp_BB)
	if (Standable_Positions_Data.size < 1) then return false end
	--world.logInfo("Pathable positions found")	

	-- now the player doesnt want to target the floor where he can stand, but an offset in hip hight instead,
	-- so we shift them all up by the correct ammount
	local Pathable_Positions = {}
	local Pathable_Positions_size = Standable_Positions_Data.size -- just rename it
	for idx_cur_Standable_Position = 1,Standable_Positions_Data.size,1 do
		Pathable_Positions[idx_cur_Standable_Position] = madtulipWorkState.Shift_Standable_to_Pathable_Position(Standable_Positions_Data.Standable_Positions[idx_cur_Standable_Position])
	end
	
	-- We found possible targets -> set state global region of interest
	--world.logInfo("ROI found")
	madtulipWorkState.ROI.anchor_pos = tmp_ROI_anchor
	madtulipWorkState.ROI.BB = tmp_BB
	madtulipWorkState.ROI.pathable_positions = Pathable_Positions
	madtulipWorkState.ROI.pathable_positions_size = Pathable_Positions_size
	
	-- pick one of the possible targets as the current one to move towards
	madtulipWorkState.set_next_target_inside_ROI()
	
	return true
end

function madtulipWorkState.set_next_target_inside_ROI()
	madtulipWorkState.Movement.Target = madtulipWorkState.ROI.pathable_positions[math.random (madtulipWorkState.ROI.pathable_positions_size)]
end

function madtulipWorkState.Shift_Standable_to_Pathable_Position(position)
	-- just add the offset over gound that an NPC needs to target in order to walk there instead of crawling or jumping
	return vec2.add(position,{0,2})
end

function madtulipWorkState.Find_Standable_Positions_in_BB(BB)
	-- a player can stand at a location with this box around him beeing free of foreground blocks
	-- we want to check every position in BB against this box

	-- find all those positions in the BB which have a floor under them and are without foreground block themselves
	local size = 0
	local Positions_with_Floor_under_them = {}
	for X = BB[1], BB[3], 1 do
		for Y = BB[2], BB[4], 1 do
			--world.logInfo("X:" .. X .. "Y:" .. Y)
			if (madtulipWorkState.Find_Block_above_floor({X,Y},0) ~= nil) then
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

function madtulipWorkState.Find_Block_above_floor(position,max_distance)
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

function madtulipWorkState.Work_AttratorQuerry(Position,Radius,Occupation)
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

--[[
function madtulipWorkState.start_chats_on_the_way ()
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
]]

function madtulipWorkState.update_timers(stateData,dt)
	-- update Switch_Target_Inside_ROI_Timer timer
	if madtulipWorkState.Movement.Switch_Target_Inside_ROI_Timer ~= nil then
		madtulipWorkState.Movement.Switch_Target_Inside_ROI_Timer = madtulipWorkState.Movement.Switch_Target_Inside_ROI_Timer - dt
		if madtulipWorkState.Movement.Switch_Target_Inside_ROI_Timer < 0 then
			madtulipWorkState.Movement.Switch_Target_Inside_ROI_Timer = nil
		end
	end
end