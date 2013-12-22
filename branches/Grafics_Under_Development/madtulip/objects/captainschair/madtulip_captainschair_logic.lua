function initializeObject()
	-- Make our object interactive (we can interract by 'Use')
	object.setInteractive(true);
	
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
	--return "OpenCockpitInterface";
	local cockpitConfig = {config = "/interface/cockpit/cockpit.config"};
	return {"OpenCockpitInterface", cockpitConfig};
end

