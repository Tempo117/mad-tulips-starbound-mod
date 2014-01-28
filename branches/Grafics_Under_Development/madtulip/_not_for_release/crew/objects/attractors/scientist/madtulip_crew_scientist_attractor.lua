function init(virtual)
	if not virtual then
		entity.setInteractive(true);
		
		-- why doesnt this work ?
		--Data.race = world.entitySpecies(entity.id());
	end
end

function onInteraction(args)
	local player_ID   = args["sourceId"]
	local player_race = world.entitySpecies(player_ID);
	
	-- TODO: place this elsewhere in init
	--Data.race = player_race;
	
	-- spawn NPC of users race
	world.spawnNpc(entity.toAbsolutePosition({ 0.0, 2.0 }),
				   player_race,
				   "madtulip_" .. player_race .. "_normal_crew",
				   entity.level());
	-- kill self
	entity.smash()
end

function hasCapability(capability)
  if capability == 'barracks_atractor' then
    return true
  else
    return false
  end
end

function onNodeConnectionChange(args)

end

function onInboundNodeChange(args)

end
