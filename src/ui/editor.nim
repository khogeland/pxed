import times
import constants
import color
import framebuffer
import picker
import gfx/sprites
import gfx/image

let initialColors: array[256, RGB18Color] = block:
  var colors: array[256, RGB18Color]
  colors[0] = rgb(0.1, 0.1, 0.1)
  colors[1] = rgb(0.8, 0.8, 0.8)
  colors

const
  valueStep = 1.0/64.0
  # TODO: different max zooms for different image sizes
  zoomLevels = [1, 2, 4]

type UIType = enum
  editorUI, pickerUI

type Editor* = object
  w*, h*: int
  cursorX*: int
  cursorY*: int
  cursorColor: uint8
  lastPressed: set[ButtonInput]
  image: RGB18Image
  currentUI: UIType
  path*: string
  saveWaiting: bool
  saveTime: float
  colorSwapping: bool
  colorSwap: uint8
  zoom: int
  zoomX, zoomY: int

const saveDelay = 1.0
var paletteBack: Sprite
var paletteBacks: seq[Sprite]
var paletteWheel: Sprite
var paletteId: int

proc loadEditorSprites*() =
  loadPickerSprites()
  paletteBack = loadImage(86, 104, 2, "paletteback.tga")
  paletteBacks = @[
    loadImage(86, 104, 2, "paletteback1.tga"),
    loadImage(86, 104, 2, "paletteback2.tga"),
    loadImage(86, 104, 2, "paletteback3.tga"),
    loadImage(86, 104, 2, "paletteback4.tga"),
  ]
  paletteWheel = loadImage(90, 108, 2, "palette.tga")
  paletteId = paletteWheel.palette

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

proc setup(ed: var Editor) =
  ed.updatePalette()
  ed.cursorX = ed.w div 2
  ed.cursorY = ed.h div 2

proc initEditor*(path: string): Editor =
  result = Editor(
    cursorColor: 1,
    currentUI: editorUI,
  )
  result.loadTGA(path)
  result.setup()

proc initEditorNewFile*(path: string, w, h: int): Editor =
  result = Editor(
    cursorColor: 1,
    currentUI: editorUI,
    w: w, h: h,
    path: path,
    saveWaiting: false,
    image: RGB18Image(w: w, h: h, palette: initialColors, contents: newSeq[uint8](w*h))
  )
  result.setup()

proc saveImage*(ed: Editor) =
  if ed.saveWaiting:
    writeTGA(ed.path, ed.image.tga)

proc deferSave(ed: var Editor) =
  ed.saveWaiting = true
  ed.saveTime = cpuTime() + saveDelay

proc maybeSave*(ed: var Editor) =
  if ed.saveWaiting and cpuTime() > ed.saveTime:
    ed.saveWaiting = false
    ed.saveImage()

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
    let f = (SCREEN_HEIGHT div ed.w) * zoomLevels[ed.zoom]
    let skipY = SCREEN_WIDTH * f
    var eX = ed.zoomX-1
    var eY = ed.zoomY-1
    var color: RGB18Color
    let cursorColor = ed.image.palette[ed.cursorColor]
    # the compiler fares better with iterating through the buffer
    # at the top level rather than the image, so this inside-out
    # approach is much faster than the intuitive implementation.
    #
    # we iterate through the buffer in order and update the color on
    # the index of every pixel boundary.
    for i in 0..len(buffer)-1:
      if i mod f == 0:
        eX += 1
        if eX == ed.zoomX + (ed.w div zoomLevels[ed.zoom]):
          eX = ed.zoomX
        if i mod skipY == 0:
          eY += 1
        color = if eX == ed.cursorX and eY == ed.cursorY:
            cursorColor
          else:
            ed.image.palette[ed[eX, eY]]
      if i > len(buffer)-1:
        break
      buffer[i] = color
    let inverted = hsvToRgb(invertColor(rgbToHsv(cursorColor)))
    buffer[(ed.cursorX-ed.zoomX) * f, (ed.cursorY-ed.zoomY) * f] = inverted
    if ed.colorSwapping:
      for y in 123..127:
        for x in 101..109:
          buffer[x, y] = ed.image.palette[ed.colorSwap]

proc moveCursor(ed: var Editor, x, y: int) =
  ed.cursorX = max(ed.zoomX, min(ed.zoomX+(ed.w div zoomLevels[ed.zoom])-1, ed.cursorX+x))
  ed.cursorY = max(ed.zoomY, min(ed.zoomY+(ed.h div zoomLevels[ed.zoom])-1, ed.cursorY+y))

proc moveZoom(ed: var Editor, x, y: int) =
  ed.zoomX = max(0, min(ed.w-(ed.w div zoomLevels[ed.zoom]), ed.zoomX+x))
  ed.zoomY = max(0, min(ed.h-(ed.h div zoomLevels[ed.zoom]), ed.zoomY+y))

proc changeZoom(ed: var Editor, pos: bool) =
  let idx = if pos: min(len(zoomLevels)-1, ed.zoom+1) else: max(0, ed.zoom-1)
  let zX = (ed.cursorX - (ed.w div zoomLevels[idx]) div 2) - ed.zoomX
  let zY = (ed.cursorY - (ed.h div zoomLevels[idx]) div 2) - ed.zoomY
  ed.zoom = idx
  ed.moveZoom(zX, zY)
  ed.moveCursor(0, 0)

proc hideEditorSprites(): void =
  paletteBack.hide()
  for i in 0..len(paletteBacks)-1:
    paletteBacks[i].hide()
  paletteWheel.hide()

proc handleInput*(ed: var Editor, pressed: set[ButtonInput], instant: set[InstantInput], scrollSpeed = 1): bool =
  hideEditorSprites()
  var newPressed = pressed
  newPressed.excl(ed.lastPressed)
  ed.lastPressed = pressed
  # TODO: hack around my laptop's arrow key rollover limitation so I can make this require all 4
  if E_Left in pressed and E_Right in pressed:
    hideEditorSprites()
    return true
  if E_X in pressed and E_Y in pressed:
      ed.currentUI = pickerUI
      if E_Y in newPressed or E_X in newPressed:
        initPicker(ed.image.palette[ed.cursorColor])
  else:
    if ed.currentUI == pickerUI:
      closePicker()
    ed.currentUI = editorUI
  case ed.currentUI:
    of editorUI:
      if E_X in newPressed and E_B in pressed:
        ed.flood(ed.cursorX, ed.cursorY, ed.cursorColor)
        ed.deferSave()
      if not(E_X in pressed):
        ed.colorSwapping = false
      if E_X in pressed and not(E_B in pressed):
        paletteWheel.show()
        paletteBacks[ed.cursorColor mod 4].show()
        if E_Left in newPressed or E_ScrollDown in instant:
          ed.cursorColor -= scrollSpeed.uint8
          ed.updatePalette()
          return
        elif E_Right in newPressed or E_ScrollUp in instant:
          ed.cursorColor += scrollSpeed.uint8
          ed.updatePalette()
          return
        elif E_Up in newPressed:
          ed.colorSwapping = true
          ed.colorSwap = ed.cursorColor
        elif E_Down in newPressed and ed.colorSwapping:
          let a = ed.image.palette[ed.colorSwap]
          ed.image.palette[ed.colorSwap] = ed.image.palette[ed.cursorColor]
          ed.image.palette[ed.cursorColor] = a
          for i in 0..len(ed.image.contents)-1:
            if ed.image.contents[i] == ed.colorSwap:
              ed.image.contents[i] = ed.cursorColor
            elif ed.image.contents[i] == ed.cursorColor:
              ed.image.contents[i] = ed.colorSwap
          ed.colorSwapping = false
          ed.updatePalette()
        elif E_A in newPressed:
          ed.image.palette[ed.cursorColor] = ed.image.palette[ed[ed.cursorX, ed.cursorY]] # eyedropper to palette
          ed.updatePalette()
          ed.deferSave()
      elif E_Y in pressed:
        if E_Up in pressed:
          if E_Up in newPressed or E_ScrollUp in instant:
            ed.moveZoom(0, scrollSpeed)
            ed.moveCursor(0, scrollSpeed)
          elif E_ScrollDown in instant:
            ed.moveZoom(0, -scrollSpeed)
            ed.moveCursor(0, -scrollSpeed)
        elif E_Down in pressed:
          if E_Down in newPressed or E_ScrollDown in instant:
            ed.moveZoom(0, -scrollSpeed)
            ed.moveCursor(0, -scrollSpeed)
          elif E_ScrollUp in instant:
            ed.moveZoom(0, scrollSpeed)
            ed.moveCursor(0, scrollSpeed)
        elif E_Left in pressed:
          if E_Left in newPressed or E_ScrollUp in instant:
            ed.moveZoom(-scrollSpeed, 0)
            ed.moveCursor(-scrollSpeed, 0)
          elif E_ScrollUp in instant:
            ed.moveZoom(scrollSpeed, 0)
            ed.moveCursor(scrollSpeed, 0)
        elif E_Right in pressed:
          if E_Right in newpressed or E_ScrollDown in instant:
            ed.moveZoom(scrollSpeed, 0)
            ed.moveCursor(scrollSpeed, 0)
          elif E_ScrollUp in instant:
            ed.moveZoom(-scrollSpeed, 0)
            ed.moveCursor(-scrollSpeed, 0)
        elif E_ScrollUp in instant:
          ed.changeZoom(true)
        elif E_ScrollDown in instant:
          ed.changeZoom(false)
      elif E_Up in newPressed:
        ed.moveCursor(0, +1)
      elif E_Down in newPressed:
        ed.moveCursor(0, -1)
      elif E_B in pressed:
        if E_A in newPressed: # eyedropper
          ed.cursorColor = ed[ed.cursorX, ed.cursorY]
          ed.updatePalette()
      elif E_Left in newPressed:
        ed.moveCursor(-1, 0)
        if E_A in pressed:
          ed[ed.cursorX, ed.cursorY] = ed.cursorColor
          ed.deferSave()
      elif E_Right in newPressed:
        ed.moveCursor(+1, 0)
        if E_A in pressed:
          ed[ed.cursorX, ed.cursorY] = ed.cursorColor
          ed.deferSave()
      elif E_ScrollUp in instant:
        if E_Right in pressed or E_Left in pressed:
          ed.moveCursor(+scrollSpeed, 0)
        else:
          ed.moveCursor(0, -scrollSpeed)
        if E_A in pressed:
          ed[ed.cursorX, ed.cursorY] = ed.cursorColor
          ed.deferSave()
      elif E_ScrollDown in instant:
        if E_Right in pressed or E_Left in pressed:
          ed.moveCursor(-scrollSpeed, 0)
        else:
          ed.moveCursor(0, +scrollSpeed)
        if E_A in pressed:
          ed[ed.cursorX, ed.cursorY] = ed.cursorColor
          ed.deferSave()
      elif E_ScrollRight in instant:
        ed.moveCursor(+scrollSpeed, 0)
        if E_A in pressed:
          ed[ed.cursorX, ed.cursorY] = ed.cursorColor
          ed.deferSave()
      elif E_ScrollLeft in instant:
        ed.moveCursor(-scrollSpeed, 0)
        if E_A in pressed:
          ed[ed.cursorX, ed.cursorY] = ed.cursorColor
          ed.deferSave()
      elif E_A in pressed:
        ed[ed.cursorX, ed.cursorY] = ed.cursorColor
        ed.deferSave()
    of pickerUI:
      if E_Up in newPressed:
        movePickerCursor(0, +1)
        ed.deferSave() # TODO dedupe
      elif E_Down in newPressed:
        movePickerCursor(0, -1)
        ed.deferSave()
      elif E_Left in newPressed:
        movePickerCursor(-1, 0)
        ed.deferSave()
      elif E_Right in newPressed:
        movePickerCursor(+1, 0)
        ed.deferSave()
      if E_ScrollUp in instant:
        if E_Right in pressed or E_Left in pressed:
          movePickerCursor(+scrollSpeed, 0)
          ed.deferSave()
        elif E_Up in pressed or E_Down in pressed:
          movePickerCursor(0, -scrollSpeed)
          ed.deferSave()
        else:
          changePickerValue(valueStep)
          ed.deferSave()
      elif E_ScrollDown in instant:
        if E_Right in pressed or E_Left in pressed:
          movePickerCursor(-scrollSpeed, 0)
          ed.deferSave()
        elif E_Up in pressed or E_Down in pressed:
          movePickerCursor(0, +scrollSpeed)
          ed.deferSave()
        else:
          changePickerValue(-valueStep)
          ed.deferSave()
      ed.image.palette[ed.cursorColor] = pickerCursorColor()
      ed.updatePalette()
  return false
