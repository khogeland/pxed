import constants

type
  RGB18Color* = object
    r*, g*, b*: u6
  HSVColor* = object
    hue*, saturation*, value*: float

func rgb*(r, g, b: u6): RGB18Color = RGB18Color(r: r, g: g, b: b)
func rgb*(r, g, b: float): RGB18Color = RGB18Color(
  r: uint8(r*63.9).u6,
  g: uint8(g*63.9).u6,
  b: uint8(b*63.9).u6)
func hsv*(h, s, v: float): HSVColor = HSVColor(hue: h, saturation: s, value: v)

func adjustValue*(rgb: RGB18Color, value: float): RGB18Color =
  let v = value * 63.9
  if value == 0:
    return RGB18Color(r: 0.u6, g: 0.u6, b: 0.u6)
  # TODO: organization red flag, this is for the picker color map mask
  if max(rgb.r, max(rgb.g, rgb.b)) == 0.u6:
    return rgb(0,0,0)
  let r = float(rgb.r)
  let g = float(rgb.g)
  let b = float(rgb.b)

  if r >= g and r >= b:
    return rgb(u6(v), u6((g/r) * v), u6((b/r) * v))
  elif g >= r and g >= b:
    return rgb(u6((r/g) * v), u6(v), u6((b/g) * v))
  else:
    return rgb(u6((r/b) * v), u6((g/b) * v), u6(v))

func invertColor*(hsv: HSVColor): HSVColor =
  result = hsv
  result.hue += 180.0 
  if result.hue > 360.0:
    result.hue -= 360.0
  result.value = if hsv.value > 0.5: hsv.value-0.5 else: hsv.value+0.5  

func rgbToHsv*(rgb: RGB18Color): HSVColor =
  let r = float(rgb.r)/64.0
  let g = float(rgb.g)/64.0
  let b = float(rgb.b)/64.0
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

proc hsvToRgb*(hsv: HSVColor): RGB18Color =
  let s = hsv.saturation
  let v = hsv.value
  if s < 0.0001: # gray
    let vi = u6(v*63.9)
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
  return rgb(u6(r*63.9), u6(g*63.9), u6(b*63.9))
