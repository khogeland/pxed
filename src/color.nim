import math
#

type
  # TODO TODO TODO TODO refactor to use 18-bit mode
  # i think i chose this for convenience but that's a stupid reason to impose limits
  # Store things as 16-bit RGB for consistency
  RGB16Color* = uint16
  RGBColor* = object
    red*, green*, blue*: float
  HSVColor* = object
    hue*, saturation*, value*: float

func rgb*(r, g, b: float): RGBColor = RGBColor(red: r, green: g, blue: b)
func hsv*(h, s, v: float): HSVColor = HSVColor(hue: h, saturation: s, value: v)

func invertColor*(hsv: HSVColor): HSVColor =
  result = hsv
  result.hue += 180.0 
  if result.hue > 360.0:
    result.hue -= 360.0
  result.value = 1 - hsv.value

func rgbToHsv*(rgb: RGBColor): HSVColor =
  let r = rgb.red
  let g = rgb.green
  let b = rgb.blue
  let v = max(r, max(g, b))
  if v < 0.0001:
    return HSVColor(
      hue: 0.0,
      saturation: 0.0,
      value: 0.0,
    )
  let minrgb = min(r, min(g, b))
  let delta = v - minrgb
  if delta < 0.0001:
    return HSVColor(
      hue: 0.0,
      saturation: 0.0,
      value: v,
    )
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

#func rgbToHsv*(rgb: RGBColor): HSVColor =
  #let v = max(max(rgb.red, rgb.green), rgb.blue)
  #if v == 0:
    #return hsv(0,0,0)
  #let rgbMin = min(min(rgb.red, rgb.green), rgb.blue)
  #let s = (255 * (float(v - rgbMin) / float(v))).toInt()
  #let h = if v == rgb.red:
      #0 + 43 * float(rgb.green - rgb.blue) / float(v - rgbMin)
    #elif v == rgb.green: 85 + 43 * float(rgb.blue - rgb.red) / float(v - rgbMin)
    #else: 171 + 43 * float(rgb.red - rgb.green) / float(v - rgbMin)
  #return hsv(uint8(h.toInt()), uint8(s), v)

proc hsvToRgb*(hsv: HSVColor): RGBColor =
  let s = hsv.saturation
  let v = hsv.value
  if s < 0.0001: # gray
    return RGBColor(
      red: v,
      green: v,
      blue: v,
    )
  var h = hsv.hue
  if h > 359.99:
    h = 0.0
  h /= 60.0
  let i = int(h)
  let ff = h - float(i)
  var p = v * (1.0 - s)
  var q = v * (1.0 - (s * ff))
  var t = v * (1.0 - (s * (1.0 - ff)))
  var r, g, b: float
  if i == 0:
    r = v
    g = t
    b = p
  elif i == 1:
    r = q
    g = v
    b = p
  elif i == 2:
    r = p
    g = v
    b = t
  elif i == 3:
    r = p
    g = q
    b = v
  elif i == 4:
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
  return RGBColor(
    red: r,
    green: g,
    blue: b,
  )

#func hsvToRgb*(hsv: HSVColor): RGBColor =
  #if hsv.saturation == 0: # gray
    #return rgb(hsv.value, hsv.value, hsv.value)

  #let h = int(hsv.hue)
  #let s = int(hsv.saturation)
  #let v = int(hsv.value)

  #let region = h div 43
  #let remainder = (h - (region * 43)) * 6; 
  #let p = (v * (255 - s)) shr 8
  #let q = (v * (255 - ((s * remainder) shr 8))) shr 8
  #let t = (v * (255 - ((s * (255 - remainder)) shr 8))) shr 8;
  #var r, g, b: int
  #if region == 0:
    #r = v
    #g = t
    #b = p
  #elif region == 1:
    #r = q
    #g = v
    #b = p
  #elif region == 2:
    #r = p
    #g = v
    #b = t
  #elif region == 3:
    #r = p
    #g = q
    #b = v
  #elif region == 4:
    #r = t
    #g = p
    #b = v
  #else:
    #r = v
    #g = p
    #b = q

  #return rgb(uint8(r), uint8(g), uint8(b))

func RGB16asRGB*(rgb16: RGB16Color): RGBColor =
  # RRRRRGGG GGGBBBBB (in order)
  return RGBColor(
    red: float((rgb16 shr 8)   and 0b11111000)/255.0,
    green: float((rgb16 shr 3) and 0b11111100)/255.0,
    blue: float((rgb16 shl 3)  and 0b11111000)/255.0,
  )

proc RGBasRGB16*(rgb: RGBColor): RGB16Color =
  let r = uint16(toInt(rgb.red * 255.0)) shr 3
  let g = uint16(toInt(rgb.green * 255.0)) shr 2
  let b = uint16(toInt(rgb.blue * 255.0)) shr 3
  return (r shl 11) or (g shl 5) or b

func invertColor*(rgb: RGB16Color): RGB16Color =
  #TODO: LMFAO. LOL.
  return RGBasRGB16(hsvToRgb(invertColor(rgbToHsv(RGB16asRGB(rgb)))))
