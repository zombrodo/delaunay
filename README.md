# Constrained Delaunay

A port of the Constrained Delaunay Algorithm explained by [Erik Nordeus on Habrador](https://www.habrador.com/tutorials/math/14-constrained-delaunay/)

This library also contains functions for Convex Hull, Simple Triangulation,
and Delaunay Triangulation (ignoring constraints)

I recommend reading through their blog posts to get a better understanding
of what this algorithm is doing, and what it's for. They do an amazing job
coming from the basics of convex hull, and ending with this (rather complex)
algorithm.

This implementation is mostly a 'first pass' attempt at getting it running
with Love2d - there's no guarantees about the efficiency of the implementation.

Improvements welcomed :)

## Example

Check the `main.lua` for examples of each algorithm in this library.

- `h` will run convex hull over the current points
- `s` will run simple triangulation over the current points
- `d` will run delaunay triangulation over the current points
  (ignoring constraints)
- `c` will run constrained triangulation over the current points
- `r` will randomly generate new points

## Usage

Copy `delaunay.lua` into your libs folder, and import it as per usual

```lua
local Delaunay = require "path.to.libs.delaunay
```

Every function expects points to be passed in the form of a
`Delaunay.Vertex`. This just ensures the points are in the form of something
the algorithms understand.

```lua
local point = Delaunay.vertex(x, y)
```

## API

### `Delaunay.vertex(x: number, y: number): Delaunay.Vertex`

Given an `x` and `y` value, returns a `Delaunay.Vertex` object.

It's main job is to ensure the data is in a common shape that the algorithms
understand, so you shouldn't have to touch anything inside of it, except to
retrieve the positions out on the other side. You can take a look at the code to
understand what other values are available.

### `Delaunay.Vertex.position: Table<number>`

Returns a table containing the points `x` and `y` coordinates.

```lua
local x = vertex.position[1]
local y = vertex.position[2]
```

### `Delaunay.Triangle`

A `Triangle` is a collection of 3 `Delaunay.Vertex` objects. You can retrieve
these through using the `triangle.v1`, `triangle.v2` and `triangle.v3` fields.

### `Delaunay.convexHull(points: Table<Delaunay.Vertex>): Table<Delaunay.Vertex>`

Takes a collection of points, and returns its Convex Hull as a table of
`Delaunay.Vertex` objects.

![](/images/hull.png)

### `Delaunay.simpleTriangulation(points: Table<Delaunay.Vertex>): Table<Delaunay.Triangle>`

Takes a collection of points, and returns a simple triangulation. Returns a table
of `Delaunay.Triangle` objects.

![](/images/simple.png)

### `Delaunay.triangulate(points: Table<Delaunay.Vertex>): Table<Delaunay.Triangle>`

Performs Delaunay Triangulation, without constraints. Returns a table of
`Delaunay.Triangle`.

![](/images/delaunay.png)

### `Delaunay.constrainedTriangulation(points: Table<Delaunay.Vertex>, constraints: Table<Delaunay.Vertex>): Table<Delaunay.Triangle>`

Given a list of `points` and a list of `constraints`, finds the constrained
Delaunay triangulation. Returns a table of `Delaunay.Triangle`

![](/images/constrained.png)
