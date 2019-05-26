import cdt/[dt, vectors, edges, types]
import random, parseutils, OS, math, tables

const
  initVector = initVector3

proc main =
  echo "this is a plain basic test with only textual output"

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

  discard dt.insert(Vector(x: 10, y: 10), Vector(x: 20, y: 10), Vector(x: 20, y: 90), Vector(x: 10, y: 90), Vector(x: 10, y: 10))
  discard dt.insert(Vector(x: 30, y: 10), Vector(x: 40, y: 10), Vector(x: 40, y: 90), Vector(x: 30, y: 90), Vector(x: 30, y: 10))
  discard dt.insert(Vector(x: 20, y: 30), Vector(x: 30, y: 90))
  discard dt.insert(Vector(x: 20, y: 10), Vector(x: 30, y: 70))
  discard dt.insert(Vector(x: 50, y: 10), Vector(x: 60, y: 10), Vector(x: 60, y: 90), Vector(x: 50, y: 90), Vector(x: 50, y: 10))
  discard dt.insert(Vector(x: 80, y: 10), Vector(x: 90, y: 10), Vector(x: 80, y: 90), Vector(x: 70, y: 90), Vector(x: 80, y: 10))
  discard dt.insert(Vector(x: 90, y: 10), Vector(x: 100, y: 10), Vector(x: 110, y: 90), Vector(x: 100, y: 90), Vector(x: 90, y: 10))
  discard dt.insert(Vector(x: 120, y: 10), Vector(x: 130, y: 10), Vector(x: 120, y: 90), Vector(x: 110, y: 90), Vector(x: 120, y: 10))
  discard dt.insert(Vector(x: 130, y: 10), Vector(x: 140, y: 10), Vector(x: 150, y: 90), Vector(x: 140, y: 90), Vector(x: 130, y: 10))

  for i in 1 .. 9:
    echo dt.removeConstraint(ConstraintID(i))

  for j in 0 .. 4:
    discard dt.insert(myrand()[0])
    discard dt.insert(myrand()[0])
    discard dt.insert(myrand())

  echo "Vertices:"
  for x in dt.subdivision.vertices.values:
    echo x

main()
