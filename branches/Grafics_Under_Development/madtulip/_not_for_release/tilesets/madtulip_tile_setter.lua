function init()
	-- Change animation for state "active"
	entity.setAnimationState("beaconState", "active");
	
	-- Make our object interactive (we can interract by 'Use')
	entity.setInteractive(true);
	
	self = {}
	self.stackcounter = 0;
end

function main()
	place_stack()
end

function onInteraction(args)
	if (self.stackcounter > 0) then return end
	
	self = {}
	self.stackcounter = 0;
	self.boxsize = 100;
	self.pos = entity.toAbsolutePosition({ 0.0, 0.0 });
	self.BB = {}
	self.BB[1] = self.pos[1]-self.boxsize;
	self.BB[2] = self.pos[2]-self.boxsize;
	self.BB[3] = self.pos[1]+self.boxsize;
	self.BB[4] = self.pos[2]+self.boxsize;
				
			-- X coordinate where to get data
	local cur_Pos = {};
	local cur_Neigh_Pos = {};
	local cur_F_mat = nil;
	local cur_B_mat = nil;
	local f_tileset_mat_type = nil -- nil,human,glitch ...
	local X_abs = nil;
	local Y_abs = nil;
	local own_mat_to_be_set = nil
	local layer = "foreground"
	local place_block_here = false
	for X=self.BB[1],self.BB[3],1 do
		for Y=self.BB[2],self.BB[4],1 do
			place_block_here = false
			cur_Pos[1] = X;
			cur_Pos[2] = Y;
			cur_F_mat = world.material(cur_Pos, layer)
			
			f_tileset_mat_type = get_tileset_mat_type(cur_F_mat)
			if(f_tileset_mat_type ~= nil) then
				-- update tile
				self.neighbours = {}
				for cur_neighbour = 1 , 8 , 1 do
					self.neighbours[cur_neighbour] = false;
				end
				for X_rel=-1,1,1 do
					for Y_rel=-1,1,1 do
						X_abs = X + X_rel;
						Y_abs = Y + Y_rel;
						cur_Neigh_Pos[1] = X_abs;
						cur_Neigh_Pos[2] = Y_abs;
						cur_neigh_mat = world.material(cur_Neigh_Pos, layer)
						neigh_tileset_mat_type = get_tileset_mat_type(cur_neigh_mat)
						if (f_tileset_mat_type == neigh_tileset_mat_type) then
							place_block_here = true
							if((X_rel ==  0) and (Y_rel ==  1)) then self.neighbours[1] = true end -- top
							if((X_rel ==  1) and (Y_rel ==  1)) then self.neighbours[2] = true end -- top right
							if((X_rel ==  1) and (Y_rel ==  0)) then self.neighbours[3] = true end -- right
							if((X_rel ==  1) and (Y_rel == -1)) then self.neighbours[4] = true end -- bottom right
							if((X_rel ==  0) and (Y_rel == -1)) then self.neighbours[5] = true end -- bottom
							if((X_rel == -1) and (Y_rel == -1)) then self.neighbours[6] = true end -- bottom left
							if((X_rel == -1) and (Y_rel ==  0)) then self.neighbours[7] = true end -- left
							if((X_rel == -1) and (Y_rel ==  1)) then self.neighbours[8] = true end -- top left
						end
					end
				end
				
				-- set grafic according to neighbours
				-- +
				if     (self.neighbours[1] and self.neighbours[3] and self.neighbours[5] and self.neighbours[7]) then own_mat_to_be_set = "TRBL"
				-- T
				elseif (self.neighbours[1] and self.neighbours[3] and self.neighbours[5]) then own_mat_to_be_set = "TRB"
				elseif (self.neighbours[3] and self.neighbours[5] and self.neighbours[7]) then own_mat_to_be_set = "RBL"
				elseif (self.neighbours[5] and self.neighbours[7] and self.neighbours[1]) then own_mat_to_be_set = "BLT"
				elseif (self.neighbours[7] and self.neighbours[1] and self.neighbours[3]) then own_mat_to_be_set = "LTR"
				-- Corner
				elseif (self.neighbours[1] and self.neighbours[3]) then own_mat_to_be_set = "TR"
				elseif (self.neighbours[3] and self.neighbours[5]) then own_mat_to_be_set = "BR"
				elseif (self.neighbours[5] and self.neighbours[7]) then own_mat_to_be_set = "BL"
				elseif (self.neighbours[7] and self.neighbours[1]) then own_mat_to_be_set = "TL"
				-- straight
				elseif (self.neighbours[1] and self.neighbours[5]) then own_mat_to_be_set = "TB"
				elseif (self.neighbours[3] and self.neighbours[7]) then own_mat_to_be_set = "LR"
				-- single ended straight
				elseif (self.neighbours[1]) then own_mat_to_be_set = "TB"
				elseif (self.neighbours[5]) then own_mat_to_be_set = "TB"
				elseif (self.neighbours[3]) then own_mat_to_be_set = "LR"
				elseif (self.neighbours[7]) then own_mat_to_be_set = "LR"
				else
					own_mat_to_be_set = "TRBL"
				end
				
				if (place_block_here) then
					--set_own_mat (cur_Pos,layer,f_tileset_mat_type,own_mat_to_be_set)
					add_mat_to_placement_stack (cur_Pos[1],cur_Pos[2],layer,f_tileset_mat_type,own_mat_to_be_set)
				end
			end
		end
	end
end

function get_tileset_mat_type(cur_F_mat)
	-- returns the mat type of the mat (human,glitch ..) or nil if unknown
	if     (cur_F_mat == "madtulip_human_BL")
		or (cur_F_mat == "madtulip_human_BLT")
		or (cur_F_mat == "madtulip_human_BR")
		or (cur_F_mat == "madtulip_human_LR")
		or (cur_F_mat == "madtulip_human_LTR")
		or (cur_F_mat == "madtulip_human_RBL")
		or (cur_F_mat == "madtulip_human_TB")
		or (cur_F_mat == "madtulip_human_TL")
		or (cur_F_mat == "madtulip_human_TR")
		or (cur_F_mat == "madtulip_human_TRB")
		or (cur_F_mat == "madtulip_human_TRBL") then
		return "human"
	end
	
	-- default
	return nil
end

function add_mat_to_placement_stack (X,Y,layer,f_tileset_mat_type,own_mat_to_be_set)
	self.stackcounter = self.stackcounter+1;
	if (self.stackcounter == 1) then 
		-- reset
		self.stack = {}
		self.stack.cur_Pos = {}
		self.stack.layer = {}
		self.stack.f_tileset_mat_type = {}
		self.stack.own_mat_to_be_set = {}
		self.stack.was_processed = {}
	end
	self.stack.cur_Pos[self.stackcounter]            = {X,Y}
	self.stack.layer[self.stackcounter]              = layer
	self.stack.f_tileset_mat_type[self.stackcounter] = f_tileset_mat_type
	self.stack.own_mat_to_be_set[self.stackcounter]  = own_mat_to_be_set
	self.stack.was_processed[self.stackcounter]      = false
end

function place_stack()
	if (self.stackcounter < 1) then return end
	
	local done_placing = true
	local could_place = false
	for cur_stackcounter = 1,self.stackcounter,1 do
		if not(self.stack.was_processed[cur_stackcounter]) then
			could_place = set_own_mat (self.stack.cur_Pos[cur_stackcounter]
									  ,self.stack.layer[cur_stackcounter]
									  ,self.stack.f_tileset_mat_type[cur_stackcounter]
									  ,self.stack.own_mat_to_be_set[cur_stackcounter])
			if (could_place)then
world.logInfo ("could_place")
				self.stack.was_processed[cur_stackcounter] = true
			else
				done_placing = false
world.logInfo ("done_placing = false")
world.logInfo ("cur_stackcounter" .. cur_stackcounter)
			end
		end
	end
	
	if (done_placing) then
		-- reade to read again
		self.stackcounter = 0
	end
end

function set_own_mat (cur_Pos,layer,f_tileset_mat_type,own_mat_to_be_set)
world.logInfo ("set_own_mat")
world.logInfo ("cur_Pos:" .. " layer:" .. layer .. " f_tileset_mat_type:" .. f_tileset_mat_type .. " own_mat_to_be_set:" .. own_mat_to_be_set)
	-- parameters are i.e. {X,Y},"TB","human"
	-- remove old block
	world.damageTiles({cur_Pos}, layer, cur_Pos, "crushing", 10000)
	-- place new block
	local could_place = false
	if (f_tileset_mat_type == "human") then
		if(own_mat_to_be_set == "BL")       then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_human_BL")
		elseif(own_mat_to_be_set == "BLT")  then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_human_BLT")
		elseif(own_mat_to_be_set == "BR")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_human_BR")
		elseif(own_mat_to_be_set == "LR")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_human_LR")
		elseif(own_mat_to_be_set == "LTR")  then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_human_LTR")
		elseif(own_mat_to_be_set == "RBL")  then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_human_RBL")
		elseif(own_mat_to_be_set == "TB")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_human_TB")
		elseif(own_mat_to_be_set == "TL")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_human_TL")
		elseif(own_mat_to_be_set == "TR")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_human_TR")
		elseif(own_mat_to_be_set == "TRB")  then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_human_TRB")
		elseif(own_mat_to_be_set == "TRBL") then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_human_TRBL")
		else
			return nil
		end
	else
		-- default
		return nil
	end
	
	return could_place
end