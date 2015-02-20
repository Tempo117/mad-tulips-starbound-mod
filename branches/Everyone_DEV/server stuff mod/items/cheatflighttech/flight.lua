function init()
  data.active = false
  data.specialLast = false
end
  
  
  
function input(args)
  local currentBoost = nil

  if args.moves["special"] == 1 and not data.specialLast then
    if data.active then
      return "flightDeactivate"
    else
      return "flightActivate"
    end
  end

  data.specialLast = args.moves["special"] == 1
  
  if data.active then
    if args.moves["right"] and args.moves["up"] then
        currentBoost = "boostRightUp"
    elseif args.moves["right"] and args.moves["down"] then
        currentBoost = "boostRightDown"
    elseif args.moves["left"] and args.moves["up"] then
        currentBoost = "boostLeftUp"
    elseif args.moves["left"] and args.moves["down"] then
        currentBoost = "boostLeftDown"
    elseif args.moves["right"] then
        currentBoost = "boostRight"
    elseif args.moves["down"] then
        currentBoost = "boostDown"
    elseif args.moves["left"] then
        currentBoost = "boostLeft"
    elseif args.moves["up"] then
        currentBoost = "boostUp"
	end
  end
  

  return currentBoost
end
  
  
  
function update(args)
  local boostControlForce = tech.parameter("boostControlForce")
  local boostSpeed = tech.parameter("boostSpeed")
  local energyUsagePerSecond = tech.parameter("energyUsagePerSecond")
  local energyUsage = energyUsagePerSecond * args.dt

  local boosting = false
  local diag = 1 / math.sqrt(2)

  if not data.active and args.actions["flightActivate"] then
        data.active = true
  elseif data.active and args.actions["flightDeactivate"] then
		data.active = false
  end
  
  if data.active then
    boosting = true
    if args.actions["boostRightUp"] then
      tech.control({boostSpeed * diag, boostSpeed * diag}, boostControlForce, true, true)
    elseif args.actions["boostRightDown"] then
      tech.control({boostSpeed * diag, -boostSpeed * diag}, boostControlForce, true, true)
    elseif args.actions["boostLeftUp"] then
      tech.control({-boostSpeed * diag, boostSpeed * diag}, boostControlForce, true, true)
    elseif args.actions["boostLeftDown"] then
      tech.control({-boostSpeed * diag, -boostSpeed * diag}, boostControlForce, true, true)
    elseif args.actions["boostRight"] then
      tech.control({boostSpeed, 0}, boostControlForce, true, true)
    elseif args.actions["boostDown"] then
      tech.control({0, -boostSpeed}, boostControlForce, true, true)
    elseif args.actions["boostLeft"] then
      tech.control({-boostSpeed, 0}, boostControlForce, true, true)
    elseif args.actions["boostUp"] then
      tech.control({0, boostSpeed}, boostControlForce, true, true)
    else
      boosting = false
	  tech.setYVelocity(0)
	  tech.setXVelocity(0)
    end
  end
end