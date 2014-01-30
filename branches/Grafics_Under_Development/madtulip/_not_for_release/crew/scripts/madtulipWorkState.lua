madtulipWorkState = {}

function madtulipWorkState.enter()
	-- declare variables
	madtulipWorkState.ROI = madtulipLocation.get_empty_ROI()
	
	madtulipWorkState.Movement = {}
	madtulipWorkState.Movement.Target = nil -- current movement target block
	madtulipWorkState.Movement.Switch_Target_Inside_ROI_Timer = nil -- time to pass between targets inside the same ROI
	madtulipWorkState.Movement.Close_doors_behind_you_Timer = nil -- time to pass between targets inside the same ROI
	
	-- constants
	madtulipWorkState.Movement.Min_XY_Dist_required_to_reach_target = 3 -- radius
	madtulipWorkState.Movement.Min_X_Dist_required_to_reach_target  = 1 -- X Axis only
	
	-- equip work clothing
	Set_Occupation_Cloth()
	
	return {
		timer = entity.randomizeParameterRange("madtulipWork.timeRange")
	}
end

function madtulipWorkState.update(dt, stateData)
	-- return if wander is on cooldown
	stateData.timer = stateData.timer - dt
	if stateData.timer < 0 then
		return true, entity.configParameter("madtulipWork.cooldown", nil)
	end

	madtulipWorkState.update_timers(stateData,dt)
	
	if (madtulipWorkState.ROI.anchor_pos == nil) then
		--world.logInfo("get_Work_ROI_Anchor_Position")
		-- no region of interest to walk to determined -> get an anchor for such a ROI
		local Work_ROI_Anchor_Position = madtulipWorkState.set_Work_Anchor_around(entity.position())
		if (Work_ROI_Anchor_Position == nil) then return nil end
		
		--world.logInfo("get_ROI")
		-- create a ROI around the anchor
		-- Boundary Box defining the ROI around the anchor
		local BB = entity.configParameter("madtulipWork.Work_ROI_BB",nil)
		local ROI = madtulipLocation.create_ROI_from_anchor(Work_ROI_Anchor_Position,BB)
		if (ROI ~= nil) then madtulipWorkState.ROI = ROI end
		
		--world.logInfo("get_Target")
		-- pick one target inside the ROI (all are passable) as next target to move towards
		local Target = madtulipLocation.get_next_target_inside_ROI(madtulipWorkState.ROI)
		if (Target ~= nil) then madtulipWorkState.Movement.Target = Target end
	else
		-- we have a ROI
		if madtulipWorkState.Movement.Target == nil then
			-- we have no target inside the ROI to move to
			if not madtulipWorkState.Movement.Switch_Target_Inside_ROI_Timer then
				-- its time to go somewhere else inside this ROI
				-- pick one target inside the ROI (all are passable) as next target to move towards
				local Target = madtulipLocation.get_next_target_inside_ROI(madtulipWorkState.ROI)
				if (Target ~= nil) then madtulipWorkState.Movement.Target = Target end
				madtulipWorkState.Movement.Switch_Target_Inside_ROI_Timer = entity.randomizeParameterRange("madtulipWork.Move_Inside_ROI_Time")
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
				madtulipWorkState.start_chats_on_the_way()
				
				if not madtulipWorkState.Movement.Switch_Target_Inside_ROI_Timer then
					madtulipWorkState.close_doors_behind_you()
				end
				
				return false
			end
		end
	end

	-- default return : we are not done
	return false
end

function madtulipWorkState.set_Work_Anchor_around(position)
	-- find all close by job attractors
	local AttractorID_Data = madtulipLocation.Work_AttratorQuerry(position,entity.configParameter("madtulipWork.Work_Attractor_Search_Radius", nil),storage.Occupation)
	--world.logInfo("AttractorID_Data.size=" .. tostring(AttractorID_Data.size))
	if (AttractorID_Data.size == 0) then return nil end
	local target_nr = math.random (AttractorID_Data.size)
	--world.logInfo("AttractorID_Data.size: " .. tostring(AttractorID_Data.size) .. " target_nr: " .. target_nr .. "ID : " .. AttractorID_Data.AttractorIDs[target_nr] .. "Pos X: " .. world.entityPosition(AttractorID_Data.AttractorIDs[target_nr])[1] .. " Y:" .. world.entityPosition(AttractorID_Data.AttractorIDs[target_nr])[2])
	-- use the position of a random attractor as new ROI anchor for now
	return world.entityPosition(AttractorID_Data.AttractorIDs[target_nr])
end

function madtulipWorkState.start_chats_on_the_way()
	-- Chat with other NPCs on the way
	if chatState ~= nil then
		local chatDistance = entity.configParameter("madtulipWork.chatDistance", nil)
		if chatDistance ~= nil then
			if madtulipWorkState.Movement.Target ~= nil then
			-- determine if we walk right or left
			local toTarget = world.distance({entity.position()[1],0},{madtulipWorkState.Movement.Target[1],0})
			local direction = nil
			if (toTarget[1] > 0) then direction = 1 else direction = -1 end
				if chatState.initiateChat(entity.position(), vec2.add({ chatDistance * direction, 0 }, entity.position())) then
					return true
				end
			end
		end
	end
end

function madtulipWorkState.close_doors_behind_you()
	-- Chat with other NPCs in the way
	local close_doors_behind_range = entity.configParameter("madtulipWork.close_doors_behind_range", nil)
	if close_doors_behind_range ~= nil then
		if madtulipWorkState.Movement.Target ~= nil then
			-- determine if we walk right or left
			local toTarget = world.distance({entity.position()[1],0},{madtulipWorkState.Movement.Target[1],0})
			local direction = nil
			if (toTarget[1] > 0) then direction = 1 else direction = -1 end
			
			-- determine range behind us to search for doors to close
			local ray = {}
			local position = entity.position();
			ray [1] = close_doors_behind_range[1] * direction + position[1]
			ray [2] = position[2]
			ray [3] = close_doors_behind_range[2] * direction + position[1]
			ray [4] = position[2]
			
			-- try to close doors
			--world.logInfo("Triing to close doors ray[1,2] X:" .. ray[1] .. " Y:" .. ray[2] .. " ray X:" .. ray[1] .. " Y:" .. ray[2])
			local doorIds = world.objectLineQuery({ray[1],ray[2]}, {ray[3],ray[4]}, { callScript = "hasCapability", callScriptArgs = { "door" } })
			for _, doorId in pairs(doorIds) do
				-- close door
				world.callScriptedEntity(doorId, "closeDoor")
				-- set timer so we don't close doors to fast
				madtulipWorkState.Movement.Switch_Target_Inside_ROI_Timer = entity.configParameter("madtulipWork.Close_doors_behind_you_Timer")
			end
		end
	end
end

function madtulipWorkState.update_timers(stateData,dt)
	-- update Switch_Target_Inside_ROI_Timer timer
	if madtulipWorkState.Movement.Switch_Target_Inside_ROI_Timer ~= nil then
		madtulipWorkState.Movement.Switch_Target_Inside_ROI_Timer = madtulipWorkState.Movement.Switch_Target_Inside_ROI_Timer - dt
		if madtulipWorkState.Movement.Switch_Target_Inside_ROI_Timer < 0 then
			madtulipWorkState.Movement.Switch_Target_Inside_ROI_Timer = nil
		end
	end
	-- update Close_doors_behind_you_Timer
	if madtulipWorkState.Movement.Close_doors_behind_you_Timer ~= nil then
		madtulipWorkState.Movement.Close_doors_behind_you_Timer = madtulipWorkState.Movement.Close_doors_behind_you_Timer - dt
		if madtulipWorkState.Movement.Close_doors_behind_you_Timer < 0 then
			madtulipWorkState.Movement.Close_doors_behind_you_Timer = nil
		end
	end
end