from math import sqrt, hypot
from salewski import `^`

type
  Vector2* = object of RootObj
    x*, y*: float

  Vector3* = object of Vector2
    z*: float

  Vector4* = object of Vector3
    w*: float

  Vec* = Vector2 | Vector3 | Vector4

{.push inline.} # inline tiny procs

func dim(a: Vec): static[int] =
  when a is Vector4:
    result = 4
  else:
    when a is Vector3:
      result = 3
    else:
      result = 2

func initVector3*(x: float = 0, y: float = 0, z: float = 0): Vector3 =
  Vector3(x: x, y: y, z: z)

func `[]`*(v: Vec; i: static[int]): float =
  when i == 0: return v.x
  else:
    when i == 1: return v.y
    else:
      when v is Vector3 and i == 2: return v.z
      else:
        when v is Vector4 and i == 3: return v.w
        else:
          system.quit("Index error")

func `[]`*(v: Vec; i: int): float =
  if i == 0: return v.x
  if i == 1: return v.y
  when v is Vector3:
    if i == 2: return v.z
  when v is Vector4:
    if i == 3: return v.w
  system.quit("Index error")

func `+`*(a, b: Vec): Vec =
  result.x = a.x + b.x
  result.y = a.y + b.y
  when a is Vector3:
    result.z = a.z + b.z
  when a is Vector4:
    result.w = a.w + b.w

# this does not compile
#func `&`*(a, b: Vec): Vec =
#    for i in 0 .. dim(a):
#      result[i] = a[i] + b[i]

func `-`*(a, b: Vec): Vec =
  result.x = a.x - b.x
  result.y = a.y - b.y
  when a is Vector3:
    result.z = a.z - b.z
  when a is Vector4:
    result.w = a.w - b.w

func `+=`*(a: var Vec; b: Vec) =
  a.x += b.x
  a.y += b.y
  when a is Vector3:
    a.z += b.z
  when a is Vector4:
    a.w += b.w

func `-=`*(a: var Vec; b: Vec) =
  a.x -= b.x
  a.y -= b.y
  when a is Vector3:
    a.z -= b.z
  when a is Vector4:
    a.w -= b.w

func `*`*(b: float; a: Vec): Vec =
  result.x = a.x * b
  result.y = a.y * b
  when a is Vector3:
    result.z = a.z * b
  when a is Vector4:
    result.w = a.w * b

func `*`*(a: Vec; b: float): Vec =
  b * a

# https://en.wikipedia.org/wiki/Cross_product
func cross*(a, b: Vector3): Vector3 =
    result.x = a.y * b.z - a.z * b.y
    result.y = a.z * b.x - a.x * b.z
    result.z = a.x * b.y - a.y * b.x

func `^`*(a, b: Vector3): Vector3 =
  a.cross(b)

func dot*(a, b: Vec): float =
  result = a.x * b.x + a.y * b.y
  when a is Vector3:
    result += a.z * b.z
  when a is Vector4:
    result += a.w * b.w

func lengthSqr*(a: Vec): float =
  result = a.x * a.x + a.y * a.y
  when a is Vector3:
    result += a.z * a.z
  when a is Vector4:
    result += a.w * a.w

func length*(a: Vec): float =
  math.sqrt(lengthSqr(a))

func length2dSqr*(a: Vec): float =
  a.x * a.x + a.y * a.y

func length2d*(a: Vec): float =
  hypot(a.x, a.y)

proc normalize*(a: var Vec) =
  let l = 1 / a.length
  a.x *= l
  a.y *= l
  when a is Vector3:
    a.z *= l
  when a is Vector4:
    a.w *= l

{.pop.} # inline

when isMainModule:

  var x: Vector3 = Vector3(x:1, y:2, z:3)
  var y: Vector3 = initVector3(4, 5, 6)

  echo repr(x + y)
  #echo repr(x & y)

