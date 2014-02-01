function init(virtual)
	if not virtual then
		entity.setInteractive(true);
	end
end

function onInteraction(args)
	if not is_shipworld() then return end

	local player_ID   = args["sourceId"]
	local player_race = world.entitySpecies(player_ID);

	-- spawn NPC of users race
	world.spawnNpc(entity.toAbsolutePosition({ 0.0, 2.0 }),
				   player_race,
				   "madtulip_normal_crew",
				   entity.level());
	-- kill self
	entity.smash()
end

function is_shipworld()
	if (world.info() == nil) then return true else return false end
end
