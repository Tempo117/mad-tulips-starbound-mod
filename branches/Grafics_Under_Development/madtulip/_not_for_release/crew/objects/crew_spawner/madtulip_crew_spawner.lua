function init(virtual)
	if not virtual then
		entity.setInteractive(true);
	end
end

function onInteraction(args)
	local player_ID = args["sourceId"]
	
	-- spawn NPC of users race
	world.spawnNpc(entity.toAbsolutePosition({ 0.0, 2.0 }),
				   world.entitySpecies(player_ID),
				   "madtulip_normal_crew",
				   entity.level());
	-- kill self
	entity.smash()
end

function onNodeConnectionChange(args)

end

function onInboundNodeChange(args)

end
