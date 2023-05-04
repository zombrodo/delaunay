local Delaunay = {}

local function equals(a, b)
  return a[1] == b[1] and a[2] == b[2]
end

-- =============================================================================
-- Vertex
-- =============================================================================

local Vertex = {}
Vertex.__index = Vertex

function Vertex.new(x, y)
  local self = setmetatable({}, Vertex)
  self.position = { x, y }
  self.halfEdge = nil
  self.triangle = nil
  self.previousVertex = nil
  self.nextVertex = nil

  self.isReflex = false
  self.isConvex = false
  self.isEar = false

  return self
end

function Vertex:equals(other)
  return equals(self.position, other.position)
end

function Delaunay.vertex(x, y)
  return Vertex.new(x, y)
end

-- =============================================================================
-- Triangle
-- =============================================================================

local Triangle = {}
Triangle.__index = Triangle

function Triangle.new(x1, y1, x2, y2, x3, y3)
  local self = setmetatable({}, Triangle)
  self.v1 = Vertex.new(x1, y1)
  self.v2 = Vertex.new(x2, y2)
  self.v3 = Vertex.new(x3, y3)

  self.halfEdge = nil

  return self
end

function Triangle.fromVertices(v1, v2, v3)
  return Triangle.new(
    v1.position[1], v1.position[2],
    v2.position[1], v2.position[2],
    v3.position[1], v3.position[2]
  )
end

function Triangle:changeOrientation()
  local temp = self.v1
  self.v1 = self.v2
  self.v2 = temp
end

-- =============================================================================
-- Half Edge
-- =============================================================================

local HalfEdge = {}
HalfEdge.__index = HalfEdge

function HalfEdge.new(vertex)
  local self = setmetatable({}, HalfEdge)
  self.vertex = vertex
  self.triangle = nil
  self.nextEdge = nil
  self.previousEdge = nil
  self.oppositeEdge = nil
  return self
end

-- =============================================================================
-- Edge
-- =============================================================================

local Edge = {}
Edge.__index = Edge

function Edge.new(x1, y1, x2, y2)
  local self = setmetatable({}, Edge)
  self.v1 = Vertex.new(x1, y1)
  self.v2 = Vertex.new(x2, y2)

  self.isIntersecting = false

  return self
end

function Edge.fromVertices(v1, v2)
  return Edge.new(
    v1.position[1], v1.position[2],
    v2.position[1], v2.position[2]
  )
end

function Edge:flip()
  local temp = self.v1
  self.v1 = self.v2
  self.v2 = temp
end

-- =============================================================================
-- Helpers
-- =============================================================================

local function midpoint(v1, v2)
  local x = v1.position[1] + v2.position[1]
  local y = v1.position[2] + v2.position[2]

  return Vertex.new(x / 2, y / 2)
end

local function checkLineIntersection(a1, a2, b1, b2, includeEnds)
  local d = ((b2[2] - b1[2]) * (a2[1] - a1[1]))
      - ((b2[1] - b1[1]) * (a2[2] - a1[2]))

  if d ~= 0 then
    local ua = ((b2[1] - b1[1]) * (a1[2] - b1[2])
      - (b2[2] - b1[2]) * (a1[1] - b1[1]))

    local ub = ((a2[1] - a1[1]) * (a1[2] - b1[2])
      - (a2[2] - a1[2]) * (a1[1] - b1[1]))

    ua = ua / d
    ub = ub / d

    if includeEnds then
      return ua >= 0 and ua <= 1 and ub >= 0 and ub <= 1
    end

    return ua > 0 and ua < 1 and ub > 0 and ub < 1
  end

  return false
end

local function wrapIndex(index, size)
  local result = ((index - 1) % size) + 1
  print(index, size, result)
  return result
end

local function printPosition(position)
  return "(" .. position[1] .. ", " .. position[2] .. ")"
end
-- =============================================================================
-- Convex Hull
-- =============================================================================

local function cross(a, b, p)
  return (a.position[1] - p.position[1]) * (b.position[2] - p.position[2])
      - (a.position[2] - p.position[2]) * (b.position[1] - p.position[1])
end

local function sortFn(a, b)
  return a.position[1] < b.position[1]
end

local function findConvexHull(points)
  table.sort(points, sortFn)

  local hull = {}
  for i, point in ipairs(points) do
    while #hull >= 2 and cross(hull[#hull - 1], hull[#hull], point) <= 0 do
      table.remove(hull)
    end
    table.insert(hull, point)
  end

  local limit = #hull + 1
  for i = #points, 1, -1 do
    local point = points[i]
    while #hull >= limit and cross(hull[#hull - 1], hull[#hull], point) <= 0 do
      table.remove(hull)
    end
    table.insert(hull, point)
  end

  table.remove(hull)

  return hull
end

function Delaunay.convexHull(points)
  return findConvexHull(points)
end

-- =============================================================================
-- Random Point Triangulation
-- =============================================================================

local function areEdgesIntersecting(e1, e2)
  local result = checkLineIntersection(
    e1.v1.position, e1.v2.position, e2.v1.position, e2.v2.position, true
  )

  return result
end

local function triangulate(points)
  local triangles = {}
  table.sort(points, sortFn)

  local newTriangle = Triangle.fromVertices(points[1], points[2], points[3])
  table.insert(triangles, newTriangle)

  local edges = {}
  table.insert(edges, Edge.fromVertices(newTriangle.v1, newTriangle.v2))
  table.insert(edges, Edge.fromVertices(newTriangle.v2, newTriangle.v3))
  table.insert(edges, Edge.fromVertices(newTriangle.v3, newTriangle.v1))

  for i = 4, #points do
    local currentPoint = points[i]
    local newEdges = {}

    for j = 1, #edges do
      local currentEdge = edges[j]

      local midPoint = midpoint(currentEdge.v1, currentEdge.v2)
      local edgeToMidpoint = Edge.fromVertices(currentPoint, midPoint)

      local canSeeEdge = true

      for k = 1, #edges do
        if k ~= j and areEdgesIntersecting(edgeToMidpoint, edges[k]) then
          canSeeEdge = false
          break
        end
      end

      if canSeeEdge then
        local edgeToPointA = Edge.fromVertices(
          currentEdge.v1,
          Vertex.new(currentPoint.position[1], currentPoint.position[2])
        )

        local edgeToPointB = Edge.fromVertices(
          currentEdge.v2,
          Vertex.new(currentPoint.position[1], currentPoint.position[2])
        )

        table.insert(newEdges, edgeToPointA)
        table.insert(newEdges, edgeToPointB)

        local tri = Triangle.fromVertices(
          edgeToPointA.v1, edgeToPointA.v2, edgeToPointB.v1
        )

        table.insert(triangles, tri)
      end
    end

    for _, edge in ipairs(newEdges) do
      table.insert(edges, edge)
    end
  end

  return triangles
end

function Delaunay.simpleTriangulation(points)
  return triangulate(points)
end

-- =============================================================================
-- Delaunay Triangulation
-- =============================================================================

local function findOrientation(a, b, c)
  return a[1] * b[2] + c[1] * a[2] + b[1] * c[2]
      - a[1] * c[2] - c[1] * b[2] - b[1] * a[2]
end

local function isCounterClockwise(triangle)
  local a = triangle.v1.position
  local b = triangle.v2.position
  local c = triangle.v3.position

  return findOrientation(a, b, c) > 0
end

local function orientTriangle(triangle)
  if isCounterClockwise(triangle) then
    triangle:changeOrientation()
  end
end

local function convertTrianglesToHalfEdges(triangles)
  local halfEdges = {}
  for i, triangle in ipairs(triangles) do
    orientTriangle(triangle)

    local hea = HalfEdge.new(triangle.v1)
    local heb = HalfEdge.new(triangle.v2)
    local hec = HalfEdge.new(triangle.v3)

    hea.nextEdge = heb
    heb.nextEdge = hec
    hec.nextEdge = hea

    hea.previousEdge = hec
    heb.previousEdge = hea
    hec.previousEdge = heb

    hea.vertex.halfEdge = heb
    heb.vertex.halfEdge = hec
    hec.vertex.halfEdge = hea

    triangle.halfEdge = hea
    hea.triangle = triangle
    heb.triangle = triangle
    hec.triangle = triangle

    table.insert(halfEdges, hea)
    table.insert(halfEdges, heb)
    table.insert(halfEdges, hec)
  end

  for i, halfEdge in ipairs(halfEdges) do
    local to = halfEdge.vertex
    local from = halfEdge.previousEdge.vertex
    for j, otherEdge in ipairs(halfEdges) do
      if i ~= j then
        if equals(from.position, otherEdge.vertex.position) and
            equals(to.position, otherEdge.previousEdge.vertex.position) then
          halfEdge.oppositeEdge = otherEdge
          break
        end
      end
    end
  end

  return halfEdges
end

local function circleCheck(pa, pb, pc, pd)
  local a = pa[1] - pd[1]
  local d = pb[1] - pd[1]
  local g = pc[1] - pd[1]

  local b = pa[2] - pd[2]
  local e = pb[2] - pd[2]
  local h = pc[2] - pd[2]

  local c = a * a + b * b
  local f = d * d + e * e
  local i = g * g + h * h

  return (a * e * i) + (b * f * g) + (c * d * h)
      - (g * e * c) - (h * f * a) - (i * d * b)
end

local function isQuadrilateralConvex(a, b, c, d)
  local abc = findOrientation(a, b, c) <= 0
  local abd = findOrientation(a, b, d) <= 0
  local bcd = findOrientation(b, c, d) <= 0
  local cad = findOrientation(c, a, d) <= 0

  local u = abc and abd and (bcd and not cad)
  local v = abc and abd and (not bcd and cad)
  local w = abd and not abd and (bcd and cad)
  local x = not abc and not abd and (not bcd and cad)
  local y = not abc and not abd and (bcd and not cad)
  local z = not abc and abd and (not bcd and not cad)

  return u or v or w or x or y or z
end

local function flipEdge(one)
  local two = one.nextEdge
  local three = one.previousEdge
  local four = one.oppositeEdge
  local five = one.oppositeEdge.nextEdge
  local six = one.oppositeEdge.previousEdge

  local a = one.vertex
  local b = one.nextEdge.vertex
  local c = one.previousEdge.vertex
  local d = one.oppositeEdge.nextEdge.vertex

  a.halfEdge = one.nextEdge
  c.halfEdge = one.oppositeEdge.nextEdge

  one.nextEdge = three
  one.previousEdge = five

  two.nextEdge = four
  two.previousEdge = six

  three.nextEdge = five
  three.previousEdge = one

  four.nextEdge = six
  four.previousEdge = two

  five.nextEdge = one
  five.previousEdge = three

  six.nextEdge = two
  six.previousEdge = four

  one.vertex = b
  two.vertex = b
  three.vertex = c
  four.vertex = d
  five.vertex = d
  six.vertex = a

  local t1 = one.triangle
  local t2 = four.triangle

  one.triangle = t1
  three.triangle = t1
  five.triangle = t1

  two.triangle = t2
  four.triangle = t2
  six.triangle = t2

  t1.v1 = b
  t1.v2 = c
  t1.v3 = d

  t2.v1 = b
  t2.v2 = d
  t2.v3 = a

  t1.halfEdge = three
  t2.halfEdge = four
end

local function flipEdges(points)
  local triangles = Delaunay.simpleTriangulation(points)
  local halfEdges = convertTrianglesToHalfEdges(triangles)

  local saftey = 0
  local flippedEdges = 0

  while true do
    saftey = saftey + 1
    if saftey > 100000 then
      print("Triangulation stuck in infinite loop")
      break
    end

    local hasFlippedEdge = false
    for i, edge in ipairs(halfEdges) do
      if edge.oppositeEdge then
        local a = edge.vertex.position
        local b = edge.nextEdge.vertex.position
        local c = edge.previousEdge.vertex.position
        local d = edge.oppositeEdge.nextEdge.vertex.position

        if circleCheck(a, b, c, d) < 0 then
          if isQuadrilateralConvex(a, b, c, d) then
            if circleCheck(b, c, d, a) >= 0 then
              flippedEdges = flippedEdges + 1
              hasFlippedEdge = true
              flipEdge(edge)
            end
          end
        end
      end
    end

    if not hasFlippedEdge then
      break
    end
  end

  return triangles
end

function Delaunay.triangulate(points)
  return flipEdges(points)
end

-- =============================================================================
-- Constrained Delaunay Triangulation
-- =============================================================================

local function areCrossing(a1, b1, a2, b2)
  if equals(a1, a2) or equals(a1, b2) or equals(b1, a2) or equals(b1, b2) then
    return false
  end

  return checkLineIntersection(a1, b1, a2, b2, false)
end

local function findIntersectingEdges(triangulation, a, b)
  local edges = {}
  local t = nil

  for i, tri in ipairs(triangulation) do
    local e1 = tri.halfEdge
    local e2 = e1.nextEdge
    local e3 = e2.nextEdge

    if equals(e1.vertex.position, a.position) or equals(e2.vertex.position, a.position) or
        equals(e3.vertex.position, a.position) then
      t = tri
      break
    end
  end

  local safety = 0
  local lastEdge = nil
  local startTriangle = t
  local restart = false

  while true do
    safety = safety + 1
    if safety > 10000 then
      print("stuck in infinite loop")
      break
    end

    local e1 = t.halfEdge
    local e2 = e1.nextEdge
    local e3 = e2.nextEdge

    local eprime = nil

    if not equals(e1.vertex.position, a.position) and
        not equals(e1.previousEdge.vertex.position, a.position) then
      eprime = e1
    end

    if not equals(e2.vertex.position, a.position) and
        not equals(e2.previousEdge.vertex.position, a.position) then
      eprime = e2
    end

    if not equals(e3.vertex.position, a.position) and
        not equals(e3.previousEdge.vertex.position, a.position) then
      eprime = e3
    end

    if areCrossing(
          eprime.vertex.position, eprime.previousEdge.vertex.position, a.position, b.position
        ) then
      break
    end

    local searchArea = {}

    -- relies on reference equality, eww gross
    if e1 ~= eprime then
      table.insert(searchArea, e1)
    end

    if e2 ~= eprime then
      table.insert(searchArea, e2)
    end

    if e3 ~= eprime then
      table.insert(searchArea, e3)
    end

    if lastEdge == nil then
      lastEdge = searchArea[1]
      if lastEdge.oppositeEdge == nil or restart then
        lastEdge = searchArea[2]
      end
      t = lastEdge.oppositeEdge.triangle
    else
      if searchArea[1].oppositeEdge ~= lastEdge then
        lastEdge = searchArea[1]
      else
        lastEdge = searchArea[2]
      end

      if lastEdge.oppositeEdge == nil then
        restart = true
        t = startTriangle
        lastEdge = nil
      else
        t = lastEdge.oppositeEdge.triangle
      end
    end
  end

  safety = 0
  lastEdge = nil

  while true do
    safety = safety + 1
    if safety > 10000 then
      print("Infinite loop encountered")
      break
    end

    local e1 = t.halfEdge
    local e2 = e1.nextEdge
    local e3 = e2.nextEdge

    if equals(e1.vertex.position, b.position)
        or equals(e2.vertex.position, b.position)
        or equals(e3.vertex.position, b.position) then
      break
    end

    if e1.oppositeEdge ~= lastEdge and areCrossing(
          e1.vertex.position, e1.previousEdge.vertex.position, a.position, b.position
        ) then
      lastEdge = e1
    elseif e2.oppositeEdge ~= lastEdge and areCrossing(
          e2.vertex.position, e2.previousEdge.vertex.position, a.position, b.position
        ) then
      lastEdge = e2
    else
      lastEdge = e3
    end

    t = lastEdge.oppositeEdge.triangle

    table.insert(edges, lastEdge)
  end

  return edges
end

local function removeIntersectingEdges(a, b, edges)
  local newEdges = {}
  local safety = 0

  while #edges > 0 do
    safety = safety + 1
    if safety > 10000 then
      print("Infinite loop when fixing constrained edges")
      break
    end

    local currentEdge = edges[1]
    table.remove(edges, 1)

    local vk = currentEdge.vertex.position
    local vl = currentEdge.previousEdge.vertex.position
    local vthird = currentEdge.nextEdge.vertex.position
    local vopp = currentEdge.oppositeEdge.nextEdge.vertex.position

    if not isQuadrilateralConvex(vk, vl, vthird, vopp) then
      table.insert(edges, currentEdge)
    else
      flipEdge(currentEdge)

      local vm = currentEdge.vertex.position
      local vn = currentEdge.previousEdge.vertex.position

      if areCrossing(a.position, b.position, vm, vn) then
        table.insert(edges, currentEdge)
      else
        table.insert(newEdges, currentEdge)
      end
    end
  end

  return newEdges
end

local function restoreTriangulation(a, b, newEdges)
  local safety = 0
  local flippedEdges = 0

  while true do
    safety = safety + 1
    if safety > 1000000 then
      print("Stuck in infinite loop restoring newEdges")
      break
    end

    local hasFlippedEdge = false

    for i, edge in ipairs(newEdges) do
      local vk = edge.vertex.position
      local vl = edge.previousEdge.vertex.position

      if not ((equals(vk, a.position) and equals(vl, b.position))
            or (equals(vl, a.position) and equals(vk, b.position))) then
        local vthird = edge.nextEdge.vertex.position
        local vopp = edge.oppositeEdge.nextEdge.vertex.position
        local circleTest = circleCheck(vk, vl, vthird, vopp)

        if circleTest < 0 then
          if isQuadrilateralConvex(vk, vl, vthird, vopp) then
            if circleCheck(vopp, vl, vthird, vk) > circleTest then
              hasFlippedEdge = true
              flipEdge(edge)
              flippedEdges = flippedEdges + 1
            end
          end
        end
      end
    end

    if not hasFlippedEdge then
      break
    end
  end
end

local function containsTriangle(list, triangle)
  for i, tri in ipairs(list) do
    if tri == triangle then
      return true
    end
  end
  return false
end

local function isConstraint(a, b, constraints)
  for i, constraint in ipairs(constraints) do
    local other = constraints[wrapIndex(i + 1, #constraints)]
    if (equals(a, constraint.position) and equals(b, other.position))
        or (equals(b, constraint.position) and equals(a, other.position)) then
      return true
    end
  end
  return false
end

local function cleanTriangles(triangulation, constraints)
  if #constraints == 3 then
    return
  end

  local borderTriangle = nil
  local p1 = constraints[1]
  local p2 = constraints[2]

  for i, triangle in ipairs(triangulation) do
    local e1 = triangle.halfEdge
    local e2 = e1.nextEdge
    local e3 = e2.nextEdge

    if equals(e1.vertex.position, p2.position) and equals(e1.previousEdge.vertex.position, p1.position) then
      borderTriangle = triangle
      break
    end

    if equals(e2.vertex.position, p2.position) and equals(e2.previousEdge.vertex.position, p1.position) then
      borderTriangle = triangle
      break
    end

    if equals(e3.vertex.position, p2.position) and equals(e3.previousEdge.vertex.position, p1.position) then
      borderTriangle = triangle
      break
    end
  end

  if borderTriangle == nil then
    return
  end

  local toRemove = {}
  local neighbours = {}
  table.insert(neighbours, borderTriangle)

  local safety = 0
  while true do
    safety = safety + 1
    if safety > 100000 then
      print("Infinite loop when trying to remove triangles")
      break
    end

    if #neighbours == 0 then
      break
    end

    local t = neighbours[1]
    table.remove(neighbours, 1)
    table.insert(toRemove, t)

    local e1 = t.halfEdge
    local e2 = e1.nextEdge
    local e3 = e2.nextEdge

    if e1.oppositeEdge ~= nil and
        not containsTriangle(toRemove, e1.oppositeEdge.triangle) and
        not containsTriangle(neighbours, e1.oppositeEdge.triangle) and
        not isConstraint(
          e1.vertex.position, e1.previousEdge.vertex.position, constraints
        ) then
      table.insert(neighbours, e1.oppositeEdge.triangle)
    end

    if e2.oppositeEdge ~= nil and
        not containsTriangle(toRemove, e2.oppositeEdge.triangle) and
        not containsTriangle(neighbours, e2.oppositeEdge.triangle) and
        not isConstraint(
          e2.vertex.position, e2.previousEdge.vertex.position, constraints
        ) then
      table.insert(neighbours, e2.oppositeEdge.triangle)
    end

    if e3.oppositeEdge ~= nil and
        not containsTriangle(toRemove, e3.oppositeEdge.triangle) and
        not containsTriangle(neighbours, e3.oppositeEdge.triangle) and
        not isConstraint(
          e3.vertex.position, e3.previousEdge.vertex.position, constraints
        ) then
      table.insert(neighbours, e3.oppositeEdge.triangle)
    end
  end

  for i = #triangulation, 1, -1 do
    if containsTriangle(toRemove, triangulation[i]) then
      local t = triangulation[i]
      table.remove(triangulation, i)

      local e1 = t.halfEdge
      local e2 = e1.nextEdge
      local e3 = e2.nextEdge

      if e1.oppositeEdge then
        e1.oppositeEdge.oppositeEdge = nil
      end

      if e2.oppositeEdge then
        e2.oppositeEdge.oppositeEdge = nil
      end

      if e3.oppositeEdge then
        e3.oppositeEdge.oppositeEdge = nil
      end
    end
  end
end

local function isEdgeInTriangulation(triangulation, a, b)
  for i, triangle in ipairs(triangulation) do
    local x = triangle.v1.position
    local y = triangle.v2.position
    local z = triangle.v3.position

    if (equals(x, a.position) and equals(y, b.position)) or (equals(x, b.position) and equals(y, a.position)) then
      return true
    end

    if (equals(y, a.position) and equals(z, b.position)) or (equals(y, b.position) and equals(z, a.position)) then
      return true
    end

    if (equals(z, a.position) and equals(x, b.position)) or (equals(z, b.position) and equals(x, a.position)) then
      return true
    end
  end
  return false
end

local function addConstraints(triangulation, constraints)
  for i, constraint in ipairs(constraints) do
    local other = constraints[wrapIndex(i + 1, #constraints)]
    if not isEdgeInTriangulation(triangulation, constraint, other) then
      local intersectingEdges = findIntersectingEdges(
        triangulation, constraint, other
      )
      local newEdges = removeIntersectingEdges(
        constraint, other, intersectingEdges
      )
      restoreTriangulation(constraint, other, newEdges)
    end
  end

  cleanTriangles(triangulation, constraints)
  return triangulation
end

local function generateTriangulation(points, constraints)
  for i, elem in ipairs(constraints) do
    table.insert(points, elem)
  end

  local triangulation = Delaunay.triangulate(points)
  local constrainedTriangulation = addConstraints(triangulation, constraints)

  return constrainedTriangulation
end

function Delaunay.constrainedTriangulation(points, constraints)
  return generateTriangulation(points, constraints)
end

return Delaunay
