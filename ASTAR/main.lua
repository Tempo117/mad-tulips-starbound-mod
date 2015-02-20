require "madtulip_pf"

-- TODO: generation of map from starbound
-- TODO: jumping: measure physics and build trajectories
-- TODO: clearance_size_shift doesnt work with negative values due to the for loop implementation counting only up
-- TODO: option to update each node the moment he is walked (once per pathfinding!)

-- Here we want to find a path from current position to target
-- Set up a collision map
-- 0 := air
-- 1 := has floor under it (standable)
-- 2 := blocked
local map = {
    {2,2,2,2,2,2,2,2,2,2},
    {1,1,1,1,1,1,1,1,1,1},
    {0,0,0,0,0,0,0,0,0,0},
    {0,0,0,0,0,0,0,0,0,0},
    {0,0,0,0,0,0,0,0,0,0},
    {0,2,2,2,2,2,2,2,0,0},
    {0,1,1,1,1,1,1,1,0,0},
    {0,0,0,0,0,0,0,0,0,0},
    {0,0,0,0,0,0,0,0,0,0},
    {0,0,0,0,0,0,0,0,0,0}
}
-- Value for walkable tiles
local walkable = function(v) return v~=2 end

-- sizes of agent to move the map
local agent_size =  2
-- x,y shift to apply to the agent_size to allow for rect none square agents
local agent_size_shift = {0,0} -- {0,0} for a quadratic agent_size agent -- {0,2} together with agent_size 2 for a 2,4 player sized model
-- create grid from map
local grid = madtulip_pf.new_grid(map);
-- create jump connection tree (only needed for ground based units)
-- local JumpConnections = madtulip_pf.new_JumpMap ()
-- pathfinden routine
local finder = madtulip_pf.ASTAR
-- heuristic function calculating costs to move from NodeA to NodeB (for ground bound unit that has to jump)
--local heuristic = madtulip_pf.Jump_EUCLIDIAN
-- heuristic function calculating costs to move from NodeA to NodeB (for flyer)
local heuristic = madtulip_pf.Walk_EUCLIDIAN
-- if diagonal movement on the map is allowed
local allowDiagonal = true
-- if a diagonal tunnel through 2 blocked tiles is allowed
local tunnel = true

print "--- Creating Pathfinder ---"
madtulip_pf.new_pathfinder(grid, JumpConnections, finder, walkable, heuristic, allowDiagonal, tunnel)
print "--- Annotating Grid ---"
madtulip_pf.annotateGrid()

print "--- Searching Path ---"
-- start and end of path to find
local startx, starty = 1,2
local endx, endy     = 5,7
-- find a path from start to end
local path = madtulip_pf.getPath(startx, starty, endx, endy, agent_size, agent_size_shift)

-- Pretty-printing the results
-- Path
if path then
    print(('Path found! Length: %.2f'):format(#path._nodes))
    for count,node in pairs(path._nodes) do
        print(('Step: %d - x: %d - y: %d - g: %f - f: %f - h: %f - j: %f'):format(count, node._x, node._y, node._g, node._f, node._h, node._j))
    end
else
    print('NO Path found!')
end
--[[
-- Clearance map
for y = 1, #map do
    local s = ''
    for x = 1, #map[y] do
        local node = madtulip_pf.get_preprocessed_NodeAt(x,y)
        s = (s .. ' ' .. madtulip_pf.getClearance(x,y,walkable))
    end
    print(s)
end
--]]