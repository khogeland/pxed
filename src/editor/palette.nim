import constants
import color
import math
#

const TAG*: cstring = "palette"

type
  ColorPicker = object
    red, green, blue, saturation, value: float

proc initPicker*(): ColorPicker =
  return ColorPicker(
    red: 0.5,
    green: 0.5,
    blue: 0.5,
    saturation: 1.0,
    value: 0.5,
  )

const shiftspeed: float = 0.01

proc moveColor(colorVar: var float, moveDeg, colorDeg: float) =
  colorVar += (1 - 2 * (abs(colorDeg - moveDeg) / 180)) * shiftspeed
  if colorVar > 0.9999:
    colorVar = 1.0
  if colorVar < 0.0001:
    colorVar = 0.0

proc moveHue*(picker: var ColorPicker, x, y: float64) =
  if abs(x) < 0.001 and abs(y) < 0.001:
    return
  let moveDeg = 180 + arctan2(y,x)*180/PI
  moveColor(picker.red, moveDeg, 90)
  moveColor(picker.green, moveDeg, 210)
  moveColor(picker.blue, moveDeg, 330)


proc draw*(picker: ColorPicker, buffer: var framebuffer) =
  let rgbColor = rgb(picker.red, picker.green, picker.blue)
  var hsvColor = rgbToHsv(rgbColor)
  #hsvColor.saturation = picker.saturation
  hsvColor.value = picker.value
  let realColor = RGBasRGB16(hsvToRgb(hsvColor))
  let pc = RGB16asRGB(realColor)
  # TODO
