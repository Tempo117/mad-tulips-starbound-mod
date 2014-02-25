function init(args)
	entity.setInteractive(true)
end

function main()

end

function onInteraction(args)
	-- if clicked by middle mouse or "e"
	-- return {"OpenCockpitInterface"};
	
	-- Now build the actual trading config
	local dummy = {}
	return {"OpenCockpitInterface",{}}

--[[
	local tradingConfig = {}
	tradingConfig.gui = {}
	tradingConfig.gui.background = {}
	tradingConfig.gui.background.type = "background"
	tradingConfig.gui.background.fileHeader = "/interface/wires/header.png"
	tradingConfig.gui.background.fileBody   = "/interface/wires/body.png"
	tradingConfig.gui.background.fileFooter = "/interface/wires/footer.png"
	return {"OpenNpcInterface",tradingConfig}
--]]
	
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

