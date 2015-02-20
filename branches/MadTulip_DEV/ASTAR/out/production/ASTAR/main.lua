-- Here we want to find a path from current position to target
-- Set up a collision map
local map = {
    {0,1,0,1,0},
    {0,1,0,1,0},
    {0,1,1,1,0},
    {0,0,0,0,0},
}
-- Value for walkable tiles
local walkable = 0

print "--- Creating Grid ---"
local grid = madtulip_pf.new_grid(map);
print "--- Creating Pathfinder ---"
madtulip_pf.new_pathfinder(grid, 'ASTAR', walkable)

-- start and end of path to find
local startx, starty = 1,1
local endx, endy = 5,1

print "--- Searching Path ---"
print "--- Warning! madtulip_pf.reset_pf() skipped! ---"
local path = madtulip_pf.getPath(startx, starty, endx, endy)

-- Pretty-printing the results
if path then
    print(('Path found! Length: %.2f'):format(#path._nodes))
    for count,node in pairs(path._nodes) do
        print(('Step: %d - x: %d - y: %d'):format(count, node._x, node._y))
    end
else
    print('NO Path found!')
end




