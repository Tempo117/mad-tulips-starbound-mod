madtulip_pf = {}

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

--------------------------------------------------------------------------

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

function madtulip_pf.getNeighbours(node, walkable, allowDiagonal, tunnel, clearance)
    local neighbours = {}
    for i = 1,#madtulip_pf.straightOffsets do
        local n = madtulip_pf.get_preprocessed_NodeAt(
            node._x + madtulip_pf.straightOffsets[i].x,
            node._y + madtulip_pf.straightOffsets[i].y
        )
        if n and madtulip_pf.isWalkableAt(n._x, n._y, walkable, clearance) then
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
        if n and madtulip_pf.isWalkableAt(n._x, n._y, walkable, clearance) then
            if tunnel then
                neighbours[#neighbours+1] = n
            else
                local skipThisNode = false
                local n1 = madtulip_pf.get_preprocessed_NodeAt(node._x+diagonalOffsets[i].x, node._y)
                local n2 = madtulip_pf.get_preprocessed_NodeAt(node._x, node._y+diagonalOffsets[i].y)
                if ((n1 and n2) and not madtulip_pf.isWalkableAt(n1._x, n1._y, walkable, clearance) and not madtulip_pf.isWalkableAt(n2._x, n2._y, walkable, clearance)) then
                    skipThisNode = true
                end
                if not skipThisNode then neighbours[#neighbours+1] = n end
            end
        end
    end

    return neighbours
end

function madtulip_pf.isWalkableAt(x, y, walkable, clearance)
    local nodeValue = madtulip_pf.finder._grid._map[y] and madtulip_pf.finder._grid._map[y][x]
    if nodeValue then
        if not walkable then return true end
    else
        return false
    end
    local hasEnoughClearance = not clearance and true or false
    if not hasEnoughClearance then
        if not madtulip_pf.finder._grid._isAnnotated[walkable] then return false end
        local node = madtulip_pf.get_preprocessed_NodeAt(x,y)
        local nodeClearance = node._clearance[walkable]
        hasEnoughClearance = (nodeClearance >= clearance)
    end
    if madtulip_pf.finder._grid._eval then
        return walkable(nodeValue) and hasEnoughClearance
    end
    return ((nodeValue == walkable) and hasEnoughClearance)
end

--------------------------------------------------------------------------

function madtulip_pf.new_pathfinder(grid, finderName, walkable)
    madtulip_pf.finder = {}
    madtulip_pf.finder._grid = grid
    madtulip_pf.finder._finder = madtulip_pf.ASTAR
    madtulip_pf.finder._walkable = walkable
    madtulip_pf.finder._grid._eval = walkable and type(walkable) == 'function'
    madtulip_pf.finder._allowDiagonal = true
    madtulip_pf.finder._heuristic = madtulip_pf.EUCLIDIAN
    madtulip_pf.finder._tunnel = true
    madtulip_pf.finder._toClear = {}
end

function madtulip_pf.getPath(startX, startY, endX, endY, clearance)
    madtulip_pf.reset_pf() -- <- not fully done yet!
    local startNode = madtulip_pf.get_preprocessed_NodeAt(startX, startY)
    local endNode = madtulip_pf.get_preprocessed_NodeAt(endX, endY)
    --assert(startNode, ('Invalid location [%d, %d]'):format(startX, startY))
    --assert(endNode and madtulip_pf.finder._grid:isWalkableAt(endX, endY),
    --('Invalid or unreachable location [%d, %d]'):format(endX, endY))
    local _endNode = madtulip_pf.finder._finder(startNode, endNode, clearance)
    if _endNode then
        --print "END NODE!"
        -- create madtulip_pf.path
        return madtulip_pf.traceBackPath(_endNode, startNode)
    end
    return nil
end

function madtulip_pf.reset_pf()
    -- TODO: this probably needs to target nodes in newPathfinder._grid._nodes
    -- toClear should contain keys for this nodes
    for node in pairs(madtulip_pf.finder._toClear) do madtulip_pf.reset_Node(node) end
    madtulip_pf.finder._toClear = {}
end

function madtulip_pf.get_preprocessed_NodeAt(x,y)
    return madtulip_pf.finder._grid._nodes[y] and madtulip_pf.finder._grid._nodes[y][x] or nil
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
            node = node._parent
        else
            table.insert(madtulip_pf.path._nodes,1,startNode)
            --print "END of path build"
            return madtulip_pf.path
        end
    end
end

----------------------------------------------------------

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


----------------------------------------------------------------------------

--- Inits a new `node`
-- @class function
-- @tparam int x the x-coordinate of the node on the collision map
-- @tparam int y the y-coordinate of the node on the collision map
-- @treturn node a new `node`
-- @usage local node = Node(3,4)
function madtulip_pf.new_Node(x,y)
    return setmetatable({_x = x, _y = y, _clearance = {}}, Node)
end

function madtulip_pf.reset_Node(Node)
    Node._g, Node._h, Node._f = nil, nil, nil
    Node._opened, Node._closed, Node._parent = nil, nil, nil
    return Node
end

---------------------------------------------------------------------------


function madtulip_pf.EUCLIDIAN(nodeA, nodeB)
    local dx = nodeA._x - nodeB._x
    local dy = nodeA._y - nodeB._y
    return math.sqrt(dx*dx+dy*dy)
end

function madtulip_pf.ASTAR(startNode, endNode, clearance)
    --local openList = Heap()
    madtulip_pf.Heap = {}
    startNode._g = 0
    startNode._h = madtulip_pf.finder._heuristic(endNode, startNode)
    startNode._f = startNode._g + startNode._h
    --openList:push(startNode)
    madtulip_pf.Heap[#madtulip_pf.Heap+1] = startNode
    madtulip_pf.finder._toClear[startNode] = true
    startNode._opened = true

    --while not openList:empty() do
    while not (#madtulip_pf.Heap == 0) do
        --print (#madtulip_pf.Heap)
        --local node = openList:pop()
        local node = madtulip_pf.Heap[#madtulip_pf.Heap];madtulip_pf.Heap[#madtulip_pf.Heap] = nil
        node._closed = true
        if node == endNode then return node end
        local neighbours = madtulip_pf.getNeighbours(node, madtulip_pf.finder._walkable, madtulip_pf.finder._allowDiagonal, madtulip_pf.finder._tunnel)
        for i = 1,#neighbours do
            local neighbour = neighbours[i]
            if not neighbour._closed then
                madtulip_pf.finder._toClear[neighbour] = true
                if not neighbour._opened then
                    neighbour._g = huge
                    neighbour._parent = nil
                end
                madtulip_pf.updateVertex(node, neighbour, endNode, clearance)
            end
        end
    end

    return nil
end

-- Updates vertex node-neighbour
function madtulip_pf.updateVertex(node, neighbour, endNode, clearance)
    local oldG = neighbour._g
    if (oldG == nil) then oldG = math.huge end
    neighbour = madtulip_pf.computeCost(node, neighbour, clearance)
    if neighbour._g < oldG then
        local nClearance = neighbour._clearance[madtulip_pf.finder._walkable]
        local pushThisNode = clearance and nClearance and (nClearance >= clearance)
        if (clearance and pushThisNode) or (not clearance) then
            if neighbour._opened then neighbour._opened = false end
            neighbour._h = madtulip_pf.finder._heuristic(endNode, neighbour)
            neighbour._f = neighbour._g + neighbour._h
            --openList:push(neighbour)
            madtulip_pf.Heap[#madtulip_pf.Heap +1] = neighbour
            neighbour._opened = true
        end
    end
end

-- Updates G-cost
function madtulip_pf.computeCost(node, neighbour, clearance)
    local mCost = madtulip_pf.finder._heuristic(neighbour, node)
    if (neighbour._g == nil) or (node._g + mCost < neighbour._g) then
        neighbour._parent = node
        neighbour._g = node._g + mCost
    end

    return neighbour
end

