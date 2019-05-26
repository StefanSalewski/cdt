# https://www.researchgate.net/publication/2478154_Fully_Dynamic_Constrained_Delaunay_Triangulations
# by Marcelo Kallmann, Hanspeter Bieri and Daniel Thalmann
#
# http://www.karlchenofhell.org/cppswp/lischinski.pdf (basic application)
#
# http://www.faqs.org/faqs/graphics/algorithms-faq/ (collection of geometric algorithm)
#
# https://static.aminer.org/pdf/PDF/000/111/347/fast_randomized_point_location_without_preprocessing_in_two_and_three.pdf
#
# (C) 2019 S. Salewski 
# v0.1 26-MAY-2019

import geometry
import types, vectors, vertices, edges, subdivisions, salewski, minmax
import tables, random
from math import sqrt, pow
from salewski import `^`

const FullDebug = compileOption("assertions") and false

type
  DelaunayTriangulation* = object
    subdivision*: Subdivision
    constraints*: Table[int, Vertex]
    epsilon*: float
    constraintID: ConstraintID
    xmin, ymin, xmax, ymax: float
    mark: int
    straightEdges*: bool
    interpolateZ*: bool

proc `==`(i, j: ConstraintID): bool {.borrow.}

proc nextMark(this: var DelaunayTriangulation): int {.inline.} =
  inc(this.mark)
  return this.mark

proc nextConstraintID(cdt: var DelaunayTriangulation): ConstraintID {.inline.} =
  inc(int(cdt.constraintID))
  cdt.constraintID

#     /e
#   /
# a ----- p
func getLeftEdge(a: Vertex; p: Vector): Edge =
  result = a.firstEdge
  let o = result.org.point
  while not ccw(o, p,  result.dest.point):
    result = result.onext
  while ccw(o, p,  result.oprev.dest.point):
    result = result.oprev

func getConnection(a: Vertex; b: Vertex): Edge =
  result = a.firstEdge
  let start = result
  while  true:
    if result.dest == b:
      break
    result = result.onext
    if result == start:
      return nil

proc connect(this: var DelaunayTriangulation; a: Vertex; b: Vertex): Edge =
  assert a.firstEdge != nil
  assert b.firstEdge != nil
  this.subdivision.connect(getLeftEdge(a, b.point).sym, getLeftEdge(b, a.point).oprev)

# Essentially turns edge e counterclockwise inside its enclosing
# quadrilateral. The data pointers are modified accordingly.
# http://www.karlchenofhell.org/cppswp/lischinski.pdf
proc swap(e: Edge) =
  let a: Edge = e.oprev
  let b: Edge = e.sym.oprev
  splice(e, a)
  splice(e.sym, b)
  splice(e, a.lnext)
  splice(e.sym, b.lnext)
  e.setEndPoints(a.dest, b.dest)

# https://www.researchgate.net/publication/2478154_Fully_Dynamic_Constrained_Delaunay_Triangulations
proc flipEdges(p: Vector; stack: var seq[Edge]) =
  while stack.len > 0:
    let e = stack.pop
    assert(ccw(e.org.point, e.dest.point, p))
    if e.quadEdge.crep.len == 0 and dInCircumCircle(e.org.point, e.dest.point, p,  e.dnext.org.point):
      stack.add(e.oprev)
      stack.add(e.dnext)
      assert(ccw(e.oprev.org.point, e.oprev.dest.point, p))
      assert(ccw(e.dnext.org.point, e.dnext.dest.point, p))
      swap(e)

proc initDelaunayTriangulation*(a, b: Vector; precision = 1e-8): DelaunayTriangulation =
  assert(a.x != b.x and a.y != b.y)
  assert(precision <= 1e-6 and precision >= 1e-14)
  (result.xmin, result.xmax) = (a.x, b.x)
  if result.xmin > result.xmax:
    swap(result.xmin, result.xmax)
  (result.ymin, result.ymax) = (a.y, b.y)
  if result.ymin > result.ymax:
    swap(result.ymin, result.ymax)
  let boundary =
    [Vector(x: result.xmin, y: result.ymin), Vector(x: result.xmax, y: result.ymin),
    Vector(x: result.xmax, y: result.ymax), Vector(x: result.xmin, y: result.ymax)]
  result.epsilon = max(result.xmax - result.xmin, result.ymax - result.ymin) * precision
  for pcn in xclusters(boundary, 3):
    assert ccw(pcn[0], pcn[1], pcn[2])
  var verts: seq[Vertex]
  for p in boundary:
    verts.add(result.subdivision.createVertex(p))
  var edges: seq[Edge]
  for cn in xpairs(verts):
    edges.add(result.subdivision.createEdge(cn[0], cn[1]))
    edges[^1].quadEdge.crep.add(ConstraintId(0))
  for cn in xpairs(edges):
    splice(cn[0].sym, cn[1])
  discard result.subdivision.connect(edges[1], edges[0])

# http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.61.3862&rep=rep1&type=pdf
# TriangulatePseudopolygonDelaunay()
proc retriangulateFace(this: var DelaunayTriangulation; base: Edge) =
  assert base != nil
  if base.lnext.lnext.lnext == base:
    return
  var base = base
  while not ccw(base.org.point, base.dest.point, base.lnext.dest.point):
    base = base.lnext
  var c = base.lnext
  var e = c
  while true:
    e = e.lnext
    if e.lnext == base:
      break
    if dInCircumCircle(base.org.point, base.dest.point, c.dest.point, e.dest.point):
      c = e
  assert c != base
  if c.lnext.lnext != base:
    let b = this.subdivision.connect(base.lprev, c.lnext)
    retriangulateFace(this, b)
  if c != base.lnext:
    let a = this.subdivision.connect(c, base.lnext)
    retriangulateFace(this, a)

proc removeVertex(this: var DelaunayTriangulation; vert: Vertex) =
  let base: Edge = vert.firstEdge
  assert base != nil # vertex with no edges, ...
  assert base.org == vert
  let remaining: Edge = base.lnext
  while true:
    let e = vert.firstEdge
    if e.isNil:
      break
    this.subdivision.removeEdge(e)
  this.subdivision.removeVertex(vert)
  this.retriangulateFace(remaining)

# the jump part of the jump and walk algorithm
proc getStartVertex(this: DelaunayTriangulation; x, y: float): Vertex =
  let n = pow(this.subdivision.vertices.len.float, 1.0 / 3.0).int
  result = this.subdivision.vertices[this.subdivision.vertIDs[^1].int]
  var dist = (result.point.x - x) ^ 2 + (result.point.y - y) ^ 2
  for i in 0 .. n:
    let v = this.subdivision.vertices[sample(this.subdivision.vertIDs).int]
    let d = (v.point.x - x) ^ 2 + (v.point.y - y) ^ 2
    if dist > d:
      dist = d
      result = v

func rightOf(x: Vector; e: Edge): bool {.inline.} =
  ccw(e.dest.point, e.org.point, x)

# Returns an edge e, s.t. either x is on e, or e is an edge of
# a triangle containing x. The search starts from startingEdge
# and proceeds in the general direction of x. Based on the
# pseudocode in Guibas and Stolfi (1985) p.121.
# http://www.karlchenofhell.org/cppswp/lischinski.pdf
# if point is in face, we return the closest edge -- triArea(e.org.point, e.dest.point, p) >= 0
proc xlocatePoint(p: Vector; startEdge: Edge): Edge =
  var e = startEdge
  assert e != nil
  while true: # TODO: can we get an infinite loop -- and how to best fix it?
    if p == e.org.point or p == e.dest.point:
      return e
    elif p.rightOf(e):
      e = e.sym
    elif not p.rightOf(e.onext):
      e = e.onext
    elif not p.rightOf(e.dprev):
      e = e.dprev
    else:
      break
  assert not p.rightOf(e)
  let a = triArea(e.org.point, e.dest.point, p)
  assert a >= 0
  if a > 0:
    e = minValueByIt([e, e.onext.sym, e.dprev.sym], linePointDistSqr(it.org.point, it.dest.point, p))
  assert not p.rightOf(e)
  return e

type
  LocPos = enum
    lpOrg, lpDest, lpEdge, lpFace

proc locatePoint(this: DelaunayTriangulation; p: Vector; startEdge: Edge = nil): (Edge, LocPos) =
  var e = startEdge
  if e == nil:
    e = this.getStartVertex(p.x, p.y).edge
  e = xlocatePoint(p, e)
  var pos: LocPos
  assert triArea(e.org.point, e.dest.point, p) >= 0
  let epsSqr = this.epsilon ^ 2
  let d = linePointDistSqr(e.org.point, e.dest.point, p)
  assert d >= 0
  if d <  epsSqr:
    let dorgSqr = (e.org.point.x - p.x) ^ 2 + (e.org.point.y - p.y) ^ 2
    let ddestSqr = (e.dest.point.x - p.x) ^ 2 + (e.dest.point.y - p.y) ^ 2
    pos = lpEdge
    if dorgSqr < ddestSqr:
      if dorgSqr < epsSqr:
        pos = lpOrg
    else:
      if ddestSqr < epsSqr:
        pos = lpDest
  else:
    pos = lpFace
  return (e, pos)

proc insertPointInEdge(this: var DelaunayTriangulation; point: Vector; edge: Edge): Vertex =
  var p = point
  var e = edge
  var stack: seq[Edge] = @[e.onext.sym, e.dprev.sym, e.oprev, e.dnext]
  for e in stack:
    assert(ccw(e.org.point, e.dest.point, p))
  if this.straightEdges or this.interpolateZ:
    p = projection(e.org.point, e.dest.point, p)
    if not this.straightEdges:
      (p.x, p.y) = (point.x, point.y)
    when point is Vector3:
      if not this.interpolateZ:
        p.z = point.z
  let origCrep = e.quadEdge.crep
  e = edge.oprev
  this.subdivision.removeEdge(e.onext)
  result = this.subdivision.createVertex(p)
  var base: Edge = this.subdivision.createEdge(e.org, result)
  base.quadEdge.crep = origCrep
  splice(base, e)
  base = this.subdivision.connect(e, base.sym)
  e = base.oprev
  base = this.subdivision.connect(e, base.sym)
  base.quadEdge.crep = origCrep
  e = base.oprev
  base = this.subdivision.connect(e, base.sym)
  flipEdges(p, stack)

proc insertPointInFace(this: var DelaunayTriangulation; p: Vector; edge: Edge): Vertex =
  var stack: seq[Edge] = @[edge.onext.sym, edge, edge.dprev.sym]
  for e in stack:
    assert(ccw(e.org.point, e.dest.point, p))
  result = this.subdivision.createVertex(p)
  when p is Vector3:
    if this.interpolateZ:
      interpolateZ(edge.org.point, edge.dest.point, edge.onext.dest.point, result.point)
  var base: Edge = this.subdivision.createEdge(edge.org, result)
  splice(base, edge)
  base = this.subdivision.connect(edge, base.sym)
  discard this.subdivision.connect(base.oprev, base.sym)
  flipEdges(p, stack)

proc insertPoint*(this: var DelaunayTriangulation; p: Vector): Vertex =
  let (e, locPos) = this.locatePoint(p)
  if locPos == lpEdge:
    result = this.insertPointInEdge(p, e)
  elif locPos == lpFace:
    result = this.insertPointInFace(p, e)
  elif locPos == lpOrg:
    result = e.org
  elif locPos == lpDest:
    result = e.dest
  return result

proc echoPoints(edges: seq[Edge]) =
  for e in edges:
    echo e.org.point, " ", e.dest.point

proc echoPoints(verts: seq[Vertex]) =
  for p in verts:
    echo p.point

proc splitEdge(this: var DelaunayTriangulation; point: Vector; edge: Edge): Vertex =
  let origCrep = edge.quadEdge.crep
  let e = edge.oprev
  let e2 = edge.dnext
  this.subdivision.removeEdge(e.onext)
  result = this.subdivision.createVertex(point)
  var base: Edge = this.subdivision.createEdge(e.org, result)
  base.quadEdge.crep = origCrep
  splice(base, e)
  base = this.subdivision.connect(e2, base.sym)
  base.quadEdge.crep = origCrep

proc fixCrossingEdges(this: var DelaunayTriangulation; a, b: Vertex): seq[Vertex] =
  var e: Edge = getLeftEdge(a, b.point)
  result.add(a)
  while e.dest != b:
    let d = linePointDistSqr(a.point, b.point, e.dest.point)
    let next =
      if d > 0:
        e.rprev
      else:
        e.onext
    if d < -(this.epsilon ^ 2):
      if e.quadedge.crep.len > 0:
        let (x, y, ua, ub) = lineLineIntersection(e.org.point, e.dest.point, a.point, b.point)
        assert ua < 1 and ua > 0
        assert ub < 1 and ub > 0
        var p = Vector(x: x, y: y)
        when e.org.point is Vector3:
          interpolateZ(e.org.point, e.dest.point, p) # TODO: 4 point interpolation including a, b?
        result.add(this.splitEdge(p, e))
      else:
        this.subdivision.removeEdge(e)
    elif d < this.epsilon ^ 2:
      if e.dest != result[^1]:
        if this.straightEdges or this.interpolateZ:
          var p = projection(a.point, b.point, e.dest.point)
          if not this.straightEdges:
            (p.x, p.y) = (e.dest.point.x, e.dest.point.y)
          when p is Vector3:
            if not this.interpolateZ:
              p.z = e.dest.point.z
          e.dest.point = p
        result.add(e.dest)
    e = next
  result.add(b)

proc insertSegment(this: var DelaunayTriangulation; a, b: Vertex; id: ConstraintID) =
  let verts = this.fixCrossingEdges(a, b)
  for i in 1 .. verts.high:
    var connection: Edge = getConnection(verts[i - 1], verts[i])
    if connection.isNil:
      connection = this.connect(verts[i - 1], verts[i])
      this.retriangulateFace(connection)
      this.retriangulateFace(connection.sym)
    connection.quadEdge.crep.add(id)

proc rangeCheck(this: DelaunayTriangulation; v: Vector) =
  assert(v.x > this.xmin and v.x < this.xmax and v.y > this.ymin and v.y < this.ymax)

proc insert*(this: var DelaunayTriangulation; points: varargs[Vector]): ConstraintID =
  var lastVert: Vertex
  let cid = this.nextConstraintID
  for c in points:
    this.rangeCheck(c)
    let vert = this.insertPoint(c)
    assert vert != nil
    this.constraints[cid.int] = vert
    if lastVert != nil:
      this.insertSegment(lastVert, vert, cid)
    lastVert = vert
  when FullDebug:
    discard # add some deep debugging code here
  return cid

iterator edges*(this: var DelaunayTriangulation): Edge =
  for v in this.subdivision.vertices.values:
    let start = v.edge
    var e = start
    while true: # while e != nil ?
      if cast[int](e.org) < cast[int](e.dest):
        yield e
      e = e.onext
      if e == start:
        break

iterator constrainedEdges*(this: var DelaunayTriangulation): Edge =
  for v in this.subdivision.vertices.values:
    let start = v.edge
    var e = start
    while true: # while e != nil ?
      if cast[int](e.org) < cast[int](e.dest) and e.quadEdge.crep.len > 0:
        yield e
      e = e.onext
      if e == start:
        break

iterator unconstrainedEdges*(this: var DelaunayTriangulation): Edge =
  for v in this.subdivision.vertices.values:
    let start = v.edge
    var e = start
    while true: # while e != nil ?
      if cast[int](e.org) < cast[int](e.dest) and e.quadEdge.crep.len == 0:
        yield e
      e = e.onext
      if e == start:
        break

iterator edges*(v: Vertex): Edge {.inline.} =
  let start = v.edge
  var e = start
  while true: # while e != nil ?
    yield e
    e = e.onext
    if e == start:
      break

iterator orgFriends*(e: Edge): Edge {.inline.} =
  var next = e.onext
  while next != e:
    yield next
    next = next.onext

iterator destFriends*(e: Edge): Edge {.inline.} =
  var next = e.dnext
  while next != e:
    yield next
    next = next.dnext

iterator allFriends*(e: Edge): Edge {.inline.} =
  var next = e.onext
  while next != e:
    yield next
    next = next.onext
  next = e.dnext
  while next != e:
    yield next
    next = next.dnext

proc removeConstraint*(this: var DelaunayTriangulation; id: ConstraintID): bool =
  var v: Vertex
  result = this.constraints.take(id.int, v)
  if not result:
    assert v.isNil
    return false
  var estack: seq[Edge]
  let newMark = this.nextMark
  for e in edges(v):
    if e.quadEdge.crep.contains(id):
      estack.add(e)
      e.quadEdge.mark = newMark
  var elist: seq[Edge]
  while estack.len > 0:
    let e: Edge = estack.pop
    elist.add(e)
    for f in allFriends(e):
      if f.quadEdge.crep.contains(id) and f.quadEdge.mark != newMark:
        estack.add(f)
        f.quadEdge.mark = newMark
  for e in mitems(elist):
    let h = e.quadEdge.crep.find(id)
    assert h >= 0
    e.quadEdge.crep.del(h)
  var vlist: seq[Vertex]
  for e in elist:
    if e.org.mark != newMark:
      vlist.add(e.org)
      e.org.mark = newMark
    if e.dest.mark != newMark:
      vlist.add(e.dest)
      e.dest.mark = newMark
  for v in vlist:
    assert v.edge != nil
    var n = 0 # number of remaining constrained edges adjacent to v
    for e in edges(v):
      if e.quadEdge.crep.len > 0:
        inc(n)
    if n == 0:
      this.removeVertex(v)
    elif n == 2:
      var e1 = v.edge
      while e1.quadEdge.crep.len == 0:
        e1 = e1.onext
      var e2 = e1.onext
      while e2.quadEdge.crep.len == 0:
        e2 = e2.onext
      assert e1 != e2
      if e1.quadEdge.crep == e2.quadEdge.crep and  linePointDistSqr(e1.org.point, e2.dest.point, e1.dest.point).abs < (this.epsilon ^ 2):
        let v1 = e1.dest #let v1 and v2 be the two vertices incident to e1 and e2 different than v
        let v2 = e2.dest
        assert v1 != v and v2 != v
        assert v1 != v2
        let crep = e1.quadEdge.crep
        this.removeVertex(v)
        let e: Edge = this.connect(v1, v2)
        e.quadEdge.crep = crep

# 486 lines
