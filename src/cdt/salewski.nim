#
# https://github.com/nim-lang/Nim/blob/devel/lib/system/iterators.nim#L1
# https://forum.nim-lang.org/t/4582#28715
iterator span*[T](a: openArray[T]; j, k: Natural): T {.inline.} =
  assert k < a.len
  var i: int = j 
  while i <= k:
    yield a[i]
    inc(i)

#[
proc `^`*[T](x: T, y: static[Natural]): T {.inline.} =
  when y < 7:
    when y == 0:
      result = T(1)
    when y == 1:
      result = x
    when y == 2:
      result = x * x
    when y == 3:
      result = x * x * x
    when y == 4:
      result = x * x
      result *= result
    when y == 5:
      result = x * x
      result *= (result * x)
    when y == 6:
      result = x * x
      result *= (result * result)
  else:
    result = math.`^`(x, y)
]#

# make ^ really fast -- this is optimized perfectly by gcc
# https://github.com/nim-lang/Nim/issues/10910
func `^`*[T](x: T, y: static[Natural]): T {.inline.} =
  when y < 10:
    result = T(1)
    var i = y
    while i > 0:
      result *= x
      dec(i)
  else:
    result = math.`^`(x, y)

iterator xpairs*[T](a: openarray[T]): array[2, T] {.inline.} =
  var i, j: int
  while i < len(a):
    inc(j)
    if j == a.len:
      j = 0
    yield [a[i], a[j]]
    inc(i)

iterator xclusters*[T](a: openarray[T]; s: static[int]): array[s, T] {.inline.} =
  var result: array[s, T] # iterators have no default result variable
  var i = 0
  while i < len(a):
    for j, x in mpairs(result):
      x = a[(i + j) mod len(a)]
    yield result
    inc(i)

when isMainModule:

  for xp in xpairs([1, 2, 3, 4, 5]):
    echo xp
  echo ""

  for xp in xclusters([1, 2, 3, 4, 5], 2):
    var u, v: int
    (u, v) = xp # tuple unpacking works for arrays too!
    echo u, ", ", v
  echo ""

  for xp in xclusters([1, 2, 3, 4, 5], 3):
    echo xp
  echo ""
