import math
import constants
import color
import framebuffer
import picker
import gfx/sprites
import gfx/image

#type Palette = object
  #colors: array[256, RGB18Color]

#proc `[]`(p: Palette, idx: uint8): RGB18Color = p.colors[idx]

#proc `[]=`(p: var Palette, idx: uint8, c: RGB18Color): void = p.colors[idx] = c

const initialColors: array[256, RGB18Color] = block:
  var colors: array[256, RGB18Color]
  colors[0] = rgb(0.1, 0.1, 0.1)
  colors[1] = rgb(0.5, 0.5, 0.5)
  colors[2] = rgb(0.9, 0.9, 0.9)
  colors[3] = rgb(0.8, 0.3, 0.1) # Warm red
  colors[4] = rgb(0.4, 0.15, 0.05) # Warm red dark
  colors[5] = rgb(0.2, 0.3, 0.8) # Cool blue
  colors[6] = rgb(0.1, 0.15, 0.4) # Cool blue dark
  colors[7] = rgb(0.3, 0.7, 0.3) # Green gray
  colors[8] = rgb(0.15, 0.35, 0.15) # Green gray dark
  colors

const
  valueStep = 1.0/64.0

type UIType = enum
  editorUI, pickerUI

type Editor*[W, H: static int] = object
  cursorX*: int
  cursorY*: int
  cursorColor: uint8
  lastPressed: set[ButtonInput]
  image: RGB18Image
  #contents: array[W * H, uint8]
  #palette: Palette
  currentUI: UIType

proc initEditor*[W, H: static int](): Editor[W, H] =
  #let palette = Palette(
      #colors: initialColors,
    #)
  let image = RGB18Image(w: W, h: H, palette: initialColors, contents: newSeq[uint8](W*H))
  return Editor[W, H](
    cursorColor: 0,
    currentUI: editorUI,
    image: image,
  )

proc `[]`*[W, H: static int](editor: Editor[W, H], x, y: int): uint8 = editor.image.contents[(y * W) + x]
proc `[]=`*[W, H: static int](editor: var Editor[W, H], x, y: int, c: uint8) = editor.image.contents[(y * W) + x] = c

proc loadTGA*[W, H: static int](ed: var Editor[W, H], tga: TGA) =
  if W != tga.w or H != tga.h:
    raise newException(ValueError, "cannot load TGA, wrong dimensions")
  ed.image = tga.img18

proc toTGA*[W, H: static int](ed: Editor[W, H]): TGA =
  return ed.image.tga

proc flood[W, H: static int](editor: var Editor[W, H], x, y: int, newColor: uint8): void =
  let oldColor = editor[x, y]
  if oldColor == newColor:
    return
  var queue: seq[(int, int)] = @[(x, y)]
  while len(queue) != 0:
    let (ix, iy) = queue.pop()
    if editor[ix, iy] == oldColor:
      editor[ix, iy] = newColor
      if ix > 0:
        queue.add((ix-1, iy))
      if ix < W-1:
        queue.add((ix+1, iy))
      if iy > 0:
        queue.add((ix, iy-1))
      if iy < H-1:
        queue.add((ix, iy+1))

proc draw*[W, H: static int](editor: Editor[W, H], buffer: var framebuffer18) =
  if editor.currentUI == pickerUI:
    drawPicker(buffer)
  else:
    const f = SCREEN_HEIGHT div W
    const skipY = SCREEN_WIDTH * f
    var eX = -1
    var eY = -1
    var color: RGB18Color
    let cursorColor = editor.image.palette[editor.cursorColor]
    for i in 0..len(buffer)-1:
      if i mod f == 0:
        eX += 1
        if eX == W:
          eX = 0
        if i mod skipY == 0:
          eY += 1
        color = if eX == editor.cursorX and eY == editor.cursorY:
            cursorColor
          else:
            editor.image.palette[editor[eX, eY]]
      buffer[i] = color
    let inverted = hsvToRgb(invertColor(rgbToHsv(cursorColor)))
    buffer[editor.cursorX * f, editor.cursorY * f] = inverted

proc moveCursor[W, H](e: var Editor[W, H], x, y: int): void =
  e.cursorX = max(0, min(W-1, e.cursorX+x))
  e.cursorY = max(0, min(H-1, e.cursorY+y))

var paletteWheel = loadImage(90, 108, 2, "palette.tga")
let paletteId = paletteWheel.palette
paletteWheel.show()

proc updatePalette(ed: Editor): void =
  paletteWheel.show()
  var turned: array[256, RGB18Color]
  const centerOffset = -12
  for i in 0..255:
    # mod doesn't work as expected with negative numbers?
    let ti = (i + ed.cursorColor.int + centerOffset + 256) mod 256
    turned[i] = ed.image.palette[ti]
  updatePalette(paletteId, turned)

proc hideEditorSprites(): void =
  discard
  paletteWheel.hide()

proc handleInput*[W, H](editor: var Editor[W, H], pressed: set[ButtonInput], instant: set[InstantInput]) =
  var newPressed = pressed
  newPressed.excl(editor.lastPressed)
  editor.lastPressed = pressed
  if E_Y in pressed:
    if editor.currentUI == editorUI:
      hideEditorSprites()
    editor.currentUI = pickerUI
    if E_Y in newPressed:
      initPicker(editor.image.palette[editor.cursorColor])
    else:
      if E_Up in newPressed:
        movePickerCursor(0, +1)
      elif E_Down in newPressed:
        movePickerCursor(0, -1)
      elif E_Left in newPressed:
        movePickerCursor(-1, 0)
      elif E_Right in newPressed:
        movePickerCursor(+1, 0)

    editor.image.palette[editor.cursorColor] = pickerCursorColor()
  else:
    if editor.currentUI == pickerUI:
      closePicker()
    editor.currentUI = editorUI
  case editor.currentUI:
    of editorUI:
      paletteWheel.hide()
      if E_Up in newPressed:
        editor.moveCursor(0, +1)
      elif E_Down in newPressed:
        editor.moveCursor(0, -1)
      elif E_B in pressed:
        if E_X in newPressed: # flood fill, hard to press
          editor.flood(editor.cursorX, editor.cursorY, editor.cursorColor)
        elif E_A in newPressed: # eyedropper
          editor.cursorColor = editor[editor.cursorX, editor.cursorY]
      elif E_X in pressed:
        paletteWheel.show()
        if E_Left in newPressed or E_ScrollUp in instant:
          editor.cursorColor -= 1
          #if editor.cursorColor == 255:
            #editor.cursorColor = editor.palette.size
          editor.updatePalette()
          return
        elif E_Right in newPressed or E_ScrollDown in instant:
          editor.cursorColor += 1
          #if editor.cursorColor > editor.palette.size-1:
            #editor.cursorColor = 0
          editor.updatePalette()
          return
      elif E_Left in newPressed:
        editor.moveCursor(-1, 0)
      elif E_Right in newPressed:
        editor.moveCursor(+1, 0)
          
      elif E_A in pressed:
        editor[editor.cursorX, editor.cursorY] = editor.cursorColor

      if E_ScrollUp in instant:
        if E_Right in pressed or E_Left in pressed:
          editor.moveCursor(+1, 0)
        else:
          editor.moveCursor(0, -1)
      elif E_ScrollDown in instant:
        if E_Right in pressed or E_Left in pressed:
          editor.moveCursor(-1, 0)
        else:
          editor.moveCursor(0, +1)
      if E_ScrollRight in instant:
        editor.moveCursor(+1, 0)
      elif E_ScrollLeft in instant:
        editor.moveCursor(-1, 0)
    of pickerUI:
      if E_ScrollUp in instant:
        if E_Right in pressed or E_Left in pressed:
          movePickerCursor(+2, 0)
        elif E_Up in pressed or E_Down in pressed:
          movePickerCursor(0, -2)
        else:
          changePickerValue(valueStep)
      elif E_ScrollDown in instant:
        if E_Right in pressed or E_Left in pressed:
          movePickerCursor(-2, 0)
        elif E_Up in pressed or E_Down in pressed:
          movePickerCursor(0, +2)
        else:
          changePickerValue(-valueStep)
