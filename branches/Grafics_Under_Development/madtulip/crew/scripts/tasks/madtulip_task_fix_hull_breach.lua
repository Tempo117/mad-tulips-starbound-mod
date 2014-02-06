madtulip_task_fix_hull_breach = {}

function madtulip_task_fix_hull_breach.can_PickTask(Task)
	-- this gets called by all NPCs that receive this task which are searching for a Task to do it.
	-- If this returns true the NPC will pick this Task and start to execute it.
	-- So here you should check for the currents NPC Occupation i.e. to see if hes able to do it.
	--world.logInfo("madtulip_task_fix_hull_breach.can_PickTask()")
	
	-- Check if I have the right Occupation to do the job
	if not((Task.Header.Occupation == "all") or (Task.Header.Occupation == storage.Occupation)) then return false end

	--entity.setItemSlot("primary", "beamaxe")
	--entity.setItemSlot("alt", nil)
	return true
end

function madtulip_task_fix_hull_breach.main_Task(Task)
	-- the main of the Task which is called all the time until it return true (the task is done)
	--world.logInfo("madtulip_task_fix_hull_breach.main_Task(Task)")
	
	local own_position = entity.position()
	local distance = world.magnitude(world.distance(own_position,Task.Header.Target_Position))
	
	-- move towards target (handled by madtulipROIState)
	Task.Var.Cur_Target_Position    = Task.Header.Target_Position
	Task.Var.Cur_Target_Position_BB = entity.configParameter("madtulipTS.Hull_Breach_ROI_BB", nil)

	-- aim at target
	entity.setAimPosition(Task.Header.Target_Position)
	if (distance < entity.configParameter("madtulipTS.Hull_Breach_place_Block_Range", nil))then
		-- close enough to use bone mender --> fire
		local could_place = world.placeMaterial(Task.Header.Target_Position, "foreground", "dirt")
		-- place background instead if foreground isn`t possible
		if not (could_place) then
			could_place = world.placeMaterial(Task.Header.Target_Position, "background", "dirt")
			if not (could_place) then
				-- if thats also not possible then try placing in the surrounding (maybe its a diagonal breach)
				for X=-1,1,1 do
					for Y=-1,1,1 do
						-- from -1,-1 to +1,+1 around target
						-- check if foreground is placed
						if    (world.material({Task.Header.Target_Position[1]+X,Task.Header.Target_Position[2]+Y},"foreground") == nil)
						  and (world.material({Task.Header.Target_Position[1]+X,Task.Header.Target_Position[2]+Y},"background") == nil) then
							-- if not try to place foreground
							could_place = world.placeMaterial({Task.Header.Target_Position[1]+X,Task.Header.Target_Position[2]+Y}, "foreground", "dirt")
							-- else place background at least
							if not (could_place) then world.placeMaterial({Task.Header.Target_Position[1]+X,Task.Header.Target_Position[2]+Y}, "backround", "dirt") end
						end
					end
				end
			end
		end
	end

	if (world.material(Task.Header.Target_Position,"foreground") ~= nil) then
		return true -- if done
	else
		return false -- if NOT done
	end
end

function madtulip_task_fix_hull_breach.end_Task()
	-- Called when the Task was completed
	-- eigther by me, or by someone else doing the same thing!
	--world.logInfo("madtulip_task_fix_hull_breach.end_Task()")
	
	entity.setItemSlot("primary", nil)
	entity.setItemSlot("alt", nil)
	
	-- TODO: exit all current state machine states (before killing the task)
end
