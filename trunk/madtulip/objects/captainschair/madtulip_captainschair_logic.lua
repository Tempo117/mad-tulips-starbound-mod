function initializeObject()
	-- Make our object interactive (we can interract by 'Use')
	object.setInteractive(true);
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
	return {"OpenCockpitInterface"};
	
	--Ship_Properties = {};
	--Ship_Properties.Driveable = 0;
	

	-- some other functions defines this:
	--Ship_Properties.Driveable = 1;
	
	
	--if Ship_Properties.Driveable == 1 then
		-- ok, you may fly.
		--return {"OpenCockpitInterface"};
	--else
		--return { "ShowPopup", { message = "You cant fly because of this and that." } };
	--end
end

