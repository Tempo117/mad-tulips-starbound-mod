function initializeObject()
	-- Make our object interactive (we can interract by 'Use')
	entity.setInteractive(true);
	
	-- Change animation for state "normal_operation"
	entity.setAnimationState("DisplayState", "no_vent");
	
	-- globals
	madtulip = {}
	madtulip.MSS_Range = 1000; -- maximum range to scan for other vents around the master
	madtulip.Door_max_range = 10 -- maximum number of blocks in all directions around a door root that are scanned for the door
	madtulip.On_Off_State = 1; -- "1:ON,2:OFF"
	madtulip.maximum_particle_fountains = 50;
	madtulip.ANY_Breach = 0;	
	
	-- spawn a new main calculation thread
	co = coroutine.create(function ()
		-- Automatic Hull Breach Scans for all Vents in the Area
		Multistage_Scan_all_Vents_in_the_Area();
	 end)
end

function kill_self()
	world.spawnItem("madtulip_life_support_system", entity.toAbsolutePosition({ 0.0, 0.0 }));
	entity.smash();
end

function main()
    -- due to
	-- "scriptDelta" : 100
	-- in the object script this is called approximately every 1s for my hardware

	-- Check for the single execution
	if self.initialized == nil then
		-- Init object
		initializeObject();
		-- Set flag
		self.initialized = true;
	end

	--- smash all other life support masters in the area - we only need one, firste come first serve :) ---
	local madtulip_life_support_system_Ids  = world.objectQuery (entity.toAbsolutePosition({ 0.0, 0.0 }),1000,{name = "madtulip_life_support_system"});
	for _, madtulip_life_support_system_Id in pairs(madtulip_life_support_system_Ids) do
		if (madtulip_life_support_system_Id > entity.id()) then
			world.callScriptedEntity(madtulip_life_support_system_Id, "kill_self");
		end
	end
	
	--Multistage_Scan_all_Vents_in_the_Area();
	if (coroutine.status(co) == "suspended") then
		-- start thread
		coroutine.resume(co);
	elseif (coroutine.status(co) == "dead") then
		-- spawn a new main calculation thread
		co = coroutine.create(function ()
			-- Automatic Hull Breach Scans for all Vents in the Area
			Multistage_Scan_all_Vents_in_the_Area();
		 end)
	elseif (coroutine.status(co) == "running") then
		-- nothing
	end
end

function onInteraction(args)
	-- if clicked by middle mouse or "e"
	
	-- here you can switch the main unit and all slaves off
	if(madtulip.On_Off_State == 1) then
		madtulip.On_Off_State = 2;
		entity.setAnimationState("DisplayState", "offline");
	else
		madtulip.On_Off_State = 1;
		entity.setAnimationState("DisplayState", "no_vent");
	end
end

function Multistage_Scan_all_Vents_in_the_Area()
	-- Range: range from life support system in blocks in which to search for vents
	
	madtulip.Nr_of_all_vents = 0;
	madtulip.Postion_of_all_vents = {};
	madtulip.IDs_of_all_vents = {};
	
	madtulip.Scan_Results = {};
	madtulip.Scan_Results.Origin = {};
	madtulip.Scan_Results.Stage_ranges = {};
	madtulip.Scan_Results.Counter_Nr_Vents_Processed = 0;
	madtulip.Scan_Results.Nr_Vent_Ids_overlapping    = 0;
	madtulip.Scan_Results.Vent_Ids_overlapping       = {};
	-- while looping over all vents the global results of all flood fill scans are saved here
	madtulip.Scan_Results.ANY_Room_is_not_enclosed   = 0;
	madtulip.Scan_Results.ANY_Background_breach      = 0;
	madtulip.Scan_Results.ANY_BreachES      = {};
	madtulip.Scan_Results.counter_breaches           = 0;
	-- while looping over all vents the results of theire flood fill scans are saved here
	madtulip.Scan_Results.SINGLE_VENTS_ID                   = {};
	madtulip.Scan_Results.SINGLE_VENTS_WAS_SKIPPED          = {};
	madtulip.Scan_Results.SINGLE_VENTS_Room_is_not_enclosed = {};
	madtulip.Scan_Results.SINGLE_VENTS_Background_breach    = {};
	madtulip.Scan_Results.SINGLE_VENTS_BREACHES             = {};
	
	-- find all vents in the area and get theire position
	madtulip.Scan_Results.Vents_Ids  = world.objectQuery (entity.toAbsolutePosition({ 0.0, 0.0 }),madtulip.MSS_Range,{name = "madtulip_vent"});
	-- Perform scan for hull breach using each vents origin as point to start an individual scan
	
	local process_this_vent = nil
	local this_vent_is_already_know_for_overlapping = nil	

	for _, Vents_Id in pairs(madtulip.Scan_Results.Vents_Ids) do
--world.logInfo ("VENT ID: " .. Vents_Id)
		madtulip.Nr_of_all_vents = madtulip.Nr_of_all_vents+1;
		madtulip.Postion_of_all_vents[madtulip.Nr_of_all_vents] = world.entityPosition (Vents_Id);
		madtulip.IDs_of_all_vents[madtulip.Nr_of_all_vents] = Vents_Id;
	end
	
	-- check for master system beeing offline
	if (madtulip.On_Off_State ~= 1) then
		-- master is offline
		entity.setAnimationState("DisplayState", "offline");
		for _, Vents_Id in pairs(madtulip.Scan_Results.Vents_Ids) do
			-- set vens offline as well
			world.callScriptedEntity(Vents_Id, "set_O2_Offline_State");
		end
	else
		-- master is online
		-- default animation: no ventilators found
		entity.setAnimationState("DisplayState", "no_vent");

		----- Scan all vents -----
--world.logInfo ("SCAN ALL VENTS")
		for _, Vents_Id in pairs(madtulip.Scan_Results.Vents_Ids) do
--world.logInfo ("next vent")
			-- check if the current vent was already implicitly tested by beeing flooded by another earlier tested vent
			process_this_vent = 1;
--world.logInfo ({"Nr_overlapping:",madtulip.Scan_Results.Nr_Vent_Ids_overlapping})
			for n = 1,madtulip.Scan_Results.Nr_Vent_Ids_overlapping,1 do
--world.logInfo ({"comparing:",madtulip.Scan_Results.Vent_Ids_overlapping[n],Vents_Id})
				if(madtulip.Scan_Results.Vent_Ids_overlapping[n] == Vents_Id) then
					-- it was hit already, dont test this again.
					process_this_vent = 0;
--world.logInfo ("found one to skip")
				end
			end
			if (process_this_vent == 1) then
--world.logInfo ("processing vent")
				-- inc counter
				madtulip.Scan_Results.Counter_Nr_Vents_Processed = madtulip.Scan_Results.Counter_Nr_Vents_Processed +1;
				
				-- expensive call (start flood fill for the current Vent)
				madtulip.Scan_Results.Origin = (world.entityPosition (Vents_Id))
				madtulip.Scan_Results.Stage_ranges = {50,250,1000}
				Automatic_Multi_Stage_Scan();
--world.logInfo ("Flood_Fill DONE")
				
				-- save the impact of this current Vent on the Life Support Main "breached" or "not breached" status
				if (madtulip.Flood_Data_Matrix.Room_is_not_enclosed == 1) then
					-- globally this is also true (one is enough)
					madtulip.Scan_Results.ANY_Room_is_not_enclosed = 1;
					if (madtulip.Flood_Data_Matrix.Background_breach == 1) then
						-- its a defined background breach. no out of memory or iteration counter
						madtulip.Scan_Results.ANY_Background_breach    = 1;		
					end
				end

				-- save states of the currently checked vent
				madtulip.Scan_Results.SINGLE_VENTS_ID[madtulip.Scan_Results.Counter_Nr_Vents_Processed]       = Vents_Id;
				madtulip.Scan_Results.SINGLE_VENTS_BREACHES[madtulip.Scan_Results.Counter_Nr_Vents_Processed] = madtulip.Flood_Data_Matrix.Breaches;
				for _, Breach_Location in pairs(madtulip.Flood_Data_Matrix.Breaches) do
					madtulip.Scan_Results.counter_breaches = madtulip.Scan_Results.counter_breaches +1;
					madtulip.Scan_Results.ANY_BreachES[madtulip.Scan_Results.counter_breaches] = Breach_Location;
				end
				madtulip.Scan_Results.SINGLE_VENTS_WAS_SKIPPED[madtulip.Scan_Results.Counter_Nr_Vents_Processed]              = 0;
				if (madtulip.Flood_Data_Matrix.Room_is_not_enclosed == 1) then
					madtulip.Scan_Results.SINGLE_VENTS_Room_is_not_enclosed[madtulip.Scan_Results.Counter_Nr_Vents_Processed] = 1;
				else
					madtulip.Scan_Results.SINGLE_VENTS_Room_is_not_enclosed[madtulip.Scan_Results.Counter_Nr_Vents_Processed] = 0;
				end
				if (madtulip.Flood_Data_Matrix.Background_breach == 1) then
					madtulip.Scan_Results.SINGLE_VENTS_Background_breach[madtulip.Scan_Results.Counter_Nr_Vents_Processed]    = 1;
				else
					madtulip.Scan_Results.SINGLE_VENTS_Background_breach[madtulip.Scan_Results.Counter_Nr_Vents_Processed]    = 0;
				end

				-- if other vents then the current one where flooded by the current one
				for cur_overlapping_vent_nr = 1 ,madtulip.Flood_Data_Matrix.Nr_Vent_Ids_overlapping,1 do
					this_vent_is_already_know_for_overlapping = 0;
					for n = 1,madtulip.Scan_Results.Nr_Vent_Ids_overlapping,1 do
						if(madtulip.Scan_Results.Vent_Ids_overlapping[madtulip.Scan_Results.Nr_Vent_Ids_overlapping] == madtulip.Flood_Data_Matrix.Vent_Ids_overlapping[cur_overlapping_vent_nr]) then
							-- it was not known that theese two vents share the same flooded plain
							this_vent_is_already_know_for_overlapping = 1;
						end
					end
					
					if not (this_vent_is_already_know_for_overlapping == 1) then
						-- register the newly found redundant vent here
						madtulip.Scan_Results.Nr_Vent_Ids_overlapping = madtulip.Scan_Results.Nr_Vent_Ids_overlapping+1;
						madtulip.Scan_Results.Vent_Ids_overlapping[madtulip.Scan_Results.Nr_Vent_Ids_overlapping] = madtulip.Flood_Data_Matrix.Vent_Ids_overlapping[cur_overlapping_vent_nr];
						
						-- save the state of the redundant vent. its the same as the state of the current one
						madtulip.Scan_Results.Counter_Nr_Vents_Processed = madtulip.Scan_Results.Counter_Nr_Vents_Processed +1;
						
						madtulip.Scan_Results.SINGLE_VENTS_ID[madtulip.Scan_Results.Counter_Nr_Vents_Processed]       = madtulip.Flood_Data_Matrix.Vent_Ids_overlapping[cur_overlapping_vent_nr];
						madtulip.Scan_Results.SINGLE_VENTS_WAS_SKIPPED[madtulip.Scan_Results.Counter_Nr_Vents_Processed]              = 1;
						if (madtulip.Flood_Data_Matrix.Room_is_not_enclosed == 1) then
							madtulip.Scan_Results.SINGLE_VENTS_Room_is_not_enclosed[madtulip.Scan_Results.Counter_Nr_Vents_Processed] = 1;
						else
							madtulip.Scan_Results.SINGLE_VENTS_Room_is_not_enclosed[madtulip.Scan_Results.Counter_Nr_Vents_Processed] = 0;
						end
						if (madtulip.Flood_Data_Matrix.Background_breach == 1) then
							madtulip.Scan_Results.SINGLE_VENTS_Background_breach[madtulip.Scan_Results.Counter_Nr_Vents_Processed]    = 1;
						else
							madtulip.Scan_Results.SINGLE_VENTS_Background_breach[madtulip.Scan_Results.Counter_Nr_Vents_Processed]    = 0;
						end
					end
				end
			end
		end
		------- all vents have been scanned -------
		------- perform actions -------
		-- if any vents detected at all
		if (madtulip.Scan_Results.Counter_Nr_Vents_Processed > 0) then
			-- for the master based on the scan results
			if(madtulip.Scan_Results.ANY_Background_breach == 1) then
				-- play a meeping warning sound
				entity.playSound("Breach_Warning_Sound");
			end	
			if (madtulip.Scan_Results.ANY_Room_is_not_enclosed == 1) then
				-- set animation state of master wall panel to breach
				entity.setAnimationState("DisplayState", "breach");
				madtulip.ANY_Breach = 1;
			else
				-- set animation state to normal operation
				entity.setAnimationState("DisplayState", "normal_operation");
				madtulip.ANY_Breach = 0;
			end
			
			-- perform actions for each vent based on the scan results
			--local madtulip.Scan_Results.counter_breaches = 0;
			for cur_Vent_Nr = 1,madtulip.Scan_Results.Counter_Nr_Vents_Processed,1 do
				if (madtulip.Scan_Results.SINGLE_VENTS_Room_is_not_enclosed[cur_Vent_Nr] == 1) then
					-- the current Vent is not in a closed room -> display that graficaly
					world.callScriptedEntity(madtulip.Scan_Results.SINGLE_VENTS_ID[cur_Vent_Nr], "set_O2_BAD_State");
				else
					-- this vents room was not breached -> display that graficaly
					world.callScriptedEntity(madtulip.Scan_Results.SINGLE_VENTS_ID[cur_Vent_Nr], "set_O2_OK_State");
				end
			end

			-- spawn breach grafics
			-- limit theire number
			if (madtulip.Scan_Results.counter_breaches > madtulip.maximum_particle_fountains) then
				-- spawn them (limited amount)
				for cur_particle_fountain_to_generate = 1,madtulip.maximum_particle_fountains,1 do
					world.spawnProjectile("madtulip_breach", madtulip.Scan_Results.ANY_BreachES[math.random(madtulip.Scan_Results.counter_breaches)]);
				end
			else
				-- spawn them (all)
				for cur_counter_breaches = 1,madtulip.Scan_Results.counter_breaches,1 do
					world.spawnProjectile("madtulip_breach", madtulip.Scan_Results.ANY_BreachES[cur_counter_breaches]);
				end
			end

		end
	end
end

function Automatic_Multi_Stage_Scan()
	-- first check with very small memory footprint 50 blocks in each direction
	Start_New_Room_Breach_Scan(madtulip.Scan_Results.Stage_ranges[1],1);
	if (madtulip.Flood_Data_Matrix.Room_is_not_enclosed == 1) then
		if (madtulip.Flood_Data_Matrix.Background_breach ~= 1) then
			-- if no closed room was found we enlargen the search area
			-- this could have been done in the first place, but it takes longer if the initial room is small already
			Start_New_Room_Breach_Scan(madtulip.Scan_Results.Stage_ranges[2],1);
			if (madtulip.Flood_Data_Matrix.Room_is_not_enclosed == 1) then
				if (madtulip.Flood_Data_Matrix.Background_breach ~= 1) then
					-- if no closed room was found we enlargen the search area
					-- this could have been done in the first place, but it takes longer if the initial room is small already
					Start_New_Room_Breach_Scan(madtulip.Scan_Results.Stage_ranges[3],1);
				end
			end
		end
	end
	-- now we stop scanning because a larger area which would be larger then (Scanner_ranges*2+1)^2 blocks uses quite some mem and time.
	-- you can however use Scanner_ranges = 10000 or mor if you like. see how long it takes if you are in a realy large room :)
end

function Start_New_Room_Breach_Scan(size_to_scan,Scan_8_method)
	-- Input:
	-- size_to_scan:number of block in x and y directions around the origin to scan with flood.if flood runs out of this area, area is marked as not enclosed.
	-- Sca_8_method: Scans west,north, east, south blocks only if ~= 0. Scans diagonal blocks also if == 1
	
	-- create global Flood Data matrix which holds the room which is flooded
	madtulip.Flood_Data_Matrix               = {}; -- nothing stored here
	-- data
	madtulip.Flood_Data_Matrix.Content       = {}; -- stores at [x,y] the "color" of the block which tells if its background, foreground or open
	madtulip.Flood_Data_Matrix.Breaches      = {}; -- stores {x,y} pairs of locations of breach
	madtulip.Flood_Data_Matrix.Background_in_scanned_Area = {}; -- stores {x,y} pairs of background only (interior) locations of enclosed area
	madtulip.Flood_Data_Matrix.Vent_Ids_overlapping       = {} -- stroes IDs of Vents that are in the area flooded by the current vent. we dont need to check them again.
	-- settings
	madtulip.Flood_Data_Matrix.Origin         = madtulip.Scan_Results.Origin;
	madtulip.Flood_Data_Matrix.size_to_scan   = size_to_scan;
	madtulip.Flood_Data_Matrix.X_min          = madtulip.Scan_Results.Origin[1] - size_to_scan;
	madtulip.Flood_Data_Matrix.X_max          = madtulip.Scan_Results.Origin[1] + size_to_scan;
	madtulip.Flood_Data_Matrix.Y_min          = madtulip.Scan_Results.Origin[2] - size_to_scan;
	madtulip.Flood_Data_Matrix.Y_max          = madtulip.Scan_Results.Origin[2] + size_to_scan;
	madtulip.Flood_Data_Matrix.Max_Iteration  = ((size_to_scan*2)+1)*((size_to_scan*2)+1); -- maximum room size. if the room is larger this will terminate early stating that the room is not closed
	madtulip.Flood_Data_Matrix.Scan_8_method  = Scan_8_method; -- if == 0 scan 4 surrounding blocks (W,N,E,S) else scan also the 4 diagonal corners
	madtulip.Flood_Data_Matrix.max_door_hight_top    = 5;
	madtulip.Flood_Data_Matrix.max_door_hight_bottom = 5;
	madtulip.Flood_Data_Matrix.target_color          = 1;
	madtulip.Flood_Data_Matrix.none_target_color     = 2;
	madtulip.Flood_Data_Matrix.replacement_color     = 3;
	-- counter
	madtulip.Flood_Data_Matrix.Area                    = 0; -- counts the area filled with flood
	madtulip.Flood_Data_Matrix.Cur_Iteration           = 0; -- counter for number of iterations done so far
	madtulip.Flood_Data_Matrix.Nr_of_Breaches          = 0; -- counter for number of breaches detected
	madtulip.Flood_Data_Matrix.Nr_Vent_Ids_overlapping = 0; -- counts how many other ventilators area beeing flooded by this one. we dont want to run those again.
	-- bools
	madtulip.Flood_Data_Matrix.Stop_Iteration       = 0; -- bool
	madtulip.Flood_Data_Matrix.Room_is_not_enclosed = 0; -- bool
	-- flags after breaking condition has been reached
	madtulip.Flood_Data_Matrix.Background_breach            = 0; -- not enclose due to hole in the back wall
	madtulip.Flood_Data_Matrix.Background_Breach_Location   = {};
	madtulip.Flood_Data_Matrix.Max_Nr_of_Iterations_happend = 0; -- enclosure couldn't be found in maximum number of iteration steps
	madtulip.Flood_Data_Matrix.Maximum_size_to_scan_reached = 0;

	-- init data matrix memory for flood fill
	for cur_X = madtulip.Flood_Data_Matrix.X_min,madtulip.Flood_Data_Matrix.X_max,1 do
		madtulip.Flood_Data_Matrix.Content[cur_X] = {};
		for cur_Y = madtulip.Flood_Data_Matrix.Y_min,madtulip.Flood_Data_Matrix.Y_max,1 do
			madtulip.Flood_Data_Matrix.Content[cur_X][cur_Y] = {};
		end	
	end
	
	-- check for doors in the area first
	Prepare_Doors_for_Flood_Fill();

	-- test the area around the block where this is placed for beeing an enclosed room
	Flood_Fill(madtulip.Flood_Data_Matrix.Origin,1,2,3);
end

function Prepare_Doors_for_Flood_Fill()
	-- add additional information about surrounding, like doors
	local radius_to_scan = madtulip.Flood_Data_Matrix.size_to_scan*2;
	local closedDoorIds  = world.objectQuery (madtulip.Flood_Data_Matrix.Origin, radius_to_scan, { callScript = "hasCapability", callScriptArgs = { "closedDoor" } });
	
	if (closedDoorIds == nil) then
		-- no doors found, nothing to do
		return;
	end
	
	local root_Door_Position = {}
	local cur_Door_IDs = {}
	local cur_door_pos = {}
	local foreground_block_found = nil
	-- for all closed doors in vicinity, get theire coordinates
	for closed_door_nr, closedDoorId in pairs(closedDoorIds) do
		root_Door_Position = world.entityPosition (closedDoorId);
		-- door is inside currently intialized memory
world.logInfo ("Root closed door #" .. closed_door_nr .. "@X:" .. root_Door_Position[1] .. "Y:" .. root_Door_Position[2])
		set_flood_data_matrix_content (root_Door_Position[1],root_Door_Position[2],madtulip.Flood_Data_Matrix.replacement_color)
		--madtulip.Flood_Data_Matrix.Content[root_Door_Position[1]][root_Door_Position[2]] = madtulip.Flood_Data_Matrix.replacement_color;
		
		cur_door_pos = { root_Door_Position[1], root_Door_Position[2] }
		if (world.material(cur_door_pos, "foreground")) then
world.logInfo ("Door root has foreground")
			-- root of the door is a foreground block -> we asume its going only up
			-- scan from root to top
			foreground_block_found = false;
			for cur_Y=(root_Door_Position[2]+1),(root_Door_Position[2]+madtulip.Door_max_range),1 do		
				if not(foreground_block_found) then
					cur_door_pos = { root_Door_Position[1], cur_Y }
					if (world.material(cur_door_pos, "foreground")) then
						foreground_block_found = true
					else
world.logInfo ("Closed door #" .. closed_door_nr .. "@X:" .. root_Door_Position[1] .. "Y:" .. cur_Y)
						set_flood_data_matrix_content (root_Door_Position[1],cur_Y,madtulip.Flood_Data_Matrix.replacement_color)
						--madtulip.Flood_Data_Matrix.Content[root_Door_Position[1]][cur_Y] = madtulip.Flood_Data_Matrix.replacement_color;
					end
				end
			end
		else
world.logInfo ("Door root has NO foreground")
			-- root of the door is NO foreground block. we scan towards top and bottom
			-- scan from root to top
			foreground_block_found = false;
			for cur_Y=(root_Door_Position[2]+1),(root_Door_Position[2]+madtulip.Door_max_range),1 do		
				if not(foreground_block_found) then
					cur_door_pos = { root_Door_Position[1], cur_Y }
					if (world.material(cur_door_pos, "foreground")) then
						foreground_block_found = true
					else
world.logInfo ("Closed door #" .. closed_door_nr .. "@X:" .. root_Door_Position[1] .. "Y:" .. cur_Y)
						set_flood_data_matrix_content (root_Door_Position[1],cur_Y,madtulip.Flood_Data_Matrix.replacement_color)
						--madtulip.Flood_Data_Matrix.Content[root_Door_Position[1]][cur_Y] = madtulip.Flood_Data_Matrix.replacement_color;
					end
				end
			end
			-- scan from root to bottom
			foreground_block_found = false;
			for cur_Y=(root_Door_Position[2]-1),(root_Door_Position[2]-madtulip.Door_max_range),1 do		
				if not(foreground_block_found) then
					cur_door_pos = { root_Door_Position[1], cur_Y }
					if (world.material(cur_door_pos, "foreground")) then
						foreground_block_found = true
					else
world.logInfo ("Closed door #" .. closed_door_nr .. "@X:" .. root_Door_Position[1] .. "Y:" .. cur_Y)
						set_flood_data_matrix_content (root_Door_Position[1],cur_Y,madtulip.Flood_Data_Matrix.replacement_color)
						--madtulip.Flood_Data_Matrix.Content[root_Door_Position[1]][cur_Y] = madtulip.Flood_Data_Matrix.replacement_color;
					end
				end
			end
		end
	end
end

function Flood_Fill(cur_Position)
	--  ----- ITERATION BREAKING CONDITIONS: -----
	-- if some step of the iteration already determined to stop iteration
	if madtulip.Flood_Data_Matrix.Stop_Iteration == 1 then
		return;
	end
	-- if this block has already been scanned
	if madtulip.Flood_Data_Matrix.Content[cur_Position[1]][cur_Position[2]] == madtulip.Flood_Data_Matrix.replacement_color then
		-- we have already been here
		return;
	end
	if madtulip.Flood_Data_Matrix.Content[cur_Position[1]][cur_Position[2]] == madtulip.Flood_Data_Matrix.none_target_color then
		-- we have already been here
		return;
	end	
	-- if we leave assigned memory size
	if (cur_Position[1] < madtulip.Flood_Data_Matrix.X_min) then
		madtulip.Flood_Data_Matrix.Maximum_size_to_scan_reached = 1;
		madtulip.Flood_Data_Matrix.Stop_Iteration = 1;
		return;
	end
	if (cur_Position[1] > madtulip.Flood_Data_Matrix.X_max) then
		madtulip.Flood_Data_Matrix.Maximum_size_to_scan_reached = 1;
		madtulip.Flood_Data_Matrix.Stop_Iteration = 1;
		return;
	end
	if (cur_Position[2] < madtulip.Flood_Data_Matrix.Y_min) then
		madtulip.Flood_Data_Matrix.Maximum_size_to_scan_reached = 1;
		madtulip.Flood_Data_Matrix.Stop_Iteration = 1;
		return;
	end
	if (cur_Position[2] > madtulip.Flood_Data_Matrix.Y_max) then
		madtulip.Flood_Data_Matrix.Maximum_size_to_scan_reached = 1;
		madtulip.Flood_Data_Matrix.Stop_Iteration = 1;
		return;
	end
	-- if maximum number of iterations is reached
	if (madtulip.Flood_Data_Matrix.Cur_Iteration > madtulip.Flood_Data_Matrix.Max_Iteration) then
		-- iteration limit reached
		madtulip.Flood_Data_Matrix.Room_is_not_enclosed          = 1; -- set flag
		madtulip.Flood_Data_Matrix.Max_Nr_of_Iterations_happend  = 1; -- set flag
		madtulip.Flood_Data_Matrix.Stop_Iteration                = 1; -- break iteration
	end
	
	local cur_vent_position
	if (madtulip.Flood_Data_Matrix.Cur_Iteration > 0) then
		-- the first iteration checks the vent which initiated this fllod
		for n=1,madtulip.Nr_of_all_vents,1 do
			cur_vent_position = madtulip.Postion_of_all_vents[n];
			if (cur_Position[1] == cur_vent_position[1])and(cur_Position[2] == cur_vent_position[2]) then
				-- there is another vents beeing flooded. we dont need to search that again, it will have the same result as the current one.
				madtulip.Flood_Data_Matrix.Nr_Vent_Ids_overlapping = madtulip.Flood_Data_Matrix.Nr_Vent_Ids_overlapping +1;
				madtulip.Flood_Data_Matrix.Vent_Ids_overlapping[madtulip.Flood_Data_Matrix.Nr_Vent_Ids_overlapping] = madtulip.IDs_of_all_vents[n];
			end
		end
	end
	
	-- ----- so far we are good, take next step in the state machine -----
	-- increment iteration step
	madtulip.Flood_Data_Matrix.Cur_Iteration = madtulip.Flood_Data_Matrix.Cur_Iteration + 1;
	
	-- check if there is a foreground block
	--  ,if not then check if there is a background block
	--  ,if also not its a breach.
	-- write the gathered info to "madtulip.Flood_Data_Matrix.Content[x,y]" which is the data object used further on
	if world.material(cur_Position, "foreground") == nil then
		-- nil foreground block found. This is our target.
		madtulip.Flood_Data_Matrix.Content[cur_Position[1]][cur_Position[2]] = madtulip.Flood_Data_Matrix.target_color;
		-- if this is also a nil background block we have a breach that we might or might not be aware of yet
		if  world.material(cur_Position, "background") == nil then
		
			-- its a bachground breach that we have not been aware of!
			madtulip.Flood_Data_Matrix.Nr_of_Breaches = madtulip.Flood_Data_Matrix.Nr_of_Breaches+1;-- inc counter for breaches
			madtulip.Flood_Data_Matrix.Breaches[madtulip.Flood_Data_Matrix.Nr_of_Breaches] = cur_Position;-- store location of breach
			madtulip.Flood_Data_Matrix.Room_is_not_enclosed       = 1; -- set flag that the room is open
			madtulip.Flood_Data_Matrix.Background_breach          = 1; -- not enclose due to hole in the background
			
			-- we did hit the a breach here, don`t spawn further searches from this block
			madtulip.Flood_Data_Matrix.Content[cur_Position[1]][cur_Position[2]] = madtulip.Flood_Data_Matrix.none_target_color;
			return;
		end
	else
		-- an existing foreground block is a none target
		-- we did hit the wall here, don`t spawn further searches from this block
		madtulip.Flood_Data_Matrix.Content[cur_Position[1]][cur_Position[2]] = madtulip.Flood_Data_Matrix.none_target_color;
	end

	--  ----- 1. If the "color" of current node is not equal to target-color, return. -----
	if (madtulip.Flood_Data_Matrix.Content[cur_Position[1]][cur_Position[2]] ~= madtulip.Flood_Data_Matrix.target_color) then
		-- the current block is not an open foreground space -> don`t spawn further searches from this block
		return;
	end
	
	-- ----- 2. Set the color of node to replacement-color. -----
	-- this block is an empty foreground block. we mark it as "processed" by putting the replacement color
	madtulip.Flood_Data_Matrix.Content[cur_Position[1]][cur_Position[2]] = madtulip.Flood_Data_Matrix.replacement_color;
	madtulip.Flood_Data_Matrix.Area = madtulip.Flood_Data_Matrix.Area + 1; -- increment flooded area (starts at 0)
	madtulip.Flood_Data_Matrix.Background_in_scanned_Area[madtulip.Flood_Data_Matrix.Area] = cur_Position;
	
	-- ----- 3. Spawn searches in the surrounding blocks -----
	--	Perform Flood-fill (one step to the west of node, target-color, replacement-color).
	if madtulip.Flood_Data_Matrix.Stop_Iteration == 0 then -- west
		Flood_Fill({cur_Position[1] - 1,cur_Position[2]    });
	end
	if madtulip.Flood_Data_Matrix.Stop_Iteration == 0 then -- east
		Flood_Fill({cur_Position[1] + 1,cur_Position[2]    });
	end
	if madtulip.Flood_Data_Matrix.Stop_Iteration == 0 then -- north
		Flood_Fill({cur_Position[1]    ,cur_Position[2] + 1});
	end
	if madtulip.Flood_Data_Matrix.Stop_Iteration == 0 then -- south
		Flood_Fill({cur_Position[1]    ,cur_Position[2] - 1});
	end
	
	if madtulip.Flood_Data_Matrix.Scan_8_method == 1 then
		if madtulip.Flood_Data_Matrix.Stop_Iteration == 0 then -- north west
			Flood_Fill({cur_Position[1] - 1,cur_Position[2] + 1});
		end
		if madtulip.Flood_Data_Matrix.Stop_Iteration == 0 then -- north east
			Flood_Fill({cur_Position[1] + 1,cur_Position[2] + 1});
		end
		if madtulip.Flood_Data_Matrix.Stop_Iteration == 0 then -- south east
			Flood_Fill({cur_Position[1] + 1,cur_Position[2] - 1});
		end
		if madtulip.Flood_Data_Matrix.Stop_Iteration == 0 then -- south west
			Flood_Fill({cur_Position[1] - 1,cur_Position[2] - 1});
		end
	end
end

function set_flood_data_matrix_content (X,Y,Content)
	if    (X >= madtulip.Flood_Data_Matrix.X_min)
	   and(X <= madtulip.Flood_Data_Matrix.X_max)
	   and(Y >= madtulip.Flood_Data_Matrix.Y_min)
	   and(Y <= madtulip.Flood_Data_Matrix.Y_max) then
			madtulip.Flood_Data_Matrix.Content[X][Y] = Content;
	   end
end