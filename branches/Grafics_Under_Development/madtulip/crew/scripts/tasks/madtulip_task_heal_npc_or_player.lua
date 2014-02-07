madtulip_Task_Heal_NPC_or_Player = {}

function madtulip_Task_Heal_NPC_or_Player.spot_Task()
	-- init variables
	local Tasks = {}
	local radius = entity.configParameter("madtulipTS.find_Heal_NPC_or_Player_range", nil)
	local Tasks_size = 0
	
	-- find damaged players
	for idx, PlayerId in pairs(world.playerQuery(entity.position(), radius)) do
		local Player_health = world.entityHealth(PlayerId)
		-- health smaller 95% of max health
		if (Player_health[1] < 0.95* Player_health[2]) then
			-- spawn task
			Tasks_size = Tasks_size + 1;
			Tasks[Tasks_size] = {}
			Tasks[Tasks_size].Header = {}
			Tasks[Tasks_size].Header.Name = "Heal_Player"
			Tasks[Tasks_size].Header.Occupation = "Medic"
			Tasks[Tasks_size].Header.Target_ID = PlayerId
			Tasks[Tasks_size].Header.Fct_Task  = "madtulip_Task_Heal_NPC_or_Player"
			Tasks[Tasks_size].Header.Msg_on_discover_this_Task = "MEDIC!!!"
			Tasks[Tasks_size].Header.Msg_on_PickTask = "I can handle that!"
			Tasks[Tasks_size].Global = {}
			Tasks[Tasks_size].Global.is_beeing_handled = false
			Tasks[Tasks_size].Global.is_done = false
			Tasks[Tasks_size].Const = {}
			Tasks[Tasks_size].Const.Timeout = 30
			Tasks[Tasks_size].Var = {}
			Tasks[Tasks_size].Var.Cur_Target_Position = nil
			Tasks[Tasks_size].Var.Cur_Target_Position_BB = nil
			
			--Tasks[Tasks_size].Const.Do_this_from  = os.time() + 5
			--Tasks[Tasks_size].Const.Do_this_until = os.time() + 10
		end
	end

	-- find damaged NPCs
	for idx, NPCId in pairs(world.npcQuery(entity.position(), radius)) do
		local NPC_health = world.entityHealth(NPCId)
		-- health smaller 95% of max health
		if (NPC_health[1] < 0.95* NPC_health[2]) then
			-- spawn task
			Tasks_size = Tasks_size + 1;
			Tasks[Tasks_size] = {}
			Tasks[Tasks_size].Header = {}
			Tasks[Tasks_size].Header.Name = "Heal_Player"
			Tasks[Tasks_size].Header.Occupation = "Medic"
			Tasks[Tasks_size].Header.Target_ID = NPCId
			Tasks[Tasks_size].Header.Fct_Task  = "madtulip_Task_Heal_NPC_or_Player"
			Tasks[Tasks_size].Header.Msg_on_discover_this_Task = "MEDIC!!!"
			Tasks[Tasks_size].Header.Msg_on_PickTask = "I can handle that!"
			Tasks[Tasks_size].Global = {}
			Tasks[Tasks_size].Global.is_beeing_handled = false
			Tasks[Tasks_size].Global.is_beeing_handled_timestemp = os.time()
			Tasks[Tasks_size].Global.is_done = false
			Tasks[Tasks_size].Global.is_done_timestemp = os.time()
			Tasks[Tasks_size].Const = {}
			Tasks[Tasks_size].Const.Timeout = 30
			Tasks[Tasks_size].Var = {}
			Tasks[Tasks_size].Var.Cur_Target_Position = nil
			Tasks[Tasks_size].Var.Cur_Target_Position_BB = nil
			
			--Tasks[Tasks_size].Const.Do_this_from  = os.time() + 5
			--Tasks[Tasks_size].Const.Do_this_until = os.time() + 10
		end
	end
	
	return Tasks;
end

function madtulip_Task_Heal_NPC_or_Player.can_PickTask(Task)
	-- this gets called by all NPCs that receive this task which are searching for a Task to do it.
	-- If this returns true the NPC will pick this Task and start to execute it.
	-- So here you should check for the currents NPC Occupation i.e. to see if hes able to do it.
	--world.logInfo("madtulip_Task_Heal_NPC_or_Player.can_PickTask()")
	
	-- Check if I have the right Occupation to do the job
	if not((Task.Header.Occupation == "all") or (Task.Header.Occupation == storage.Occupation)) then return false end

	entity.setItemSlot("primary", "madtulip_bone_mender")
	entity.setItemSlot("alt", nil)
	return true
end

function madtulip_Task_Heal_NPC_or_Player.main_Task(Task)
	-- the main of the Task which is called all the time until it return true (the task is done)
	--world.logInfo("madtulip_Task_Heal_NPC_or_Player.main_Task(Task)")
	
	local cur_health = world.entityHealth(Task.Header.Target_ID)
	if (cur_health[1] < 0.95* cur_health[2]) then
	--if (Task.Const.Do_this_until > os.time()) then
		-- health larger 95% of max health
		local own_position = entity.position()
		local target_position = world.entityPosition (Task.Header.Target_ID)
		local distance = world.magnitude(world.distance(own_position,target_position))
		
		-- move towards target (handled by madtulipROIState)
		Task.Var.Cur_Target_Position    = target_position
		Task.Var.Cur_Target_Position_BB = entity.configParameter("madtulipTS.Heal_NPC_or_Player_ROI_BB", nil)

--[[ just included as an example
		if (Task.Var.State_Error_cant_reach_Target) then
			-- State Machine couldn't find a passable target to finish job
			Task.Var.State_Error_cant_reach_Target = nil -- clear flag
			--return true -- stop Task
			-- instead of stopping we can just wait for timeout.
			-- other NPCs will also not be able to reach the target of this task.
			-- we could increase the BB to search for a moveable target here.
			-- is possible that the target is just jumping atm. and will be targetable for movement again soon.
		end
		
		if (Task.Var.State_ROI_on_the_move) then
			-- state machine is still moveing towards its target
			Task.Var.State_ROI_on_the_move = false -- clear flag
		end
]]
		-- aim at target
	    entity.setAimPosition(target_position)
		if (distance < entity.configParameter("madtulipTS.use_bonemender_range", nil))then
			-- close enough to use bone mender --> fire
			entity.beginPrimaryFire()
			
--[[ just included as an example
			if (Task.Var.State_ROI_target_reached) then
				-- state machine reach position and exited state
				Task.Var.State_ROI_target_reached = false -- clear flag
				--> remove target so state machine stops starting again for searching for new target
				--Task.Var.Cur_Target_Position    = nil
				--Task.Var.Cur_Target_Position_BB = nil
			end
]]
		end
		
		return false -- if NOT done
	else
		return true -- if done
	end
end

function madtulip_Task_Heal_NPC_or_Player.end_Task()
	-- Called when the Task was completed
	-- eigther by me, or by someone else doing the same thing!
	--world.logInfo("madtulip_Task_Heal_NPC_or_Player.end_Task()")
	
	entity.setItemSlot("primary", nil)
	entity.setItemSlot("alt", nil)
	
	-- TODO: exit all current state machine states (before killing the task)
end
