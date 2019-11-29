#
# http://www.faqs.org/faqs/graphics/algorithms-faq/ (collection of geometric algorithm)
#
# (C) 2019 S. Salewski 
# v0.1 25-MAY-2019

import types, vectors
from math import sqrt
from salewski import `^`

#     c
#   /
# a ---- b
# https://en.wikipedia.org/wiki/Cross_product#Geometric_meaning
# Returns twice the area of the oriented triangle (a, b, c), i.e., the
# area is positive if the triangle is oriented counterclockwise.
func triArea*(a, b, c: Vector): float {.inline.} =
  (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)

# Returns TRUE if the points a, b, c are in a counterclockwise order
func ccw*(a, b, c: Vector): bool {.inline.} =
  triArea(a, b, c) > 0

# http://mathworld.wolfram.com/Point-LineDistance2-Dimensional.html
#
#   v  /P2
#    \/
#    /\
#   /  \d
#  /    \ 
# /------P0
# P1  r
#
# If the line is specified by two points P1=(x1,y1) and P2=(x2,y2), then a vector V perpendicular to the line is given by
#
# vx = y2 - y1
# vy = -(x2 - x1)
#
# Let R be a vector from the point P0 to P1
#
# rx = x1 - x0
# ry = y1 - y0
#
# Then the distance from P0 to the line is given by projecting R onto V, giving 
#
# d = |(r dot v)| / |v|
#
# d = abs((x1 - x0) * (y2 - y1) - (y1 - y0) * (x2 - x1)) / sqrt((x2 - x1)^2 + (y2 - y1)^2)
#
# We return the square of the result -- sign is positive, if P1, P2, P0 are orientated counterclockwise.
func linePointDistSqr*(p1, p2, p0: Vector): float {.inline.} =
  let d =  (p1.x - p0.x) * (p2.y - p1.y) - (p1.y - p0.y) * (p2.x - p1.x)
  return d * abs(d) / ((p2.x - p1.x) * (p2.x - p1.x) + (p2.y - p1.y) * (p2.y - p1.y))

# http://paulbourke.net/geometry/pointlineplane/
# Minimum Distance between a Point and a Line.
# Line is given by two points P1, P2.
# We search distance of Point P3 to this line.
# Point P is the projection of P3 onto the line.
#
#      P2
#   P /
#    / .P3
#   /
#  /
# P1
#
# We follow the approach of Paul Bourke.
#
# (if u is less than zero, then P is before line segment, if u > 1 then P is after line segment)
#
# P = P1 + u(P2 - P1)
#
# (P3 - P) dot (P2 - P1) = 0
#
# --
#
# (P3 - P1 - u(P2 - P1)) dot (P2 - P1) = 0
#
# --
#
# (x3 - x1 - u(x2 - x1)) * (x2 - x1) + (y3 - y1 - u(y2 - y1)) * (y2 - y1) = 0
#
# (x3 - x1) * (x2 - x1) - u(x2 - x1)^2 + (y3 - y1) * (y2 - y1) - u(y2 - y1)^2 = 0
#
# u = ((x3 - x1) * (x2 - x1) + (y3 - y1) * (y2 - y1)) / ((x2 - x1)^2 + (y2 - y1)^2)
#
# Note: d2 and v2 are the squared distances from point p3 to infinite line and to segment p1-p2
func distanceLinePointSqr*(p1, p2, p3: Vector): (float, float, float, float, float) =
  let
    x1 = p1.x
    y1 = p1.y
    x2 = p2.x
    y2 = p2.y
    x3 = p3.x
    y3 = p3.y
  assert(x2 != x1 or y2 != y1) # division by zero 
  let
    u = ((x3 - x1) * (x2 - x1) + (y3 - y1) * (y2 - y1)) / ((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1))
    x = x1 + u * (x2 - x1)
    y = y1 + u * (y2 - y1)
    d2 = (x - x3) * (x - x3) + (y - y3) * (y - y3) # squared distance to infinite line through p1-p2
  var v2: float # squared distance to line segment defined by p1-p2
  if u < 0:
    v2 = (x3 - x1) * (x3 - x1) + (y3 - y1) * (y3 - y1)
  elif u > 1:
    # v2 = (x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1) # stupid typo in initial release!
    v2 = (x3 - x2) * (x3 - x2) + (y3 - y2) * (y3 - y2)
  else:
    v2 = d2
  return (d2, v2, u, x, y)

# http://paulbourke.net/geometry/pointlineplane/
# Intersection point of two line segments in 2 dimensions
#
# \P3  P2
#  \  /line a
#   \/
#   /\
#  /  \line b
# /P1  P4
#
# The equations of the lines are
#
# Pa = P1 + ua (P2 - P1)
#
# Pb = P3 + ub (P4 - P3) 
#
# Solving for the point where Pa = Pb gives the following two equations in two unknowns (ua and ub)
#
# x1 + ua (x2 - x1) = x3 + ub (x4 - x3) = xa = xb
#
# y1 + ua (y2 - y1) = y3 + ub (y4 - y3) = ya = yb
#
# --
#
# ub = (y1 + ua (y2 - y1) - y3) / (y4 - y3)
#
# x1 + ua (x2 - x1) = x3 + (x4 - x3) * (y1 + ua (y2 - y1) - y3) / (y4 - y3)
#
# x1 + ua (x2 - x1) - (x4 - x3) * (y1 + ua (y2 - y1) - y3) / (y4 - y3) = x3
#
# x1 + ua (x2 - x1) - ((x4 - x3) * y1 + (x4 - x3) * ua (y2 - y1) - (x4 - x3) * y3) / (y4 - y3) = x3
#
# ua (x2 - x1) * (y4 - y3) - ((x4 - x3) * y1 + (x4 - x3) * ua (y2 - y1) - (x4 - x3) * y3) = (x3 - x1) * (y4 - y3)
#
# ua ((x2 - x1) * (y4 - y3) - (x4 - x3) * (y2 - y1)) = (x3 - x1) * (y4 - y3) - (x4 - x3) * y3 + (x4 - x3) * y1
#
# ua = ((x3 - x1) * (y4 - y3) + (x4 - x3) * (y1 - y3)) / ((x2 - x1) * (y4 - y3) - (x4 - x3) * (y2 - y1))
#
# ua = ((x4 - x3) * (y3 - y1) - (x3 - x1) * (y4 - y3)) / ((y2 - y1) * (x4 - x3) - (y4 - y3) * (x2 - x1))
#
# --
#
# ua = ((x3 - x1 + ub (x4 - x3)) / (x2 - x1))
#
# ((x3 - x1 + ub (x4 - x3)) / (x2 - x1)) * (y2 - y1) = y3 + ub (y4 - y3) - y1
#
# (x3 - x1) * (y2 - y1) + ub * (y2 - y1) * (x4 - x3)) = (y3 - y1) * (x2 - x1) + ub (y4 - y3) * (x2 - x1)
#
# ub * ((y2 - y1) * (x4 - x3) - (y4 - y3) * (x2 - x1)) = (y3 - y1) * (x2 - x1) - (x3 - x1) * (y2 - y1)
#
# ub = ((y3 - y1) * (x2 - x1) - (x3 - x1) * (y2 - y1)) / ((y2 - y1) * (x4 - x3) - (y4 - y3) * (x2 - x1))
#
# --
# x = x1 + ua (x2 - x1)
#
# y = y1 + ua (y2 - y1) 
#
# --
#
# The denominators for the equations for ua and ub are the same.
# If the denominator for the equations for ua and ub is 0 then the two lines are parallel.
# If the denominator and numerator for the equations for ua and ub are 0 then the two lines are coincident.
# The equations apply to lines, if the intersection of line segments is required then it is only necessary
# to test if ua and ub lie between 0 and 1. Whichever one lies within that range then the corresponding line
# segment contains the intersection point. If both lie within the range of 0 to 1 then the intersection
# point is within both line segments.
#
func lineLineIntersection*(p1, p2, p3, p4: Vector): (float, float, float, float) =
  let
    x1 = p1.x
    y1 = p1.y
    x2 = p2.x
    y2 = p2.y
    x3 = p3.x
    y3 = p3.y
    x4 = p4.x
    y4 = p4.y
    y2y1 = y2 - y1
    x4x3 = x4 - x3
    y4y3 = y4 - y3
    x2x1 = x2 - x1
    d = y2y1 * x4x3 - y4y3 * x2x1
  var ua = (x4x3 * (y3 - y1) - (x3 - x1) * y4y3)
  var ub = ((y3 - y1) * x2x1 - (x3 - x1) * y2y1)
  var x, y: float
  if d == 0: # parallel
    if ua == 0 or ub == 0: # coincident.
      ua = NaN
      ub = NaN
      x = NaN
      y = NaN
    else:
      ua = Inf
      ua = Inf
      x = Inf
      y = Inf
  else:
    ua /= d
    ub /= d
    x = x1 + ua * x2x1
    y = y1 + ua * y2y1
  return (x, y, ua, ub) 

# https://en.wikipedia.org/wiki/Delaunay_triangulation#Algorithms
# https://stackoverflow.com/questions/39984709/how-can-i-check-wether-a-point-is-inside-the-circumcircle-of-3-points
#
#       | ax-dx, ay-dy, (ax-dx)^2 + (ay-dy)^2 |
# det = | bx-dx, by-dy, (bx-dx)^2 + (by-dy)^2 |
#       | cx-dx, cy-dy, (cx-dx)^2 + (cy-dy)^2 |
#
#
# a1 = ax-dx
# a2 = ay-dy
# b1 = bx-dx
# b2 = by-dy
# c1 = cx-dx
# c2 = cy-dy
#
# det =
#
# (a1 * a1 + a2 * a2) * ((b1 * c2) - (b2 * c1)) +
# (b1 * b1 + b2 * b2) *((a2 * c1) - (a1 * c2)) +
# (c1 * c1 + c2 * c2) * ((a1 * b2) - (a2 * b1))
#
# Caution: This test may be numerical inacurate, seems hard to do epsilon test. Unused! 
func unused_dInCircumCircle2(a, b, c, d: Vector): bool =
  assert ccw(a, b, c)
  let a1 = a.x - d.x
  let a2 = a.y - d.y
  let b1 = b.x - d.x
  let b2 = b.y - d.y
  let c1 = c.x - d.x
  let c2 = c.y - d.y
  (a1 * a1 + a2 * a2) * ((b1 * c2) - (b2 * c1)) + (b1 * b1 + b2 * b2) * ((a2 * c1) - (a1 * c2)) +
  (c1 * c1 + c2 * c2) * ((a1 * b2) - (a2 * b1)) > 0

# http://paulbourke.net/geometry/circlesphere/
# https://en.wikipedia.org/wiki/Circumscribed_circle#Cartesian_coordinates_2
# http://www.faqs.org/faqs/graphics/algorithms-faq/
#
# Triangle in 2D with given points a, b, c
# Find center of circumcircle -- and finally Radius R
#
# We use the trick from wikipedia article of translating whole triangle by vector -a
# Then we get two plain circle equations, with being u the unknown vector to circle center
#
#         /\c
#        /u \
# a(0,0)/----\b
#
# (bx - ux)^2 + (by - uy)^2 = ux^2 + uy^2 = R^2
#
# (cx - ux)^2 + (cy - uy)^2 = ux^2 + uy^2
#
# --
#
# bx^2 - 2bxux + ux^2 + by^2 - 2byuy + uy^2 = ux^2 + uy^2
#
# cx^2 - 2cxux + ux^2 + cy^2 - 2cyuy + uy^2 = ux^2 + uy^2
#
# --
#
# bx^2 - 2bxux + by^2 - 2byuy = 0
#
# cx^2 - 2cxux + cy^2 - 2cyuy = 0
#
# --
#
# uy = (cx^2 - 2cxux + cy^2) / (2cy)
#
# bx^2 - 2bxux + by^2 - 2by * (cx^2 - 2cxux + cy^2) / (2cy) = 0
#
# 2cy * bx^2 - 4bxcyux + 2cy * by^2 - 2by * cx^2 + 4bycxux - 2by * cy^2 = 0
#
# ux = (cy * bx^2 + cy * by^2 - by * cx^2 - by * cy^2) / (2bxcy - 2bycx)
#
# --
#
# ux = (bx^2 - 2byuy + by^2) / (2bx)
#
# cx^2 - 2cx * (bx^2 - 2byuy + by^2) / (2bx) + cy^2 - 2cyuy = 0
#
# uy = (bx * cx^2 - cx * bx^2 - cx * by^2 + bx * cy^2) / (2bxcy - 2bycx)
#
# --
#
# D = 2(bxcy - bycx)
#
# ux = (cy * (bx^2 + by^2) - by * (cx^2 + cy^2)) / D
#
# uy = (bx * (cx^2 + cy^2) - cx * (bx^2 + by^2)) / D
#
# seems that we have to apply sqrt() for well defined epsilon test
# TODO: Should we use epsilon test with fixed value, or with user defined this.epsilon?
func dInCircumCircle*(a, b, c, d: Vector): bool =
  assert ccw(a, b, c) # triArea(a, b, c) != 0 is what we really need
  let
    bx = b.x - a.x # initial translation by -a
    by = b.y - a.y
    cx = c.x - a.x
    cy = c.y - a.y
    D = 2 * (bx * cy - by * cx)
    b2 = (bx * bx + by * by)
    c2 = (cx * cx + cy * cy)
    ux = (cy * b2 - by * c2) / D
    uy = (bx * c2 - cx * b2) / D
    # R^2 = ux * ux + uy * uy 
    x = d.x - a.x
    y = d.y - a.y
  sqrt((x - ux) * (x - ux) + (y - uy) * (y - uy)) * (1 + 1e-12) < sqrt(ux * ux + uy * uy)

# https://en.wikipedia.org/wiki/Barycentric_coordinate_system
# https://codeplea.com/triangular-interpolation
func interpolateZ*(p1, p2, p3: Vector; p: var Vector) =
  when p is Vector3:
    let detT = (p2.y - p3.y) * (p1.x - p3.x) + (p3.x - p2.x) * (p1.y - p3.y)
    let l1 = ((p2.y - p3.y) * (p.x - p3.x) + (p3.x - p2.x) * (p.y - p3.y)) / detT
    let l2 = ((p3.y - p1.y) * (p.x - p3.x) + (p1.x - p3.x) * (p.y - p3.y)) / detT
    let l3 = 1 - l1 - l2
    p.z = l1 * p1.z + l2 * p2.z + l3 * p3.z

# https://en.wikipedia.org/wiki/Linear_interpolation
func interpolateZ*(p1, p2: Vector; p: var Vector) =
  when p is Vector3:
    p.z = p1.z + (p2.z - p1.z) * sqrt(((p.x - p1.x) ^ 2 + (p.y - p1.y) ^ 2) / ((p2.x - p1.x) ^ 2 + (p2.y - p1.y)))

# projection u of point P0 on line defined by Point P1 and P2
# https://en.wikipedia.org/wiki/Vector_projection
#
#      /P2
#     /
#    /\
#  u/  \ 
#  /    \ 
# /------P0
# P1
#
# u = (P2 - P1) dot (P0 - P1) / |P2 - P1|
# u = ((x2 - x1) * (x0 - x1) + (y2 - y1) * (y0 - y1)) / sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
# x = u * (x2 - x1)
# y = u * (y2 - y1)
# z = u * (z2 - z1)
#
func projection*(p1, p2, p0: Vector): Vector {.inline.} =
  let u = ((p2.x - p1.x) * (p0.x - p1.x) + (p2.y - p1.y) * (p0.y - p1.y)) / sqrt((p2.x - p1.x) ^ 2 + (p2.y - p1.y) ^ 2)
  result.x = u * (p2.x - p1.x)
  result.y = u * (p2.y - p1.y)
  when Vector is Vector3:
    result.z = u * (p2.z - p1.z)

# http://erich.realtimerendering.com/ptinpoly/
# http://www.faqs.org/faqs/graphics/algorithms-faq/
# https://stackoverflow.com/questions/217578/how-can-i-determine-whether-a-2d-point-is-within-a-polygon
#
#int pnpoly(int npol, float *xp, float *yp, float x, float y)
#{
#  int i, j, c = 0;
#  for (i = 0, j = npol-1; i < npol; j = i++) {
#    if ((((yp[i]<=y) && (y<yp[j])) ||
#         ((yp[j]<=y) && (y<yp[i]))) &&
#        (x < (xp[j] - xp[i]) * (y - yp[i]) / (yp[j] - yp[i]) + xp[i]))
#
#      c = !c;
#  }
#  return c;
#}
#
func pnpoly*(p: openArray[Vector]; x, y: float): bool {.inline.} =
  var i, j: int
  j = p.high
  while i < p.len:
    if (((p[i].y <= y) and (y < p[j].y)) or ((p[j].y <= y) and (y < p[i].y))) and
        (x < (p[j].x - p[i].x) * (y - p[i].y) / (p[j].y - p[i].y) + p[i].x):
      result = not result
    inc(i) 
    j = i
