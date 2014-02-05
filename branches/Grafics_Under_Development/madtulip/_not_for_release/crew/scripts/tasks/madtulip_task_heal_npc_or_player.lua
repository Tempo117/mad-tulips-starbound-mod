madtulip_Task_Heal_NPC_or_Player = {}

function madtulip_Task_Heal_NPC_or_Player.spot_Task()
--[[
	-- add a dummy task
	Tasks = {}
	Tasks.Header = {} -- header is to be set initially and never again afterwards. the exact same header is the exact same task
	Tasks.Header.Name = "someone_at_low_health" -- any content here is optional, but all of it together is used as a key to define this task as unique
	Tasks.Header.Occupation = "Medic" -- any content here is optional, but all of it together is used as a key to define this task as unique
	Tasks.Header.Target_ID = PlayerId
	Tasks.Header.Fct_Task  = "madtulip_Task_Heal_NPC_or_Player"
	Tasks.Header.Msg_on_discover_this_Task = "MEDIC!!!"
	Tasks.Header.Msg_on_PickTask = "I can handle that!"
	Tasks.Global = {}
	Tasks.Global.is_beeing_handled = false
	Tasks.Global.is_beeing_handled_timestemp = os.time()
	Tasks.Global.is_done = false
	Tasks.Global.is_done_timestemp = os.time()
	Tasks.Const = {} -- const is to be set initially and never again afterwards. content can varry while still being the same task (if header is the same)
	Tasks.Const.Timeout = 10 -- required to prevent network oscillation
	
	return Tasks
	-- return nil -- no task avaible of this type

	Tasks_size = Tasks_size + 1;
	Tasks[Tasks_size] = {}
	Tasks[Tasks_size].Header = {}
	Tasks[Tasks_size].Header.Name = "save the rain forest"
	Tasks[Tasks_size].Header.Occupation = "Medic"
	Tasks[Tasks_size].Header.Target_ID = PlayerId
	--Tasks[Tasks_size].Header.Fct_can_PickTask  = madtulip_Task_Heal_NPC_or_Player.can_PickTask
	--Tasks[Tasks_size].Header.Fct_main_PickTask = madtulip_Task_Heal_NPC_or_Player.main_Task
	--Tasks[Tasks_size].Header.Fct_end_PickTask  = madtulip_Task_Heal_NPC_or_Player.end_Task
	Tasks[Tasks_size].Header.Msg_on_discover_this_Task = "MEDIC!!!"
	--Tasks[Tasks_size].Header.Msg_on_heared_about_Task = "MEDIC!!!"
	Tasks[Tasks_size].Header.Msg_on_PickTask = "I can handle that!"
	Tasks[Tasks_size].Const = {}
	Tasks[Tasks_size].Const.Timeout = 3

	for idx, NPCId in pairs(world.npcQuery(entity.position(), 250)) do
		local NPC_health = world.entityHealth(NPCId)
		-- health smaler 95% of max health
		if (NPC_health[1] < 0.95* NPC_health[2]) then
			-- spawn task
			Tasks_size = Tasks_size + 1;
			Tasks[Tasks_size] = {}
			Tasks[Tasks_size].Header = {}
			Tasks[Tasks_size].Header.Name = "Heal_NPC"
			Tasks[Tasks_size].Header.Occupation = "Medic"
			Tasks[Tasks_size].Header.Target_ID = PlayerId
			Tasks[Tasks_size].Header.Fct_Task  = "madtulip_Task_Heal_NPC_or_Player"
			Tasks[Tasks_size].Header.Msg_on_discover_this_Task = "MEDIC!!!"
			--Tasks[Tasks_size].Header.Msg_on_heared_about_Task = "MEDIC!!!"
			Tasks[Tasks_size].Header.Msg_on_PickTask = "I can handle that!"
			Tasks[Tasks_size].Const = {}
			Tasks[Tasks_size].Const.Timeout = 30
		end
	end
]]
	local Tasks = {}
	local radius = 50
	local Tasks_size = 0
	
	for idx, PlayerId in pairs(world.playerQuery(entity.position(), radius)) do
		local Player_health = world.entityHealth(PlayerId)
		-- health smaller 95% of max health
		if (Player_health[1] < 1.95* Player_health[2]) then
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
			Tasks[Tasks_size].Global.is_beeing_handled_timestemp = os.time()
			Tasks[Tasks_size].Global.is_done = false
			Tasks[Tasks_size].Global.is_done_timestemp = os.time()
			Tasks[Tasks_size].Const = {}
			Tasks[Tasks_size].Const.Timeout = 30
			
			Tasks[Tasks_size].Const.Do_this_from  = os.time() + 5
			Tasks[Tasks_size].Const.Do_this_until = os.time() + 10
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
	
	local Player_health = world.entityHealth(Task.Header.Target_ID)
	--if (Player_health[1] < 2.95* Player_health[2]) then
	if (Task.Const.Do_this_until > os.time()) then
		-- health larger 95% of max health
		local position = entity.position()
		position[1] = position[1]+3
	    entity.setAimPosition(position)
		if (Task.Const.Do_this_from < os.time()) then
			entity.beginPrimaryFire()
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
end
