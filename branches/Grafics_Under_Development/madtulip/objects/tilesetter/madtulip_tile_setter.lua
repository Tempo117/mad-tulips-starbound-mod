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
	
	-- to check for tiles
	self.BB = {}
	self.BB[1] = self.pos[1]-self.boxsize;
	self.BB[2] = self.pos[2]-self.boxsize;
	self.BB[3] = self.pos[1]+self.boxsize;
	self.BB[4] = self.pos[2]+self.boxsize;

	-- prevent tile setter from killing itself
	self.anchor = {}
	self.anchor[1] = self.pos[1]-2;
	self.anchor[2] = self.pos[2]-2;
	self.anchor[3] = self.pos[1]+0;
	self.anchor[4] = self.pos[2]+0;
	local cur_mat = nil;
	local cur_Pos = {};
	for X = self.anchor[1],self.anchor[3],1 do
		for Y = self.anchor[2],self.anchor[4],1 do
			cur_Pos[1] = X;
			cur_Pos[2] = Y;
			cur_mat = world.material(cur_Pos, "background")
			if (get_tileset_mat_type(cur_mat) ~= nil) then
				-- one of my backgrounds is a tile. stop the process.
				return { "ShowPopup", { message =  "Cant execute! The Tilesetter is anchored on tiles itself!"}};
			end
		end
	end
	
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
					if     (self.neighbours[1] and self.neighbours[3] and self.neighbours[5] and self.neighbours[7]) then own_mat_to_be_set = "trbl"
					-- T
					elseif (self.neighbours[1] and self.neighbours[3] and self.neighbours[5]) then own_mat_to_be_set = "trb"
					elseif (self.neighbours[3] and self.neighbours[5] and self.neighbours[7]) then own_mat_to_be_set = "rbl"
					elseif (self.neighbours[5] and self.neighbours[7] and self.neighbours[1]) then own_mat_to_be_set = "blt"
					elseif (self.neighbours[7] and self.neighbours[1] and self.neighbours[3]) then own_mat_to_be_set = "ltr"
					-- Corner
					elseif (self.neighbours[1] and self.neighbours[3]) then own_mat_to_be_set = "tr"
					elseif (self.neighbours[3] and self.neighbours[5]) then own_mat_to_be_set = "br"
					elseif (self.neighbours[5] and self.neighbours[7]) then own_mat_to_be_set = "bl"
					elseif (self.neighbours[7] and self.neighbours[1]) then own_mat_to_be_set = "tl"
					-- straight
					elseif (self.neighbours[1] and self.neighbours[5]) then own_mat_to_be_set = "tb"
					elseif (self.neighbours[3] and self.neighbours[7]) then own_mat_to_be_set = "lr"
					-- single ended straight
					elseif (self.neighbours[1]) then own_mat_to_be_set = "tb"
					elseif (self.neighbours[5]) then own_mat_to_be_set = "tb"
					elseif (self.neighbours[3]) then own_mat_to_be_set = "lr"
					elseif (self.neighbours[7]) then own_mat_to_be_set = "lr"
					else
						own_mat_to_be_set = "default"
					end
					
					if (place_block_here) then
						-- check if the current block is already the same as the block we want to place
						if not (cur_F_mat == "madtulip_" .. f_tileset_mat_type .. "_" .. own_mat_to_be_set) then
							-- place only if block to be placed is different from current block.
							-- world.logInfo ("cur_F_mat:" .. cur_F_mat .. " f_tileset_mat_type:" .. f_tileset_mat_type .. " own_mat_to_be_set:" .. own_mat_to_be_set)
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
	if cur_F_mat == nil then return nil end
	if cur_F_mat == false then return nil end
	
	if string.find(cur_F_mat, "madtulip_apex3_") then return "apex3" end
	if string.find(cur_F_mat, "madtulip_apex2_") then return "apex2" end
	if string.find(cur_F_mat, "madtulip_apex_") then return "apex" end
	if string.find(cur_F_mat, "madtulip_avian3_") then return "avian3" end
	if string.find(cur_F_mat, "madtulip_avian2_") then return "avian2" end
	if string.find(cur_F_mat, "madtulip_avian_") then return "avian" end
	if string.find(cur_F_mat, "madtulip_floran3_") then return "floran3" end
	if string.find(cur_F_mat, "madtulip_floran2_") then return "floran2" end
	if string.find(cur_F_mat, "madtulip_floran_") then return "floran" end
	if string.find(cur_F_mat, "madtulip_glitch3_") then return "glitch3" end
	if string.find(cur_F_mat, "madtulip_glitch2_") then return "glitch2" end
	if string.find(cur_F_mat, "madtulip_glitch_") then return "glitch" end
	if string.find(cur_F_mat, "madtulip_human3_") then return "human3" end
	if string.find(cur_F_mat, "madtulip_human2_") then return "human2" end
	if string.find(cur_F_mat, "madtulip_human_") then return "human" end
	if string.find(cur_F_mat, "madtulip_hylotl3_") then return "hylotl3" end
	if string.find(cur_F_mat, "madtulip_hylotl2_") then return "hylotl2" end
	if string.find(cur_F_mat, "madtulip_hylotl_") then return "hylotl" end
	if string.find(cur_F_mat, "madtulip_novakid3_") then return "novakid3" end
	if string.find(cur_F_mat, "madtulip_novakid2_") then return "novakid2" end
	if string.find(cur_F_mat, "madtulip_novakid_") then return "novakid" end
	if string.find(cur_F_mat, "madtulip_glass_") then return "glass" end
	
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
	if not(   (f_tileset_mat_type == "apex")
           or (f_tileset_mat_type == "apex2")
		   or (f_tileset_mat_type == "apex3")
		   or (f_tileset_mat_type == "avian") 
		   or (f_tileset_mat_type == "avian2") 
		   or (f_tileset_mat_type == "avian3") 
		   or (f_tileset_mat_type == "floran") 
		   or (f_tileset_mat_type == "floran2") 
		   or (f_tileset_mat_type == "floran3") 
		   or (f_tileset_mat_type == "glitch") 
		   or (f_tileset_mat_type == "glitch2") 
		   or (f_tileset_mat_type == "glitch3") 
		   or (f_tileset_mat_type == "human") 
		   or (f_tileset_mat_type == "human2") 
		   or (f_tileset_mat_type == "human3") 
		   or (f_tileset_mat_type == "hylotl") 
		   or (f_tileset_mat_type == "hylotl2") 
		   or (f_tileset_mat_type == "hylotl3") 
		   or (f_tileset_mat_type == "novakid") 
		   or (f_tileset_mat_type == "novakid2") 
		   or (f_tileset_mat_type == "novakid3") 
		   or (f_tileset_mat_type == "glass")) then return nil end
	if not(   (own_mat_to_be_set == "bl")
           or (own_mat_to_be_set == "blt") 
		   or (own_mat_to_be_set == "br") 
		   or (own_mat_to_be_set == "lr") 
		   or (own_mat_to_be_set == "ltr") 
		   or (own_mat_to_be_set == "rbl") 
		   or (own_mat_to_be_set == "tb") 
		   or (own_mat_to_be_set == "tl") 
		   or (own_mat_to_be_set == "tr") 
		   or (own_mat_to_be_set == "trb") 
		   or (own_mat_to_be_set == "trbl") 
		   or (own_mat_to_be_set == "default")) then return nil end
		   
	could_place = world.placeMaterial(cur_Pos, layer, "madtulip_" .. f_tileset_mat_type .. "_" .. own_mat_to_be_set)
	
	return could_place
end