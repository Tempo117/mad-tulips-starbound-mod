madtulip_npc_commandState = {};

-- Init called when a NPC that binds this calls self.state.pickState .
-- It will enter this state if this state doesnt return nil.
-- The return value of this is the parameter args for the update function
   -- its content needs to be persistent!
function madtulip_npc_commandState.enterWith(args)
world.logInfo("madtulip_npc_commandState.enterWith(args)")
	if args.interactArgs.madtulip.Issue_Command == nil then return nil end
	if args.interactArgs.madtulip.Issue_Command == true then
world.logInfo("args.Issue_Command == true")
		-- command has been issued
		if args.interactArgs.madtulip.Command == nil then return nil end
		-- switch command type
		if     (args.interactArgs.madtulip.Command == "Set_Occupation") then
world.logInfo("args.Command == Set_Occupation")
			-- set occupation
			if madtulip_npc_commandState.Set_Occupation(args.interactArgs.madtulip.Occupation) then
					return {sourceId = args.interactArgs.sourceId,
							timer = 3}
			else
				return nil
			end
--[[
		elseif (args.interactArgs.madtulip.Command == "2") then
			return {A = "A1",
					B = "B1"}
		elseif (args.interactArgs.madtulip.Command == "3") then
			return {A = "A1",
					B = "B1"}
]]
		end
	end
	
	return nil
end

-- Main called every dt with stateData being the return value of "enter.With()"
-- State ends if this function returns true.
function madtulip_npc_commandState.update(dt, stateData)
  -- face command issuing player
  local sourcePosition = world.entityPosition(stateData.sourceId)
  if sourcePosition == nil then return true end
  local toSource = world.distance(sourcePosition, entity.position())
  setFacingDirection(toSource[1])

  -- timeout ends state
  stateData.timer = stateData.timer - dt
  return (stateData.timer <= 0)
end

-- Deinit function called when stateis left
function madtulip_npc_commandState.leavingState()
end

function madtulip_npc_commandState.Set_Occupation(args)
world.logInfo("madtulip_npc_commandState.Set_Occupation(args)")
	if args.Occupation == nil then return nil end
	
	if     args.Occupation == "Engineer" then
		-- Engineer
		Data.Occupation = "Engineer";
		entity.say("Im an Engineer!")
		return true
	elseif args.Occupation == "Medic" then
		-- Medic
		entity.say("Im a Medic!")
		Data.Occupation = "Medic";
		return true
	elseif args.Occupation == "Scientist" then
		-- Medic
		entity.say("Im a Scientist!")
		Data.Occupation = "Scientist";
		return true
	elseif args.Occupation == "Marine" then
		-- Medic
		entity.say("Im a Marine!")
		Data.Occupation = "Marine";
		return true
	elseif args.Occupation == "None" then
		-- Medic
		entity.say("Im without occupation!")
		Data.Occupation = "None";
		return true
	else
		return nil
	end
	
	return nil
end