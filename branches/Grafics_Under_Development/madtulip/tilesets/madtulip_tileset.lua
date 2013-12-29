function init(args)
	if not(Did_Init) then
		-- update the neighbours
		local pos = entity.toAbsolutePosition({ 0.0, 0.0 });
		local BB = {}
		BB[1] = pos[1]-1;
		BB[2] = pos[2]-1;
		BB[3] = pos[1]+1;
		BB[4] = pos[2]+1;
		world.objectQuery({BB[1], BB[2]}, {BB[3], BB[4]},{callScript = "madtulip_Update_Grafics"})
		
		madtulip_Update_Grafics()
		Did_Init = true;
	else
	end
end

function main()
	--madtulip_Update_Grafics()
end

function madtulip_Update_Grafics()
world.logInfo("---------------------------------UpdateGrafics---------------------------------")
	local pos = entity.toAbsolutePosition({ 0.0, 0.0 });
	local BB = {}
	BB[1] = pos[1]-1;
	BB[2] = pos[2]-1;
	BB[3] = pos[1]+1;
	BB[4] = pos[2]+1;

	-- 812
	-- 7X3
	-- 654
	local neighbours = {}
	for cur_neighbour = 1 , 8 , 1 do
		neighbours[cur_neighbour] = false;
	end

	local ObjectIds = {}
	--ObjectIds = world.objectQuery({BB[1], BB[2]}, {BB[3], BB[4]})
	ObjectIds = world.objectQuery({BB[1], BB[2]}, {BB[3], BB[4]},{name = "madtulip_human_hull_tileset"})
--[[
	if (AlertNeighbours) then
world.logInfo("ALERT")
		ObjectIds = world.objectQuery({BB[1], BB[2]}, {BB[3], BB[4]},{callScript = "madtulip_Update_Grafics", callScriptArgs = {false}})
	else
world.logInfo("NO ALERT")
		ObjectIds = world.objectQuery({BB[1], BB[2]}, {BB[3], BB[4]},{callScript = "madtulip_Do_Nothing_Function"})
	end
]]
	if ObjectIds then
world.logInfo("ObjectIds -> yes")
		-- find neighbours
		local obj_pos
		local cur_rel_pos
		for i, ObjectId in pairs(ObjectIds) do
world.logInfo("Obj. found")
world.logInfo(ObjectId)
world.logInfo(i)
			if (ObjectId ~= entity.id()) then
world.logInfo("Obj is not me. Nr.:" .. i)
				obj_pos = world.entityPosition(ObjectId)
				cur_rel_pos = {}
				cur_rel_pos[1] = obj_pos[1] - pos[1];
				cur_rel_pos[2] = obj_pos[2] - pos[2];
world.logInfo("pos: " .. pos[1] .. " " .. pos[2])
world.logInfo("obj_pos: " .. obj_pos[1] .. " " .. obj_pos[2])
world.logInfo("cur_rel_pos: " .. cur_rel_pos[1] .. " " .. cur_rel_pos[2])
				if((cur_rel_pos[1] ==  0) and (cur_rel_pos[2] ==  1)) then neighbours[1] = true end
				if((cur_rel_pos[1] ==  1) and (cur_rel_pos[2] ==  1)) then neighbours[2] = true end
				if((cur_rel_pos[1] ==  1) and (cur_rel_pos[2] ==  0)) then neighbours[3] = true end
				if((cur_rel_pos[1] ==  1) and (cur_rel_pos[2] == -1)) then neighbours[4] = true end
				if((cur_rel_pos[1] ==  0) and (cur_rel_pos[2] == -1)) then neighbours[5] = true end
				if((cur_rel_pos[1] == -1) and (cur_rel_pos[2] == -1)) then neighbours[6] = true end
				if((cur_rel_pos[1] == -1) and (cur_rel_pos[2] ==  0)) then neighbours[7] = true end
				if((cur_rel_pos[1] == -1) and (cur_rel_pos[2] ==  1)) then neighbours[8] = true end
			end
		end
		
		-- set grafic according to neighbours
world.logInfo("set grafic according to neighbours")
if neighbours[1] then world.logInfo("N1") end
if neighbours[2] then world.logInfo("N2") end
if neighbours[3] then world.logInfo("N3") end
if neighbours[4] then world.logInfo("N4") end
if neighbours[5] then world.logInfo("N5") end
if neighbours[6] then world.logInfo("N6") end
if neighbours[7] then world.logInfo("N7") end
if neighbours[8] then world.logInfo("N8") end
		-- +
		if     (neighbours[1] and neighbours[3] and neighbours[5] and neighbours[7]) then entity.setAnimationState("DisplayState", "S_TRBL")
		-- T
		elseif (neighbours[1] and neighbours[3] and neighbours[5]) then entity.setAnimationState("DisplayState", "S_TRB")
		elseif (neighbours[3] and neighbours[5] and neighbours[7]) then entity.setAnimationState("DisplayState", "S_RBL")
		elseif (neighbours[5] and neighbours[7] and neighbours[1]) then entity.setAnimationState("DisplayState", "S_BLT")
		elseif (neighbours[7] and neighbours[1] and neighbours[3]) then entity.setAnimationState("DisplayState", "S_LTR")
		-- Corner
		elseif (neighbours[1] and neighbours[3]) then entity.setAnimationState("DisplayState", "S_TR")
		elseif (neighbours[3] and neighbours[5]) then entity.setAnimationState("DisplayState", "S_BR")
		elseif (neighbours[5] and neighbours[7]) then entity.setAnimationState("DisplayState", "S_BL")
		elseif (neighbours[7] and neighbours[1]) then entity.setAnimationState("DisplayState", "S_TL")
		-- straight
		elseif (neighbours[1] and neighbours[5]) then entity.setAnimationState("DisplayState", "S_TB")
		elseif (neighbours[3] and neighbours[7]) then entity.setAnimationState("DisplayState", "S_LR")
		end
	else
		-- default state
world.logInfo("set grafics with no neighbours")
		entity.setAnimationState("DisplayState", "S_TRBL");
	end	
end

function madtulip_Do_Nothing_Function()
	world.logInfo("called!")
	-- 42! ;)
end