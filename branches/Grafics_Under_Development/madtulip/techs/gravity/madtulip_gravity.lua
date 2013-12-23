function init()
  data.holdingJump = false
  data.ranOut = false
  
  tech.setAnimationState("jetpack", "off");
end

function input(args)
  -- jump
  if args.moves["jump"] and tech.jumping() then
    data.holdingJump = true
  elseif not args.moves["jump"] then
    data.holdingJump = false
  end
  
  --move left
  if args.moves["left"] then
    data.holdingLeft = true
  else
    data.holdingLeft = false
  end
  --move right
  if args.moves["right"] then
    data.holdingRight = true
  else
    data.holdingRight = false
  end
  --move up
  if args.moves["up"] then
    data.holdingUp = true
  else
    data.holdingUp = false
  end
  --move down
  if args.moves["down"] then
    data.holdingDown = true
  else
    data.holdingDown = false
  end

  return 0;
end

function update(args)
  local Speed_Y = tech.parameter("Speed_Y")
  local ControlForce_Y = tech.parameter("ControlForce_Y")
  local energyUsagePerSecond = tech.parameter("energyUsagePerSecond")
  local energyUsage = energyUsagePerSecond * args.dt

  if args.availableEnergy < energyUsage then
    data.ranOut = true
  elseif tech.onGround() or tech.inLiquid() then
    data.ranOut = false
  end

  local v_x = 0;
  local v_y = 0;
  local a_x = 0;
  local a_y = 0;
  
  if data.holdingUp and not data.ranOut then
    v_y = 2;
  end
  if data.holdingDown and not data.ranOut then
    v_y = -2;
  end
  if data.holdingLeft and not data.ranOut then
    v_x = -2;
	a_x = 50;
  end
  if data.holdingRight and not data.ranOut then
    v_x = 2;
	a_x = 50;
  end
  
  tech.xControl(0+v_x, 0+a_x, false);
  tech.yControl(0+v_y, 100+a_y, false);
  
  return 0;
  
  --if args.actions["jetpack"] and not data.ranOut then
    --tech.setAnimationState("jetpack", "on")
	--tech.yControl(Speed_Y, ControlForce_Y, true)
    --tech.xControl(Speed_Y, ControlForce_Y, true)
	--tech.yControl(Speed_Y, ControlForce_Y, true)
    --return energyUsage
  --else
    --tech.setAnimationState("jetpack", "off")
    --return 0
  --end

  --return usedEnergy
end
