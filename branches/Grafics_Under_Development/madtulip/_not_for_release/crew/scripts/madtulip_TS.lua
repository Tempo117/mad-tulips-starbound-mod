-- TODO: all constants like broadcast ranges and such to external config file

-- Task Scheduler handles detection, communication and reaction to Tasks.
-- Task can be as general as wanna be (any Table).
madtulip_TS = {}

function madtulip_TS.update_Task_Scheduler (dt)
	if storage.Known_Tasks == nil then storage.Known_Tasks = {} end
	if storage.Known_Tasks.size == nil then storage.Known_Tasks.size = 0 end
	if storage.Known_Tasks.Tasks == nil then storage.Known_Tasks.Tasks = {} end

	-- Search surroundings for all kinds of Tasks
	local Detected_Tasks = madtulip_TS.Search_Tasks()
	
	-- Find only those Tasks which are not known already
	local New_Tasks = madtulip_TS.Find_New_Tasks(Detected_Tasks)
	
	-- Remember the new Tasks found
	madtulip_TS.Remember_Tasks(New_Tasks)
	
	-- Broadcast newly detected Tasks
	madtulip_TS.Broadcast_Tasks(New_Tasks)
	
	-- Forget old Tasks
	madtulip_TS.Forget_Old_Tasks(dt)
	
	-- Broadcast known Tasks ? Maybe every once in a while
	--madtulip_TS.Broadcast_Tasks(storage.Known_Tasks)
	
	-- Pick a Task for self
	madtulip_TS.Pick_Task()
end

function madtulip_TS.Search_Tasks()
	Tasks = {};
	Tasks_size = 0;
	
--[[
	-- add a dummy task
	Tasks_size = Tasks_size + 1;
	Tasks[Tasks_size] = {}
	Tasks[Tasks_size].Header = {} -- header is to be set initially and never again afterwards. the exact same header is the exact same task
	Tasks[Tasks_size].Header.Name = "someone_at_low_health" -- any content here is optional, but all of it together is used as a key to define this task as unique
	Tasks[Tasks_size].Header.Occupation = "Medic" -- any content here is optional, but all of it together is used as a key to define this task as unique
	Tasks[Tasks_size].Const = {} -- const is to be set initially and never again afterwards. content can varry while still being the same task (if header is the same)
	Tasks[Tasks_size].Const.Timeout = 3 -- required to prevent network oscillation
	Tasks[Tasks_size].Var = {}	-- optional. all variables that are to be used or transported which are not part of the key of the task

	Tasks_size = Tasks_size + 1;
	Tasks[Tasks_size] = {}
	Tasks[Tasks_size].Header = {}
	Tasks[Tasks_size].Header.Name = "save the rain forest"
	Tasks[Tasks_size].Header.Occupation = "Medic"
	Tasks[Tasks_size].Const = {}
	Tasks[Tasks_size].Const.Timeout = 3
	Tasks[Tasks_size].Var = {}
]]
	
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
			Tasks[Tasks_size].Header.Msg_on_discover_this_Task = "MEDIC!!!"
			--Tasks[Tasks_size].Header.Msg_on_heared_about_Task = "MEDIC!!!"
			Tasks[Tasks_size].Header.Msg_on_PickTask = "I can handle that!"
			Tasks[Tasks_size].Const = {}
			Tasks[Tasks_size].Const.Timeout = 30
		end
	end
	
	return {
		Tasks = Tasks,
		size = Tasks_size
		}
end

function madtulip_TS.Find_New_Tasks(Tasks_to_check)
	if Tasks_to_check == nil then return end
	if Tasks_to_check.size == nil then return end
	-- compare Tasks_to_check with storage.Tasks, storage.Tasks_size
	-- if new
	--- add to storage.Tasks, storage.Tasks_size
	--- add to New_Tasks
	
	-- any inbound Tasks at all ?
	if (Tasks_to_check.size < 1) then return nil end
	
	-- init variables
	local New_Tasks = {}
	New_Tasks.Tasks = {}
	New_Tasks.size = 0
	
	local cur_Task_to_check_is_an_old_hat = false
	local there_is_new_information_in_cur_Task_to_check = false
	local known_val = nil
	
	-- for all inbound Tasks
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
			for Task_to_check_prop, Task_to_check_val in pairs(Tasks_to_check.Tasks[idx_cur_Task].Header) do
				-- check if that Header property is present in current known Task
				--if Task_to_check_prop ~= nil then world.logInfo("Task_to_check_prop : " .. Task_to_check_prop) end
				--if Task_to_check_val ~= nil then world.logInfo("Task_to_check_val : " .. Task_to_check_val) end
				if storage.Known_Tasks.Tasks[idx_cur_known_Task].Header[Task_to_check_prop] ~= nil then
					-- known task has the same property
					known_val = storage.Known_Tasks.Tasks[idx_cur_known_Task].Header[Task_to_check_prop]
					--if Task_to_check_val ~= nil then world.logInfo("known_val : " .. known_val) end
					if (Task_to_check_val ~= known_val) then
						-- values of known and current task of that property differ
						--> this known task is not the same as the one to check against
						--world.logInfo("This value is not known by this known Task")
						there_is_new_information_in_cur_Task_to_check = true
					end
				else
					-- we dont even have that property in the current known task
					--world.logInfo("This property is not known by this known Task")
					there_is_new_information_in_cur_Task_to_check = true
				end
			end
			if not there_is_new_information_in_cur_Task_to_check then
				cur_Task_to_check_is_an_old_hat = true
			end
		end
		if not(cur_Task_to_check_is_an_old_hat) then
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
	return New_Tasks
end

function madtulip_TS.Remember_Tasks(New_Tasks)
	if New_Tasks == nil then return end
	if New_Tasks.size == nil then return end
	--world.logInfo("Remembering ... ")
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
		if storage.Known_Tasks.Tasks[storage.Known_Tasks.size].Var == nil then storage.Known_Tasks.Tasks[storage.Known_Tasks.size].Var = {} end
		if storage.Known_Tasks.Tasks[storage.Known_Tasks.size].Var.Timeout_timer == nil then
			-- only if the Task didn`t have a running Timer we start a new one.
			-- This ensures that Tasks, no matter if communicated or self generated
			-- never live longer and thus don`t oscillate through the net
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
	local idx_cur_Surviving_Task = 0
	for idx_cur_Task = 1,storage.Known_Tasks.size,1 do
		-- decrease timers
		storage.Known_Tasks.Tasks[idx_cur_Task].Var.Timeout_timer = storage.Known_Tasks.Tasks[idx_cur_Task].Var.Timeout_timer - dt
		
		if storage.Known_Tasks.Tasks[idx_cur_Task].Var.Timeout_timer > 0 then
			-- NO timeout for this task.
			-- shrink array
			idx_cur_Surviving_Task = idx_cur_Surviving_Task +1
			storage.Known_Tasks.Tasks[idx_cur_Surviving_Task] = storage.Known_Tasks.Tasks[idx_cur_Task]
		else
			-- delete Task
			--world.logInfo("Deleting Task due to Timeout!")
			storage.Known_Tasks.Tasks[idx_cur_Task] = {}
		end
	end
	-- update size
	storage.Known_Tasks.size = idx_cur_Surviving_Task
end

function madtulip_TS.Pick_Task()
	-- search through all tasks i know
	for idx_cur_Task = 1,storage.Known_Tasks.size,1 do
		-- Check if i have the right Occupation to do the job
		if (storage.Known_Tasks.Tasks[idx_cur_Task].Header.Occupation == "all") or
		   (storage.Known_Tasks.Tasks[idx_cur_Task].Header.Occupation == storage.Occupation) then
		    -- Is there something i should say to start the Job ?
			-- TODO: randomized List of sentences here.
			if (storage.Known_Tasks.Tasks[idx_cur_Task].Header.Msg_on_PickTask ~= nil) then
				entity.say(storage.Known_Tasks.Tasks[idx_cur_Task].Header.Msg_on_PickTask)
			end
			-- TODO: switch case "Name" of job to find handling function.
			-- TODO: maybe even include handling function as variable content :)
		end
	end
end

function madtulip_TS.Broadcast_Tasks(New_Tasks)
	if New_Tasks == nil then return end
	if New_Tasks.size == nil then return end
	
	if (New_Tasks.size > 0) then
		-- Tell all NPCs in the area that can receive it the good news (or maybe bad ones also .... .  .... ... .)
		world.npcQuery(entity.position(), 250, {withoutEntityId = entity.id(),callScript = "madtulip_TS.Offer_Tasks", callScriptArgs = {New_Tasks}})
	end
end

function madtulip_TS.Offer_Tasks(Offered_Tasks)
	if Offered_Tasks == nil then return end
	if Offered_Tasks.size == nil then return end
--[[
world.logInfo("--- Tasks Offered ---")
	for idx_cur_Task = 1,Offered_Tasks.size,1 do
		world.logInfo("Offered_Tasks Nr: " .. idx_cur_Task)
		world.logInfo("Offered_Tasks Name: " .. Offered_Tasks.Tasks[idx_cur_Task].Header.Name)
		world.logInfo("Offered_Tasks Occupation: " .. Offered_Tasks.Tasks[idx_cur_Task].Header.Occupation)
	end
]]
	-- Find only those Tasks which are not known already
	local New_Tasks = madtulip_TS.Find_New_Tasks(Offered_Tasks)
--[[
	for idx_cur_Task = 1,New_Tasks.size,1 do
		world.logInfo("--- Some of the offered Tasks where even news to me. ---")
		world.logInfo("New_Tasks Nr: " .. idx_cur_Task)
		world.logInfo("New_Tasks Name: " .. New_Tasks.Tasks[idx_cur_Task].Header.Name)
		world.logInfo("New_Tasks Occupation: " .. New_Tasks.Tasks[idx_cur_Task].Header.Occupation)
	end
]]
	-- Remember the new Tasks found
	madtulip_TS.Remember_Tasks(New_Tasks)
end
