require "madtulip_pf"

-- TODO: clearance_size_shift doesnt work with negative values due to the for loop implementation counting only up
--- TODO: would it be better to have 2 clearance maps for x and y direction ?
-- TODO: option to update each node the moment he is walked (once per pathfinding!)
-- TODO: jumping
--- TODO: physics and trajectory
--- TODO: heuristics need to assign costs accordingly
-- TODO: generation of map from starbound

-- Here we want to find a path from current position to target
-- Set up a collision map
-- 0 is air
-- 1 has floor under it
-- 2 is not walkable
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
-- start and end of path to find
local startx, starty = 1,2
local endx, endy = 5,7

-- Value for walkable tiles
local walkable = function(v) return v~=2 end
-- sizes of agent to move the map
local agent_size =  2
-- TODO: this needs to be able to handle {0,-2}. i believe the agent is upside down atm!
local agent_size_shift = {0,2} -- x,y shift to apply to the agent_size to allow for rect none square agents
-- create grid from map
local grid = madtulip_pf.new_grid(map);
-- create jump connection tree
local JumpConnections = madtulip_pf.new_JumpMap ()
-- pathfinden routine
local finder = madtulip_pf.ASTAR
-- heuristic function calculating costs to move from NodeA to NodeB
local heuristic = madtulip_pf.Jump_EUCLIDIAN
-- if diagonal movement on the map is allowed
local allowDiagonal = true
-- if a diagonal tunnel through 2 blocked tiles is allowed
local tunnel = true

print "--- Creating Pathfinder ---"
madtulip_pf.new_pathfinder(grid, JumpConnections, finder, walkable, heuristic, allowDiagonal, tunnel)
print "--- Annotating Grid ---"
madtulip_pf.annotateGrid()

print "--- Searching Path ---"
local path = madtulip_pf.getPath(startx, starty, endx, endy, agent_size, agent_size_shift)

-- Pretty-printing the results
-- Path
if path then
    print(('Path found! Length: %.2f'):format(#path._nodes))
    for count,node in pairs(path._nodes) do
        print(('Step: %d - x: %d - y: %d - g: %f - f: %f - h: %f'):format(count, node._x, node._y, node._g, node._f, node._h))
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