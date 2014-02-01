madtulipROIState = {}

function madtulipROIState.enter()
	if not isTimeFor("madtulipROI.timeOfDayRanges") then
		return nil, entity.configParameter("madtulipROI.cooldown")
	end
	-- randomize the order the states are beeing executed in
	self.state.shuffleStates()
	
	-- declare variables
	madtulipROIState.ROI = madtulipLocation.get_empty_ROI()
	
	madtulipROIState.Movement = {}
	madtulipROIState.Movement.Target = nil -- current movement target block
	madtulipROIState.Movement.Switch_Target_Inside_ROI_Timer = nil -- time to pass between targets inside the same ROI
	madtulipROIState.Movement.Close_doors_behind_you_Timer = nil -- time to pass between targets inside the same ROI
	
	-- constants
	madtulipROIState.Movement.Min_XY_Dist_required_to_reach_target = 3 -- radius
	madtulipROIState.Movement.Min_X_Dist_required_to_reach_target  = 1 -- X Axis only
	
	-- equip work clothing
	Set_Occupation_Cloth()
	
	return {
		timer = entity.randomizeParameterRange("madtulipROI.timeRange"),
		direction = util.toDirection(math.random(100) - 50)
	}
end

function madtulipROIState.update(dt, stateData)
	-- return if wander is on cooldown
	stateData.timer = stateData.timer - dt
	if stateData.timer < 0 then
		--world.logInfo("COOLDOWN")
		return true, entity.configParameter("madtulipROI.cooldown", nil)
	end

	madtulipROIState.update_timers(stateData,dt)
	
	if (madtulipROIState.ROI.anchor_pos == nil) then
		--world.logInfo("get_Work_ROI_Anchor_Position")
		-- no region of interest to walk to determined -> get an anchor for such a ROI
		local Work_ROI_Anchor_Position = madtulipROIState.set_ROI_Anchor_around(entity.position())
		if (Work_ROI_Anchor_Position == nil) then return true end
		
		--world.logInfo("get_ROI")
		-- create a ROI around the anchor
		-- Boundary Box defining the ROI around the anchor
		local BB = entity.configParameter("madtulipROI.ROI_BB",nil)
		local ROI = madtulipLocation.create_ROI_from_anchor(Work_ROI_Anchor_Position,BB)
		if (ROI ~= nil) then madtulipROIState.ROI = ROI end
		
		--world.logInfo("get_Target")
		-- pick one target inside the ROI (all are passable) as next target to move towards
		local Target = madtulipLocation.get_next_target_inside_ROI(madtulipROIState.ROI)
		if (Target ~= nil) then madtulipROIState.Movement.Target = Target end
	else
		-- we have a ROI
		if madtulipROIState.Movement.Target == nil then
			-- we have no target inside the ROI to move to
			if not madtulipROIState.Movement.Switch_Target_Inside_ROI_Timer then
				-- its time to go somewhere else inside this ROI
				-- pick one target inside the ROI (all are passable) as next target to move towards
				local Target = madtulipLocation.get_next_target_inside_ROI(madtulipROIState.ROI)
				if (Target ~= nil) then madtulipROIState.Movement.Target = Target end
				madtulipROIState.Movement.Switch_Target_Inside_ROI_Timer = entity.randomizeParameterRange("madtulipROI.Switch_Target_Inside_ROI_Time")
			end
		else
			-- move
			local toTarget = world.distance(madtulipROIState.Movement.Target, entity.position())
			if world.magnitude(toTarget) < madtulipROIState.Movement.Min_XY_Dist_required_to_reach_target and
			   math.abs(toTarget[1]) < madtulipROIState.Movement.Min_X_Dist_required_to_reach_target then
					-- target reached -> clear movement target
					madtulipROIState.Movement.Target = nil
					--return true
			else
				-- still moving
				moveTo(madtulipROIState.Movement.Target, dt)
				-- chat while moving
				madtulipROIState.start_chats_on_the_way()
				-- close doors while moving
				if not madtulipROIState.Movement.Switch_Target_Inside_ROI_Timer then
					madtulipROIState.close_doors_behind_you()
				end
				
				return false
			end
		end
	end

	-- default return : we are not done
	return false
end

function madtulipROIState.set_ROI_Anchor_around(position)
	-- find all close by job attractors
	local AttractorID_Data
	if isTimeFor("madtulipROI.timeOfDayRangeWork") then
		-- search a work target
		AttractorID_Data = madtulipROIState.Work_AttratorQuerry(position,entity.configParameter("madtulipROI.Work_Attractor_Search_Radius", nil),storage.Occupation)
	elseif isTimeFor("madtulipROI.timeOfDayRangeRest") then
		-- search a rest target
		AttractorID_Data = madtulipROIState.Rest_AttratorQuerry(position,entity.configParameter("madtulipROI.Rest_Attractor_Search_Radius", nil))
	else
		-- there is no known state for this time
		return nil
	end
	--world.logInfo("AttractorID_Data.size=" .. tostring(AttractorID_Data.size))
	if (AttractorID_Data.size == 0) then return nil end
	
	-- use the position of a random attractor as new ROI anchor for now
	local target_nr = math.random (AttractorID_Data.size)
	--world.logInfo("AttractorID_Data.size: " .. tostring(AttractorID_Data.size) .. " target_nr: " .. target_nr .. "ID : " .. AttractorID_Data.AttractorIDs[target_nr] .. "Pos X: " .. world.entityPosition(AttractorID_Data.AttractorIDs[target_nr])[1] .. " Y:" .. world.entityPosition(AttractorID_Data.AttractorIDs[target_nr])[2])
	return world.entityPosition(AttractorID_Data.AttractorIDs[target_nr])
end

function madtulipROIState.Work_AttratorQuerry(Position,Radius,Occupation)
	--world.logInfo("Work_AttratorQuerry(Position[" .. Position[1] .. "," .. Position[2] .. "],Radius[" .. Radius .. "],Occupation[" .. Occupation .. "])")
	local AttractorNames = nil
	local size = 0
	local AttractorIDs = {}
	local ObjectIds = nil
	
	-- get list of interesting object names for this occupation
	if Occupation == "Deckhand" then
		AttractorNames =  entity.configParameter("madtulipROI.deckhand_attractors", nil)
	elseif Occupation == "Engineer" then
		AttractorNames =  entity.configParameter("madtulipROI.engineer_attractors", nil)
	elseif Occupation == "Marine" then
		AttractorNames =  entity.configParameter("madtulipROI.marine_attractors", nil)
	elseif Occupation == "Medic" then
		AttractorNames =  entity.configParameter("madtulipROI.medic_attractors", nil)
	elseif Occupation == "Scientist" then
		AttractorNames =  entity.configParameter("madtulipROI.scientist_attractors", nil)
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

function madtulipROIState.Rest_AttratorQuerry(Position,Radius)
	--world.logInfo("Rest_AttratorQuerry(Position[" .. Position[1] .. "," .. Position[2] .. "],Radius[" .. Radius .. "],Occupation[" .. Occupation .. "])")
	local AttractorNames = nil
	local size = 0
	local AttractorIDs = {}
	local ObjectIds = nil
	
	-- get list of interesting object names for this occupation
	AttractorNames =  entity.configParameter("madtulipROI.rest_attractors", nil)
	
	-- find instances of those attractors in the vicinity
	--world.logInfo("for AttractorNames")
	for AttractorName_Nr, AttractorName in pairs(AttractorNames) do
		-- world.logInfo("Attractor_Nr: " .. tostring(AttractorName_Nr))
		-- world.logInfo("AttractorName: " .. AttractorName)
		ObjectIds = world.objectQuery (Position, Radius,{name = AttractorName})
		for ObjectId_Nr, ObjectId in pairs(ObjectIds) do
			--world.logInfo("ObjectId_Nr: " .. tostring(ObjectId_Nr))
			--world.logInfo("ObjectId: " .. tostring(ObjectId))
			size = size + 1;
			AttractorIDs[size] = ObjectId;
		end
	end	
	
	-- add unoccupied beds
	local BedIds = world.loungeableQuery(Position, Radius, { orientation = "lay", order = "nearest" })
		for _, BedId in pairs(BedIds) do
		if not world.loungeableOccupied(BedId) then
			size = size + 1;
			AttractorIDs[size] = BedId;
		end
	end
	
	return {
		AttractorIDs = AttractorIDs,
		size = size
	}
end

function madtulipROIState.start_chats_on_the_way()
	-- Chat with other NPCs on the way
	if chatState ~= nil then
		local chatDistance = entity.configParameter("madtulipROI.chatDistance", nil)
		if chatDistance ~= nil then
			if madtulipROIState.Movement.Target ~= nil then
			-- determine if we walk right or left
			local toTarget = world.distance({entity.position()[1],0},{madtulipROIState.Movement.Target[1],0})
			local direction = nil
			if (toTarget[1] > 0) then direction = 1 else direction = -1 end
				if chatState.initiateChat(entity.position(), vec2.add({ chatDistance * direction, 0 }, entity.position())) then
					return true
				end
			end
		end
	end
end

function madtulipROIState.close_doors_behind_you()
	-- Chat with other NPCs in the way
	local close_doors_behind_range = entity.configParameter("madtulipROI.close_doors_behind_range", nil)
	local close_doors_behind_offset = entity.configParameter("madtulipROI.close_doors_behind_offset", nil)
	if close_doors_behind_range ~= nil then
		if madtulipROIState.Movement.Target ~= nil then
			-- determine if we walk right or left
			local toTarget = world.distance({entity.position()[1],0},{madtulipROIState.Movement.Target[1],0})
			local direction = nil
			if (toTarget[1] > 0) then direction = 1 else direction = -1 end
			
			-- determine range behind us to search for doors to close
			local ray = {}
			local position = entity.position();
			ray [1] = close_doors_behind_range[1] * direction + position[1] + close_doors_behind_offset[1]
			ray [2] = position[2] + close_doors_behind_offset[2]
			ray [3] = close_doors_behind_range[2] * direction + position[1] + close_doors_behind_offset[1]
			ray [4] = position[2] + close_doors_behind_offset[2]
			
			-- try to close doors
			--world.logInfo("Triing to close doors ray[1,2] X:" .. ray[1] .. " Y:" .. ray[2] .. " ray X:" .. ray[1] .. " Y:" .. ray[2])
			local doorIds = world.objectLineQuery({ray[1],ray[2]}, {ray[3],ray[4]}, { callScript = "hasCapability", callScriptArgs = { "door" } })
			for _, doorId in pairs(doorIds) do
				-- close door
				world.callScriptedEntity(doorId, "closeDoor")
				-- set timer so we don't close doors to fast
				madtulipROIState.Movement.Switch_Target_Inside_ROI_Timer = entity.configParameter("madtulipROI.Close_doors_behind_you_Timer")
			end
		end
	end
end

function madtulipROIState.update_timers(stateData,dt)
	-- update Switch_Target_Inside_ROI_Timer timer
	if madtulipROIState.Movement.Switch_Target_Inside_ROI_Timer ~= nil then
		madtulipROIState.Movement.Switch_Target_Inside_ROI_Timer = madtulipROIState.Movement.Switch_Target_Inside_ROI_Timer - dt
		if madtulipROIState.Movement.Switch_Target_Inside_ROI_Timer < 0 then
			madtulipROIState.Movement.Switch_Target_Inside_ROI_Timer = nil
		end
	end
	-- update Close_doors_behind_you_Timer
	if madtulipROIState.Movement.Close_doors_behind_you_Timer ~= nil then
		madtulipROIState.Movement.Close_doors_behind_you_Timer = madtulipROIState.Movement.Close_doors_behind_you_Timer - dt
		if madtulipROIState.Movement.Close_doors_behind_you_Timer < 0 then
			madtulipROIState.Movement.Close_doors_behind_you_Timer = nil
		end
	end
end