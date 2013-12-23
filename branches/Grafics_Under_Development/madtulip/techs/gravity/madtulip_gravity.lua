function init()
	tech.setAnimationState("dummy_nothing", "off");
end

function input(args)

	-- default
	data.holdingJump = false;
	data.holdingLeft = false;
	data.holdingRight = false;
	data.holdingUp = false;
	data.holdingDown = false;

	-- jump
	if args.moves["jump"] and tech.jumping() then data.holdingJump = true end
	--move left
	if args.moves["left"] then data.holdingLeft = true end
	--move right
	if args.moves["right"] then data.holdingRight = true end
	--move up
	if args.moves["up"] then data.holdingUp = true end
	--move down
	if args.moves["down"] then data.holdingDown = true end

	return 0;
end

function update(args)
	local Range = 4; -- range of blocks around the player that need to be void to be "in space"
	if (determine_if_ZERO_gravity(Range)) then
		use_ZERO_gravity_movement();
	end
	return 0;
end

function determine_if_ZERO_gravity(Range)

--world.logInfo ("START");
--for cur_X = 1,10,1 do
--	for cur_Y = 1,10,1 do
		--world.logInfo ({world.material({cur_X,cur_Y}, "foreground")});
	--end
--end
--world.logInfo ("END");

--	if(world.material({1,1}, "background") ~= "apexshipdetails") then
		--world.logInfo ("RETURNING");
		--return false;
	--end

--world.logInfo ("START");
	--local We_are_in_Shipworld = false;
	--local Flag_Ids  = world.objectQuery (tech.position(),5000,{name = "madtulip_flag_shipworld"});
--world.logInfo ({Flag_Ids});
	-- Perform scan for hull breach using each vents origin as point to start an individual scan
	--for _, Flag_Id in pairs(Flag_Ids) do
--world.logInfo ({Flag_Id});
		--world.logInfo ({world.entityPosition (Flag_Id)});
--world.logInfo ({world.logInfo ({world.entityPosition (Flag_Id)});});
		--world.entityPosition (Flag_Id);
		--world.logInfo ("HIT!");
		--We_are_in_Shipworld = true;
	--end
	
	--if (We_are_in_Shipworld ~= true) then
--world.logInfo ("RETURNING");
		--return false;
	--end



	--if (storage ~= nil) then
	--	world.logInfo ("1)");
--		if (storage.Flags ~= nil) then
			--world.logInfo ("2)");
		--	world.logInfo ({storage.Flags.this_is_the_shipworld});	
	--		if not(storage.Flags.this_is_the_shipworld == true) then
--world.logInfo ("--- shipworld FLAG not found ---");
		--		return 0;
	--		end
--		end
	--end

	local Origin = tech.position();
	-- we assume Zero gravity unless we find blocks in the vicinity
	local Zero_gravity = true;
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
				Zero_gravity = false;
			end
		end	
	end
	
	return Zero_gravity;
end

function use_ZERO_gravity_movement()
	-- setup movement vector
	local v_x = 0;
	local v_y = 0;
	local a_x = 0;
	local a_y = 0;
	if data.holdingUp then
		v_y = 2;
	end
	if data.holdingDown then
		v_y = -2;
	end
	if data.holdingLeft then
		v_x = -2;
		a_x = 50;
	end
	if data.holdingRight then
		v_x = 2;
		a_x = 50;
	end

	-- execute movement vector
	tech.xControl(0+v_x, 0+a_x, false);
	tech.yControl(0+v_y, 100+a_y, false);
end