function initializeObject()
	-- Make our object interactive (we can interract by 'Use')
	object.setInteractive(true);
	
	-- Change animation for state "normal_operation"
	object.setAnimationState("DisplayState", "normal_operation");
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
	
    -- Perform scan for hull breach
	Automatic_Multi_Stage_Scan();
end

function onInteraction(args)

	-- if clicked by middle mouse or "e"
	
	-- Perform scan for hull breach
	Automatic_Multi_Stage_Scan();

	-- so lets give debug feedback about the result which is stored in a global variable
	-- if we had nice write permission lua by now we could even do something with the result here.
	if (Flood_Data_Matrix.Room_is_not_enclosed == 1) then
		-- no closed room found
		-- what was the reason ?
		if (Flood_Data_Matrix.Background_breach == 1) then
			-- there was an open background tile
			local relative_breach_position = {};
			local first_detected_breach_location = Flood_Data_Matrix.Breaches[1];
			relative_breach_position[1] = first_detected_breach_location[1] - Flood_Data_Matrix.Origin[1];
			relative_breach_position[2] = first_detected_breach_location[2] - Flood_Data_Matrix.Origin[2];
			return { "ShowPopup", { message = {"Hull breach detected!",
											   " First breach at [x,y] absolute:",first_detected_breach_location,
											   " [x,y] relative:",relative_breach_position,
											   " Total Nr. of breaches:",Flood_Data_Matrix.Nr_of_Breaches,
											   " Total area of room:",Flood_Data_Matrix.Area}}};
		end
		if (Flood_Data_Matrix.Max_Nr_of_Iterations_happend == 1) then
			-- there was an open background tile
			return { "ShowPopup", { message = {"Max Nr. of iterations happend!",
											   " Total area of room:",Flood_Data_Matrix.Area,
											   " Nr_Iterations:",Flood_Data_Matrix.Cur_Iteration}}};
		end
		if (Flood_Data_Matrix.Maximum_size_to_scan_reached == 1) then
			-- there was an open background tile
			return { "ShowPopup", { message = {"Max size to scan reached!",
											   " Total area of Room:",Flood_Data_Matrix.Area,
											   " Nr_Iterations:",Flood_Data_Matrix.Cur_Iteration}}};
		end
	else
		return { "ShowPopup", { message = {"Room is hermetically sealed!",
										   " Area of room:",Flood_Data_Matrix.Area}}};
	end
end

function Automatic_Multi_Stage_Scan()
	-- check a +-50,+-50 square area around the Origin for a closed room
	local Origin          = object.toAbsolutePosition({ 0.0, 0.0 });
	local Scanner_ranges  = {50,250,1000}; -- ....

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
	
	Perform_Action_After_Multistage_Scan();
end

function Perform_Action_After_Multistage_Scan()
	if (Flood_Data_Matrix.Room_is_not_enclosed == 1) then
		-- set animation state to breach!
		object.setAnimationState("DisplayState", "breach");
		object.playSound("Breach_Warning_Sound");
	else
		-- set animation state to breach!
		object.setAnimationState("DisplayState", "normal_operation");
	end
	
	for _, Breach_Location in pairs(Flood_Data_Matrix.Breaches) do
		world.spawnProjectile("madtulip_breach", Breach_Location);
	end
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
	-- settings
	Flood_Data_Matrix.Origin        = Origin;
	Flood_Data_Matrix.size_to_scan  = size_to_scan;
	Flood_Data_Matrix.X_min         = Origin[1] - size_to_scan;
	Flood_Data_Matrix.X_max         = Origin[1] + size_to_scan;
	Flood_Data_Matrix.Y_min         = Origin[2] - size_to_scan;
	Flood_Data_Matrix.Y_max         = Origin[2] + size_to_scan;
	Flood_Data_Matrix.Max_Iteration = ((size_to_scan*2)+1)*((size_to_scan*2)+1); -- maximum room size. if the room is larger this will terminate early stating that the room is not closed
	Flood_Data_Matrix.Scan_8_method = Scan_8_method; -- if == 0 scan 4 surrounding blocks (W,N,E,S) else scan also the 4 diagonal corners
	Flood_Data_Matrix.max_door_hight_top    = 5;
	Flood_Data_Matrix.max_door_hight_bottom = 5;
	Flood_Data_Matrix.target_color          = 1;
	Flood_Data_Matrix.none_target_color     = 2;
	Flood_Data_Matrix.replacement_color     = 3;

	-- counter
	Flood_Data_Matrix.Area = 0; -- counts the area filled with flood
	Flood_Data_Matrix.Cur_Iteration = 0; -- counter for number of iterations done so far
	Flood_Data_Matrix.Nr_of_Breaches = 0; -- counter for number of breaches detected
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
	Flood_Data_Matrix.Area = Flood_Data_Matrix.Area + 1; -- increment flooded area
	
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
	
	if Flood_Data_Matrix.Scan_8_method ~= 0 then
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