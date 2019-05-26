import cdt/[dt, vectors, edges, types]
import gintro/cairo
import cdt/drawingarea
import random, parseutils, OS, math, tables

const
  initVector = initVector3

proc main =
  if paramCount() == 1:
    var r: int
    discard parseInt(paramStr(1), r)
    echo r
    randomize(r)
  else:
    randomize()
    let r = rand(1000)
    echo r
    randomize(r)

  proc extents(): (float, float, float, float) =
    (-10.0, -10.0, 180.0, 120.0)

  let
    minX = 0.0
    minY = 0.0
    maxX = 160.0
    maxY = 100.0

  var dt: DelaunayTriangulation = initDelaunayTriangulation(initVector(minX, minY), initVector(maxX, maxY))

  proc myrand: array[2, Vector] =
    result[0].x = rand(130.0) + 15
    result[0].y = rand(70.0) + 15
    result[1].x = result[0].x + rand(20.0) - 10
    result[1].y = result[0].y + rand(20.0) - 10

  proc update =
    var i {.global.}: int
    if i == 100:
      for j in 0 .. 25:
        discard dt.insert(myrand()[0])
        discard dt.insert(myrand()[0])
        discard dt.insert(myrand())
      return

    case i:
      of 0: discard dt.insert(Vector(x: 10, y: 10), Vector(x: 20, y: 10), Vector(x: 20, y: 90), Vector(x: 10, y: 90), Vector(x: 10, y: 10))
      of 1: discard dt.insert(Vector(x: 30, y: 10), Vector(x: 40, y: 10), Vector(x: 40, y: 90), Vector(x: 30, y: 90), Vector(x: 30, y: 10))
      of 2: discard dt.insert(Vector(x: 20, y: 30), Vector(x: 30, y: 90))
      of 3: discard dt.insert(Vector(x: 20, y: 10), Vector(x: 30, y: 70))
      of 4: discard dt.insert(Vector(x: 50, y: 10), Vector(x: 60, y: 10), Vector(x: 60, y: 90), Vector(x: 50, y: 90), Vector(x: 50, y: 10))
      of 5: discard dt.insert(Vector(x: 80, y: 10), Vector(x: 90, y: 10), Vector(x: 80, y: 90), Vector(x: 70, y: 90), Vector(x: 80, y: 10))
      of 6: discard dt.insert(Vector(x: 90, y: 10), Vector(x: 100, y: 10), Vector(x: 110, y: 90), Vector(x: 100, y: 90), Vector(x: 90, y: 10))
      of 7: discard dt.insert(Vector(x: 120, y: 10), Vector(x: 130, y: 10), Vector(x: 120, y: 90), Vector(x: 110, y: 90), Vector(x: 120, y: 10))
      of 8: discard dt.insert(Vector(x: 130, y: 10), Vector(x: 140, y: 10), Vector(x: 150, y: 90), Vector(x: 140, y: 90), Vector(x: 130, y: 10))
      else: discard
    inc(i)
    if i == 10: i = -i + 1

    if i < 0:
      if not dt.removeConstraint(ConstraintID(10 + i)):
        i = 100

  proc draw(cr: cairo.Context) =
    cr.setSource(1, 1, 1) 
    cr.paint
    cr.setSource(0, 0, 0, 0.5)
    cr.setLineWidth(0.3)
    cr.setLineCap(LineCap.round)
    for e in unconstrainedEdges(dt):
      cr.moveTo(e.org.point[0], e.org.point[1])
      cr.lineTo(e.dest.point[0], e.dest.point[1])
    cr.stroke
    cr.setLineWidth(0.8)
    cr.setSource(1, 0, 0, 0.6)
    for e in constrainedEdges(dt):
      cr.moveTo(e.org.point[0], e.org.point[1])
      cr.lineTo(e.dest.point[0], e.dest.point[1])
    cr.stroke
    cr.setSource(0, 0, 0, 0.5)
    for v in values(dt.subdivision.vertices):
      cr.newSubPath
      cr.arc(v.point[0], v.point[1], 1, 0, math.Tau)
    cr.stroke

  var data: PDA_Data
  data.draw = draw
  data.update = update
  data.extents = extents
  data.windowSize = (800, 600)
  newDisplay(data)

main()
