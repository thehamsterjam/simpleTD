local Vector = require( "vector" )
local Luafinding = require( "luafinding" )

-- local X = 0
-- local Y = 0
-- local speed = 100

local tileSize = 20
local maxY = 600/ tileSize
local maxX = 800/ tileSize
local map = {}
local start = Vector( 1, 1 )
local finish = Vector( maxX, maxY )
local path = nil
local counter = 0


local creeps = {}
local creepSpeed = 0.5
local towers = {}
local attacks = {}

local roundCount = 0
local creepsPerRound = 10
local roundLength = 60
local roundTimer = 0
local timeToNextCreep = 9999 --make sure creep is spawned

local function updatePath(startPos)
    return Luafinding( startPos, finish, function ( pos )
        local x, y = pos.x, pos.y
        if not map[x] or not map[x][y] then return false end
        return map[x][y] == 0
    end ):GetPath()
end

function love.load()
    for i = 1,maxX do
        map[i] = {}
        for j = 1,maxY do
            map[i][j] = 0
        end
    end
end

function love.update(dt)
    updateCreeps(dt)

    path = updatePath(start)

    updateTowers(dt)
    updateAttacks(dt)
end

function updateCreeps(dt)
    counter = counter + dt
    roundTimer = roundTimer + dt
    timeToNextCreep = timeToNextCreep + dt

    local toRemove = {}
    for i = 1, #creeps do
        local creep = creeps[i]
        if creep.life <= 0 then
            table.insert(toRemove, i)
        end
    end
    removeAll(creeps, toRemove)

    if counter > creepSpeed then
        counter = 0
        for i = 1, #creeps do
            local creep = creeps[i]

            local creepPath = updatePath(creep.pos)
            if creepPath ~= nil then
                creep.pos.x = creepPath[2].x
                creep.pos.y = creepPath[2].y
            end
        end
    end

    if timeToNextCreep > (roundLength / creepsPerRound) then
        timeToNextCreep = 0
        spawnCreep()
    end
end

function spawnCreep()
    table.insert(creeps, {
        pos = Vector(1, 1),
        life = 2
    })
end

function updateCreep(creep)

end

function updateTowers(dt)
    for i = 1, #towers do
        updateTower(towers[i], dt)
    end
end

function updateTower(tower, dt)
    tower.cooldown = tower.cooldown - dt
    if tower.cooldown <= 0 then
        tower.cooldown = 0
        local closestCreep, closestCreepDist = closestCreep(tower)
        if closestCreep == nil or closestCreepDist > tower.range then
            return
        end
        addNewAttack(tower, closestCreep)
        tower.cooldown = tower.cooldownLength
    end
end

function updateAttacks(dt)
    local toRemove = {}
    for i = 1, #attacks do
        local attack = attacks[i]
        attack.timeOnScreen = attack.timeOnScreen - dt
        if attack.timeOnScreen <= 0 then
            attack.creep.life = attack.creep.life - attack.damage
            table.insert(toRemove, i)
        end
    end
    removeAll(attacks, toRemove)
end

function removeAll(tbl, toRemove)
    for i = 1, #toRemove do
        table.remove(tbl, toRemove[i])
    end
end

function closestCreep(tower)
    local closestCreep = nil
    local closestCreepDist = 999999
    for i = 1, #creeps do
        local creep = creeps[i]
        local creepDist = dist(creep, tower)
        if creepDist < closestCreepDist then
            closestCreep = creeps[i]
            closestCreepDist = creepDist
        end
    end
    return closestCreep, closestCreepDist
end

function dist(creep, tower)
    return math.sqrt((creep.pos.x - tower.pos.x)^2 + (creep.pos.y - tower.pos.y))
end

function addNewAttack(tower, creep)
    print(tower, creep)

    table.insert(attacks, createAttack(tower, creep))
end

function createAttack(tower, creep)
    return {
        tower = tower,
        creep = creep,
        damage = tower.damage,
        timeOnScreen = 0.5
    }
end

function createWall(x, y)
    local _x, _y = mouseToMap(x), mouseToMap(y)
    map[_x][_y] = 1
end


function createTower(x, y)
    local _x, _y = mouseToMap(x), mouseToMap(y)
    map[_x][_y] = 2
    towers[#towers + 1] = {
        pos = {
            x = _x,
            y = _y
        },
        range = 8,
        cooldown = 0,
        cooldownLength = 5,
        damage = 1
    }
end

function deleteAt(x, y)
    local _x, _y = mouseToMap(x), mouseToMap(y)
    map[_x][_y] = 0
    -- todo delete towers
end

function drawTile(x, y)
    love.graphics.rectangle("fill", (x - 1)*tileSize, (y - 1)*tileSize, tileSize, tileSize)
end

function drawCreep(creep)
    local x, y = creep.pos.x, creep.pos.y
    love.graphics.rectangle("fill", (x - 1)*tileSize + tileSize / 3, (y - 1)*tileSize + tileSize / 3, tileSize / 3, tileSize / 3)
end

function renderMap()
    for i = 1,maxX do
        for j = 1,maxY do
            if map[i][j] == 0 then
                goto continue
            end
            if map[i][j] == 1 then
                love.graphics.setColor(1, 0, 0)
            elseif map[i][j] == 2 then
                love.graphics.setColor(0, 1, 0)
            end
            drawTile(i, j)
            ::continue::
        end
    end
    love.graphics.setColor(1, 1, 1)
end

function mouseToMap(x)
    return (x - x % tileSize) / tileSize + 1
end

function love.mousepressed( x, y, button, istouch, presses)
    for i = 1,#creeps do
        if creeps[i].pos.x == mouseToMap(x) and creeps[i].pos.y == mouseToMap(y) then
            return
        end
    end
    if button == 1 then
        createWall(x, y)
    elseif button == 2 then
        createTower(x, y)
    else
        deleteAt(x, y)
    end

    path = updatePath(start)

    if path == nil then
        deleteAt(x, y)
    end
end

function love.draw()
    renderMap()
    love.graphics.setColor(1, 1, 1)

    drawTile(start.x, start.y)
    love.graphics.setColor(1, 1, 1)
    drawTile(finish.x, finish.y)

    drawPath()

    drawCreeps()

    drawAttacks()
end

function drawPath()
    if path then
        love.graphics.setColor( 0,  0 , 0.8)
        for _, v in ipairs( path ) do
            drawTile(v.x, v.y)
        end
        love.graphics.setColor( 0, 0, 0 )
    end
end

function drawCreeps()
    love.graphics.setColor( 1, 1, 0 )
    for i = 1,#creeps do
        drawCreep(creeps[i])
    end
end

function posToPx(pos)
    return {
        x = (pos.x - 1) * tileSize + tileSize / 2,
        y = (pos.y - 1) * tileSize + tileSize / 2
    }
end
function drawAttacks()
    love.graphics.setLineWidth(2)
    love.graphics.setColor(0.349, 1, 0.875)
    for i = 1, #attacks do
        local attack = attacks[i]
        local towerPos = posToPx(attack.tower.pos)
        local creepPos = posToPx(attack.creep.pos)
        love.graphics.line(towerPos.x, towerPos.y, creepPos.x, creepPos.y)
    end
    
end

function love.keypressed(key, u)
   --Debug
   if key == "t" then --set to whatever key you want to use
      debug.debug()
   end
end

function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
 end
