function initializeObject()
	-- Make our object interactive (we can interract by 'Use')
	object.setInteractive(true);
	
	-- Change animation for state "normal_operation"
	object.setAnimationState("DisplayState", "normal_operation");
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
	-- if clicked by middle mouse or "e"
	
end

function set_O2_OK_State()
	object.setAnimationState("DisplayState", "normal_operation");
end

function set_O2_BAD_State()
	object.setAnimationState("DisplayState", "breach");
end

function set_O2_Offline_State()
	object.setAnimationState("DisplayState", "offline");
end