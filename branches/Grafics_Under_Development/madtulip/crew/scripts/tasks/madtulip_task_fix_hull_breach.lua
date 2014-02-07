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
	
	madtulip_task_fix_hull_breach.is_init = nil
	
	return true
end

function madtulip_task_fix_hull_breach.main_Task(Task)
	-- the main of the Task which is called all the time until it return true (the task is done)
	--world.logInfo("madtulip_task_fix_hull_breach.main_Task(Task)")

	local own_position = entity.position()
	local target_position = Task.Var.Breach_Cluster.Cluster[1] -- pick first breach location as target
	local distance = world.magnitude(world.distance(own_position,target_position))
	
	-- move towards target (handled by madtulipROIState)
	Task.Var.Cur_Target_Position    = target_position
	Task.Var.Cur_Target_Position_BB = entity.configParameter("madtulipTS.Hull_Breach_ROI_BB", nil)

	-- enforce to pick ROI state to navigate to target
	if not madtulip_task_fix_hull_breach.is_init then
		world.logInfo("Enforcing ROI State")
-- TODO: Hand the Movement relevant parameters to the ROI State here instead of accessing the TASK from the STATE.
-- The state should not need to know about the task at all. remove all those dependencies
-- The is the option to implement a callback once the state is done reaching the target
		self.state.pickState("TEST")
		madtulip_task_fix_hull_breach.is_init = true
	end
	
	-- aim at target
	entity.setAimPosition(target_position)
	if (distance < entity.configParameter("madtulipTS.Hull_Breach_place_Block_Range", nil))then
		-- close enough to use bone mender --> fire
		for cur_breach = 1,Task.Var.Breach_Cluster.size,1 do
			world.placeMaterial(Task.Var.Breach_Cluster.Cluster[cur_breach], "foreground", "dirt")
			world.placeMaterial(Task.Var.Breach_Cluster.Cluster[cur_breach], "background", "dirt")
			world.placeMaterial(Task.Var.Breach_Cluster.Cluster[cur_breach], "foreground", "dirt")
			world.placeMaterial(Task.Var.Breach_Cluster.Cluster[cur_breach], "background", "dirt")
		end
	end
	
-- TODO: if we cant reach the target (ROI cant be placed)
-- we need to mark this task as unsolvable for us, stop it and dont try it again.
-- This "i tried it once and failed condition should be a general thing for tasks to be implemented
	
	-- check if all breaches have been closed
	local all_breaches_closed = true
	for cur_breach = 1,Task.Var.Breach_Cluster.size,1 do
		if (world.material(Task.Var.Breach_Cluster.Cluster[cur_breach],"foreground") == nil) then all_breaches_closed = false end
	end
	
	-- end task depending on all breaches beeing closed
	if all_breaches_closed then
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
	
	-- Exit current state machine State
	self.state.endState()
	
	-- TODO: exit all current state machine states (before killing the task)
end
