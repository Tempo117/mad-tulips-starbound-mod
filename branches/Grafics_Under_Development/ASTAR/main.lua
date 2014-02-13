require "madtulip_pf"

-- Here we want to find a path from current position to target
-- Set up a collision map
--[[
local map = {
    {0,0,0,0,0},
    {0,0,1,0,0},
    {0,0,1,0,0},
    {0,0,1,0,0},
    {0,0,1,0,0}
}
--]]
local map = {
    {0,0,0,0,0,0,0,0,0,0},
    {0,0,0,0,0,0,0,0,1,0},
    {0,0,0,0,0,0,0,0,0,0},
    {0,0,0,1,0,0,0,0,0,0},
    {0,0,1,0,0,0,0,0,1,0},
    {0,0,1,2,1,0,2,1,2,0},
    {0,0,1,1,1,0,1,0,0,1},
    {0,0,0,0,1,0,0,0,0,0},
    {0,0,0,0,0,0,0,0,0,0},
    {0,0,0,0,0,0,0,0,0,0}
}
-- Value for walkable tiles
local walkable = function(v) return v~=2 end
-- TODO: clearance_size_shift doesnt work with negative values due to the for loop implementation counting only up
--- TODO: would it be better to have 2 clearance maps for x and y direction ?
-- TODO: option to update each node the moment he is walked (once per pathfinding!)
-- TODO: jumping
--- TODO: physics and trajectory
--- TODO: heuristics need to assign costs accordingly
-- TODO: generation of map from starbound

-- start and end of path to find
local startx, starty = 2,2
local endx, endy = 9,7
local agent_size = 2
local agent_size_shift = {0,2} -- x,y shift to apply to the agent_size to allow for rect none square agents

print "--- Creating Grid ---"
local grid = madtulip_pf.new_grid(map);

print "--- Creating Pathfinder ---"
madtulip_pf.new_pathfinder(grid, 'ASTAR', walkable)

print "--- Annotating Grid ---"
madtulip_pf.annotateGrid()

print "--- Searching Path ---"
print "--- Warning! madtulip_pf.reset_pf() skipped! ---"
local path = madtulip_pf.getPath(startx, starty, endx, endy, agent_size, agent_size_shift)

-- Pretty-printing the results
if path then
    print(('Path found! Length: %.2f'):format(#path._nodes))
    for count,node in pairs(path._nodes) do
        print(('Step: %d - x: %d - y: %d - g: %f'):format(count, node._x, node._y, node._g))
    end
else
    print('NO Path found!')
end

-- Plot Clearance map
for y = 1, #map do
    local s = ''
    for x = 1, #map[y] do
        local node = madtulip_pf.get_preprocessed_NodeAt(x,y)
        s = (s .. ' ' .. madtulip_pf.getClearance(x,y,walkable))
    end
    print(s)
end



