--Override the default Interact() function
interact = function(args)
	-- Check for item beeing interacted with (command type)
	if world.entityHandItem(args.sourceId, "primary") == "madtulip_engineere_promotion" then
		-- Set Engineer occupation
		self.state.pickState({
			sourceId      = args.sourceId,
			Issue_Command = true,
			Command       = "Set_Occupation",
			Occupation    = "Engineer"
		 })
	elseif world.entityHandItem(args.sourceId, "primary") == "madtulip_medic_promotion" then
		-- Set Medic occupation
		self.state.pickState({
			sourceId      = args.sourceId,
			Issue_Command = true,
			Command       = "Set_Occupation",
			Occupation    = "Medic"
		 })
	elseif world.entityHandItem(args.sourceId, "primary") == "madtulip_scientist_promotion" then
		-- Set Scientist occupation
		self.state.pickState({
			sourceId      = args.sourceId,
			Issue_Command = true,
			Command       = "Set_Occupation",
			Occupation    = "Scientist"
		 })
	elseif world.entityHandItem(args.sourceId, "primary") == "madtulip_marine_promotion" then
		-- Set Marine occupation
		self.state.pickState({
			sourceId      = args.sourceId,
			Issue_Command = true,
			Command       = "Set_Occupation",
			Occupation    = "Marine"
		 })
	elseif world.entityHandItem(args.sourceId, "primary") == "madtulip_deckhand_demotion" then
		-- Set Deckhand occupation (basic guy)
		self.state.pickState({
			sourceId      = args.sourceId,
			Issue_Command = true,
			Command       = "Set_Occupation",
			Occupation    = "Deckhand"
		 })
	else
		-- no known item
	end
end