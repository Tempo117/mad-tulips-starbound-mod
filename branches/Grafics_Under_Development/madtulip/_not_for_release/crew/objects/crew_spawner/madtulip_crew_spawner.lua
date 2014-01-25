function init(virtual)
	if not virtual then
		entity.setInteractive(true);
	end
end

function onInteraction(args)
	local player_ID   = args["sourceId"]
	local player_race = world.entitySpecies(player_ID);
	
	-- spawn NPC of users race
	world.spawnNpc(entity.toAbsolutePosition({ 0.0, 2.0 }),
				   player_race,
				   "madtulip_" .. player_race .. "_normal_crew",
				   entity.level());
	-- kill self
	entity.smash()
end

function onNodeConnectionChange(args)

end

function onInboundNodeChange(args)

end
