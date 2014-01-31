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
	elseif world.entityHandItem(args.sourceId, "primary") == "madtulip_crew_info" then
		-- Show Crew information
		--world.logInfo("Show information for ID:" .. entity.id())
		--world.logInfo("Species: " .. entity.species())
		return {"ShowPopup",{message =
				"^green;Name: ^white;" .. world.entityName(entity.id()) .. "\n" ..
				"^green;Species : ^white;" .. entity.species() .. "\n" ..
				"^green;Occupation: ^white;" .. storage.Occupation
				}}
	else
		-- Default is just chat
-- TODO: explicit call chat state here
		self.state.pickState({
			interactArgs      = args
		 })		
	end
end