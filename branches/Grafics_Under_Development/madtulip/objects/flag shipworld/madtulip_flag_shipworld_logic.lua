function initializeObject()
	-- Make our object interactive (we can interract by 'Use')
	entity.setInteractive(true);
	-- Change animation for state "off"
	entity.setAnimationState("dummy_nothing", "off");
	
	--storage.Flags = {};
	--storage.Flags.this_is_the_shipworld = true;
end

function main()
	-- Check for the single execution
	if self.initialized == nil then
		-- Init object
		initializeObject();
		-- Set flag
		self.initialized = true;
	end
end

function onInteraction(args)

end
