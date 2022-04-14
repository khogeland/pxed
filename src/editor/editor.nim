import math
import constants
import color
import picker

type ButtonInput* = enum
  E_Up
  E_Down
  E_Left
  E_Right
  E_A
  E_B
  E_X
  E_Y
  E_L
  E_R

type InstantInput* = enum
  E_ScrollUp
  E_ScrollDown
  E_ScrollRight
  E_ScrollLeft

type Palette = object
  size: uint8
  colors: array[256, RGB16Color]

proc rgb16(r, g, b: float): uint16 =
  let r5: uint16 = uint16(r * 255) shr 3
  let g6: uint16 = uint16(g * 255) shr 2
  let b5: uint16 = uint16(b * 255) shr 3
  return (r5 shl 11) or (g6 shl 5) or b5

proc `[]`(p: Palette, idx: uint8): uint16 = p.colors[idx]

proc `[]=`(p: var Palette, idx: uint8, c: uint16): void = p.colors[idx] = c

const initialColors: array[256, uint16] = block:
  var colors: array[256, uint16]
  colors[0] = rgb16(0.1, 0.1, 0.1)
  colors[1] = rgb16(0.5, 0.5, 0.5)
  colors[2] = rgb16(0.9, 0.9, 0.9)
  colors[3] = rgb16(0.8, 0.3, 0.1) # Warm red
  colors[4] = rgb16(0.4, 0.15, 0.05) # Warm red dark
  colors[5] = rgb16(0.2, 0.3, 0.8) # Cool blue
  colors[6] = rgb16(0.1, 0.15, 0.4) # Cool blue dark
  colors[7] = rgb16(0.3, 0.7, 0.3) # Green gray
  colors[8] = rgb16(0.15, 0.35, 0.15) # Green gray dark
  colors

const
  initialPaletteSize: uint8 = 9
  # 5-6-5 encoding limits us to 32 shades
  valueStep = 1.0/32.0

type UIType = enum
  editorUI, pickerUI

type Editor[W, H: static int] = object
  cursorX*: int
  cursorY*: int
  cursorColor: uint8
  lastPressed: set[ButtonInput]
  contents: array[W, array[H, uint8]]
  palette: Palette
  currentUI: UIType
  colorPicker: ColorPicker

proc initEditor*[W, H: static int](): Editor[W, H] =
  let palette = Palette(
      colors: initialColors,
      size: initialPaletteSize,
    )
  return Editor[W, H](
    cursorColor: 2,
    palette: palette,
    colorPicker: initPicker(palette[2]),
    currentUI: editorUI,
  )

proc `[]`*(editor: Editor, x, y: int): uint8 = editor.contents[x][y]
proc `[]=`*(editor: var Editor, x, y: int, c: uint8) = editor.contents[x][y] = c

# Editor W H, Factor
proc draw*[W, H: static int](editor: Editor[W, H], buffer: var framebuffer) =
  if editor.currentUI == pickerUI:
    editor.colorPicker.draw(buffer)
    return
  const f = SCREEN_HEIGHT div W
  const tileByteWidth = f * 2
  const skipY = tileByteWidth * W * f
  var eX = -1
  var eY = -1
  let cursorColor = editor.palette[editor.cursorColor]
  var color1: uint8
  var color2: uint8
  #var skip: int
  for i in countup(0, BUFFER_LENGTH-1, 2):
    #if skip > 0:
      #skip -= 1
      #continue
    # only need to look up the color once per editor tile
    if i mod tileByteWidth == 0:
      eX += 1
      if eX == W:
        eX = 0
      if i mod skipY == 0:
        eY += 1
      let color: uint16 = if eX == editor.cursorX and eY == editor.cursorY:
          cursorColor
        else:
          editor.palette[editor[eX, eY]]
      color1 = uint8(color shr 8)
      color2 = uint8(color)
      #if (buffer[i] == color1 and buffer[i+1] == color2):
        #skip = f-1
        #continue

    buffer[i] = color1
    buffer[i+1] = color2

  let x1 = (editor.cursorX * f) - 1
  let y1 = (editor.cursorY * f) - 1
  let x2 = (editor.cursorX * f) + f
  let y2 = (editor.cursorY * f) + f
  let inverted = invertColor(cursorColor)

  for x in x1..x2:
    for y in y1..y2:
      if x < 0 or x > W * f - 1 or y < 0 or y > H * f - 1:
        continue
      if y == y1 or y == y2:
        buffer[x, y] = inverted
      if x == x1 or x == x2:
        buffer[x, y] = inverted
    


proc handleInput*[W, H](editor: var Editor[W, H], pressed: set[ButtonInput], instant: set[InstantInput]) =
  var newPressed = pressed
  newPressed.excl(editor.lastPressed)
  editor.lastPressed = pressed
  if E_Y in pressed:
    editor.currentUI = pickerUI
    if E_Y in newPressed:
      editor.colorPicker = initPicker(editor.palette[editor.cursorColor])
    else:
      if E_Up in pressed:
        editor.colorPicker.moveCursor(UP)
      elif E_Down in pressed:
        editor.colorPicker.moveCursor(DOWN)
      elif E_Left in pressed:
        editor.colorPicker.moveCursor(LEFT)
      elif E_Right in pressed:
        editor.colorPicker.moveCursor(RIGHT)

    editor.palette[editor.cursorColor] = editor.colorPicker.cursorColor()
  else:
    editor.currentUI = editorUI
  case editor.currentUI:
    of editorUI:
      if E_Up in newPressed:
        editor.cursorY = min(editor.cursorY + 1, editor.H - 1)
      elif E_Down in newPressed:
        editor.cursorY = max(editor.cursorY - 1, 0)
      if E_Right in newPressed:
        if E_X in pressed:
          editor.cursorColor += 1
          if editor.cursorColor > editor.palette.size-1:
            editor.cursorColor = 0
        else:
          editor.cursorX = min(editor.cursorX + 1, editor.W - 1)
      elif E_Left in newPressed:
        if E_X in pressed:
          editor.cursorColor -= 1
          if editor.cursorColor == 255:
            editor.cursorColor = editor.palette.size
        else:
          editor.cursorX = max(editor.cursorX - 1, 0)

      if E_A in pressed:
        editor[editor.cursorX, editor.cursorY] = editor.cursorColor

      if E_ScrollUp in instant:
        editor.cursorY = min(editor.cursorY + 1, editor.H - 1)
      elif E_ScrollDown in instant:
        editor.cursorY = max(editor.cursorY - 1, 0)
      if E_ScrollRight in instant:
        editor.cursorX = min(editor.cursorX + 1, editor.W - 1)
      elif E_ScrollLeft in instant:
        editor.cursorX = max(editor.cursorX - 1, 0)
    of pickerUI:
      if E_ScrollUp in instant:
        # TODO: 
        editor.colorPicker.changeValue(0.05)
      elif E_ScrollDown in instant:
        editor.colorPicker.changeValue(-0.05)
      if E_ScrollRight in instant:
        editor.cursorX = min(editor.cursorX + 1, editor.W - 1)
      elif E_ScrollLeft in instant:
        editor.cursorX = max(editor.cursorX - 1, 0)
