-- TODO: all constants like broadcast ranges and such to external config file

-- Task Scheduler handles detection, communication and reaction to Tasks.
-- Task can be as general as wanna be (any Table).
madtulip_TS = {}

function madtulip_TS.Init()
	if storage.Known_Tasks == nil then storage.Known_Tasks = {} end
	if storage.Known_Tasks.size == nil then storage.Known_Tasks.size = 0 end
	if storage.Known_Tasks.Tasks == nil then storage.Known_Tasks.Tasks = {} end
	if storage.Known_Tasks.Is_Init == nil then storage.Known_Tasks.Is_Init = true end
end

function madtulip_TS.update_Task_Scheduler (dt)
	madtulip_TS.Init()
	
	-- Search surroundings for all kinds of Tasks
	local Detected_Tasks = madtulip_TS.Search_Tasks()
	
	-- Find only those Tasks which are not known already OR which are known but have new information
	-- TODO: Process old again for new information inside
	-- The .Global property like i.e.:
	--   storage.Known_Tasks.Tasks[idx_cur_Task].Global.is_beeing_handled = true
	--   storage.Known_Tasks.Tasks[idx_cur_Task].Global.handled_by_ID = entity.id()
	-- Do we need a system OS timestamp for "is_beeing_handled" ?
	-- if I handle it and then hear from others that they also handle it i would ?
	--   stop doing it.
	-- Known Tasks should set .Var.Known_as_index to which one in storage they refer
	local Splited_Tasks = madtulip_TS.Split_Task_in_New_and_Known(Detected_Tasks)
	
	-- TODO: implement this.
	-- .Var.Known_as_index of each Task in Known_Tasks point to its alias in storage.
	-- We update what we know about the .Global part of the Task only.
	-- This has probably to be done by comparing an OS timestemp of my and the new information.
	-- If i have newer information i need to broadcast that leaving the timestemp as is. ? or did i already broadcast that?
	-- I dont need to care for Global.is_done as long as i update that (it will be handled by forget)
	-- If Global.is_beeing_handled == true and im also handling this and the ID of th guy handling it is not mine
	-- i should check if that other guy exists. If he doesnt then i continue handling it as his ID might have changed.
	-- If he does exist then i should stop doing it.
	-- madtulip_TS.Update_Known_Tasks_Properties(Splited_Tasks.Known_Tasks)
	-- Remember the new Tasks found
	if (Splited_Tasks ~= nil) then
		if (Splited_Tasks.New_Tasks ~= nil) then
			if (Splited_Tasks.New_Tasks.size ~= nil) then
				if (Splited_Tasks.New_Tasks.size > 0) then
					madtulip_TS.Remember_Tasks(Splited_Tasks.New_Tasks)
					
					-- Broadcast newly detected Tasks
					madtulip_TS.Broadcast_Tasks(Splited_Tasks.New_Tasks)
				end
			end
		end
	end

	-- Forget old Tasks
	madtulip_TS.Forget_Old_Tasks(dt)
	
	-- Broadcast known Tasks ? Maybe every once in a while
	--if (Splited_Tasks ~= nil) then
	--madtulip_TS.Broadcast_Tasks(storage.Known_Tasks)
	--end

	-- Pick a Task for self
	madtulip_TS.Update_My_Task()
end

function madtulip_TS.Search_Tasks()
	Tasks = {};
	Tasks_size = 0;

	-- add a dummy task
	Tasks_size = Tasks_size + 1;
	Tasks[Tasks_size] = {}
	Tasks[Tasks_size].Header = {} -- header is to be set initially and never again afterwards. the exact same header is the exact same task
	Tasks[Tasks_size].Header.Name = "someone_at_low_health" -- any content here is optional, but all of it together is used as a key to define this task as unique
	Tasks[Tasks_size].Header.Occupation = "Medic" -- any content here is optional, but all of it together is used as a key to define this task as unique
	Tasks[Tasks_size].Header.Target_ID = PlayerId
	Tasks[Tasks_size].Header.Fct_Task  = "madtulip_Task_Heal_NPC_or_Player"
	Tasks[Tasks_size].Header.Msg_on_discover_this_Task = "MEDIC!!!"
	Tasks[Tasks_size].Header.Msg_on_PickTask = "I can handle that!"
	Tasks[Tasks_size].Const = {} -- const is to be set initially and never again afterwards. content can varry while still being the same task (if header is the same)
	Tasks[Tasks_size].Const.Timeout = 3 -- required to prevent network oscillation
--[[
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

-- TODO: from config real which functions to call to search for tasks. then get this from a Task_bla.lua
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
	for idx, PlayerId in pairs(world.playerQuery(entity.position(), 250)) do
		local Player_health = world.entityHealth(PlayerId)
		-- health smaler 95% of max health
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
			--Tasks[Tasks_size].Header.Msg_on_heared_about_Task = "MEDIC!!!"
			Tasks[Tasks_size].Header.Msg_on_PickTask = "I can handle that!"
			Tasks[Tasks_size].Const = {}
			Tasks[Tasks_size].Const.Timeout = 30
		end
	end
]]
	return {
		Tasks = Tasks,
		size = Tasks_size
		}
end

function madtulip_TS.Split_Task_in_New_and_Known(Tasks_to_check)
	-- compare Tasks_to_check with storage.Tasks, storage.Tasks_size
	-- if new
	--- add to New_Tasks
	-- if known
	--- add to Known_Tasks
	
	-- return if input is bad
--[[
	if Tasks_to_check == nil then return end
	if Tasks_to_check.Tasks == nil then return end
	if Tasks_to_check.size == nil then return end
	-- any inbound Tasks at all ?
	if (Tasks_to_check.size < 1) then return nil end
]]
	
	-- init variables
	local New_Tasks = {}
	New_Tasks.Tasks = {}
	New_Tasks.size = 0

	local Known_Tasks = {}
	Known_Tasks.Tasks = {}
	Known_Tasks.size = 0
	
	local cur_Task_to_check_is_an_old_hat = false
	local there_is_new_information_in_cur_Task_to_check = false
	local known_val = nil
	
	-- for all Tasks_to_check
	for idx_cur_Task = 1,Tasks_to_check.size,1 do
		--world.logInfo("Tasks_to_check Nr: " .. idx_cur_Task)
		--world.logInfo("Tasks_to_check Name: " .. Tasks_to_check.Tasks[idx_cur_Task].Header.Name)
		--world.logInfo("Tasks_to_check Occupation: " .. Tasks_to_check.Tasks[idx_cur_Task].Header.Occupation)
		
		-- for all known Tasks
		cur_Task_to_check_is_an_old_hat = false
		for idx_cur_known_Task = 1,storage.Known_Tasks.size,1 do
			-- check if everything in Header is the same for the new and the known Task.
			--- if not its a new Task. if yes then the Task is known already
			there_is_new_information_in_cur_Task_to_check = false
			for Task_to_check_key, Task_to_check_val in pairs(Tasks_to_check.Tasks[idx_cur_Task].Header) do
				-- check if that Header property is present in current known Task
				--if Task_to_check_key ~= nil then world.logInfo("Task_to_check_key : " .. Task_to_check_key) end
				--if Task_to_check_val ~= nil then world.logInfo("Task_to_check_val : " .. Task_to_check_val) end
				if storage.Known_Tasks.Tasks[idx_cur_known_Task].Header[Task_to_check_key] ~= nil then
					-- known task has the same property
					known_val = storage.Known_Tasks.Tasks[idx_cur_known_Task].Header[Task_to_check_key]
					--if Task_to_check_val ~= nil then world.logInfo("known_val : " .. known_val) end
					if (Task_to_check_val ~= known_val) then
						-- values of known and current task of that property differ
						--> this known task is not the same as the one to check against
						--world.logInfo("This value is not known by this known Task")
						there_is_new_information_in_cur_Task_to_check = true
					end
				else
					-- we dont even have that property in the current known task
					--world.logInfo("This key is not known by this known Task")
					there_is_new_information_in_cur_Task_to_check = true
				end
			end
			if not there_is_new_information_in_cur_Task_to_check then
				-- we know that Task already
				cur_Task_to_check_is_an_old_hat = true
				-- save the storage index as which we know it
				if Tasks_to_check.Tasks[idx_cur_Task].Var == nil then Tasks_to_check.Tasks[idx_cur_Task].Var = {} end
				Tasks_to_check.Tasks[idx_cur_Task].Var.Known_as_storage_index = idx_cur_known_Task
			end
		end
		
		-- switch the current Task to New or Known
		if (cur_Task_to_check_is_an_old_hat) then
			-- add it to list of Known_Tasks
			Known_Tasks.size = Known_Tasks.size + 1
			Known_Tasks.Tasks[Known_Tasks.size] = Tasks_to_check.Tasks[idx_cur_Task]
		else
			-- add it to list of New_Tasks
			New_Tasks.size = New_Tasks.size + 1
			New_Tasks.Tasks[New_Tasks.size] = Tasks_to_check.Tasks[idx_cur_Task]
		end
	end
--[[
	for idx_cur_Task = 1,New_Tasks.size,1 do
		world.logInfo("New_Tasks Nr: " .. idx_cur_Task)
		world.logInfo("New_Tasks Name: " .. New_Tasks.Tasks[idx_cur_Task].Header.Name)
		world.logInfo("New_Tasks Occupation: " .. New_Tasks.Tasks[idx_cur_Task].Header.Occupation)
	end
]]
	return {New_Tasks = New_Tasks,Known_Tasks = Known_Tasks}
end

function madtulip_TS.Update_Known_Tasks_Properties(Known_Tasks)
-- TODO: work the Knwon_Tasks into storage
end

function madtulip_TS.Remember_Tasks(New_Tasks)
	--if New_Tasks == nil then return end
	--if New_Tasks.size == nil then return end
	for idx_cur_Task = 1,New_Tasks.size,1 do
--[[
		world.logInfo("New Task found!")
		world.logInfo("New_Tasks Nr: " .. idx_cur_Task)
		world.logInfo("New_Tasks Name: " .. New_Tasks.Tasks[idx_cur_Task].Header.Name)
		world.logInfo("New_Tasks Occupation: " .. New_Tasks.Tasks[idx_cur_Task].Header.Occupation)
]]
		-- copy the new task to our "knowledge"
		storage.Known_Tasks.size = storage.Known_Tasks.size +1
		storage.Known_Tasks.Tasks[storage.Known_Tasks.size] = New_Tasks.Tasks[idx_cur_Task]
		
		-- add minimal required structure to it
		if storage.Known_Tasks.Tasks[storage.Known_Tasks.size].Var == nil then storage.Known_Tasks.Tasks[storage.Known_Tasks.size].Var = {} end
		if storage.Known_Tasks.Tasks[storage.Known_Tasks.size].Global == nil then storage.Known_Tasks.Tasks[storage.Known_Tasks.size].Global = {} end
		if storage.Known_Tasks.Tasks[storage.Known_Tasks.size].Global.is_done == nil then storage.Known_Tasks.Tasks[storage.Known_Tasks.size].Global.is_done = false end
		-- Set its Timeout value
		if storage.Known_Tasks.Tasks[storage.Known_Tasks.size].Var.Timeout_timer == nil then
			-- only if the Task didn`t have a running Timer we start a new one.
			-- This ensures that Tasks, no matter if communicated or self noticed
			-- never live longer then max timer and thus don`t oscillate through the net.
			storage.Known_Tasks.Tasks[storage.Known_Tasks.size].Var.Timeout_timer = New_Tasks.Tasks[idx_cur_Task].Const.Timeout
			
			-- Say something if you heared about this task (not the first one to discover it
			if storage.Known_Tasks.Tasks[storage.Known_Tasks.size].Header.Msg_on_discover_this_Task ~= nil then
				entity.say(storage.Known_Tasks.Tasks[storage.Known_Tasks.size].Header.Msg_on_discover_this_Task)
			end
		end
		
		-- Say something if you heared about this task (not the first one to discover it
		if storage.Known_Tasks.Tasks[storage.Known_Tasks.size].Header.Msg_on_heared_about_Task ~= nil then
			entity.say(storage.Known_Tasks.Tasks[storage.Known_Tasks.size].Header.Msg_on_heared_about_Task)
		end
	end
--[[	
	for idx_cur_Task = 1,storage.Known_Tasks.size,1 do
		world.logInfo("Known_Tasks Nr: " .. idx_cur_Task)
		world.logInfo("Known_Tasks Name: " .. storage.Known_Tasks.Tasks[idx_cur_Task].Header.Name)
		world.logInfo("Known_Tasks Occupation: " .. storage.Known_Tasks.Tasks[idx_cur_Task].Header.Occupation)
	end
]]
end

function madtulip_TS.Forget_Old_Tasks(dt)
	--world.logInfo("madtulip_TS.Forget_Old_Tasks(dt)")
	local idx_cur_Surviving_Task = 0
	local Task_is_done = nil
	local Task_has_timetout = nil
	
	-- search all known Tasks if they can be removed
	for idx_cur_Task = 1,storage.Known_Tasks.size,1 do
		Task_is_done = false
		Task_has_timetout = false
		
		-- decrease timers
		storage.Known_Tasks.Tasks[idx_cur_Task].Var.Timeout_timer = storage.Known_Tasks.Tasks[idx_cur_Task].Var.Timeout_timer - dt
		-- check if timeout occured
		if not (storage.Known_Tasks.Tasks[idx_cur_Task].Var.Timeout_timer > 0) then
			Task_has_timetout = true
		end
		
		-- check if this thas was handled and can thus be discarded
		if (storage.Known_Tasks.Tasks[idx_cur_Task].Global.is_done == true) then
			Task_is_done = true
		end
		
		if (Task_has_timetout or Task_is_done) then
			-- Task is obsolete -> delete Task
			storage.Known_Tasks.Tasks[idx_cur_Task] = {}
		else
			-- Task is still OK -> resize array if required
			idx_cur_Surviving_Task = idx_cur_Surviving_Task +1
			if (idx_cur_Task ~= idx_cur_Surviving_Task) then
				-- resize
				storage.Known_Tasks.Tasks[idx_cur_Surviving_Task] = storage.Known_Tasks.Tasks[idx_cur_Task]
				-- adjust this pointer to stay on the same target
				if (storage.Known_Tasks.idx_of_my_current_Task ~= nil) then
					if (storage.Known_Tasks.idx_of_my_current_Task == idx_cur_Task) then
						storage.Known_Tasks.idx_of_my_current_Task = idx_cur_Surviving_Task
					end
				end
			end
		end
	end
	-- update size
	storage.Known_Tasks.size = idx_cur_Surviving_Task
end

function madtulip_TS.Update_My_Task()
	-- execute my current Task
	-- or search through all known tasks (storage)
	-- and find one which can be picked and executed if i dont have one.
	if storage.Known_Tasks.idx_of_my_current_Task == nil then
		-- I don`t have a task
		--> search through all tasks i know
		for idx_cur_Task = 1,storage.Known_Tasks.size,1 do
			-- we dont have a task, so try to pick one from those im aware of.
			-- check if this one is being handled by someone else already
			if storage.Known_Tasks.Tasks[idx_cur_Task].Global.is_beeing_handled == nil
			   or storage.Known_Tasks.Tasks[idx_cur_Task].Global.is_beeing_handled == false then
			   -- noone I know of handles it
				if (_ENV[storage.Known_Tasks.Tasks[idx_cur_Task].Header.Fct_Task].can_PickTask(storage.Known_Tasks.Tasks[idx_cur_Task])) then
					-- I could handle this task
					--> pick this task (save by index)
					storage.Known_Tasks.idx_of_my_current_Task = idx_cur_Task
					
					-- mark the task as being processed
					storage.Known_Tasks.Tasks[idx_cur_Task].Global.is_beeing_handled = true
					storage.Known_Tasks.Tasks[idx_cur_Task].Global.handled_by_ID = entity.id()
					
					-- communicate to others that I handle it
					local Msg_Tasks = {}
					Msg_Tasks.Tasks = {}
					Msg_Tasks.size = 1
					Msg_Tasks.Tasks[1] = storage.Known_Tasks.Tasks[idx_cur_Task]
					madtulip_TS.Broadcast_Tasks(Msg_Tasks)
					
					break -- we did pick a new task for us, we can stop searching.
				end
			end
		end
	else
		-- I do have a Task, lets execute it!
		if (_ENV[storage.Known_Tasks.Tasks[storage.Known_Tasks.idx_of_my_current_Task].Header.Fct_Task].main_Task(storage.Known_Tasks.Tasks[storage.Known_Tasks.idx_of_my_current_Task])) then
			-- my current task is finished!
			--> call its ending function
			_ENV[storage.Known_Tasks.Tasks[storage.Known_Tasks.idx_of_my_current_Task].Header.Fct_Task].end_Task()

			-- mark Task as done
			storage.Known_Tasks.Tasks[storage.Known_Tasks.idx_of_my_current_Task].Global.is_done = true
			
			-- communicate to others that "I did it !"
			local Msg_Tasks = {}
			Msg_Tasks.Tasks = {}
			Msg_Tasks.size = 1
			Msg_Tasks.Tasks[1] = storage.Known_Tasks.Tasks[storage.Known_Tasks.idx_of_my_current_Task]
			madtulip_TS.Broadcast_Tasks(Msg_Tasks)
			
			-- forget that I was working on that
			storage.Known_Tasks.idx_of_my_current_Task = nil
			
			-- it will be removed from my memory with the next call to "madtulip_TS.Forget_Old_Tasks(dt)"
		end
	end
end

function madtulip_TS.Broadcast_Tasks(New_Tasks)
-- TODO: replace 250 by parameter
		-- Tell all NPCs in the area that can receive it the good news (or maybe bad ones also :p)
		world.npcQuery(entity.position(), 250, {withoutEntityId = entity.id(),callScript = "madtulip_TS.Offer_Tasks", callScriptArgs = {New_Tasks}})
end

function madtulip_TS.Offer_Tasks(Offered_Tasks)
	if (storage.Known_Tasks.Is_Init) then
		--world.logInfo("External offered")
		local Splited_Tasks = madtulip_TS.Split_Task_in_New_and_Known(Offered_Tasks)

		-- Remember the new Tasks found
		if (Splited_Tasks ~= nil) then
			if (Splited_Tasks.New_Tasks ~= nil) then
				if (Splited_Tasks.New_Tasks.size ~= nil) then
					if (Splited_Tasks.New_Tasks.size > 0) then
						madtulip_TS.Remember_Tasks(Splited_Tasks.New_Tasks)
					end
				end
			end
		end
		
		-- Tasks that we already knew about might have been updated
		--madtulip_TS.Update_Known_Tasks_Properties(Splited_Tasks.Known_Tasks)
	end
end

--------------- THIS TO A NEW FILE INSTEAD -----------------
madtulip_Task_Heal_NPC_or_Player = {}
function madtulip_Task_Heal_NPC_or_Player.can_PickTask(Task)
	world.logInfo("madtulip_Task_Heal_NPC_or_Player.can_PickTask()")
	-- Check if I have the right Occupation to do the job
	if not((Task.Header.Occupation == "all") or (Task.Header.Occupation == storage.Occupation)) then return false end
		   
	-- Is there something i should say to start the Job ?
	-- TODO: randomized List of sentences here.
	if (Task.Header.Msg_on_PickTask ~= nil) then
		entity.say(Task.Header.Msg_on_PickTask)
	end

	return true
end
function madtulip_Task_Heal_NPC_or_Player.main_Task(Task)
	world.logInfo("madtulip_Task_Heal_NPC_or_Player.main_Task(Task)")
	return true -- if done
end
function madtulip_Task_Heal_NPC_or_Player.end_Task()
	world.logInfo("madtulip_Task_Heal_NPC_or_Player.end_Task()")
end
