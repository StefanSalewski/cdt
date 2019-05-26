import vectors, types, edges

{.push inline.} # inline tiny procs

func newVertex*(p: Vector; id: VertexID): Vertex =
  Vertex(point: p, id: id)

func newVertex*(x, y: float; z: float = 0; id: VertexID): Vertex =
  when result.point is Vector3:
    Vertex(point: Vector(x: x, y: y, z: z), id: id)
  else:
    Vertex(point: Vector(x: x, y: y), id: id)

# Returns the unique ID assigned to this Vertex.
func getID*(v: Vertex): VertexID =
  v.id

# Returns an arbitrary Edge linked to this Vertex.
# All Edges linked to this Vertex can be found by iterating around the returned Edge using Edge.oNext().
func firstEdge*(v: Vertex): Edge =
  v.edge

proc clearEdge*(v: Vertex) =
  v.edge = nil

# Remove an Edge linked to this Vertex.
proc removeEdge*(v: Vertex; e: Edge) =
  assert e.org == v
  if e.oNext == e:
    v.edge = nil
  else:
    v.edge = e.oNext

{.pop.}
