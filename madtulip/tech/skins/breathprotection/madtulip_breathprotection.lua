function init()
	----- Suit -----
	status.setPersistentEffects("breathprotectionTech", {{stat = "breathProtection", amount = 1}})
	
	-- Here we remove the invulnerability of the player on the Shipworld when he first equipps a suit
	world.setProperty("invinciblePlayers",false)
  
	No_Gravity_In_Space_init();
end

function uninit()
	status.clearPersistentEffects("breathprotectionTech")
end

function input(args)
	No_Gravity_In_Space_input(args);
end

function update(args)
	Require_Life_Support();
	No_Gravity_In_Space_update(args);
end