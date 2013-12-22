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
    local Origin = object.toAbsolutePosition({ 0.0, 0.0 });
	local Range = 1;
	
	-- gather data about blocks at those locations
	local Data = {};
	Data = Scan_Area_for_Dead_Content(Origin, Range, Range);

	-- debug out the gathered data
	return { "ShowPopup", { message = {Data.Material.Position,Data.Material.foreground,Data.Material.background} } };
end

function Scan_Area_for_Dead_Content(Origin, Range)
	-- searches area in a square defined by:
	  --(origin[1]+Range[1],origin[1]+Range[2],origin[2]+Range[1],origin[2]+Range[2])
	-- returns a table containing X,Y coordinates and for each of them
	  -- name of foreground block
	  -- name of backgroundground block
	
	-- init
	local Data = {};
		-- store material content here
		Data.Material            = {};
		Data.Material.size       = 0;
		Data.Material.Position   = {};
		Data.Material.foreground = {};
		Data.Material.background = {};
		
		-- store object content here
		Data.Object              = {};
		Data.Object.size         = 0;
		Data.Object.Position     = {};
		Data.Object.Type         = {};

	-- loop over square area
	for cur_X = -Range, Range, 1 do
		for cur_Y = -Range, Range, 1 do
			local cur_abs_Position = {};
			-- X coordinate where to get data
			cur_abs_Position[1] = Origin[1] + cur_X;
			-- Y coordinate where to get data
			cur_abs_Position[2] = Origin[2] + cur_Y;
			
			-- get block data at that location only if there is any block to minimize output structs size
			if not((world.material(cur_abs_Position, "foreground") == nil) and (world.material(cur_abs_Position, "background") == nil)) then
				-- write the findings at this position to output variable
				Data.Material.size = Data.Material.size+1;
				Data.Material.Position[Data.Material.size]   = {cur_X, cur_Y}; -- relative coordinates
				Data.Material.foreground[Data.Material.size] = world.material(cur_abs_Position, "foreground");
				Data.Material.background[Data.Material.size] = world.material(cur_abs_Position, "background");
			end
		end	
	end

if(true) then
-- object.configParameter
world.logInfo ("----------START---------");
	world.logInfo ("My name is:");
	world.logInfo (object.configParameter("objectName"));
	world.logInfo ("your names are:");
	local ObjectIds = world.objectQuery (object.toAbsolutePosition({ 0.0, 0.0 }), 10000);
	for _, ObjectId in pairs(ObjectIds) do
		-- works only for .objects which have a "script"
		if ((world.callScriptedEntity(ObjectId, "object.configParameter", "objectName")) ~= nil) then
			world.logInfo(world.callScriptedEntity(ObjectId, "object.configParameter", "objectName"));
			if ((world.callScriptedEntity(ObjectId, "object.configParameter", "objectType")) == "container") then
				world.logInfo(world.callScriptedEntity(ObjectId, "object"));
			end
		else
			world.logInfo("name is nil");
		end
	end
world.logInfo ("----------END---------");
end

if(false) then
-- object.configParameter
world.logInfo ("----------START---------");
	world.logInfo ("My name is:");
	world.logInfo (object.configParameter("objectName"));
	world.logInfo ("your names are:");
	local ObjectIds = world.objectQuery (object.toAbsolutePosition({ 0.0, 0.0 }), 1000);
	for _, ObjectId in pairs(ObjectIds) do
		world.logInfo({"--START of next object with ID:",ObjectId,"---"});
		-- works only for .objects which have a "script"
		if ((world.callScriptedEntity(ObjectId, "object.configParameter", "objectName")) ~= nil) then
			world.logInfo(world.callScriptedEntity(ObjectId, "object.configParameter", "objectName"));
		else
			world.logInfo("name is nil");
			if ((world.callScriptedEntity(ObjectId, "initializeObject", "")) ~= nil) then
				if ((world.callScriptedEntity(ObjectId, "object.configParameter", "objectName")) ~= nil) then
					world.logInfo(world.callScriptedEntity(ObjectId, "object.configParameter", "objectName"));
				else
					world.logInfo("name is still nil");
				end
			else
				world.logInfo("couldnt init object");
			end
		end
		world.logInfo({"--END of current object with ID:",ObjectId,"---"});
	end
world.logInfo ("----------END---------");
end

if(false) then
-- world entityPosition
world.logInfo ("----------START---------");
	world.logInfo ("your positions are:");
	local ObjectIds = world.objectQuery (object.toAbsolutePosition({ 0.0, 0.0 }), 1000);
	for _, ObjectId in pairs(ObjectIds) do
		if ((world.entityPosition(ObjectId)) ~= nil) then
			world.logInfo(world.entityPosition(ObjectId));
		else
			world.logInfo("position is nil");
		end
	end
world.logInfo ("----------END---------");
end

if(false) then
world.logInfo ("----------START---------");
	world.logInfo ("My name is:");
	world.logInfo (object.configParameter("objectName"));
	world.logInfo ("your names are:");
	local ObjectIds = world.objectQuery (object.toAbsolutePosition({ 0.0, 0.0 }), 1000);
	for _, ObjectId in pairs(ObjectIds) do
		for key,value in pairs(world.callScriptedEntity(ObjectId)) do
			world.logInfo  (key);
		end
	end
world.logInfo ("----------END---------");
end

	-- get all objects
	--local ObjectIds = world.objectQuery ({1000,1000}, 1000);
--world.logInfo ("----------START---------")
	--for _, ObjectId in pairs(ObjectIds) do
		--Data.Object.size = Data.Object.size+1;
		--local cur_Obj_Position = world.entityPosition(ObjectId);
		--Data.Object.Position[Data.Object.size] = {cur_Obj_Position[1] - Origin[1], cur_Obj_Position[2] - Origin[2]}; -- store relative coordinates
		--if ((world.logInfo(world.callScriptedEntity(ObjectId, "configParameter", {"objectName"}))) ~= nil) then
			--world.logInfo(world.callScriptedEntity(ObjectId, "configParameter", "objectName"));
		--else
			--world.logInfo("nix");
		--end
	--end
--world.logInfo ("----------END---------")
		--	Data.Object              = {};
		--Data.Object.size         = 0;
		--Data.Object.Position   = {};
		--Data.Object.Type       = {};
		
--world.logInfo ("----------START---------")
	--for key,value in pairs(object) do
		--world.logInfo  (key)
	--end
--world.logInfo ("******END*******")
	
	return (Data);
end

function data_in(Data)
	g_Data = Data; -- store global in the context of the thread
end
