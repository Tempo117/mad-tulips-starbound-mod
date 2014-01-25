madtulipcommandState = {};

function madtulipcommandState.enterWith(args)
	if args.Issue_Command == nil then return nil end
	if args.Issue_Command == true then
		-- command has been issued
		if args.Command == nil then return nil end
		-- switch command type
		if     (args.Command == "Set_Occupation") then
			-- set occupation
			if madtulipcommandState.Set_Occupation(args.Occupation) then
				return {sourceId = args.sourceId,
						timer = entity.configParameter("converse.waitTime")}
			else
				return nil
			end
		-- Different commmand types as elseif here.
		end
	end
	return nil
end

function madtulipcommandState.update(dt, stateData)
-- TODO: stop NPC for a while and face player not working
  -- face command issuing player
  -- local sourcePosition = world.entityPosition(stateData.sourceId)
  -- if sourcePosition == nil then return true end
  -- local toSource = world.distance(sourcePosition, entity.position())
  -- setFacingDirection(toSource[1])

  -- timeout ends state
  stateData.timer = stateData.timer - dt
  return (stateData.timer <= 0)
end

function madtulipcommandState.Set_Occupation(Occupation)
	if Occupation == nil then return nil end
	
	if     Occupation == "Engineer" then
		-- Engineer
		Data.Occupation = "Engineer";
		entity.say("Yes SIR! Working as " .. Occupation .."!")
		entity.setItemSlot("primary", "beamaxe")
		entity.setItemSlot("alt", nil)
		entity.setItemSlot("chest", {name = "madtulip_glitch_engineer_chest", data ={ colorIndex = Data.colorIndex }})
		entity.setItemSlot("legs" , {name = "madtulip_glitch_engineer_pants", data ={ colorIndex = Data.colorIndex }})
		return true
	elseif Occupation == "Medic" then
		-- Medic
		Data.Occupation = "Medic";
		entity.say("Yes SIR! Working as " .. Occupation .. "!")
		entity.setItemSlot("primary", nil)
		entity.setItemSlot("alt", nil)
		entity.setItemSlot("chest", {name = "madtulip_glitch_medical_chest", data ={ colorIndex = Data.colorIndex }})
		entity.setItemSlot("legs" , {name = "madtulip_glitch_medical_pants", data ={ colorIndex = Data.colorIndex }})
		return true
	elseif Occupation == "Scientist" then
		-- Scientist
		Data.Occupation = "Scientist";
		entity.say("Yes SIR! Working as " .. Occupation .. "!")
		entity.setItemSlot("primary", nil)
		entity.setItemSlot("alt", nil)
		entity.setItemSlot("chest", {name = "madtulip_glitch_science_chest", data ={ colorIndex = Data.colorIndex }})
		entity.setItemSlot("legs" , {name = "madtulip_glitch_science_pants", data ={ colorIndex = Data.colorIndex }})
		return true
	elseif Occupation == "Marine" then
		-- Marine
		Data.Occupation = "Marine";
		entity.say("Yes SIR! Working as " .. Occupation .. "!")
		entity.setItemSlot("primary", nil)
		entity.setItemSlot("alt", nil)
		entity.setItemSlot("chest", {name = "madtulip_glitch_engineer_chest", data ={ colorIndex = Data.colorIndex }})
		entity.setItemSlot("legs" , {name = "madtulip_glitch_engineer_pants", data ={ colorIndex = Data.colorIndex }})
		return true
	elseif Occupation == "None" then
		-- None
		Data.Occupation = "None";
		entity.say("Im without occupation, SIR!")
		entity.setItemSlot("primary", nil)
		entity.setItemSlot("alt", nil)
		entity.setItemSlot("chest", nil) -- hihihi
		entity.setItemSlot("legs", nil)
		return true
	else
		entity.say("What kind of job is that!?, SIR!")
		return nil
	end
	
	return nil
end