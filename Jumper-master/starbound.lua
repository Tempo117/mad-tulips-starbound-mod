-- heuristic -> euclidian
function  overrideCostEval(node, neighbour, finder, clearance)
	-- clearance parameter is set by :getPath and should be 1
	
	-- if neighbour clearance was in the air we need to go back through all parents of neighbour until we find ground
	-- we store all relative {x,y} in trajectory,
	-- where first ground is {0,0} and each parent as well as current node are some offset of that
	--    X 
	--   X X
	--  X   X
	-- X
	-- _____
	
	-- trajectory has to be compared with a tree containing all possible jump trajectories
	-- to find cost increase for this new node at the end of the current trajectory.
	-- Jumps which are not contained in this tree have to be marked with math.huge costs.
	-- As we cant (?) re assign costs for older nodes the costs for all possible jump combinations
	-- which overlap need to be the same up to the point where they overlap (which is given by a tree)
	
	local mCost = Heuristics.EUCLIDIAN(neighbour, node)
	if node._g + mCost < neighbour._g then
		neighbour._parent = node
		neighbour._g = node._g + mCost
	end
end