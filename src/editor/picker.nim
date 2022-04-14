import constants
import color
import math
import strutils

const TAG*: cstring = "palette"

const
  moveSpeed = 0.5
  centerPoint = (SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2)
  radius = min(SCREEN_WIDTH, SCREEN_HEIGHT)/2.0

func findColor(hsv: HSVColor): (float, float) =
  let angle = degToRad(hsv.hue) - PI
  let dist = hsv.saturation*radius
  result[0] = centerPoint[0] + dist*sin(angle)
  result[1] = centerPoint[1] + dist*cos(angle)

type
  ColorPicker* = object
    value: float
    cursor: (float, float)

proc initPicker*(color: RGB16Color): ColorPicker =
  let rgb = RGB16asRGB(color)
  let hsv = rgbToHsv(rgb)
  return ColorPicker(
    cursor: findColor(hsv),
    value: hsv.value,
  )

proc moveCursor*(picker: var ColorPicker, d: direction): void =
  case d
    of LEFT: 
      if picker.cursor[0] > 0+moveSpeed: picker.cursor[0] -= moveSpeed
    of RIGHT:
      if picker.cursor[0] < SCREEN_WIDTH-1-moveSpeed: picker.cursor[0] += moveSpeed
    of UP:
      if picker.cursor[1] < SCREEN_HEIGHT-1-moveSpeed: picker.cursor[1] += moveSpeed
    of DOWN:
      if picker.cursor[1] > 0+moveSpeed: picker.cursor[1] -= moveSpeed

type intOrFloat = float

converter toIOF(i: int): intOrFloat = float(i)

func radialColorAt(x, y: intOrFloat, value: float): RGB16Color =
  let dx = x-centerPoint[0]
  let dy = y-centerPoint[1]
  let dist = sqrt(dx^2 + dy^2)
  #left here in memorial of a typo that made a cool looking thing
  #let distN = max(dist/r, 1.0)
  #let distN = min(dist/r, 1.0)
  let distN = dist/radius
  if distN > 1.0:
    return 0
  let hue = radToDeg(arctan2(dx, dy) + PI)
  return RGBasRGB16(hsvToRgb(hsv(hue, distN, value)))

proc cursorColor*(picker: ColorPicker): RGB16Color =
  return radialColorAt(picker.cursor[0], picker.cursor[1], picker.value)

proc drawCircle(picker: ColorPicker, buffer: var framebuffer): void =
  let c = picker.cursorColor()
  for y in 0..SCREEN_HEIGHT-1:
    for x in 0..SCREEN_WIDTH-1:
      let color = radialColorAt(x, y, picker.value)
      buffer[x, y] = color
      #TODO: whatever
      let dx = x-centerPoint[0]
      let dy = y-centerPoint[1]
      #another pretty typo
      #if sqrt(dx^2 * dy^2) > radius:
      if sqrt(dx^2 + dy^2) > radius:
        buffer[x, y] = c

proc changeValue*(picker: var ColorPicker, by: float): void =
  picker.value += by
  if picker.value < 0.001:
    picker.value = 0.0
  elif picker.value > 0.999:
    picker.value = 1.0

proc drawCursor(picker: ColorPicker, buffer: var framebuffer) =
  let cx = int(picker.cursor[0])
  let cy = int(picker.cursor[1])
  let color = picker.cursorColor()
  let inverted = invertColor(color)
  for sx in max(cx-2, 0)..min(cx+2, SCREEN_WIDTH-1):
    for sy in max(cy-2, 0)..min(cy+2, SCREEN_HEIGHT-1):
      buffer[sx, sy] = inverted

proc draw*(picker: ColorPicker, buffer: var framebuffer) =
  drawCircle(picker, buffer)
  drawCursor(picker, buffer)
