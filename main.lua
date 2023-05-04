love.math.setRandomSeed(89876)

local Delaunay = require "delaunay"

local points = {}
local constraints = {}
local triangles = nil


function love.load()
  for i = 1, 20 do
    local x = love.math.random(200, 600)
    local y = love.math.random(100, 500)
    table.insert(points, Delaunay.vertex(x, y))
  end

  constraints =  {
    Delaunay.vertex(300, 200),
    Delaunay.vertex(300, 400),
    Delaunay.vertex(400, 400),
    Delaunay.vertex(400, 200),
  }
end

function love.draw()
  for i, p in ipairs(points) do
    love.graphics.circle("fill", p.position[1], p.position[2], 2)
  end

  for i, p in ipairs(constraints) do
    love.graphics.push("all")
    love.graphics.setColor(0, 1, 0)
    love.graphics.circle("fill", p.position[1], p.position[2], 3)
    love.graphics.pop()
  end

  if triangles then
    for i, triangle in ipairs(triangles) do
      love.graphics.push("all")
      local a = triangle.v1
      local b = triangle.v2
      local c = triangle.v3
      love.graphics.setColor(1, 0, 0, 1)
      love.graphics.setLineJoin("none")
      love.graphics.polygon("line", a.position[1], a.position[2], b.position[1], b.position[2], c.position[1], c.position[2])
      love.graphics.pop()
    end
  end
end

function love.keypressed(key)
  if key == "d" then
    triangles = Delaunay.triangulate(points)
  end

  if key == "s" then
    triangles = Delaunay.simpleTriangulation(points)
  end

  if key == "c" then
    triangles = Delaunay.constrainedTriangulation(points, constraints)

    print(#triangles)
  end

  if key == "r" then
    points = {}
    triangles = nil

    for i = 1, 20 do
      local x = love.math.random(200, 600)
      local y = love.math.random(100, 500)
      table.insert(points, Delaunay.vertex(x, y))
    end
  end
end
