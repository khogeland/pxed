
func plotLine(x0, y0, x1, y1: int, space: var array[SCREEN_HEIGHT, array[SCREEN_WIDTH, bool]]): void =
  var
    x0 = x0
    y0 = y0
  let dx = abs(x1 - x0)
  let sx = if x0 < x1: 1 else: -1
  let dy = -abs(y1 - y0)
  let sy = if y0 < y1: 1 else: -1
  var error = dx + dy
  while true:
      space[x0][y0] = true
      if x0 == x1 and y0 == y1: break
      let e2 = 2 * error
      if e2 >= dy:
          if x0 == x1: break
          error = error + dy
          x0 = x0 + sx
      if e2 <= dx:
          if y0 == y1: break
          error = error + dx
          y0 = y0 + sy

const
  triPointTop = (int((SCREEN_WIDTH-1) - (tan(degToRad(15.0)) * SCREEN_HEIGHT)), 0)
  triPointLeft = (0, int((SCREEN_HEIGHT-1) - (tan(degToRad(15.0)) * SCREEN_WIDTH)))
  triPointCorner = (SCREEN_HEIGHT-1, SCREEN_WIDTH-1)
  triMaxDistance = block:
    var side = distance(triPointTop[0], triPointTop[1], triPointLeft[0], triPointLeft[1])
    side*(sqrt(3.0)/2.0)
  triangleSegments = block:
    var space: array[SCREEN_HEIGHT, array[SCREEN_WIDTH, bool]]
    plotLine(triPointTop[0], triPointTop[1], triPointLeft[0], triPointLeft[1], space)
    plotLine(triPointTop[0], triPointTop[1], triPointCorner[0], triPointCorner[1], space)
    plotLine(triPointCorner[0], triPointCorner[1], triPointLeft[0], triPointLeft[1], space)
    var segments: array[SCREEN_HEIGHT, array[2, int]]
    for y in 0..SCREEN_HEIGHT-1:
      var foundOne = false
      var last = 0
      for x in 0..SCREEN_HEIGHT-1:
        if space[x][y]:
          if not foundOne:
            segments[y][0] = x
            foundOne = true
          else:
            last = x
      segments[y][1] = last-segments[y][0]
    segments

proc drawTriangle(buffer: var framebuffer): void =
  for y in 0..SCREEN_HEIGHT-1:
    var segX = triangleSegments[y][0]
    var segL = triangleSegments[y][1]
    for x in segX..segX+segL:
      let red = max(0.0, (triMaxDistance - distance(float(x), float(y), float(triPointTop[0]), float(triPointTop[1])))/triMaxDistance)
      let green = max(0.0, (triMaxDistance - distance(float(x), float(y), float(triPointLeft[0]), float(triPointLeft[1])))/triMaxDistance)
      let blue = max(0.0, (triMaxDistance - distance(float(x), float(y), float(triPointCorner[0]), float(triPointCorner[1])))/triMaxDistance)
      buffer[x, y] = RGBasRGB16(rgb(red, green, blue))

