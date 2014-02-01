madtulip_TS = {}

function madtulip_TS.update_Task_Scheduler ()
	-- Search surroundings for all kinds of Tasks
	local Detected_Task_Data = madtulip_TS.Search_Tasks()
	
	-- Find only those Tasks which are not known already
	local New_Task_Data = madtulip_TS.Find_New_Tasks(Detected_Task_Data)
	
	-- Broadcast newly detected Tasks
	madtulip_TS.Broadcast_Tasks(New_Task_Data)
	
	-- Forget old Tasks
	madtulip_TS.Forget_Old_Tasks()
	
	-- Pick a Task for self
	madtulip_TS.Pick_Task()
end

function madtulip_TS.Search_Tasks()
	Tasks = {};
	Tasks_size = 0;
	
	-- add a dummy task
	Tasks_size = Tasks_size + 1;
	Tasks[Tasks_size] = {}
	Tasks[Tasks_size].Description = {}
	Tasks[Tasks_size].Description.Name = "someone_at_low_health"
	Tasks[Tasks_size].Description.Occupation = "Medic"
	
	return {
		Tasks = Tasks,
		size = Tasks_size
		}
end

function madtulip_TS.Find_New_Tasks(Tasks_to_check)
	-- compare Tasks_to_check with storage.TaskList, storage.TaskList_size
	-- if new
	--- add to storage.TaskList, storage.TaskList_size
	--- add to New_Tasks
	
	-- any inbound Tasks at all ?
	if (Tasks_to_check.size < 1) then return nil end
	
	-- init variables
	if storage.TaskList == nil then storage.TaskList = {} end
	if storage.TaskList.size == nil then storage.TaskList.size = 0 end
	local New_Tasks = {}

	-- for all inbound Tasks
	for idx_cur_Task = 1,Tasks_to_check.size,1 do
		--world.logInfo("Task Nr: " .. idx_cur_Task)
		--world.logInfo("Task Name: " .. Tasks_to_check.Tasks[idx_cur_Task].Description.Name)
		--world.logInfo("Task Occupation: " .. Tasks_to_check.Tasks[idx_cur_Task].Description.Occupation)
		
		-- for all known Tasks
		local cur_Task_to_check_is_an_old_hat = true
		for idx_cur_known_Task = 1,storage.TaskList.size,1 do
			-- check if everything in Description is the same for the new and the known Task.
			--- if not its a new Task. if yes then the Task is known already
			
			local there_is_new_information_in_cur_Task_to_check = false
			for Task_to_check_prop, Task_to_check_val in pairs(Tasks_to_check.Tasks[idx_cur_Task].Description) do
				-- check if that description property is present in current known Task
				if storage.TaskList.Tasks[idx_cur_known_Task].Description.Task_to_check_prop ~= nil then
					-- known task has the same property
					local known_val = storage.TaskList.Tasks[idx_cur_known_Task].Description.Task_to_check_prop
					if not (Task_to_check_val == known_val) then
						-- values of known and current task of that property differ
						--> this known task is not the same as the one to check against
						there_is_new_information_in_cur_Task_to_check = true
					end
				else
					-- we dont even have that property in the current known task
					there_is_new_information_in_cur_Task_to_check = true
				end
			end
			if not there_is_new_information_in_cur_Task_to_check then
				cur_Task_to_check_is_an_old_hat = true
			end
		end
		if not(cur_Task_to_check_is_an_old_hat) then
			-- add it to list of New_Tasks
		end
	end
	
	-- compare Tasks_to_check with storage.TaskList, storage.TaskList_size
	-- if new
	--- add to storage.TaskList, storage.TaskList_size
	--- add to New_Tasks
	New_Tasks = Tasks_to_check

	
	return New_Tasks
end

function madtulip_TS.Forget_Old_Tasks()

end

function madtulip_TS.Broadcast_Tasks(New_Tasks)

end

function madtulip_TS.Pick_Task()
	--storage.TaskList
	--storage.TaskList_size
end
