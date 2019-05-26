# the famous quadedge data structure of Leonidas J. Guibas and Jorge Stolfi (1985)
# https://en.wikipedia.org/wiki/Quad-edge
# http://www.sccg.sk/~samuelcik/dgs/quad_edge.pdf (original paper)
# https://www.cs.cmu.edu/afs/andrew/scs/cs/15-463/2001/pub/src/a2/quadedge.html (explanations)
# http://graphics.stanford.edu/courses/cs348a-17-winter/ReaderNotes/handout30.pdf (CS348a: Computer Graphics Stanford University)
# http://graphics.stanford.edu/courses/cs348a-17-winter/ReaderNotes/handout31.pdf
# http://www.karlchenofhell.org/cppswp/lischinski.pdf (basic application)

import types  

func newEdge*(id: QuadEdgeID): Edge =
  var q = QuadEdge(id: id)
  for i in 0 .. 3:
    q.e[i] = Edge(quadEdge: q, num: i)
  q.e[0].next = q.e[0]
  q.e[1].next = q.e[3]
  q.e[2].next = q.e[2]
  q.e[3].next = q.e[1]
  return q.e[0]

{.push inline.} # inline tiny procs

func getID*(e: Edge): EdgeID =
  EdgeID(int(e.quadEdge.id) * 4 + e.num)

# Returns the Edge symmetric to this one.
func sym*(e: Edge): Edge =
  e.quadEdge.e[(e.num + 2) and 3]

# Returns the dual-edge pointing from right to left.
func rot*(e: Edge): Edge =
  e.quadEdge.e[(e.num + 1) and 3]

# Returns the Dual-Edge pointing from left to right.
func invRot*(e: Edge): Edge =
  e.quadEdge.e[(e.num + 3) and 3]

# Returns the origin of this Edge.
func org*(e: Edge): Vertex =
  e.vertex

# Returns the destination of this Edge.
func dest*(e: Edge): Vertex =
  e.sym.vertex

# Edge Traversal Operators -- counter clockwise (CCW) order

# Returns the next Edge about the origin with the same origin.
func oNext*(e: Edge): Edge =
  e.next

# Returns the previous Edge about the origin with the same origin.
func oPrev*(e: Edge): Edge =
  e.rot.onext.rot

# Returns the next Edge about the Right face with the same right face.
func rNext*(e: Edge): Edge =
  e.rot.onext.invRot

# Returns the previous Edge about the Right face with the same right face.
func rPrev*(e: Edge): Edge =
  e.sym.onext

# Returns the next Edge about the destination with the same desination.
func dNext*(e: Edge): Edge =
  e.sym.onext.sym

# Returns the previous Edge about the destination with the same destination.
func dPrev*(e: Edge): Edge =
  e.invRot.onext.invRot

# Returns the next Edge about the left face with the same left face.
func lNext*(e: Edge): Edge =
  e.invRot.onext.rot

# Returns the previous Edge about the left face with the same left face.
func lPrev*(e: Edge): Edge =
  e.oNext.sym

# Set the origin Vertex of this Edge.
proc setOrg*(e: Edge; v: Vertex) =
  assert(v != nil)
  e.vertex = v
  v.edge = e

# Set the destination Vertex of this Edge.
proc setDest*(e: Edge; v: Vertex) =
  e.sym.setOrg(v)

# Simultaneously set the origin and destination Vertices of this Edge.
proc setEndPoints*(e: Edge; org, dest: Vertex) =
  e.setOrg(org)
  e.setDest(dest)

{.pop.} # pop inline

# This operator affects the two edge rings around the origins of a and b, and, independently, the two edge
# rings around the left faces of a and b. In each case, (i) if the two rings are distinct, Splice will combine
# them into one; (ii) if the two are the same ring, Splice will break it into two separate pieces.
# Thus, Splice can be used both to attach the two edges together and to break them apart.
# Guibus and Stolfi (1985 p.96)
# a First non-null Edge to Splice.
# b Second non-null Edge to Splice.
proc splice*(a, b: Edge) =
  let
    alpha = a.oNext.rot
    beta = b.oNext.rot
    temp1 = b.oNext
    temp2 = a.oNext
    temp3 = beta.oNext
    temp4 = alpha.oNext
  a.next = temp1
  b.next = temp2
  alpha.next = temp3
  beta.next = temp4
