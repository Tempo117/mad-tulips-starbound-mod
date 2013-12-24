function initializeObject()
	-- Make our entity interactive (we can interract by 'Use')
	entity.setInteractive(true);
	-- Change animation for state "active"
	entity.setAnimationState("beaconState", "active");
end

function main()
	-- Check for the single execution
	if self.initialized == nil then
		-- Init entity
		initializeObject();
		-- Set flag
		self.initialized = true;
	end
end

function onInteraction(args)
	-- if clicked by middle mouse or "e"
	-- define a square:
	--Scan_ENV_context();
	--Scan_world_context();
	--Scan_entity_context();
	--Scan_Objects();
	
    local Origin = entity.toAbsolutePosition({ 0.0, 0.0 });
	local Range = 1500;
	-- gather data about blocks at those locations
	local Data = {};
	Data = Scan_Area_for_Dead_Content(Origin, Range);
	-- debug out the gathered data
	--return { "ShowPopup", { message = {Data.Material.Position,Data.Material.foreground,Data.Material.background} } };
	return ("OpenCockpitInterface");
end

function Scan_ENV_context()
	world.logInfo("----------START _ENV Scan---------")
	for key,value in pairs(_ENV) do
		world.logInfo({key});
		--world.logInfo({value});
	end
	world.logInfo("----------END _ENV Scan-----------")
end

function Scan_world_context()
	world.logInfo("----------START World Scan---------")
	for key,value in pairs(world) do
		world.logInfo({key});
		--world.logInfo({value});
	end
	world.logInfo("----------END World Scan-----------")
end

function Scan_entity_context()
	world.logInfo("----------START Entity Scan---------")
	for key,value in pairs(entity) do
		world.logInfo({key});
		--world.logInfo({value});
	end
	world.logInfo("----------END Entity Scan-----------")
end

function Scan_Objects ()
	-- entity.configParameter
	world.logInfo ("----------START Object Scan---------");
		world.logInfo ("My name is (by entity.configparameter):");
		world.logInfo (entity.configParameter("objectName"));
		world.logInfo ("My name is (world.entityName):");
		world.logInfo (world.entityName(entity.id()));
		world.logInfo ("your names are:");
		local ObjectIds = world.entityQuery (entity.toAbsolutePosition({ 0.0, 0.0 }), 10000);
		for _, ObjectId in pairs(ObjectIds) do
			-- Name
			world.logInfo({"Name for ID (by call scripted entity):",ObjectId});
			if ((world.callScriptedEntity(ObjectId, "entity.configParameter", "objectName")) ~= nil) then
				world.logInfo(world.callScriptedEntity(ObjectId, "entity.configParameter", "objectName"));
				if ((world.callScriptedEntity(ObjectId, "entity.configParameter", "objectType")) == "container") then
					world.logInfo("It has objectType = container. the entity is:");
					world.logInfo(world.callScriptedEntity(ObjectId, "entity"));
				end
			else
				world.logInfo("name is nil");
			end
			
			world.logInfo({"Name for ID (by world.entityName):",ObjectId});
			if ((world.entityName(ObjectId)) ~= nil) then
				world.logInfo(world.entityName(ObjectId));
			else
				world.logInfo("name is nil");
			end
			-- position
			world.logInfo({"Position for ID:",ObjectId});
			if ((world.entityPosition(ObjectId)) ~= nil) then
				world.logInfo(world.entityPosition(ObjectId));
			else
				world.logInfo("position is nil");
			end
		end
	world.logInfo ("----------END Object Scan---------");
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
		
		-- store entity content here
		Data.Object              = {};
		Data.Object.size         = 0;
		Data.Object.Position     = {};
		Data.Object.Name         = {};

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

	world.logInfo ("----------START Object Scan---------");
	local ObjectIds = world.entityQuery (entity.toAbsolutePosition({ 0.0, 0.0 }), Range);
	for _, ObjectId in pairs(ObjectIds) do
		Data.Object.size                       = Data.Object.size + 1;
		Data.Object.Name[Data.Object.size]     = world.entityName(ObjectId);
		Data.Object.Position[Data.Object.size] = world.entityPosition(ObjectId);
		
		world.logInfo (Data.Object.size);
		world.logInfo (Data.Object.Name[Data.Object.size]);
		world.logInfo (Data.Object.Position[Data.Object.size]);
	end
	world.logInfo ("----------END Object Scan---------");
	
	return (Data);
end
