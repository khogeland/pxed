
type
  RGBColor* = object
    red*, green*, blue*: float
func rgb*(r, g, b: float): RGBColor = RGBColor(red: r, green: g, blue: b)
