import constants
import color
import math
#import strutils

const TAG*: cstring = "palette"

const
  moveSpeed = 0.5
  centerPoint = (SCREEN_WIDTH / 2.0, SCREEN_HEIGHT / 2.0)
  radius = (min(SCREEN_WIDTH, SCREEN_HEIGHT)/2.0)-5

type intOrFloat = float
converter toIOF(i: int): intOrFloat = float(i)

func radialColorAt(x, y: intOrFloat, value: float): HSVColor =
  #TODO why the hell isn't this centered why is the circle unevenly sized
  #let fx = if x < centerPoint[0]: x-0.5 elif x > centerPoint[0]: x+0.5 else: 0
  let dx = (x-centerPoint[0])
  let dy = (y-centerPoint[1])
  let dist = sqrt(dx^2 + dy^2)
  #left here in memorial of a typo that made a cool looking thing
  #let distN = max(dist/r, 1.0)
  #let distN = min(dist/r, 1.0)
  let distN = dist/radius
  if distN > 1.0:
    return hsv(0, 0, 0)
  if distN < 0.001:
    return hsv(0, distN, value)
  let hue = radToDeg(arctan2(dx, dy) + PI)
  return hsv(hue, distN, value)

func findColor(hsv: HSVColor): (float, float) =
  let dist = min(hsv.saturation*radius, 0.999)
  if dist < 0.001:
    return centerPoint
  let angle = degToRad(hsv.hue) - PI
  result[0] = centerPoint[0] + dist*sin(angle)
  result[1] = centerPoint[1] + dist*cos(angle)

const baseColorMap: framebuffer = static:
  var result: framebuffer
  for y in 0..SCREEN_HEIGHT-1:
    for x in 0..SCREEN_WIDTH-1:
      let color = hsvToRgb(radialColorAt(x, y, 1.0))
      result[x, y] = color
  result

var value: float
var cursor: (float, float)
#var colorMap: framebuffer

proc initPicker*(color: RGB16Color) =
  let hsv = rgbToHsv(color)
  cursor = findColor(hsv)
  value = hsv.value
  #colorMap = baseColorMap

proc movePickerCursor*(x, y: int): void =
  cursor[0] = max(0, min(SCREEN_WIDTH-1, cursor[0]+x))
  cursor[1] = max(0, min(SCREEN_HEIGHT-1, cursor[1]+y))

proc pickerCursorColor*(): RGB16Color =
  return hsvToRgb(radialColorAt(cursor[0], cursor[1], value))

proc drawCircle(buffer: var framebuffer): void =
  let c = pickerCursorColor()
  const W = 32
  const f = SCREEN_WIDTH div W
  const tileByteWidth = f * 2
  const skipY = tileByteWidth * W * f
  var eX = -1
  var eY = -1
  var color1: uint8
  var color2: uint8
  for i in countup(0, BUFFER_LENGTH-1, 2):
    if i mod tileByteWidth == 0:
      eX += 1
      if eX == W:
        eX = 0
      if i mod skipY == 0:
        eY += 1
      let baseColor = baseColorMap[eX * f, eY * f]
      let color = if baseColor == 0: c else: adjustValue(baseColor, value)
      color1 = uint8(color shr 8)
      color2 = uint8(color)
    buffer[i] = color1
    buffer[i+1] = color2

proc drawNotCircle(buffer: var framebuffer): void =
  let c = pickerCursorColor()
  for y in 0..SCREEN_HEIGHT-1:
    for x in 0..SCREEN_WIDTH-1:
      let dx = x-centerPoint[0]
      let dy = y-centerPoint[1]
      #another pretty typo
      #if sqrt(dx^2 * dy^2) > radius:
      if sqrt(dx^2 + dy^2) > radius:
        buffer[x, y] = c

proc changePickerValue*(by: float): void =
  value += by
  if value < 0.001:
    value = 0.0
  elif value > 0.999:
    value = 1.0
  #for y in 0..SCREEN_WIDTH-1:
    #for x in 0..SCREEN_WIDTH-1:
      #colorMap[x, y] = adjustValue(colorMap[x, y], value)

proc drawCursor(buffer: var framebuffer) =
  let cx = int(cursor[0])
  let cy = int(cursor[1])
  let color = pickerCursorColor()
  let inverted = color xor 0xFFFF
  for sx in max(cx-2, 0)..min(cx+2, SCREEN_WIDTH-1):
    for sy in max(cy-2, 0)..min(cy+2, SCREEN_HEIGHT-1):
      buffer[sx, sy] = inverted

proc drawPicker*(buffer: var framebuffer) =
  drawCircle(buffer)
  #drawNotCircle(picker, buffer)
  drawCursor(buffer)
