function initializeObject()
	-- Make our object interactive (we can interract by 'Use')
	object.setInteractive(true);
	
	-- Change animation for state "normal_operation"
	object.setAnimationState("DisplayState", "no_vent");
	
	-- globals
	On_Off_State = 1; -- "1:ON,2:OFF"
	maximum_particle_fountains = 50;
	
	-- spawn a new main calculation thread
	co = coroutine.create(function ()
		-- Automatic Hull Breach Scans for all Vents in the Area
		Multistage_Scan_all_Vents_in_the_Area(1000);
	 end)
end

function kill_self()
	world.spawnItem("madtulip_life_support_system", object.toAbsolutePosition({ 0.0, 0.0 }));
	object.smash();
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
	local madtulip_life_support_system_Ids  = world.objectQuery (object.toAbsolutePosition({ 0.0, 0.0 }),1000,{name = "madtulip_life_support_system"});
	for _, madtulip_life_support_system_Id in pairs(madtulip_life_support_system_Ids) do
		if (madtulip_life_support_system_Id > object.id()) then
			world.callScriptedEntity(madtulip_life_support_system_Id, "kill_self");
		end
	end
	
	--Multistage_Scan_all_Vents_in_the_Area(1000);
	if (coroutine.status(co) == "suspended") then
		-- start thread
		coroutine.resume(co);
	elseif (coroutine.status(co) == "dead") then
		-- spawn a new main calculation thread
		co = coroutine.create(function ()
			-- Automatic Hull Breach Scans for all Vents in the Area
			Multistage_Scan_all_Vents_in_the_Area(1000);
		 end)
	elseif (coroutine.status(co) == "running") then
		-- nothing
	end
end

function onInteraction(args)
	-- if clicked by middle mouse or "e"
	
	-- here you can switch the main unit and all slaves off
	if(On_Off_State == 1) then
		On_Off_State = 2;
		object.setAnimationState("DisplayState", "offline");
	else
		On_Off_State = 1;
		object.setAnimationState("DisplayState", "no_vent");
	end
end

function Multistage_Scan_all_Vents_in_the_Area(Range)
	-- Range: range from life support system in blocks in which to search for vents
	
	Nr_of_all_vents = 0;
	Postion_of_all_vents = {};
	IDs_of_all_vents = {};
	
	local Scan_Results = {};
	Scan_Results.Counter_Nr_Vents_Processed = 0;
	Scan_Results.Nr_Vent_Ids_overlapping    = 0;
	Scan_Results.Vent_Ids_overlapping       = {};
	-- while looping over all vents the global results of all flood fill scans are saved here
	Scan_Results.ANY_Room_is_not_enclosed = 0;
	Scan_Results.ANY_Background_breach    = 0;
	Scan_Results.ANY_BREACHES             = {};
	Scan_Results.counter_breaches         = 0;
	-- while looping over all vents the results of theire flood fill scans are saved here
	Scan_Results.SINGLE_VENTS_ID                   = {};
	Scan_Results.SINGLE_VENTS_WAS_SKIPPED          = {};
	Scan_Results.SINGLE_VENTS_Room_is_not_enclosed = {};
	Scan_Results.SINGLE_VENTS_Background_breach    = {};
	Scan_Results.SINGLE_VENTS_BREACHES             = {};
	
	-- find all vents in the area and get theire position
	local Vents_Ids  = world.objectQuery (object.toAbsolutePosition({ 0.0, 0.0 }),Range,{name = "madtulip_vent"});
	-- Perform scan for hull breach using each vents origin as point to start an individual scan
	
	for _, Vents_Id in pairs(Vents_Ids) do
		Nr_of_all_vents = Nr_of_all_vents+1;
		Postion_of_all_vents[Nr_of_all_vents] = world.entityPosition (Vents_Id);
		IDs_of_all_vents[Nr_of_all_vents] = Vents_Id;
	end
	
	-- check for master system beeing offline
	if (On_Off_State ~= 1) then
		-- master is offline
		object.setAnimationState("DisplayState", "offline");
		for _, Vents_Id in pairs(Vents_Ids) do
			-- set vens offline as well
			world.callScriptedEntity(Vents_Id, "set_O2_Offline_State");
		end
	else
		-- master is online
		-- default animation: no ventilators found
		object.setAnimationState("DisplayState", "no_vent");

		----- Scan all vents -----
--world.logInfo ("SCAN ALL VENTS")
		for _, Vents_Id in pairs(Vents_Ids) do
--world.logInfo ("next vent")
			-- check if the current vent was already implicitly tested by beeing flooded by another earlier tested vent
			local process_this_vent; -- bool
			process_this_vent = 1;
--world.logInfo ({"Nr_overlapping:",Scan_Results.Nr_Vent_Ids_overlapping})
			for n = 1,Scan_Results.Nr_Vent_Ids_overlapping,1 do
--world.logInfo ({"comparing:",Scan_Results.Vent_Ids_overlapping[n],Vents_Id})
				if(Scan_Results.Vent_Ids_overlapping[n] == Vents_Id) then
					-- it was hit already, dont test this again.
					process_this_vent = 0;
--world.logInfo ("found one to skip")
				end
			end
			if (process_this_vent == 1) then
--world.logInfo ("processing vent")
				-- inc counter
				Scan_Results.Counter_Nr_Vents_Processed = Scan_Results.Counter_Nr_Vents_Processed +1;
				
				-- expensive call (start flood fill for the current Vent)
				Automatic_Multi_Stage_Scan((world.entityPosition (Vents_Id)),{50,250,1000});
				
				-- save the impact of this current Vent on the Life Support Main "breached" or "not breached" status
				if (Flood_Data_Matrix.Room_is_not_enclosed == 1) then
					-- globally this is also true (one is enough)
					Scan_Results.ANY_Room_is_not_enclosed = 1;
					if (Flood_Data_Matrix.Background_breach == 1) then
						-- its a defined background breach. no out of memory or iteration counter
						Scan_Results.ANY_Background_breach    = 1;		
					end
				end
				
				-- save states of the currently checked vent
				Scan_Results.SINGLE_VENTS_ID[Scan_Results.Counter_Nr_Vents_Processed]       = Vents_Id;
				Scan_Results.SINGLE_VENTS_BREACHES[Scan_Results.Counter_Nr_Vents_Processed] = Flood_Data_Matrix.Breaches;
				for _, Breach_Location in pairs(Flood_Data_Matrix.Breaches) do
					Scan_Results.counter_breaches = Scan_Results.counter_breaches +1;
					Scan_Results.ANY_BREACHES[Scan_Results.counter_breaches] = Breach_Location;
				end
				Scan_Results.SINGLE_VENTS_WAS_SKIPPED[Scan_Results.Counter_Nr_Vents_Processed]              = 0;
				if (Flood_Data_Matrix.Room_is_not_enclosed == 1) then
					Scan_Results.SINGLE_VENTS_Room_is_not_enclosed[Scan_Results.Counter_Nr_Vents_Processed] = 1;
				else
					Scan_Results.SINGLE_VENTS_Room_is_not_enclosed[Scan_Results.Counter_Nr_Vents_Processed] = 0;
				end
				if (Flood_Data_Matrix.Background_breach == 1) then
					Scan_Results.SINGLE_VENTS_Background_breach[Scan_Results.Counter_Nr_Vents_Processed]    = 1;
				else
					Scan_Results.SINGLE_VENTS_Background_breach[Scan_Results.Counter_Nr_Vents_Processed]    = 0;
				end
				
				-- if other vents the the current one where flooded by the current one
				for cur_overlapping_vent_nr = 1 ,Flood_Data_Matrix.Nr_Vent_Ids_overlapping,1 do
					local this_vent_is_already_know_for_overlapping = 0;
					for n = 1,Scan_Results.Nr_Vent_Ids_overlapping,1 do
						if(Scan_Results.Vent_Ids_overlapping[Scan_Results.Nr_Vent_Ids_overlapping] == Flood_Data_Matrix.Vent_Ids_overlapping[cur_overlapping_vent_nr]) then
							-- it was not known that theese two vents share the same flooded plain
							this_vent_is_already_know_for_overlapping = 1;
						end
					end
					
					if not (this_vent_is_already_know_for_overlapping == 1) then
						-- register the newly found redundant vent here
						Scan_Results.Nr_Vent_Ids_overlapping = Scan_Results.Nr_Vent_Ids_overlapping+1;
						Scan_Results.Vent_Ids_overlapping[Scan_Results.Nr_Vent_Ids_overlapping] = Flood_Data_Matrix.Vent_Ids_overlapping[cur_overlapping_vent_nr];
						
						-- save the state of the redundant vent. its the same as the state of the current one
						Scan_Results.Counter_Nr_Vents_Processed = Scan_Results.Counter_Nr_Vents_Processed +1;
						
						Scan_Results.SINGLE_VENTS_ID[Scan_Results.Counter_Nr_Vents_Processed]       = Flood_Data_Matrix.Vent_Ids_overlapping[cur_overlapping_vent_nr];
						Scan_Results.SINGLE_VENTS_WAS_SKIPPED[Scan_Results.Counter_Nr_Vents_Processed]              = 1;
						if (Flood_Data_Matrix.Room_is_not_enclosed == 1) then
							Scan_Results.SINGLE_VENTS_Room_is_not_enclosed[Scan_Results.Counter_Nr_Vents_Processed] = 1;
						else
							Scan_Results.SINGLE_VENTS_Room_is_not_enclosed[Scan_Results.Counter_Nr_Vents_Processed] = 0;
						end
						if (Flood_Data_Matrix.Background_breach == 1) then
							Scan_Results.SINGLE_VENTS_Background_breach[Scan_Results.Counter_Nr_Vents_Processed]    = 1;
						else
							Scan_Results.SINGLE_VENTS_Background_breach[Scan_Results.Counter_Nr_Vents_Processed]    = 0;
						end
					end
				end
			end
		end
		------- all vents have been scanned -------
		
		------- perform actions -------
		-- if any vents detected at all
		if (Scan_Results.Counter_Nr_Vents_Processed > 0) then
			-- for the master based on the scan results
			if(Scan_Results.ANY_Background_breach == 1) then
				-- play a meeping warning sound
				object.playSound("Breach_Warning_Sound");
			end	
			if (Scan_Results.ANY_Room_is_not_enclosed == 1) then
				-- set animation state of master wall panel to breach
				object.setAnimationState("DisplayState", "breach");
			else
				-- set animation state to normal operation
				object.setAnimationState("DisplayState", "normal_operation");
			end
			
			-- perform actions for each vent based on the scan results
			--local Scan_Results.counter_breaches = 0;
			for cur_Vent_Nr = 1,Scan_Results.Counter_Nr_Vents_Processed,1 do
				if (Scan_Results.SINGLE_VENTS_Room_is_not_enclosed[cur_Vent_Nr] == 1) then
					-- the current Vent is not in a closed room -> display that graficaly
					world.callScriptedEntity(Scan_Results.SINGLE_VENTS_ID[cur_Vent_Nr], "set_O2_BAD_State");
				else
					-- this vents room was not breached -> display that graficaly
					world.callScriptedEntity(Scan_Results.SINGLE_VENTS_ID[cur_Vent_Nr], "set_O2_OK_State");
				end
			end

			-- spawn breach grafics
			-- limit theire number
			if (Scan_Results.counter_breaches > maximum_particle_fountains) then
				-- spawn them (limited amount)
				for cur_particle_fountain_to_generate = 1,maximum_particle_fountains,1 do
					world.spawnProjectile("madtulip_breach", Scan_Results.ANY_BREACHES[math.random(Scan_Results.counter_breaches)]);
				end
			else
				-- spawn them (all)
				for cur_counter_breaches = 1,Scan_Results.counter_breaches,1 do
					world.spawnProjectile("madtulip_breach", Scan_Results.ANY_BREACHES[cur_counter_breaches]);
				end
			end

		end
	end
end

function Automatic_Multi_Stage_Scan(Origin,Scanner_ranges)
	-- first check with very small memory footprint 50 blocks in each direction
	Start_New_Room_Breach_Scan(Origin,Scanner_ranges[1],1);
	if (Flood_Data_Matrix.Room_is_not_enclosed == 1) then
		if (Flood_Data_Matrix.Background_breach ~= 1) then
			-- if no closed room was found we enlargen the search area
			-- this could have been done in the first place, but it takes longer if the initial room is small already
			Start_New_Room_Breach_Scan(Origin,Scanner_ranges[2],1);
			if (Flood_Data_Matrix.Room_is_not_enclosed == 1) then
				if (Flood_Data_Matrix.Background_breach ~= 1) then
					-- if no closed room was found we enlargen the search area
					-- this could have been done in the first place, but it takes longer if the initial room is small already
					Start_New_Room_Breach_Scan(Origin,Scanner_ranges[3],1);
				end
			end
		end
	end
	-- now we stop scanning because a larger area which would be larger then (Scanner_ranges*2+1)^2 blocks uses quite some mem and time.
	-- you can however use Scanner_ranges = 10000 or mor if you like. see how long it takes if you are in a realy large room :)
end

function Start_New_Room_Breach_Scan(Origin,size_to_scan,Scan_8_method)
	-- Input:
	-- size_to_scan:number of block in x and y directions around the origin to scan with flood.if flood runs out of this area, area is marked as not enclosed.
	-- Sca_8_method: Scans west,north, east, south blocks only if ~= 0. Scans diagonal blocks also if == 1
	
	-- create global Flood Data matrix which holds the room which is flooded
	Flood_Data_Matrix               = {}; -- nothing stored here
	-- data
	Flood_Data_Matrix.Content       = {}; -- stores at [x,y] the "color" of the block which tells if its background, foreground or open
	Flood_Data_Matrix.Breaches      = {}; -- stores {x,y} pairs of locations of breach
	Flood_Data_Matrix.Background_in_scanned_Area = {}; -- stores {x,y} pairs of background only (interior) locations of enclosed area
	Flood_Data_Matrix.Vent_Ids_overlapping       = {} -- stroes IDs of Vents that are in the area flooded by the current vent. we dont need to check them again.
	-- settings
	Flood_Data_Matrix.Origin         = Origin;
	Flood_Data_Matrix.size_to_scan   = size_to_scan;
	Flood_Data_Matrix.X_min          = Origin[1] - size_to_scan;
	Flood_Data_Matrix.X_max          = Origin[1] + size_to_scan;
	Flood_Data_Matrix.Y_min          = Origin[2] - size_to_scan;
	Flood_Data_Matrix.Y_max          = Origin[2] + size_to_scan;
	Flood_Data_Matrix.Max_Iteration  = ((size_to_scan*2)+1)*((size_to_scan*2)+1); -- maximum room size. if the room is larger this will terminate early stating that the room is not closed
	Flood_Data_Matrix.Scan_8_method  = Scan_8_method; -- if == 0 scan 4 surrounding blocks (W,N,E,S) else scan also the 4 diagonal corners
	Flood_Data_Matrix.max_door_hight_top    = 5;
	Flood_Data_Matrix.max_door_hight_bottom = 5;
	Flood_Data_Matrix.target_color          = 1;
	Flood_Data_Matrix.none_target_color     = 2;
	Flood_Data_Matrix.replacement_color     = 3;
	-- counter
	Flood_Data_Matrix.Area                    = 0; -- counts the area filled with flood
	Flood_Data_Matrix.Cur_Iteration           = 0; -- counter for number of iterations done so far
	Flood_Data_Matrix.Nr_of_Breaches          = 0; -- counter for number of breaches detected
	Flood_Data_Matrix.Nr_Vent_Ids_overlapping = 0; -- counts how many other ventilators area beeing flooded by this one. we dont want to run those again.
	-- bools
	Flood_Data_Matrix.Stop_Iteration       = 0; -- bool
	Flood_Data_Matrix.Room_is_not_enclosed = 0; -- bool
	-- flags after breaking condition has been reached
	Flood_Data_Matrix.Background_breach            = 0; -- not enclose due to hole in the back wall
	Flood_Data_Matrix.Background_Breach_Location   = {};
	Flood_Data_Matrix.Max_Nr_of_Iterations_happend = 0; -- enclosure couldn't be found in maximum number of iteration steps
	Flood_Data_Matrix.Maximum_size_to_scan_reached = 0;

	-- init data matrix memory for flood fill
	for cur_X = Flood_Data_Matrix.X_min,Flood_Data_Matrix.X_max,1 do
		Flood_Data_Matrix.Content[cur_X] = {};
		for cur_Y = Flood_Data_Matrix.Y_min,Flood_Data_Matrix.Y_max,1 do
			Flood_Data_Matrix.Content[cur_X][cur_Y] = {};
		end	
	end
	
	-- check for doors in the area first
	Prepare_Doors_for_Flood_Fill();
	
	-- test the area around the block where this is placed for beeing an enclosed room
	Flood_Fill(Flood_Data_Matrix.Origin,1,2,3);
end

function Prepare_Doors_for_Flood_Fill()
	-- add additional information about surrounding, like doors
	local radius_to_scan = Flood_Data_Matrix.size_to_scan*2;
	local closedDoorIds  = world.objectQuery (Flood_Data_Matrix.Origin, radius_to_scan, { callScript = "hasCapability", callScriptArgs = { "closedDoor" } });
	
	if (closedDoorIds == nil) then
		-- no doors found, nothing to do
		return;
	end
	
	local top_block_found     = 0; -- if a block at the top boarder of the door has been found
	local bottom_block_found  = 0;-- if a block at the bottom boarder of the door has been found
	local iteration_counter   = 0;	
	
	-- for all closed doors in vicinity, get theire coordinates
	for _, closedDoorId in pairs(closedDoorIds) do
		local cur_Door_Position = world.entityPosition (closedDoorId);
		if (cur_Door_Position == nil) then
			-- bad position, cath it
			return;
		end					
		
		-- check blocks straight north of the door.
		-- if they are empty mark as processed, we are in the door. flood will not go over this block later
		-- if they are a block we have reached the end of the door (upper frame) -> stop		
		top_block_found   = 0; -- if a block at the top boarder of the door has been found
		iteration_counter = 0;
		while (top_block_found == 0) do
			if (Flood_Data_Matrix.Y_max > cur_Door_Position[2]) then
				if world.material({cur_Door_Position[1] ,cur_Door_Position[2] + iteration_counter}, "foreground") == nil then
					-- still no foreground, we are IN the door
					Flood_Data_Matrix.Content[cur_Door_Position[1]][cur_Door_Position[2] + iteration_counter] = Flood_Data_Matrix.replacement_color;
				else
					-- its a block. mark this position as checked.
					Flood_Data_Matrix.Content[cur_Door_Position[1]][cur_Door_Position[2] + iteration_counter] = Flood_Data_Matrix.replacement_color;
					if (iteration_counter == 0) then
						-- we are at the root block of the door
						if world.material({cur_Door_Position[1] ,cur_Door_Position[2] + iteration_counter+1}, "foreground") == nil then
							-- above is clear so this must be bottom block of the door (if the door has a hole in the blocks at all)
							bottom_block_found = 1;
						end
					else
						if world.material({cur_Door_Position[1] ,cur_Door_Position[2] + iteration_counter-1}, "foreground") == nil then
							-- below is clear so this must be top block of the door (if the door has a hole in the blocks at all)
							top_block_found = 1;
						end
					end
				end
				if (iteration_counter >= Flood_Data_Matrix.max_door_hight_top) then
					top_block_found =1;
				end
			else
				-- break because we left the upper boarder of initialized memory
				top_block_found =1;
			end
			iteration_counter = iteration_counter+1;
		end

		-- check blocks straight south of the door.
		-- if they are empty mark as processed, we are in the door. flood will not go over this block later
		-- if they are a block we have reached the end of the door (upper frame) -> stop		
		--cur_position = world.entityPosition (closedDoorId);
		iteration_counter = -1;
		while (bottom_block_found == 0) do
			if (Flood_Data_Matrix.Y_min < cur_Door_Position[2]) then
				if world.material({cur_Door_Position[1] ,cur_Door_Position[2] + iteration_counter}, "foreground") == nil then
					-- still no foreground, we are IN the door
					Flood_Data_Matrix.Content[cur_Door_Position[1]][cur_Door_Position[2] + iteration_counter] = Flood_Data_Matrix.replacement_color;
				else
					-- its a block. mark this position as checked.
					Flood_Data_Matrix.Content[cur_Door_Position[1]][cur_Door_Position[2] + iteration_counter] = Flood_Data_Matrix.replacement_color;
					-- lower doorframe reached - stop
					bottom_block_found = 1;
				end
				if (iteration_counter <= -Flood_Data_Matrix.max_door_hight_bottom) then
					-- break because maximum iteration counter has been reached
					bottom_block_found =1;
				end
			else
				-- break because we left the upper boarder of initialized memory
				bottom_block_found =1;
			end
			iteration_counter = iteration_counter -1;
		end
	end
end

function Flood_Fill(cur_Position)
	--  ----- ITERATION BREAKING CONDITIONS: -----
	-- if some step of the iteration already determined to stop iteration
	if Flood_Data_Matrix.Stop_Iteration == 1 then
		return;
	end
	-- if this block has already been scanned
	if Flood_Data_Matrix.Content[cur_Position[1]][cur_Position[2]] == Flood_Data_Matrix.replacement_color then
		-- we have already been here
		return;
	end
	if Flood_Data_Matrix.Content[cur_Position[1]][cur_Position[2]] == Flood_Data_Matrix.none_target_color then
		-- we have already been here
		return;
	end	
	-- if we leave assigned memory size
	if (cur_Position[1] < Flood_Data_Matrix.X_min) then
		Flood_Data_Matrix.Maximum_size_to_scan_reached = 1;
		Flood_Data_Matrix.Stop_Iteration = 1;
		return;
	end
	if (cur_Position[1] > Flood_Data_Matrix.X_max) then
		Flood_Data_Matrix.Maximum_size_to_scan_reached = 1;
		Flood_Data_Matrix.Stop_Iteration = 1;
		return;
	end
	if (cur_Position[2] < Flood_Data_Matrix.Y_min) then
		Flood_Data_Matrix.Maximum_size_to_scan_reached = 1;
		Flood_Data_Matrix.Stop_Iteration = 1;
		return;
	end
	if (cur_Position[2] > Flood_Data_Matrix.Y_max) then
		Flood_Data_Matrix.Maximum_size_to_scan_reached = 1;
		Flood_Data_Matrix.Stop_Iteration = 1;
		return;
	end
	-- if maximum number of iterations is reached
	if (Flood_Data_Matrix.Cur_Iteration > Flood_Data_Matrix.Max_Iteration) then
		-- iteration limit reached
		Flood_Data_Matrix.Room_is_not_enclosed          = 1; -- set flag
		Flood_Data_Matrix.Max_Nr_of_Iterations_happend  = 1; -- set flag
		Flood_Data_Matrix.Stop_Iteration                = 1; -- break iteration
	end
	
	if (Flood_Data_Matrix.Cur_Iteration > 0) then
		-- the first iteration checks the vent which initiated this fllod
		for n=1,Nr_of_all_vents,1 do
			local cur_vent_position = Postion_of_all_vents[n];
			if (cur_Position[1] == cur_vent_position[1])and(cur_Position[2] == cur_vent_position[2]) then
				-- there is another vents beeing flooded. we dont need to search that again, it will have the same result as the current one.
				Flood_Data_Matrix.Nr_Vent_Ids_overlapping = Flood_Data_Matrix.Nr_Vent_Ids_overlapping +1;
				Flood_Data_Matrix.Vent_Ids_overlapping[Flood_Data_Matrix.Nr_Vent_Ids_overlapping] = IDs_of_all_vents[n];
			end
		end
	end
	
	-- ----- so far we are good, take next step in the state machine -----
	-- increment iteration step
	Flood_Data_Matrix.Cur_Iteration = Flood_Data_Matrix.Cur_Iteration + 1;
	
	-- check if there is a foreground block
	--  ,if not then check if there is a background block
	--  ,if also not its a breach.
	-- write the gathered info to "Flood_Data_Matrix.Content[x,y]" which is the data object used further on
	if world.material(cur_Position, "foreground") == nil then
		-- nil foreground block found. This is our target.
		Flood_Data_Matrix.Content[cur_Position[1]][cur_Position[2]] = Flood_Data_Matrix.target_color;
		-- if this is also a nil background block we have a breach that we might or might not be aware of yet
		if  world.material(cur_Position, "background") == nil then
		
			-- its a bachground breach that we have not been aware of!
			Flood_Data_Matrix.Nr_of_Breaches = Flood_Data_Matrix.Nr_of_Breaches+1;-- inc counter for breaches
			Flood_Data_Matrix.Breaches[Flood_Data_Matrix.Nr_of_Breaches] = cur_Position;-- store location of breach
			Flood_Data_Matrix.Room_is_not_enclosed       = 1; -- set flag that the room is open
			Flood_Data_Matrix.Background_breach          = 1; -- not enclose due to hole in the background
			
			-- we did hit the a breach here, don`t spawn further searches from this block
			Flood_Data_Matrix.Content[cur_Position[1]][cur_Position[2]] = Flood_Data_Matrix.none_target_color;
			return;
		end
	else
		-- an existing foreground block is a none target
		-- we did hit the wall here, don`t spawn further searches from this block
		Flood_Data_Matrix.Content[cur_Position[1]][cur_Position[2]] = Flood_Data_Matrix.none_target_color;
	end

	--  ----- 1. If the "color" of current node is not equal to target-color, return. -----
	if (Flood_Data_Matrix.Content[cur_Position[1]][cur_Position[2]] ~= Flood_Data_Matrix.target_color) then
		-- the current block is not an open foreground space -> don`t spawn further searches from this block
		return;
	end
	
	-- ----- 2. Set the color of node to replacement-color. -----
	-- this block is an empty foreground block. we mark it as "processed" by putting the replacement color
	Flood_Data_Matrix.Content[cur_Position[1]][cur_Position[2]] = Flood_Data_Matrix.replacement_color;
	Flood_Data_Matrix.Area = Flood_Data_Matrix.Area + 1; -- increment flooded area (starts at 0)
	Flood_Data_Matrix.Background_in_scanned_Area[Flood_Data_Matrix.Area] = cur_Position;
	
	-- ----- 3. Spawn searches in the surrounding blocks -----
	--	Perform Flood-fill (one step to the west of node, target-color, replacement-color).
	if Flood_Data_Matrix.Stop_Iteration == 0 then -- west
		Flood_Fill({cur_Position[1] - 1,cur_Position[2]    });
	end
	if Flood_Data_Matrix.Stop_Iteration == 0 then -- east
		Flood_Fill({cur_Position[1] + 1,cur_Position[2]    });
	end
	if Flood_Data_Matrix.Stop_Iteration == 0 then -- north
		Flood_Fill({cur_Position[1]    ,cur_Position[2] + 1});
	end
	if Flood_Data_Matrix.Stop_Iteration == 0 then -- south
		Flood_Fill({cur_Position[1]    ,cur_Position[2] - 1});
	end
	
	if Flood_Data_Matrix.Scan_8_method == 1 then
		if Flood_Data_Matrix.Stop_Iteration == 0 then -- north west
			Flood_Fill({cur_Position[1] - 1,cur_Position[2] + 1});
		end
		if Flood_Data_Matrix.Stop_Iteration == 0 then -- north east
			Flood_Fill({cur_Position[1] + 1,cur_Position[2] + 1});
		end
		if Flood_Data_Matrix.Stop_Iteration == 0 then -- south east
			Flood_Fill({cur_Position[1] + 1,cur_Position[2] - 1});
		end
		if Flood_Data_Matrix.Stop_Iteration == 0 then -- south west
			Flood_Fill({cur_Position[1] - 1,cur_Position[2] - 1});
		end
	end
end