#import math
#

type
  # TODO TODO TODO TODO refactor to use 18-bit mode
  # i think i chose this for convenience but that's a stupid reason to impose limits
  # Store things as 16-bit RGB for consistency
  RGB16Color* = uint16
  HSVColor* = object
    hue*, saturation*, value*: float

# TODO rgb 18
func red*(rgb: RGB16Color): uint8 = uint8((rgb shr 8)   and 0b11111000)
func green*(rgb: RGB16Color): uint8 = uint8((rgb shr 3) and 0b11111100)
func blue*(rgb: RGB16Color): uint8 = uint8((rgb shl 3)  and 0b11111000)

func rgb*(r, g, b: uint8): RGB16Color = (uint16(r shr 3) shl 11) or (uint16(g shr 2) shl 5) or (b shr 3)
func rgb*(r, g, b: float): RGB16Color = rgb(uint8(r*255) and 0b11111000, uint8(g*255) and 0b11111100, uint8(b))
func hsv*(h, s, v: float): HSVColor = HSVColor(hue: h, saturation: s, value: v)

#func adjustValue*(rgb: RGB16Color, value: uint8): RGB16Color =
  #let v = value
  #if value == 0:
    #return 0
  #let r = rgb.red()
  #let g = rgb.green()
  #let b = rgb.blue()
  #if r >= g and r >= b:
    #return rgb(v, (g div r) * v, (b div r) * v)
  #elif g >= r and g >= b:
    #return rgb((r div g) * v, v, (b div g) * v)
  #else:
    #return rgb((r div b) * v, (g div b) * v, v)
func adjustValue*(rgb: RGB16Color, value: float): RGB16Color =
  let v = value * 255
  if value == 0:
    return 0
  # TODO: organization red flag, this is for the picker color map mask
  if rgb == 0:
    return 0
  let r = float(rgb.red())
  let g = float(rgb.green())
  let b = float(rgb.blue())

  if r >= g and r >= b:
    return rgb(uint8(v), uint8((g/r) * v), uint8((b/r) * v))
  elif g >= r and g >= b:
    return rgb(uint8((r/g) * v), uint8(v), uint8((b/g) * v))
  else:
    return rgb(uint8((r/b) * v), uint8((g/b) * v), uint8(v))

func invertColor*(hsv: HSVColor): HSVColor =
  result = hsv
  result.hue += 180.0 
  if result.hue > 360.0:
    result.hue -= 360.0
  result.value = if hsv.value > 0.5: hsv.value-0.5 else: hsv.value+0.5  

func rgbToHsv*(rgb: RGB16Color): HSVColor =
  let r = float(rgb.red())/255.0
  let g = float(rgb.green())/255.0
  let b = float(rgb.blue())/255.0
  let v = max(r, max(g, b))
  if v < 0.0001:
    return HSVColor(
      hue: 0.0,
      saturation: 0.0,
      value: 0.0,
    )
  let minrgb = min(r, min(g, b))
  let delta = v - minrgb
  let s = delta / v
  var h: float
  if r >= g and r >= b:
      h = (g - b) / delta
  elif g >= r and g >= b:
      h = 2.0 + (b - r) / delta
  else:
      h = 4.0 + (r - g) / delta
  h *= 60.0
  if h < 0.0:
    h += 360.0
  return HSVColor(
    hue: h,
    saturation: s,
    value: v,
  )

const
  RED = 0
  YELLOW = 1
  GREEN = 2
  CYAN = 3
  BLUE = 4

proc hsvToRgb*(hsv: HSVColor): RGB16Color =
  let s = hsv.saturation
  let v = hsv.value
  if s < 0.0001: # gray
    let vi = uint8(v*255)
    return rgb(vi, vi, vi)
  var h = hsv.hue
  if h > 359.99:
    h = 0.0
  h /= 60.0
  let region = int(h)
  let ff = h - float(region)
  var p = v * (1.0 - s)
  var q = v * (1.0 - (s * ff))
  var t = v * (1.0 - (s * (1.0 - ff)))
  var r, g, b: float
  if region == RED: # red
    r = v
    g = t
    b = p
  elif region == YELLOW:
    r = q
    g = v
    b = p
  elif region == GREEN:
    r = p
    g = v
    b = t
  elif region == CYAN:
    r = p
    g = q
    b = v
  elif region == BLUE:
    r = t
    g = p
    b = v
  else:
    r = v
    g = p
    b = q
  # ??? sanity checking
  if r < 0.0001: r = 0.0
  if g < 0.0001: g = 0.0
  if b < 0.0001: b = 0.0
  #if r > 0.9999: r = 1.0
  #if g > 0.9999: g = 1.0
  #if b > 0.9999: b = 1.0
  return rgb(uint8(r*255.0), uint8(g*255.0), uint8(b*255.0))

  #return rgb(uint8(r), uint8(g), uint8(b))

#func RGB16asRGB*(rgb16: RGB16Color): RGBColor =
  ## RRRRRGGG GGGBBBBB (in order)
  #return RGBColor(
    #red: float((rgb16 shr 8)   and 0b11111000)/255.0,
    #green: float((rgb16 shr 3) and 0b11111100)/255.0,
    #blue: float((rgb16 shl 3)  and 0b11111000)/255.0,
  #)

#proc RGBasRGB16*(rgb: RGBColor): RGB16Color =
  #let r = uint16(toInt(rgb.red * 255.0)) shr 3
  #let g = uint16(toInt(rgb.green * 255.0)) shr 2
  #let b = uint16(toInt(rgb.blue * 255.0)) shr 3
  #return (r shl 11) or (g shl 5) or b
