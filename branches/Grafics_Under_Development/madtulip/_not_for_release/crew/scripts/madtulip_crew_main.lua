--Override the default Interact() function
interact = function(args)
--world.logInfo("madtulip NPC is calling interact = function(args)")
	-- Check for item beeing interacted with (command type)
	if world.entityHandItem(args.sourceId, "primary") == "beamaxe" then
		-- Set Engineer occupation
world.logInfo("madtulip NPC Interacted with beamaxe")
		args.madtulip = {};
		args.madtulip.Issue_Command = true;
		args.madtulip.Command       = "Set_Occupation";
		args.madtulip.Occupation    = "Engineer";
		self.state.pickState({ interactArgs = args })
	elseif world.entityHandItem(args.sourceId, "primary") == "painttool" then
world.logInfo("madtulip NPC Interacted with painttool")
		-- Set Medic occupation
		self.state.pickState({
			sourceId      = args.sourceId,
			Issue_Command = true,
			Command       = "Set_Occupation",
			Occupation    = "Medic"
		})
	elseif world.entityHandItem(args.sourceId, "primary") == "TODO!!!!!" then
		-- Set Scientist occupation
		self.state.pickState({
			sourceId      = args.sourceId,
			Issue_Command = true,
			Command       = "Set_Occupation",
			Occupation    = "Scientist"
		})
	elseif world.entityHandItem(args.sourceId, "primary") == "TODO!!!!!" then
		-- Set Marine occupation
		self.state.pickState({
			sourceId      = args.sourceId,
			Issue_Command = true,
			Command       = "Set_Occupation",
			Occupation    = "Marine"
		})
	elseif world.entityHandItem(args.sourceId, "primary") == "TODO!!!!!" then
		-- Set None occupation
		self.state.pickState({
			sourceId      = args.sourceId,
			Issue_Command = true,
			Command       = "Set_Occupation",
			Occupation    = "None"
		})
	else
		-- no known item
-- DEBUG - TODO REMOVE
-- Set no occupation
self.state.pickState({
	sourceId      = args.sourceId,
	Issue_Command = true,
	Command       = "Set_Occupation",
	Occupation    = "None"
})
-- DEBUG - TODO REMOVE
	end
end