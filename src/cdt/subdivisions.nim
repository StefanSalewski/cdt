# http://www.karlchenofhell.org/cppswp/lischinski.pdf
import random, tables
import types, vectors, vertices, edges

type
  Subdivision* = object of RootObj
    vertices*: Table[int, Vertex]
    vertIDs*: seq[VertexID]
    vertexID: VertexID
    quadEdgeID: QuadEdgeID

proc nextQuadEdgeID(s: var Subdivision): QuadEdgeID {.inline.} =
  result = s.quadEdgeID
  inc(int(s.quadEdgeID))

proc nextVertexID(s: var Subdivision): VertexID {.inline.} =
  result = s.vertexID
  inc(int(s.vertexID))

proc createEdge*(s: var Subdivision; a: Vertex = nil; b: Vertex = nil): Edge {.inline.} =
  result = newEdge(s.nextQuadEdgeID)
  result.setEndpoints(a, b)

# generally we remove all edges of a vertex first, then remove the vertex itself
proc removeEdge*(s: var Subdivision; e: Edge) =
  if e.isNil:
    return
  if e.org != nil:
    e.org.removeEdge(e) # e.org.firstEdge != e now
  if e.dest != nil:
    e.dest.removeEdge(e.sym)
  splice(e, e.oPrev)
  splice(e.sym, e.sym.oPrev)

proc createVertex*(s: var Subdivision; p: Vector): Vertex =
  result = newVertex(p, s.nextVertexID)
  s.vertices[result.id.int] = result
  result.seqPos = s.vertIDs.len
  s.vertIDs.add(result.id)

proc removeVertex*(s: var Subdivision; v: Vertex) =
  if v.isNil:
    return
  let start = v.firstEdge
  if start != nil: # generally false
    var edge = start
    while true:
      edge.setOrg(nil)
      edge = edge.oNext
      if edge == start:
        break
  assert s.vertices[v.id.int] == v
  let delPos = v.seqPos 
  let id = s.vertIDs[^1].int
  let v1 = s.vertices[id]
  assert v1 != nil
  v1.seqPos = delPos
  s.vertIDs[delPos] = v1.id
  s.vertIDs.setLen(s.vertIDs.len - 1)
  s.vertices.del(v.id.int)

proc getRandomEdge*(s: Subdivision): Edge {.inline.} =
  if s.vertices.len > 0:
    return s.vertices[sample(s.vertIDs).int].edge

proc getRandomVertex*(s: Subdivision): Vertex {.inline.} =
  if s.vertices.len > 0:
    return s.vertices[sample(s.vertIDs).int]

# Add a new Edge connecting the destination of a to the origin of b,
# in such a way that all three
# have the same left face after the connection is complete.
# a Destination of which will be the origin of the new Edge.
# b Origin of which will be the destination of the new Edge.
# return a new Edge from the desination of a to the origin of b.
proc connect*(s: var Subdivision; a, b: Edge): Edge {.inline.} =
  result = s.createEdge(a.dest, b.org)
  splice(result, a.lNext)
  splice(result.sym, b)
