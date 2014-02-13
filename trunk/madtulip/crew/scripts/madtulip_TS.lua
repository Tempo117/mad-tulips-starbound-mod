-- Task Scheduler handles detection, communication and reaction to Tasks.
-- Task can be generated by spotting them or broadcast by other sources
-- They define a number of states and goals to walk through in order to solve them (like get fire extinguisher -> walk to fire -> extinguish fire)
madtulip_TS = {}

function madtulip_TS.Has_A_Task()
	if (storage.Known_Tasks.idx_of_my_current_Task ~= nil) and (madtulip_TS.is_init) then
		return true
	end
	return false
end

function madtulip_TS.Init()
	-- adding this line forgets all previous tasks. this is sadly necessary as IDs dont persist over load.
	storage.Known_Tasks = nil

	if storage.Known_Tasks == nil then storage.Known_Tasks = {} end
	if storage.Known_Tasks.size == nil then storage.Known_Tasks.size = 0 end
	if storage.Known_Tasks.Tasks == nil then storage.Known_Tasks.Tasks = {} end
	if storage.Known_Tasks.Is_Init == nil then storage.Known_Tasks.Is_Init = true end
	
	madtulip_TS.is_init = true
end

function madtulip_TS.update_Task_Scheduler (dt)
	if not(madtulip_TS.is_init) then madtulip_TS.Init() end
	
	-- Search surroundings for all kinds of Tasks
	local Detected_Tasks = madtulip_TS.Search_Tasks()
	
	-- Find only those Tasks which are not known already OR which are known but have new information
	local Splited_Tasks = madtulip_TS.Split_Task_in_New_and_Known(Detected_Tasks)
	
	if (Splited_Tasks ~= nil) then
		if (Splited_Tasks.New_Tasks ~= nil) then
			if (Splited_Tasks.New_Tasks.size ~= nil) then
				if (Splited_Tasks.New_Tasks.size > 0) then
					-- Something to say on discover?
					for idx_cur_Task = 1,Splited_Tasks.New_Tasks.size,1 do
						if (Splited_Tasks.New_Tasks.Tasks[idx_cur_Task].Header.Msg_on_discover_this_Task ~= nil) then
							entity.say(Splited_Tasks.New_Tasks.Tasks[idx_cur_Task].Header.Msg_on_discover_this_Task)
							break; -- only one entity.say in case of multiples found. the first one in this case.
						end
					end
				
					-- The new tasks are to be copied to own memory
					madtulip_TS.Remember_Tasks(Splited_Tasks.New_Tasks)
					
					-- Broadcast newly detected Tasks
					world.logInfo("Broadcasting newly detected Tasks " .. entity.id())
					madtulip_TS.Broadcast_Tasks(Splited_Tasks.New_Tasks)
				end
			end
		end
		if (Splited_Tasks.Known_Tasks ~= nil) then
			if (Splited_Tasks.Known_Tasks.size ~= nil) then
				if (Splited_Tasks.Known_Tasks.size > 0) then
					-- Tasks that we already knew about might have been updated
					madtulip_TS.Update_Known_Tasks_Properties(Splited_Tasks.Known_Tasks)
				end
			end
		end
	end
	
	-- Pick a Task for self
	madtulip_TS.Update_My_Task()
	
	-- Forget old Tasks
	madtulip_TS.Forget_Old_Tasks(dt)
	
	--madtulip_TS.LogDump()
end

function madtulip_TS.Search_Tasks()
	local Tasks = {};
	local Tasks_size = 0;
	local cur_Tasks = {}
	local Task_spotting_functions = {}

	-- get all functions that can be used to spot the different tasks
	Task_spotting_functions = entity.configParameter("madtulipTS.Task_spotting_functions", nil)
	
	-- call all those functions. If they return a table instead of nil then use that table as a task
	for _key, cur_Task_spotting_function in pairs(Task_spotting_functions) do
		cur_Tasks = {}
		cur_Tasks = _ENV[cur_Task_spotting_function].spot_Task()
		if (cur_Tasks ~= nil) then
			for _Task_key, cur_Task in pairs(cur_Tasks) do
				Tasks_size = Tasks_size+1
				Tasks[Tasks_size] = cur_Task
			end
		end
	end
	
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
			--world.logInfo("Known_Tasks added. Known_Tasks.size: " .. Known_Tasks.size)
		else
			-- add it to list of New_Tasks
			New_Tasks.size = New_Tasks.size + 1
			New_Tasks.Tasks[New_Tasks.size] = Tasks_to_check.Tasks[idx_cur_Task]
			--world.logInfo("New_Tasks added. New_Tasks.size: " .. Known_Tasks.size)
		end
	end
	return {New_Tasks = New_Tasks,Known_Tasks = Known_Tasks}
end

function madtulip_TS.Update_Known_Tasks_Properties(Known_Tasks)
	-- world.logInfo("Update_Known_Tasks_Properties My Id: " .. entity.id())
	local idx_cur_Stored_Task = nil
	local cur_Known_Task_contained_new_global_information = nil
	
	for idx_cur_Task = 1,Known_Tasks.size,1 do
		-- index under which I stored the known Task
		idx_cur_Stored_Task = Known_Tasks.Tasks[idx_cur_Task].Var.Known_as_storage_index
		cur_Known_Task_contained_new_global_information = false
		
		--local info_who_handles_this_task_is_newer = (Known_Tasks.Tasks[idx_cur_Task].Global.is_beeing_handled_timestemp > storage.Known_Tasks.Tasks[idx_cur_Stored_Task].Global.is_beeing_handled_timestemp)
		local someone_started_handling_the_task = (Known_Tasks.Tasks[idx_cur_Task].Global.is_beeing_handled == true) and (storage.Known_Tasks.Tasks[idx_cur_Stored_Task].Global.is_beeing_handled == false)
		--local info_that_task_is_done_is_newer = (Known_Tasks.Tasks[idx_cur_Task].Global.is_done_timestemp > storage.Known_Tasks.Tasks[idx_cur_Stored_Task].Global.is_done_timestemp)
		local someone_did_the_task = (Known_Tasks.Tasks[idx_cur_Task].Global.is_done == true) and (storage.Known_Tasks.Tasks[idx_cur_Stored_Task].Global.is_done == false)		
		
		-- Copy parts of contents of the .Global part
		-- In order to decided which part of the .Global is new we use a timestemp
		if someone_started_handling_the_task then
			--world.logInfo("someone_started_handling_the_task update detected by entity id: " .. entity.id() .. " handler id: " .. " handler_ID : " .. Known_Tasks.Tasks[idx_cur_Task].Global.handled_by_ID))
			cur_Known_Task_contained_new_global_information = true;
		
			--> update my known information
			storage.Known_Tasks.Tasks[idx_cur_Stored_Task].Global.is_beeing_handled           = Known_Tasks.Tasks[idx_cur_Task].Global.is_beeing_handled
			storage.Known_Tasks.Tasks[idx_cur_Stored_Task].Global.handled_by_ID               = Known_Tasks.Tasks[idx_cur_Task].Global.handled_by_ID
			--storage.Known_Tasks.Tasks[idx_cur_Stored_Task].Global.is_beeing_handled_timestemp = Known_Tasks.Tasks[idx_cur_Task].Global.is_beeing_handled_timestemp
			
			-- if this is also my task which someone else is doing
			if (idx_cur_Stored_Task == storage.Known_Tasks.idx_of_my_current_Task) then
				-- yes, someone else started working on it also.
				-- I stop doing it as tasks are designed for only one person.
-- TODO: here we should start communication with Known_Tasks.Tasks[idx_cur_Task].Global.handled_by_ID
-- and decide who will do the job (maybe one of them is closer to being done).
				madtulip_TS.cancel_my_current_Task()
				world.logInfo("Stopping my current Task as he already does it. My Id: " .. entity.id() .. " handler_ID : " .. Known_Tasks.Tasks[idx_cur_Task].Global.handled_by_ID)
			end
		end
		if someone_did_the_task then
			--world.logInfo("someone_did_the_task update detected by entity id: " .. entity.id())
			cur_Known_Task_contained_new_global_information = true;
			
			--> update my known information
			storage.Known_Tasks.Tasks[idx_cur_Stored_Task].Global.is_done = Known_Tasks.Tasks[idx_cur_Task].Global.is_done
			--storage.Known_Tasks.Tasks[idx_cur_Stored_Task].Global.is_done_timestemp = Known_Tasks.Tasks[idx_cur_Task].Global.is_done_timestemp
			
			-- its done, am i also working on that task?
			if (idx_cur_Stored_Task == storage.Known_Tasks.idx_of_my_current_Task) then
				--world.logInfo("Stopping my current Task as someone else did already finish it.")
				-- im also working on that ... call its ending function for me as well
				madtulip_TS.cancel_my_current_Task()
			end
		end
		
		if (cur_Known_Task_contained_new_global_information) then
			-- we could update our .Global for this Known Task
			--> broadcast the new information to others as well so it propagates through the net
			local Msg_Tasks = {}
			Msg_Tasks.Tasks = {}
			Msg_Tasks.size = 1
			Msg_Tasks.Tasks[1] = storage.Known_Tasks.Tasks[idx_cur_Stored_Task]
			world.logInfo("Broadcast that i received Global. news" .. entity.id())
			madtulip_TS.Broadcast_Tasks(Msg_Tasks)
		end
	end
end

function madtulip_TS.Remember_Tasks(New_Tasks)
	--if New_Tasks == nil then return end
	--if New_Tasks.size == nil then return end
	for idx_cur_Task = 1,New_Tasks.size,1 do
		-- copy the new task to our "knowledge"
		storage.Known_Tasks.size = storage.Known_Tasks.size +1
		storage.Known_Tasks.Tasks[storage.Known_Tasks.size] = New_Tasks.Tasks[idx_cur_Task]
		
		-- add minimal required structure to it
		if storage.Known_Tasks.Tasks[storage.Known_Tasks.size].Var == nil then storage.Known_Tasks.Tasks[storage.Known_Tasks.size].Var = {} end
		-- Set its Timeout value
		if storage.Known_Tasks.Tasks[storage.Known_Tasks.size].Var.Timeout_timer == nil then
			-- only if the Task didn`t have a running Timer we start a new one.
			-- This ensures that Tasks, no matter if communicated or self noticed
			-- never live longer then max timer and thus don`t oscillate through the net.
			storage.Known_Tasks.Tasks[storage.Known_Tasks.size].Var.Timeout_timer = New_Tasks.Tasks[idx_cur_Task].Const.Timeout
		end
	end
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
		
		-- check if this task was handled and can thus be discarded
		if (storage.Known_Tasks.Tasks[idx_cur_Task].Global.is_done == true) then
			Task_is_done = true
		end
		
		if (Task_has_timetout or Task_is_done) then
			if (idx_cur_Task == storage.Known_Tasks.idx_of_my_current_Task) then
				-- I am currently working on that task -> cancel as not successful
				madtulip_TS.cancel_my_current_Task()
			end
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
			--world.logInfo("Try to pick Task.")
			--world.logInfo("storage.Known_Tasks.size: " .. storage.Known_Tasks.size)
			--world.logInfo("idx_cur_Task: " .. idx_cur_Task)
			-- we dont have a task, so try to pick one from those im aware of.
			-- check if this one is being handled by someone else already
			if (storage.Known_Tasks.Tasks[idx_cur_Task].Global.is_beeing_handled == false)
			   and not(storage.Known_Tasks.Tasks[idx_cur_Task].Var.Failed_this_already) then
			   --world.logInfo("Could Pick this.")
			   -- noone I know of handles it
				if (_ENV[storage.Known_Tasks.Tasks[idx_cur_Task].Header.Fct_Task].can_PickTask(storage.Known_Tasks.Tasks[idx_cur_Task])) then
					-- I could handle this task
					--world.logInfo("Starting Task. My Id: " .. entity.id() .. " idx_cur_Task: " .. idx_cur_Task)
					
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
					--world.logInfo("Broadcast that I start a Task " .. entity.id())
					madtulip_TS.Broadcast_Tasks(Msg_Tasks)
					
					-- Is there something i should say to start the Job ?
					-- TODO: randomized List of sentences here.
					if (storage.Known_Tasks.Tasks[idx_cur_Task].Header.Msg_on_PickTask ~= nil) then
						entity.say(storage.Known_Tasks.Tasks[idx_cur_Task].Header.Msg_on_PickTask)
					end
					
					break -- we did pick a new task for us, we can stop searching.
				end
			end
		end
	else
		-- I do have a Task, lets execute it!
		if (_ENV[storage.Known_Tasks.Tasks[storage.Known_Tasks.idx_of_my_current_Task].Header.Fct_Task].main_Task(storage.Known_Tasks.Tasks[storage.Known_Tasks.idx_of_my_current_Task])) then
			-- my current task is finished! ( eigther i finished it or someone else finished and told me about it)
			--> call its ending function
			madtulip_TS.successfully_end_my_current_Task()
		end
	end
end

function madtulip_TS.cancel_my_current_Task()
	-- call task ending function
	_ENV[storage.Known_Tasks.Tasks[storage.Known_Tasks.idx_of_my_current_Task].Header.Fct_Task].end_Task()
	
	-- forget that I was working on that
	storage.Known_Tasks.idx_of_my_current_Task = nil
end

function madtulip_TS.fail_my_current_Task()
	-- Set a Flag so we do not try this Task again until it Times out
	if (storage.Known_Tasks.Tasks[storage.Known_Tasks.idx_of_my_current_Task].Var ~= nil) then
		storage.Known_Tasks.Tasks[storage.Known_Tasks.idx_of_my_current_Task].Var.Failed_this_already = true
	end
	-- forget task and call its ending functions
	madtulip_TS.cancel_my_current_Task()
	
	entity.say("FAILED MY TASK!")
end

function madtulip_TS.successfully_end_my_current_Task()
	-- call task ending function
	_ENV[storage.Known_Tasks.Tasks[storage.Known_Tasks.idx_of_my_current_Task].Header.Fct_Task].end_Task()

	-- communicate to others that "I did it !"
	storage.Known_Tasks.Tasks[storage.Known_Tasks.idx_of_my_current_Task].Global.is_done = true
	--storage.Known_Tasks.Tasks[storage.Known_Tasks.idx_of_my_current_Task].Global.is_done_timestemp = os.time()
	
	local Msg_Tasks = {}
	Msg_Tasks.Tasks = {}
	Msg_Tasks.size = 1
	Msg_Tasks.Tasks[1] = storage.Known_Tasks.Tasks[storage.Known_Tasks.idx_of_my_current_Task]
	madtulip_TS.Broadcast_Tasks(Msg_Tasks)
	--world.logInfo("Broadcast that I successfully completed a Task " .. entity.id())
	
	-- forget that I was working on that
	storage.Known_Tasks.idx_of_my_current_Task = nil
	
	-- it will be removed from my memory with the next call to "madtulip_TS.Forget_Old_Tasks(dt)"
	entity.say("TASK DONE!")
end

function madtulip_TS.Broadcast_Tasks(New_Tasks)
		-- Tell all NPCs in the area that can receive it the good news (or maybe bad ones also :p)
-- TODO: instead of doing this in a radius we should do this with NPCs in sight only.
		local radius = entity.configParameter("madtulipTS.broadcast_range", nil)
		world.npcQuery(entity.position(), radius, {withoutEntityId = entity.id(),callScript = "madtulip_TS.Offer_Tasks", callScriptArgs = {New_Tasks}})
end

function madtulip_TS.Offer_Tasks(Offered_Tasks)
	--world.logInfo("Im offered a Task " .. entity.id())
	if (storage.Known_Tasks.Is_Init) then
		--world.logInfo("External offered to ID: " .. entity.id())
		local Splited_Tasks = madtulip_TS.Split_Task_in_New_and_Known(Offered_Tasks)

		-- Remember the new Tasks found
		if (Splited_Tasks ~= nil) then
			if (Splited_Tasks.New_Tasks ~= nil) then
				if (Splited_Tasks.New_Tasks.size ~= nil) then
					if (Splited_Tasks.New_Tasks.size > 0) then
						-- the new tasks are to be copied to memory
						-- world.logInfo("External contained NEW to ID: " .. entity.id())
						madtulip_TS.Remember_Tasks(Splited_Tasks.New_Tasks)
					end
				end
			end
			if (Splited_Tasks.Known_Tasks ~= nil) then
				if (Splited_Tasks.Known_Tasks.size ~= nil) then
					if (Splited_Tasks.Known_Tasks.size > 0) then
						-- Tasks that we already knew about might have been updated
						-- world.logInfo("External contained KNOWN to ID: " .. entity.id())
						madtulip_TS.Update_Known_Tasks_Properties(Splited_Tasks.Known_Tasks)
					end
				end
			end
		end
	end
end

function madtulip_TS.LogDump()
	-- TODO:
	world.logInfo("--- LogDump Entity ID: " .. entity.id() .. " ---")
	if(storage.Known_Tasks.idx_of_my_current_Task ~= nil) then
		world.logInfo("- NO current Task  -")
	else
		world.logInfo("- current Task  -")
		--storage.Known_Tasks.Tasks[storage.Known_Tasks.idx_of_my_current_Task].Header.Name
	end
end