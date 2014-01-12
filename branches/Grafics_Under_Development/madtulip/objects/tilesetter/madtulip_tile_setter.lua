function init()
	-- Change animation for state "active"
	entity.setAnimationState("DisplayState", "normal_operation");
	
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
	self.timeoutcounter = 0
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
	local f_tileset_mat_type = nil -- nil,human,glitch ...
	local X_abs = nil;
	local Y_abs = nil;
	local own_mat_to_be_set = nil -- "BL","TL", ...
	local layer = "foreground"
	local place_block_here = false
	for layer_nr=1,2,1 do
		if (layer_nr == 1) then layer = "background" end
		if (layer_nr == 2) then layer = "foreground" end
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
					
					-- set graphic according to neighbours
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
						own_mat_to_be_set = "DEFAULT"
					end
					
					if (place_block_here) then
						-- check if the current block is already the same as the block we want to place
						if not (cur_F_mat == "madtulip_" .. f_tileset_mat_type .. "_" .. own_mat_to_be_set) then
							-- place only if block to be placed is different from current block.
							add_mat_to_placement_stack (cur_Pos[1],cur_Pos[2],layer,f_tileset_mat_type,own_mat_to_be_set)
						end
					end
				end
			end
		end
	end
end

function get_tileset_mat_type(cur_F_mat)
	-- returns the mat type of the mat (human,glitch ..) or nil if unknown
	if     (cur_F_mat == "madtulip_apex_bl")
		or (cur_F_mat == "madtulip_apex_blt")
		or (cur_F_mat == "madtulip_apex_br")
		or (cur_F_mat == "madtulip_apex_lr")
		or (cur_F_mat == "madtulip_apex_ltr")
		or (cur_F_mat == "madtulip_apex_rbl")
		or (cur_F_mat == "madtulip_apex_tb")
		or (cur_F_mat == "madtulip_apex_tl")
		or (cur_F_mat == "madtulip_apex_tr")
		or (cur_F_mat == "madtulip_apex_trb")
		or (cur_F_mat == "madtulip_apex_trbl") 
		or (cur_F_mat == "madtulip_apex_default") then
		return "apex"
	end
	if     (cur_F_mat == "madtulip_avian_bl")
		or (cur_F_mat == "madtulip_avian_blt")
		or (cur_F_mat == "madtulip_avian_br")
		or (cur_F_mat == "madtulip_avian_lr")
		or (cur_F_mat == "madtulip_avian_ltr")
		or (cur_F_mat == "madtulip_avian_rbl")
		or (cur_F_mat == "madtulip_avian_tb")
		or (cur_F_mat == "madtulip_avian_tl")
		or (cur_F_mat == "madtulip_avian_tr")
		or (cur_F_mat == "madtulip_avian_trb")
		or (cur_F_mat == "madtulip_avian_trbl")
		or (cur_F_mat == "madtulip_avian_default") then
		return "avian"
	end
	if     (cur_F_mat == "madtulip_floran_bl")
		or (cur_F_mat == "madtulip_floran_blt")
		or (cur_F_mat == "madtulip_floran_br")
		or (cur_F_mat == "madtulip_floran_lr")
		or (cur_F_mat == "madtulip_floran_ltr")
		or (cur_F_mat == "madtulip_floran_rbl")
		or (cur_F_mat == "madtulip_floran_tb")
		or (cur_F_mat == "madtulip_floran_tl")
		or (cur_F_mat == "madtulip_floran_tr")
		or (cur_F_mat == "madtulip_floran_trb")
		or (cur_F_mat == "madtulip_floran_trbl")
		or (cur_F_mat == "madtulip_floran_default") then
		return "floran"
	end
	if     (cur_F_mat == "madtulip_glitch_bl")
		or (cur_F_mat == "madtulip_glitch_blt")
		or (cur_F_mat == "madtulip_glitch_br")
		or (cur_F_mat == "madtulip_glitch_lr")
		or (cur_F_mat == "madtulip_glitch_ltr")
		or (cur_F_mat == "madtulip_glitch_rbl")
		or (cur_F_mat == "madtulip_glitch_tb")
		or (cur_F_mat == "madtulip_glitch_tl")
		or (cur_F_mat == "madtulip_glitch_tr")
		or (cur_F_mat == "madtulip_glitch_trb")
		or (cur_F_mat == "madtulip_glitch_trbl")
		or (cur_F_mat == "madtulip_glitch_default") then
		return "glitch"
	end
	if     (cur_F_mat == "madtulip_human_bl")
		or (cur_F_mat == "madtulip_human_blt")
		or (cur_F_mat == "madtulip_human_br")
		or (cur_F_mat == "madtulip_human_lr")
		or (cur_F_mat == "madtulip_human_ltr")
		or (cur_F_mat == "madtulip_human_rbl")
		or (cur_F_mat == "madtulip_human_tb")
		or (cur_F_mat == "madtulip_human_tl")
		or (cur_F_mat == "madtulip_human_tr")
		or (cur_F_mat == "madtulip_human_trb")
		or (cur_F_mat == "madtulip_human_trbl")
		or (cur_F_mat == "madtulip_human_default") then
		return "human"
	end
	if     (cur_F_mat == "madtulip_hylotl_bl")
		or (cur_F_mat == "madtulip_hylotl_blt")
		or (cur_F_mat == "madtulip_hylotl_br")
		or (cur_F_mat == "madtulip_hylotl_lr")
		or (cur_F_mat == "madtulip_hylotl_ltr")
		or (cur_F_mat == "madtulip_hylotl_rbl")
		or (cur_F_mat == "madtulip_hylotl_tb")
		or (cur_F_mat == "madtulip_hylotl_tl")
		or (cur_F_mat == "madtulip_hylotl_tr")
		or (cur_F_mat == "madtulip_hylotl_trb")
		or (cur_F_mat == "madtulip_hylotl_trbl")
		or (cur_F_mat == "madtulip_hylotl_default") then
		return "hylotl"
	end
	if     (cur_F_mat == "madtulip_glass_bl")
		or (cur_F_mat == "madtulip_glass_blt")
		or (cur_F_mat == "madtulip_glass_br")
		or (cur_F_mat == "madtulip_glass_lr")
		or (cur_F_mat == "madtulip_glass_ltr")
		or (cur_F_mat == "madtulip_glass_rbl")
		or (cur_F_mat == "madtulip_glass_tb")
		or (cur_F_mat == "madtulip_glass_tl")
		or (cur_F_mat == "madtulip_glass_tr")
		or (cur_F_mat == "madtulip_glass_trb")
		or (cur_F_mat == "madtulip_glass_trbl")
		or (cur_F_mat == "madtulip_glass_default") then
		return "glass"
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
	if (self.stackcounter < 1) then return end -- no more blocks to place
	
	local done_placing = true
	local could_place = false
	local could_place_anything = false
	for cur_stackcounter = 1,self.stackcounter,1 do
		if not(self.stack.was_processed[cur_stackcounter]) then
			could_place = set_own_mat (self.stack.cur_Pos[cur_stackcounter]
									  ,self.stack.layer[cur_stackcounter]
									  ,self.stack.f_tileset_mat_type[cur_stackcounter]
									  ,self.stack.own_mat_to_be_set[cur_stackcounter])
			if (could_place)then
				self.stack.was_processed[cur_stackcounter] = true
				could_place_anything = true;
			else
				done_placing = false
			end
		end
	end
	
	if not (could_place_anything) then
		-- in case placing cant finish
		self.timeoutcounter = self.timeoutcounter + 1
		if (self.timeoutcounter > 10) then
			--> reset state machine
			self.stackcounter = 0
			self.timeoutcounter = 0
			return
		end
	end
	
	if (done_placing) then
		-- ready to read again
		self.stackcounter = 0
		self.timeoutcounter = 0
	end
end

function set_own_mat (cur_Pos,layer,f_tileset_mat_type,own_mat_to_be_set)
--world.logInfo ("cur_Pos:" .. " layer:" .. layer .. " f_tileset_mat_type:" .. f_tileset_mat_type .. " own_mat_to_be_set:" .. own_mat_to_be_set)
	-- parameters are i.e. {X,Y},"foreground","TB","human"
	-- remove old block
	world.damageTiles({cur_Pos}, layer, cur_Pos, "crushing", 10000)
	-- place new block
	local could_place = false
	if (f_tileset_mat_type == "human") then
		if(own_mat_to_be_set == "BL")       then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_human_bl")
		elseif(own_mat_to_be_set == "BLT")  then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_human_blt")
		elseif(own_mat_to_be_set == "BR")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_human_br")
		elseif(own_mat_to_be_set == "LR")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_human_lr")
		elseif(own_mat_to_be_set == "LTR")  then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_human_ltr")
		elseif(own_mat_to_be_set == "RBL")  then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_human_rbl")
		elseif(own_mat_to_be_set == "TB")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_human_tb")
		elseif(own_mat_to_be_set == "TL")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_human_tl")
		elseif(own_mat_to_be_set == "TR")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_human_tr")
		elseif(own_mat_to_be_set == "TRB")  then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_human_trb")
		elseif(own_mat_to_be_set == "TRBL") then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_human_trbl")
		elseif(own_mat_to_be_set == "DEFAULT") then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_human_default")
		else
			return nil
		end
	elseif (f_tileset_mat_type == "apex") then
		if(own_mat_to_be_set == "BL")       then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_apex_bl")
		elseif(own_mat_to_be_set == "BLT")  then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_apex_blt")
		elseif(own_mat_to_be_set == "BR")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_apex_br")
		elseif(own_mat_to_be_set == "LR")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_apex_lr")
		elseif(own_mat_to_be_set == "LTR")  then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_apex_ltr")
		elseif(own_mat_to_be_set == "RBL")  then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_apex_rbl")
		elseif(own_mat_to_be_set == "TB")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_apex_tb")
		elseif(own_mat_to_be_set == "TL")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_apex_tl")
		elseif(own_mat_to_be_set == "TR")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_apex_tr")
		elseif(own_mat_to_be_set == "TRB")  then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_apex_trb")
		elseif(own_mat_to_be_set == "TRBL") then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_apex_trbl")
		elseif(own_mat_to_be_set == "DEFAULT") then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_apex_default")
		else
			return nil
		end
	elseif (f_tileset_mat_type == "avian") then
		if(own_mat_to_be_set == "BL")       then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_avian_bl")
		elseif(own_mat_to_be_set == "BLT")  then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_avian_blt")
		elseif(own_mat_to_be_set == "BR")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_avian_br")
		elseif(own_mat_to_be_set == "LR")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_avian_lr")
		elseif(own_mat_to_be_set == "LTR")  then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_avian_ltr")
		elseif(own_mat_to_be_set == "RBL")  then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_avian_rbl")
		elseif(own_mat_to_be_set == "TB")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_avian_tb")
		elseif(own_mat_to_be_set == "TL")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_avian_tl")
		elseif(own_mat_to_be_set == "TR")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_avian_tr")
		elseif(own_mat_to_be_set == "TRB")  then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_avian_trb")
		elseif(own_mat_to_be_set == "TRBL") then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_avian_trbl")
		elseif(own_mat_to_be_set == "DEFAULT") then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_avian_default")
		else
			return nil
		end
	elseif (f_tileset_mat_type == "floran") then
		if(own_mat_to_be_set == "BL")       then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_floran_bl")
		elseif(own_mat_to_be_set == "BLT")  then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_floran_blt")
		elseif(own_mat_to_be_set == "BR")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_floran_br")
		elseif(own_mat_to_be_set == "LR")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_floran_lr")
		elseif(own_mat_to_be_set == "LTR")  then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_floran_ltr")
		elseif(own_mat_to_be_set == "RBL")  then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_floran_rbl")
		elseif(own_mat_to_be_set == "TB")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_floran_tb")
		elseif(own_mat_to_be_set == "TL")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_floran_tl")
		elseif(own_mat_to_be_set == "TR")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_floran_tr")
		elseif(own_mat_to_be_set == "TRB")  then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_floran_trb")
		elseif(own_mat_to_be_set == "TRBL") then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_floran_trbl")
		elseif(own_mat_to_be_set == "DEFAULT") then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_floran_default")
		else
			return nil
		end
	elseif (f_tileset_mat_type == "glitch") then
		if(own_mat_to_be_set == "BL")       then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_glitch_bl")
		elseif(own_mat_to_be_set == "BLT")  then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_glitch_blt")
		elseif(own_mat_to_be_set == "BR")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_glitch_br")
		elseif(own_mat_to_be_set == "LR")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_glitch_lr")
		elseif(own_mat_to_be_set == "LTR")  then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_glitch_ltr")
		elseif(own_mat_to_be_set == "RBL")  then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_glitch_rbl")
		elseif(own_mat_to_be_set == "TB")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_glitch_tb")
		elseif(own_mat_to_be_set == "TL")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_glitch_tl")
		elseif(own_mat_to_be_set == "TR")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_glitch_tr")
		elseif(own_mat_to_be_set == "TRB")  then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_glitch_trb")
		elseif(own_mat_to_be_set == "TRBL") then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_glitch_trbl")
		elseif(own_mat_to_be_set == "DEFAULT") then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_glitch_default")
		else
			return nil
		end
	elseif (f_tileset_mat_type == "hylotl") then
		if(own_mat_to_be_set == "BL")       then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_hylotl_bl")
		elseif(own_mat_to_be_set == "BLT")  then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_hylotl_blt")
		elseif(own_mat_to_be_set == "BR")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_hylotl_br")
		elseif(own_mat_to_be_set == "LR")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_hylotl_lr")
		elseif(own_mat_to_be_set == "LTR")  then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_hylotl_ltr")
		elseif(own_mat_to_be_set == "RBL")  then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_hylotl_rbl")
		elseif(own_mat_to_be_set == "TB")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_hylotl_tb")
		elseif(own_mat_to_be_set == "TL")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_hylotl_tl")
		elseif(own_mat_to_be_set == "TR")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_hylotl_tr")
		elseif(own_mat_to_be_set == "TRB")  then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_hylotl_trb")
		elseif(own_mat_to_be_set == "TRBL") then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_hylotl_trbl")
		elseif(own_mat_to_be_set == "DEFAULT") then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_hylotl_default")
		else
			return nil
		end
	elseif (f_tileset_mat_type == "glass") then
		if(own_mat_to_be_set == "BL")       then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_glass_bl")
		elseif(own_mat_to_be_set == "BLT")  then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_glass_blt")
		elseif(own_mat_to_be_set == "BR")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_glass_br")
		elseif(own_mat_to_be_set == "LR")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_glass_lr")
		elseif(own_mat_to_be_set == "LTR")  then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_glass_ltr")
		elseif(own_mat_to_be_set == "RBL")  then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_glass_rbl")
		elseif(own_mat_to_be_set == "TB")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_glass_tb")
		elseif(own_mat_to_be_set == "TL")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_glass_tl")
		elseif(own_mat_to_be_set == "TR")   then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_glass_tr")
		elseif(own_mat_to_be_set == "TRB")  then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_glass_trb")
		elseif(own_mat_to_be_set == "TRBL") then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_glass_trbl")
		elseif(own_mat_to_be_set == "DEFAULT") then could_place = world.placeMaterial(cur_Pos, layer, "madtulip_glass_default")
		else
			return nil
		end
	else
		-- default
		return nil
	end
	
	return could_place
end