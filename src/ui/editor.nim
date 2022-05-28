import os
import constants
import color
import framebuffer
import picker
import gfx/sprites
import gfx/image

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

type Editor* = object
  w*, h*: int
  cursorX*: int
  cursorY*: int
  cursorColor: uint8
  lastPressed: set[ButtonInput]
  image: RGB18Image
  #contents: array[W * H, uint8]
  #palette: Palette
  currentUI: UIType
  path: string

var paletteWheel = loadImage(90, 108, 2, "palette.tga")
let paletteId = paletteWheel.palette

proc setImage*(ed: var Editor, img: RGB18Image) =
  ed.w = img.w
  ed.h = img.h
  ed.image = img

proc loadTGA*(ed: var Editor, path: string) =
  let tga = readTGA(path)
  ed.path = path
  ed.setImage(tga.img18)

proc updatePalette(ed: Editor): void =
  var turned: array[256, RGB18Color]
  const centerOffset = -12
  for i in 0..255:
    # mod doesn't work as expected with negative numbers?
    let ti = (i + ed.cursorColor.int + centerOffset + 256) mod 256
    turned[i] = ed.image.palette[ti]
  updatePalette(paletteId, turned)

proc initEditor*(path: string): Editor =
  result = Editor(
    cursorColor: 0,
    currentUI: editorUI,
  )
  if fileExists(path):
    result.loadTGA(path)
  else:
    result.w = 32
    result.h = 32
    result.image = RGB18Image(w: 32, h: 32, palette: initialColors, contents: newSeq[uint8](32*32))
  result.updatePalette()

proc saveImage*(ed: Editor) =
  writeTGA(ed.path, ed.image.tga)

proc `[]`*(ed: Editor, x, y: int): uint8 = ed.image.contents[(y * ed.w) + x]
proc `[]=`*(ed: var Editor, x, y: int, c: uint8) = ed.image.contents[(y * ed.w) + x] = c

proc toTGA*(ed: Editor): TGA =
  return ed.image.tga

proc flood(ed: var Editor, x, y: int, newColor: uint8): void =
  let oldColor = ed[x, y]
  if oldColor == newColor:
    return
  var queue: seq[(int, int)] = @[(x, y)]
  while len(queue) != 0:
    let (ix, iy) = queue.pop()
    if ed[ix, iy] == oldColor:
      ed[ix, iy] = newColor
      if ix > 0:
        queue.add((ix-1, iy))
      if ix < ed.w-1:
        queue.add((ix+1, iy))
      if iy > 0:
        queue.add((ix, iy-1))
      if iy < ed.h-1:
        queue.add((ix, iy+1))

proc draw*(ed: Editor, buffer: var framebuffer18) =
  if ed.currentUI == pickerUI:
    drawPicker(buffer)
  else:
    let f = SCREEN_HEIGHT div ed.w
    let skipY = SCREEN_WIDTH * f
    var eX = -1
    var eY = -1
    var color: RGB18Color
    let cursorColor = ed.image.palette[ed.cursorColor]
    for i in 0..len(buffer)-1:
      if i mod f == 0:
        eX += 1
        if eX == ed.w:
          eX = 0
        if i mod skipY == 0:
          eY += 1
        color = if eX == ed.cursorX and eY == ed.cursorY:
            cursorColor
          else:
            ed.image.palette[ed[eX, eY]]
      buffer[i] = color
    let inverted = hsvToRgb(invertColor(rgbToHsv(cursorColor)))
    buffer[ed.cursorX * f, ed.cursorY * f] = inverted

proc moveCursor(ed: var Editor, x, y: int): void =
  ed.cursorX = max(0, min(ed.w-1, ed.cursorX+x))
  ed.cursorY = max(0, min(ed.h-1, ed.cursorY+y))

proc hideEditorSprites(): void =
  paletteWheel.hide()

proc handleInput*(ed: var Editor, pressed: set[ButtonInput], instant: set[InstantInput]): bool =
  var newPressed = pressed
  newPressed.excl(ed.lastPressed)
  ed.lastPressed = pressed
  # TODO: hack around my laptop's arrow key rollover limitation so I can make this require all 4
  if E_Left in pressed and E_Right in pressed:
    hideEditorSprites()
    return true
  if E_Y in pressed:
    if ed.currentUI == editorUI:
      hideEditorSprites()
    ed.currentUI = pickerUI
    if E_Y in newPressed:
      initPicker(ed.image.palette[ed.cursorColor])
    else:
      if E_Up in newPressed:
        movePickerCursor(0, +1)
      elif E_Down in newPressed:
        movePickerCursor(0, -1)
      elif E_Left in newPressed:
        movePickerCursor(-1, 0)
      elif E_Right in newPressed:
        movePickerCursor(+1, 0)

    ed.image.palette[ed.cursorColor] = pickerCursorColor()
  else:
    if ed.currentUI == pickerUI:
      closePicker()
    ed.currentUI = editorUI
  case ed.currentUI:
    of editorUI:
      paletteWheel.hide()
      if E_Up in newPressed:
        ed.moveCursor(0, +1)
      elif E_Down in newPressed:
        ed.moveCursor(0, -1)
      elif E_B in pressed:
        if E_X in newPressed: # flood fill, hard to press
          ed.flood(ed.cursorX, ed.cursorY, ed.cursorColor)
        elif E_A in newPressed: # eyedropper
          ed.cursorColor = ed[ed.cursorX, ed.cursorY]
      elif E_X in pressed:
        paletteWheel.show()
        if E_Left in newPressed or E_ScrollUp in instant:
          ed.cursorColor -= 1
          ed.updatePalette()
          return
        elif E_Right in newPressed or E_ScrollDown in instant:
          ed.cursorColor += 1
          ed.updatePalette()
          return
      elif E_Left in newPressed:
        ed.moveCursor(-1, 0)
      elif E_Right in newPressed:
        ed.moveCursor(+1, 0)
          
      elif E_A in pressed:
        ed[ed.cursorX, ed.cursorY] = ed.cursorColor

      if E_ScrollUp in instant:
        if E_Right in pressed or E_Left in pressed:
          ed.moveCursor(+1, 0)
        else:
          ed.moveCursor(0, -1)
      elif E_ScrollDown in instant:
        if E_Right in pressed or E_Left in pressed:
          ed.moveCursor(-1, 0)
        else:
          ed.moveCursor(0, +1)
      if E_ScrollRight in instant:
        ed.moveCursor(+1, 0)
      elif E_ScrollLeft in instant:
        ed.moveCursor(-1, 0)
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
      ed.updatePalette()
  return false
