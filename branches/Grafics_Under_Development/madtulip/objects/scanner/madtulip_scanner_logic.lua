function initializeObject()
	-- Make our object interactive (we can interract by 'Use')
	object.setInteractive(true);
	-- Change animation for state "active"
	object.setAnimationState("beaconState", "active");
end

function main()
	-- Check for the single execution
	if self.initialized == nil then
		-- Init object
		initializeObject();
		-- Set flag
		self.initialized = true;
	end
end

function onInteraction(args)
	-- if clicked by middle mouse or "e"
	-- define a square:
	  --(origin[1]-Range,origin[1]+Range,origin[2]-Range,origin[2]+Range)
    local Origin = object.toAbsolutePosition({ 0.0, 0.0 });
	local Range = 1;
	
	-- gather data about blocks at those locations
	local Data = {};
	Data = Scan_Area_for_Dead_Content(Origin, Range);
	
	-- get count of i.e. fins and other objects
	-- check if we have enough fins for Data.block_weight 

	-- debug out the gathered data
	if Data.X == nil then
	else
		return { "ShowPopup", { message = {Data.X,Data.Y,Data.background_material,Data.foreground_material} } };
	end
end

function Scan_Area_for_Dead_Content(Origin, Range)
	-- searches area in a square defined by:
	  --(origin[1]-Range,origin[1]+Range,origin[2]-Range,origin[2]+Range)
	-- returns a table containing X,Y coordinates and for each of them
	  -- name of foreground block
	  -- name of backgroundground block
	
	-- init
	local Data   = {};
	local Data.X = {};
	local Data.Y = {};
	local Data.block_weight        = 0;
	local Data.background_material = {};
	local Data.foreground_material = {};
	local cur_Position             = {};
	local cur_foreground_material  = {};
	local cur_background_material  = {};
	local n = 1; -- iteration counter

	-- loop over square area
	for cur_X = Origin[1]-Range, Origin[1]+Range, 1 do
		for cur_Y = Origin[2]-Range, Origin[2]+Range, 1 do
			-- X coordinate where to get data
			cur_Position[1] = Origin[1] + cur_X;
			-- Y coordinate where to get data
			cur_Position[2] = Origin[2] + cur_Y;
			
			-- get block data at that location
			cur_foreground_material = get_foreground_material_at(cur_Position);
			cur_background_material = get_background_material_at(cur_Position);
			-- mod 
			
			-- write the findings at this position to output variable
			Data.X[n] = cur_Position[1];
			Data.Y[n] = cur_Position[2];
			Data.foreground_material[n] = cur_foreground_material;
			Data.background_material[n] = cur_background_material;
			
			-- count foreground and background blocks. if both occupy the same position only one is counted
			if (cur_foreground_material ~= nil) then
				Data.block_weight = Data.block_weight + 1;
			else
				if (background_material ~= nil) then
					Data.block_weight = Data.block_weight + 1;
				end
			end
			
			-- inc loop
			n = n + 1; 
		end	
	end
	
	return (Data);
end

function get_foreground_material_at(Position)
	-- returns name of background block material at Position
	local material = world.material(Position, "foreground")
	if material ~= (nil) then
		-- material exists
		return material;
	else
		-- return value if material doesnt exists
		-- placed here so you could return 0 i.e.
		return "nothing";
	end
end

function get_background_material_at(Position)
	-- returns name of background block material at Position
	local material = world.material(Position, "background")
	if material ~= (nil) then
		-- material exists
		return material;
	else
		-- return value if material doesnt exists
		-- placed here so you could return 0 i.e.
		return "nothing";
	end
end

