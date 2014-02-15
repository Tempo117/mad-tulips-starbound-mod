madtulip_pf = {}

------------------------------Constants--------------------------------------------
-- Offsets for straights moves
madtulip_pf.straightOffsets = {
    {x = 1, y = 0} --[[W]], {x = -1, y =  0}, --[[E]]
    {x = 0, y = 1} --[[S]], {x =  0, y = -1}, --[[N]]
}
-- Offsets for diagonal moves
madtulip_pf.diagonalOffsets = {
    {x = -1, y = -1} --[[NW]], {x = 1, y = -1}, --[[NE]]
    {x = -1, y =  1} --[[SW]], {x = 1, y =  1}, --[[SE]]
}

-- TODO: create possible jump trajectory entries from jumping experiments in game
madtulip_pf.PossibleJumpTrajectories ={
    -- jump trajectories include the start node where the player was still on ground as well as
    -- the end node where the player hits ground again.
    -- the x and y values are relative offsets to the start of the rump. so root is allways at 0,0.
    -- a jump can be left at any point of the trajectory.

    {{x = 0, y = 0},{x = 0, y = 1},{x = 0, y = 2},{x = 0, y = 3},{x = 0, y = 4},{x = 0, y = 5},{x = 1, y = 5},{x = 2, y = 5}}
--[[
    --  XX
    -- XXXX
    --XX  XX
    --X    X
    {{x = 0, y = 0},{x = 1, y = 0},{x = 2, y = 0},{x = 2, y = 1},{x = 3, y = 1},{x = 3, y = 2},{x = 4, y = 3},{x = 4, y = 4},{x = 3, y = 4},{x = 3, y = 5},{x = 2, y = 5},{x = 2, y = 6},{x = 1, y = 6}},
    --  XX
    --  XX
    -- X
    -- X
    --X
    --X
    {{x = 0, y = 0},{x = 1, y = 0},{x = 2, y = 0},{x = 3, y = 1},{x = 4, y = 1},{x = 5, y = 2},{x = 6, y = 2},{x = 5, y = 3} }
    ]]
}
------------------------------Heuristics--------------------------------------------
function madtulip_pf.EUCLIDIAN(neighbour, startnode)
    local dx = neighbour._x - startnode._x
    local dy = neighbour._y - startnode._y
    return math.sqrt(dx*dx+dy*dy)
end

function madtulip_pf.Jump_EUCLIDIAN(neighbour, node)
    -- this block checks if we are jumping
    -- if thats not the case its just the normal euclidian costs
    local jumping = false
    if madtulip_pf.NodeIsInAir(neighbour) or madtulip_pf.NodeIsInAir(node) then
        jumping = true
        -- we are jumping or falling
        -- check if there is a possible jump trajectory leading to this point
        local jump_path = madtulip_pf.tracebackJump (neighbour, node)
        local jump_path_is_valid = madtulip_pf.validate_jump_path(jump_path)
        if not jump_path_is_valid then return math.huge end -- this jump is no possible way
    end

    -- return same cost as euclidian if jump can be done !
    -- thats important as euclidian is used alone elsewhere.
    return madtulip_pf.EUCLIDIAN(neighbour, node)
end

------------------------------Grid--------------------------------------------
function madtulip_pf.new_grid(map, cacheNodeAtRuntime)
    --[[
        if type(map) == 'string' then
                assert(Assert.isStrMap(map), 'Wrong argument #1. Not a valid string map')
                map = Utils.strToMap(map)
        end
        assert(Assert.isMap(map),('Bad argument #1. Not a valid map'))
        assert(Assert.isBool(cacheNodeAtRuntime) or Assert.isNil(cacheNodeAtRuntime),
          ('Bad argument #2. Expected \'boolean\', got %s.'):format(type(cacheNodeAtRuntime)))
        if cacheNodeAtRuntime then
            return PostProcessGrid:new(map,walkable)
        end
    --]]
    return madtulip_pf.new_PreProcessGrid(map,walkable)
end

function madtulip_pf.new_PreProcessGrid(map)
    local newGrid = {}
    newGrid._map = map
    newGrid._nodes = madtulip_pf.arrayToNodes(newGrid._map)
    newGrid._min_x, newGrid._max_x, newGrid._min_y, newGrid._max_y = madtulip_pf.getArrayBounds(newGrid._map)
    newGrid._width  = (newGrid._max_x-newGrid._min_x)+1
    newGrid._height = (newGrid._max_y-newGrid._min_y)+1
    newGrid._isAnnotated = {}
    --world.logInfo("newGrid With: " .. newGrid._width .. " Height: " .. newGrid._height)
    --world.logInfo("newGrid _min_x: " .. newGrid._min_x .. " _max_x: " .. newGrid._max_x)
    --world.logInfo("newGrid _min_y: " .. newGrid._min_y .. " _max_y: " .. newGrid._max_y)
    return setmetatable(newGrid,PreProcessGrid)
end

function madtulip_pf.getNeighbours(node, walkable, allowDiagonal, tunnel, clearance_size_shift, clearance)
    local neighbours = {}
    for i = 1,#madtulip_pf.straightOffsets do
        local n = madtulip_pf.get_preprocessed_NodeAt(
            node._x + madtulip_pf.straightOffsets[i].x,
            node._y + madtulip_pf.straightOffsets[i].y
        )
        if n and madtulip_pf.isWalkableAt(n._x, n._y, walkable, clearance, clearance_size_shift) then
            neighbours[#neighbours+1] = n
        end
    end

    if not allowDiagonal then return neighbours end

    tunnel = not not tunnel
    for i = 1,#madtulip_pf.diagonalOffsets do
        local n = madtulip_pf.get_preprocessed_NodeAt(
            node._x + madtulip_pf.diagonalOffsets[i].x,
            node._y + madtulip_pf.diagonalOffsets[i].y
        )
        if n and madtulip_pf.isWalkableAt(n._x, n._y, walkable, clearance, clearance_size_shift) then
            if tunnel then
                neighbours[#neighbours+1] = n
            else
                local skipThisNode = false
                local n1 = madtulip_pf.get_preprocessed_NodeAt(node._x+diagonalOffsets[i].x, node._y)
                local n2 = madtulip_pf.get_preprocessed_NodeAt(node._x, node._y+diagonalOffsets[i].y)
                if ((n1 and n2) and not madtulip_pf.isWalkableAt(n1._x, n1._y, walkable, clearance, clearance_size_shift) and not madtulip_pf.isWalkableAt(n2._x, n2._y, walkable, clearance, clearance_size_shift)) then
                    skipThisNode = true
                end
                if not skipThisNode then neighbours[#neighbours+1] = n end
            end
        end
    end

    return neighbours
end

function madtulip_pf.isWalkableAt(x, y, walkable, clearance, clearance_size_shift)
    local nodeValue = madtulip_pf.finder._grid._map[y] and madtulip_pf.finder._grid._map[y][x]
    if nodeValue then
        if not walkable then
            return true
        end
    else
        return false
    end
    local hasEnoughClearance = not clearance and true or false
    if not hasEnoughClearance then
        if not madtulip_pf.finder._grid._isAnnotated[walkable] then
            return false
        end
        --local node = madtulip_pf.get_preprocessed_NodeAt(x+offset_x,y+offset_y)
        --local nodeClearance = node._clearance[walkable]
        --hasEnoughClearance = (nodeClearance >= clearance)
        hasEnoughClearance = true
        for offset_x = 0,clearance_size_shift[1],1 do
            for offset_y = 0,clearance_size_shift[2],1 do
                local node = madtulip_pf.get_preprocessed_NodeAt(x+offset_x,y+offset_y)
                if (node ~= nil) then
                    local nodeClearance = node._clearance[walkable]
                    if not(nodeClearance >= clearance) then
                        hasEnoughClearance = false
                    end
                else
                    -- out of map
                    hasEnoughClearance = false
                end
            end
        end
    end
    if madtulip_pf.finder._grid._eval then
        return walkable(nodeValue) and hasEnoughClearance
    end
    return ((nodeValue == walkable) and hasEnoughClearance)
end

function madtulip_pf.annotateGrid(min_x,max_x,min_y,max_y)
    -- get values from pf if parameters not given
    if (min_x == nil) then min_x = madtulip_pf.finder._grid._min_x end
    if (max_x == nil) then max_x = madtulip_pf.finder._grid._max_x end
    if (min_y == nil) then min_y = madtulip_pf.finder._grid._min_y end
    if (max_y == nil) then max_y = madtulip_pf.finder._grid._max_y end

    for x=max_x,min_x,-1 do
        for y=max_y,min_y,-1 do
            local node = madtulip_pf.get_preprocessed_NodeAt(x,y)
            if madtulip_pf.isWalkableAt(x,y,madtulip_pf.finder._walkable) then
                local nr  = madtulip_pf.get_preprocessed_NodeAt(node._x+1, node._y  )
                local nrd = madtulip_pf.get_preprocessed_NodeAt(node._x+1, node._y+1)
                local nd  = madtulip_pf.get_preprocessed_NodeAt(node._x  , node._y+1)
                if nr and nrd and nd then
                    local m = nrd._clearance[madtulip_pf.finder._walkable] or 0
                    m = (nd._clearance[madtulip_pf.finder._walkable] or 0)<m and (nd._clearance[madtulip_pf.finder._walkable] or 0) or m
                    m = (nr._clearance[madtulip_pf.finder._walkable] or 0)<m and (nr._clearance[madtulip_pf.finder._walkable] or 0) or m
                    node._clearance[madtulip_pf.finder._walkable] = m+1
                else
                    node._clearance[madtulip_pf.finder._walkable] = 1
                end
            else
                node._clearance[madtulip_pf.finder._walkable] = 0
            end
            madtulip_pf.finder._grid._nodes[y][x] = node
        end
    end
    madtulip_pf.finder._grid._isAnnotated[madtulip_pf.finder._walkable] = true
end

--------------------------------Nodes------------------------------------------
function madtulip_pf.new_Node(x,y)
    return setmetatable({_x = x, _y = y, _clearance = {}}, Node)
end

function madtulip_pf.reset_Node(x,y)
    local Node = madtulip_pf.get_preprocessed_NodeAt(x,y)
    -- overwrite its parameters with default
    Node._g, Node._h, Node._f = nil, nil, nil
    Node._opened, Node._closed, Node._parent = nil, nil, nil
    -- write it back to global structure
    madtulip_pf.finder._grid._nodes[Node._y][Node._x] = Node
    return Node
end

function madtulip_pf.get_preprocessed_NodeAt(x,y)
    return madtulip_pf.finder._grid._nodes[y] and madtulip_pf.finder._grid._nodes[y][x] or nil
end

function madtulip_pf.getClearance(x,y,walkable)
    local node = madtulip_pf.get_preprocessed_NodeAt(x,y)
    return node._clearance[walkable]
end

function madtulip_pf.NodeIsInAir(node)
    local nodeValue = madtulip_pf.finder._grid._map[node._x] and madtulip_pf.finder._grid._map[node._y][node._x]
    return nodeValue == 0 -- 0 is air
end

-------------------------------Jumping-------------------------------------------
-- This initiates a tree starting at {0,0} the origin of each jump.
-- it branches in all supported jump trajactories (also falling) by indexing subnodes with [x][y] offsets
-- relative to jump starting block. It is later used to validate a certain jump trajectory.
function madtulip_pf.new_JumpMap (Possible_Jump_Trajectories)
    if (Possible_Jump_Trajectories == nil) then Possible_Jump_Trajectories = madtulip_pf.PossibleJumpTrajectories end
    local RootJumpNode = nil
    for idx_cur_JT = 1, #Possible_Jump_Trajectories do
        print ('--- Jump Nr.: ' .. idx_cur_JT .. '---')
        local cur_JT = Possible_Jump_Trajectories[idx_cur_JT]
        local LastJumpNode = nil
        for idx_cur_JT_node = 1, #cur_JT do
            local x = cur_JT[idx_cur_JT_node].x
            local y = cur_JT[idx_cur_JT_node].y
            -- print ('Parsing X: ' .. x .. ' Y: ' .. y)
            -- create new root node if it doesnt exists
            if (RootJumpNode == nil) then
                RootJumpNode = {}
                RootJumpNode.c = {}
            end
            -- start at root if no LastJumpNode for this jump
            if (LastJumpNode == nil) then
                LastJumpNode = RootJumpNode
            end

            -- append NewJumpNode to LastJumpNode if it doesnt exists
            if (LastJumpNode.c[x] == nil) then
                LastJumpNode.c[x] = {}
            end
            if (LastJumpNode.c[x][y] == nil) then
                -- create new node to append
                local NewJumpNode = {}
                NewJumpNode.c = {}
                -- append new node
                LastJumpNode.c[x][y] = NewJumpNode
                print ('X: ' .. x .. ' Y: ' .. y .. ' created.')
            else
                print ('X: ' .. x .. ' Y: ' .. y .. ' already existing.')
            end

            -- set pointer to created or already existing last node
            LastJumpNode = LastJumpNode.c[x][y]
        end
    end
    return RootJumpNode
end

-- This is called by the heuristics. It determines of the jump path that has been taken since liftoff until current node.
function madtulip_pf.tracebackJump (neighbour, node)
    local inv_jump_path = {}
    table.insert(inv_jump_path,1,neighbour) -- current point in jump
    print (' --- Jump Trajectory traceback --- ')
    print ('(From node    X: ' .. node._x .. ' Y: ' .. node._y .. ')')
    print ('to node       X: ' .. neighbour._x .. ' Y: ' .. neighbour._y)
    -- tracback jump tracectory up to the node where the player was on ground before jumping
    while true do
        if (madtulip_pf.NodeIsInAir(node) and node._parent) then
            -- trace path to jump start
            table.insert(inv_jump_path,1,node)
            print ('adding        X: ' .. node._x .. ' Y: ' .. node._y)
            node = madtulip_pf.get_preprocessed_NodeAt(node._parent[1],node._parent[2])
        else
            -- jump start reached
            table.insert(inv_jump_path,1,node)
            print ('START of jump X: ' .. node._x .. ' Y: ' .. node._y .. ' of length: ' .. #inv_jump_path)
            -- inverse order of inv_jump_path so it goes for start ([1]) to end ([#final_jump_path]) of the jump
            local final_jump_path = {}
            for cur_jump_path_idx = #inv_jump_path,1,-1 do
                table.insert(final_jump_path,1,inv_jump_path[cur_jump_path_idx])
            end
            return final_jump_path
        end
    end
end

-- A traced jumppath will be validated to check if its a trajectory possible for game physics.
-- If not the heuristics working on this will return INF costs marking a physically impossible jump as a blocked path.
function madtulip_pf.validate_jump_path(jump_path)
    -- get root of jump
    local rootnode = jump_path[1]

    -- if jump doesnt start on ground its not valid
    if madtulip_pf.NodeIsInAir(rootnode) then return false end

    -- this is a linked tree containing all possible jumps.
    -- its a list with relative offset to jump start in each node
    -- the adress of each following node is that offset.
    -- if there is no populated node at that adress the jump is not possible.
    -- root of tree is on ground where jump starts at {0,0}
    local cur_Possible_JumpConnection = madtulip_pf.finder._JumpConnections

    print ('---- Testing Jump ----')
    print ('Root: x: ' .. rootnode._x .. ' Y: ' .. rootnode._y)

    local sign = 0 -- undefined (not + or - in this case)
    for idxx_cur_node = 1,#jump_path do
        -- get offset from root that we want to move to next
        local x = jump_path[idxx_cur_node]._x - rootnode._x
        local y = jump_path[idxx_cur_node]._y - rootnode._y
        print ('jump_path[' .. idxx_cur_node .. '/' .. #jump_path .. '] at X: ' .. jump_path[idxx_cur_node]._x .. ' Y: ' .. jump_path[idxx_cur_node]._y )

        -- all jumps are just defined from left to right. this block allows mirroring all those jumps
        -- once the jump has decided for a certain direction it has to stay in that direction or will not be valid
        if (x > 0) and (sign < 0) then return false end -- tried to change jump direction, not possible
        if (x < 0) and (sign > 0) then return false end -- tried to change jump direction, not possible
        if (x > 0) then sign = 1 end -- set sign of jump (this is a jump to the right)
        if (x < 0) then sign = -1 end -- set sign of jump (this is a jump to the right)
        if (sign ~= 0) then x = sign*x end

        -- check if that offset is present as one of the possible next nodes in the jump tree
        if cur_Possible_JumpConnection.c[x] ~= nil then
            if cur_Possible_JumpConnection.c[x][y] ~= nil then
                -- This is a possible jump trajectory so far -> go to the next node
                cur_Possible_JumpConnection = cur_Possible_JumpConnection.c[x][y]
                print ('Jump node at X: ' .. x .. ' Y: ' .. y .. ' existed in tree.')
            else
                -- thats not a possible jump because the relative y-offset of this part of the trajectory was no valid option
                print ('Jump node at X: ' .. x .. ' Y: ' .. y .. ' DID NOT exist in tree (y is nil).')
                return false
            end
        else
            -- thats not a possible jump because the relative x-offset of this part of the trajectory was no valid option
            print ('Jump node at X: ' .. x .. ' Y: ' .. y .. ' DID NOT exist in tree (x is nil).')
            return false
        end
    end
    return true
end

--------------------------------Pathfinder------------------------------------------
function madtulip_pf.new_pathfinder(grid,JumpConnections, finder, walkable, heuristic, allowDiagonal, tunnel)
    madtulip_pf.finder = {}
    madtulip_pf.finder._grid = grid
    madtulip_pf.finder._JumpConnections = JumpConnections
    madtulip_pf.finder._finder = finder
    madtulip_pf.finder._walkable = walkable
    madtulip_pf.finder._grid._eval = walkable and type(walkable) == 'function'
    madtulip_pf.finder._allowDiagonal = allowDiagonal
    madtulip_pf.finder._heuristic = heuristic
    madtulip_pf.finder._tunnel = tunnel
    madtulip_pf.finder._toClear = {}
end

function madtulip_pf.getPath(startX, startY, endX, endY, clearance,clearance_size_shift)
    madtulip_pf.reset_pf()
    local startNode = madtulip_pf.get_preprocessed_NodeAt(startX, startY)
    local endNode = madtulip_pf.get_preprocessed_NodeAt(endX, endY)
    --assert(startNode, ('Invalid location [%d, %d]'):format(startX, startY))
    --assert(endNode and madtulip_pf.finder._grid:isWalkableAt(endX, endY),
    --('Invalid or unreachable location [%d, %d]'):format(endX, endY))
    local _endNode = madtulip_pf.finder._finder(startNode, endNode, clearance,clearance_size_shift)
    if _endNode then
        --print "END NODE!"
        -- create madtulip_pf.path
        return madtulip_pf.traceBackPath(_endNode, startNode)
    end
    return nil
end

function madtulip_pf.reset_pf()
    -- toClear should contain keys for this nodes
    for cout,node_pos in pairs(madtulip_pf.finder._toClear) do madtulip_pf.reset_Node(node_pos[1],node_pos[2]) end
    madtulip_pf.finder._toClear = {}
end

-- Extract a path from a given start/end position
function madtulip_pf.traceBackPath(node, startNode)
    --local path = Path:new()
    --path._grid = madtulip_pf.finder._grid
    madtulip_pf.path = {}
    madtulip_pf.path._nodes = {}
    while true do
        if node._parent then
            table.insert(madtulip_pf.path._nodes,1,node)
            node = madtulip_pf.get_preprocessed_NodeAt(node._parent[1],node._parent[2])
        else
            table.insert(madtulip_pf.path._nodes,1,startNode)
            --print "END of path build"
            return madtulip_pf.path
        end
    end
end

-------------------------------ASTAR--------------------------------------------
function madtulip_pf.push_to_heap(node)
    -- perculate up
    for i=#madtulip_pf.Heap,1,-1 do
        madtulip_pf.Heap[i+1] = madtulip_pf.Heap[i]
    end
    -- put at bottom of stack
    madtulip_pf.Heap[1] = {node._x,node._y}
    madtulip_pf.finder._toClear[#madtulip_pf.finder._toClear + 1] = {node._x,node._y}
end

function madtulip_pf.pop_from_heap()
    -- perculate up
    local node = madtulip_pf.get_preprocessed_NodeAt(madtulip_pf.Heap[#madtulip_pf.Heap][1],madtulip_pf.Heap[#madtulip_pf.Heap][2])
    madtulip_pf.Heap[#madtulip_pf.Heap] = nil
    return node
end

function madtulip_pf.ASTAR(startNode, endNode, clearance, clearance_size_shift)
    --local openList = Heap()
    madtulip_pf.Heap = {}
    startNode._g = 0
    -- we dont just jump euclidian here as there is no trjectory from here to end as it is in almost all cases not even a neigbour
    --startNode._h = madtulip_pf.finder._heuristic(endNode, startNode)
    startNode._h = madtulip_pf.EUCLIDIAN(endNode, startNode)
    startNode._f = startNode._g + startNode._h
    --openList:push(startNode)
    madtulip_pf.push_to_heap(startNode)
    startNode._opened = true
    -- store updated node
    --madtulip_pf.finder._grid._nodes[startNode._y][startNode._x] = startNode

    --while not openList:empty() do
    while not (#madtulip_pf.Heap == 0) do
        --print (#madtulip_pf.Heap)
        --local node = openList:pop()
        local node = madtulip_pf.pop_from_heap()
        node._closed = true
        -- store updated node
        madtulip_pf.finder._grid._nodes[node._y][node._x] = node
        if node == endNode then return node end
        local neighbours = madtulip_pf.getNeighbours(node, madtulip_pf.finder._walkable, madtulip_pf.finder._allowDiagonal, madtulip_pf.finder._tunnel, clearance_size_shift, clearance)
        for i = 1,#neighbours do
            -- get nodes again in case it was updated - required?
            --neighbours = madtulip_pf.getNeighbours(node, madtulip_pf.finder._walkable, madtulip_pf.finder._allowDiagonal, madtulip_pf.finder._tunnel)
            local neighbour = neighbours[i]
            if not neighbour._closed then
                madtulip_pf.finder._toClear[#madtulip_pf.finder._toClear + 1] = {neighbour._x,neighbour._y}
                if not neighbour._opened then
                    neighbour._g = math.huge
                    neighbour._parent = nil
                end
                neighbour = madtulip_pf.updateVertex(node, neighbour, endNode, clearance)
                -- store updated node
                madtulip_pf.finder._grid._nodes[neighbour._y][neighbour._x] = neighbour
            end
        end
    end

    return nil
end

-- Updates vertex node-neighbour
function madtulip_pf.updateVertex(node, neighbour, endNode, clearance)
    local oldG = neighbour._g
    neighbour = madtulip_pf.computeCost(node, neighbour, clearance)
    if neighbour._g < oldG then
        local nClearance = neighbour._clearance[madtulip_pf.finder._walkable]
        local pushThisNode = clearance and nClearance and (nClearance >= clearance)
        if (clearance and pushThisNode) or (not clearance) then
            if neighbour._opened then neighbour._opened = false end
            -- we dont just jump euclidian here as there is no trjectory from here to end as it is in almost all cases not even a neigbour
            -- neighbour._h = madtulip_pf.finder._heuristic(endNode, neighbour)
            neighbour._h = madtulip_pf.EUCLIDIAN(endNode, neighbour)
            neighbour._f = neighbour._g + neighbour._h
            --openList:push(neighbour)
            madtulip_pf.push_to_heap(neighbour)
            neighbour._opened = true
        end
    end
    return neighbour
end

-- Updates G-cost
function madtulip_pf.computeCost(node, neighbour, clearance)
    local mCost = madtulip_pf.finder._heuristic(neighbour, node)
    if (neighbour._g == nil) or (node._g + mCost < neighbour._g) then
        neighbour._parent = {node._x,node._y}
        neighbour._g = node._g + mCost
    end

    return neighbour
end

----------------------Utils------------------------------------
-- Converts an array to a set of nodes
function madtulip_pf.arrayToNodes(map)
    local min_x, max_x
    local min_y, max_y
    local nodes = {}
    for y in pairs(map) do
        min_y = not min_y and y or (y<min_y and y or min_y)
        max_y = not max_y and y or (y>max_y and y or max_y)
        nodes[y] = {}
        for x in pairs(map[y]) do
            min_x = not min_x and x or (x<min_x and x or min_x)
            max_x = not max_x and x or (x>max_x and x or max_x)
            nodes[y][x] = madtulip_pf.new_Node(x,y)
        end
    end
    return nodes,
    (min_x or 0), (max_x or 0),
    (min_y or 0), (max_y or 0)
end

function madtulip_pf.getArrayBounds(map)
    local min_x, max_x
    local min_y, max_y
    for y in pairs(map) do
        min_y = not min_y and y or (y<min_y and y or min_y)
        max_y = not max_y and y or (y>max_y and y or max_y)
        for x in pairs(map[y]) do
            min_x = not min_x and x or (x<min_x and x or min_x)
            max_x = not max_x and x or (x>max_x and x or max_x)
        end
    end
    return min_x,max_x,min_y,max_y
end
