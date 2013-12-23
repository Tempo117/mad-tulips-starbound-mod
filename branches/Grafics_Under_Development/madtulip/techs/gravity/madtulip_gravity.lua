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

	tech.xControl(0+v_x, 0+a_x, false);
	tech.yControl(0+v_y, 100+a_y, false);

	return 0;
end
