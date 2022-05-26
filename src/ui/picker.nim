import constants
import color
import math
import framebuffer
import gfx/sprites
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
  let dist = min(hsv.saturation*radius, radius)
  if dist < 0.001:
    return centerPoint
  let angle = degToRad(hsv.hue) - PI
  result[0] = centerPoint[0] + dist*sin(angle)
  result[1] = centerPoint[1] + dist*cos(angle)

const baseColorMap: framebuffer18 = static:
  var result: framebuffer18
  for y in 0..SCREEN_HEIGHT-1:
    for x in 0..SCREEN_WIDTH-1:
      let color = hsvToRgb(radialColorAt(x, y, 1.0))
      result[x, y] = color
  result

var value: float
var cursor: (float, float)
var pointerSprite = loadImage(10, 10, 2, "glass.tga")
pointerSprite.hide()

proc updatePointer(): void =
  pointerSprite.move(int(cursor[0]-8), int(cursor[1]-8))

proc initPicker*(color: RGB18Color) =
  pointerSprite.show()
  let hsv = rgbToHsv(color)
  cursor = findColor(hsv)
  updatePointer()
  value = hsv.value

proc closePicker*() =
  pointerSprite.hide()

proc movePickerCursor*(x, y: int): void =
  cursor[0] = max(0, min(SCREEN_WIDTH-1, cursor[0]+x))
  cursor[1] = max(0, min(SCREEN_HEIGHT-1, cursor[1]+y))
  updatePointer()

proc pickerCursorColor*(): RGB18Color =
  return hsvToRgb(radialColorAt(cursor[0], cursor[1], value))

proc drawCircle(buffer: var framebuffer18): void =
  let c = pickerCursorColor()
  const W = 32
  const f = SCREEN_WIDTH div W
  const skipY = SCREEN_WIDTH * f
  var eX = -1
  var eY = -1
  var color: RGB18Color
  for i in 0..len(buffer)-1:
    if i mod f == 0:
      eX += 1
      if eX == W:
        eX = 0
      if i mod skipY == 0:
        eY += 1
      let baseColor = baseColorMap[eX * f, eY * f]
      color = if baseColor == rgb(0,0,0): c else: adjustValue(baseColor, value)
    buffer[i] = color

proc changePickerValue*(by: float): void =
  value += by
  if value < 0.001:
    value = 0.0
  elif value > 0.999:
    value = 1.0

proc drawCursor(buffer: var framebuffer18) =
  let cx = int(cursor[0])
  let cy = int(cursor[1])
  let color = pickerCursorColor()
  #let inverted = hsvToRgb(invertColor(rgbToHsv(color)))
  for sx in max(cx-4, 0)..min(cx+4, SCREEN_WIDTH-1):
    for sy in max(cy-4, 0)..min(cy+4, SCREEN_HEIGHT-1):
      buffer[sx, sy] = color

proc drawPicker*(buffer: var framebuffer18) =
  drawCircle(buffer)
  #drawNotCircle(picker, buffer)
  drawCursor(buffer)
