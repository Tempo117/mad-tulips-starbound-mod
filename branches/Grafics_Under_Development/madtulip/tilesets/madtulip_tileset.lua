function init(virtual)
	if not(virtual) then
	end
end

function main()
	Update()
end

function Update()
	self.pos = entity.toAbsolutePosition({ 0.0, 0.0 });
	self.BB = {}
	self.BB[1] = self.pos[1]-1;
	self.BB[2] = self.pos[2]-1;
	self.BB[3] = self.pos[1]+1;
	self.BB[4] = self.pos[2]+1;
	
	-- update self
	madtulip_Update_Grafics()
	
	-- update the neighbours
	world.entityQuery({self.BB[1], self.BB[2]},
					  {self.BB[3], self.BB[4]},
					  {callScript = "madtulip_Update_Grafics"})
end

function madtulip_Update_Grafics()
	self.obj_pos = nil
	self.cur_rel_pos = nil
	
	-- 812
	-- 7X3
	-- 654
	self.neighbours = {}
	for cur_neighbour = 1 , 8 , 1 do
		self.neighbours[cur_neighbour] = false;
	end

	--local entityIds = world.monsterQuery(min, max, {callScript = "canSocialize" })
	-- local ObjectIds = world.entityQuery ({self.BB[1], self.BB[2]}, {self.BB[3], self.BB[4]},{callScript = "madtulip_Is_Tileset" })
	self.ObjectIds = world.entityQuery ({self.BB[1], self.BB[2]}, {self.BB[3], self.BB[4]},{name = "madtulip_human_hull_tileset" })
	if self.ObjectIds then
		-- find neighbours
		for i, ObjectId in pairs(self.ObjectIds) do
			if (ObjectId ~= entity.id()) then -- if its not myself
				self.obj_pos = world.entityPosition(ObjectId)
				self.cur_rel_pos = {}
				self.cur_rel_pos[1] = self.obj_pos[1] - self.pos[1];
				self.cur_rel_pos[2] = self.obj_pos[2] - self.pos[2];
				if((self.cur_rel_pos[1] ==  0) and (self.cur_rel_pos[2] ==  1)) then self.neighbours[1] = true end -- top
				if((self.cur_rel_pos[1] ==  1) and (self.cur_rel_pos[2] ==  1)) then self.neighbours[2] = true end -- top right
				if((self.cur_rel_pos[1] ==  1) and (self.cur_rel_pos[2] ==  0)) then self.neighbours[3] = true end -- right
				if((self.cur_rel_pos[1] ==  1) and (self.cur_rel_pos[2] == -1)) then self.neighbours[4] = true end -- bottom right
				if((self.cur_rel_pos[1] ==  0) and (self.cur_rel_pos[2] == -1)) then self.neighbours[5] = true end -- bottom
				if((self.cur_rel_pos[1] == -1) and (self.cur_rel_pos[2] == -1)) then self.neighbours[6] = true end -- bottom left
				if((self.cur_rel_pos[1] == -1) and (self.cur_rel_pos[2] ==  0)) then self.neighbours[7] = true end -- left
				if((self.cur_rel_pos[1] == -1) and (self.cur_rel_pos[2] ==  1)) then self.neighbours[8] = true end -- top left
			end
		end
		
		-- set grafic according to neighbours
		-- +
		if     (self.neighbours[1] and self.neighbours[3] and self.neighbours[5] and self.neighbours[7]) then entity.setAnimationState("DisplayState", "S_TRBL")
		-- T
		elseif (self.neighbours[1] and self.neighbours[3] and self.neighbours[5]) then entity.setAnimationState("DisplayState", "S_TRB")
		elseif (self.neighbours[3] and self.neighbours[5] and self.neighbours[7]) then entity.setAnimationState("DisplayState", "S_RBL")
		elseif (self.neighbours[5] and self.neighbours[7] and self.neighbours[1]) then entity.setAnimationState("DisplayState", "S_BLT")
		elseif (self.neighbours[7] and self.neighbours[1] and self.neighbours[3]) then entity.setAnimationState("DisplayState", "S_LTR")
		-- Corner
		elseif (self.neighbours[1] and self.neighbours[3]) then entity.setAnimationState("DisplayState", "S_TR")
		elseif (self.neighbours[3] and self.neighbours[5]) then entity.setAnimationState("DisplayState", "S_BR")
		elseif (self.neighbours[5] and self.neighbours[7]) then entity.setAnimationState("DisplayState", "S_BL")
		elseif (self.neighbours[7] and self.neighbours[1]) then entity.setAnimationState("DisplayState", "S_TL")
		-- straight
		elseif (self.neighbours[1] and self.self.neighbours[5]) then entity.setAnimationState("DisplayState", "S_TB")
		elseif (self.neighbours[3] and self.self.neighbours[7]) then entity.setAnimationState("DisplayState", "S_LR")
		-- single ended straight
		elseif (self.neighbours[1]) then entity.setAnimationState("DisplayState", "S_TB")
		elseif (self.neighbours[5]) then entity.setAnimationState("DisplayState", "S_TB")
		elseif (self.neighbours[3]) then entity.setAnimationState("DisplayState", "S_LR")
		elseif (self.neighbours[7]) then entity.setAnimationState("DisplayState", "S_LR")
		else
			entity.setAnimationState("DisplayState", "S_TRBL");
		end
	else
		-- default state
		entity.setAnimationState("DisplayState", "S_TRBL");
	end	
end