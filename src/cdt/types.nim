import vectors

type
  ConstraintID* = distinct int

  QuadEdgeID* = distinct int

  EdgeID* = distinct int

  VertexID* = distinct int

type
  #Vector* = Vector3
  Vector* = Vector2

type
  Vertex* = ref object
    point*: Vector
    edge*: Edge
    id*: VertexID
    seqPos*: int
    mark*: int

  QuadEdge* = ref object
    e*: array[4, Edge]
    crep*: seq[ConstraintID]
    id*: QuadEdgeID
    mark*: int

  Edge* = ref object
    quadEdge*: QuadEdge
    vertex*: Vertex
    next*{.cursor.}: Edge # added {.cursor.} for v 0.1.1
    num*: int # 0 .. 3

proc `$`*(v: Vertex): string =
  result = '(' & $v.point.x & ", " & $v.point.y
  when v.point is Vector3:
    result = result & ", " & $v.point.z
  when v.point is Vector4:
    result = result & ", " & $v.point.w
  result = result & ')'
