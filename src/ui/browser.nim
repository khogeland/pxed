import files
import constants
import color
import framebuffer
import sequtils
import gfx/image
import gfx/sprites

type
  Preview* = object
    index: int
    case empty: bool
      of false:
        path*: string
        img*: RGB18Image
      of true:
        discard
  Browser* = object
    index: int
    fileList: seq[string]
    previews: seq[Preview]
    lastPressed: set[ButtonInput]

var frameSprite = loadImage(0, 0, 2, "frames.tga")
var blackFrame = loadImage(0, 0, 2, "blackframe.tga")
#TODO these don't need to be screen sized
var leftMask = loadImage(0, 0, 2, "leftbrowsermask.tga")
var rightMask = loadImage(0, 0, 2, "rightbrowsermask.tga")

proc getSelection*(br: Browser): Preview = br.previews[2]

proc zoom(img18: RGB18Image): RGB18Image =
  result.w = img18.w*2
  result.h = img18.h*2
  result.palette = img18.palette
  result.contents = newSeq[uint8](result.w * result.h)
  let rw = img18.w * 2
  for y in 0..img18.h-1:
    let ry = y*2
    for x in 0..img18.w-1:
      let rx = x*2
      let i = (y * img18.w) + x
      let i2 = (ry*rw) + rx
      result.contents[i2] = img18.contents[i]
      result.contents[i2+1] = img18.contents[i]
    let yi1 = ry * rw
    let yi2 = yi1 + rw
    for rx in 0..rw-1:
      result.contents[yi2 + rx] = result.contents[yi1 + rx]
      #result.contents[yi2 + rx] = 5

proc loadPreview(path: string): Preview =
  result.empty = false
  result.path = path
  let img18 = readTGA(path).img18
  if img18.w == 32 and img18.h == 32:
    result.img = zoom(img18)
  elif img18.w == 64 and img18.h == 64:
    result.img = img18
  else:
    raise newException(ValueError, path & ": unsupported image size")

proc updatePalette(br: var Browser) =
  let palette = br.getSelection().img.palette
  const rgb0 = rgb(0, 0, 0)
  var colors: seq[RGB18Color]
  for c in palette:
    if c != rgb0:
      colors.add(c)
  var palette2: array[256, RGB18Color]
  for i in 1..255:
    let ci = i mod len(colors)
    palette2[i] = colors[ci]
  updatePalette(frameSprite.palette, palette2)
  #let shift = br.index - index


proc shiftPreviews(br: var Browser, shift: int) =
  if shift < 0:
    for _ in 1..abs(shift):
      let index = br.previews[0].index-1
      var p = Preview(empty: true)
      if index >= 0:
        p = loadPreview(br.fileList[index])
      p.index = index
      br.previews.insert(p, 0)
      br.previews.delete(len(br.previews)-1)
    br.updatePalette()
  elif shift > 0:
    for _ in 1..shift:
      let index = br.previews[^1].index+1
      var p = Preview(empty: true)
      if index < len(br.fileList):
        p = loadPreview(br.fileList[index])
      p.index = index
      br.previews.delete(0)
      br.previews.add(p)
    br.updatePalette()

proc initPreviews(br: var Browser) =
  br.previews = newSeq[Preview](5)
  br.previews[0] = Preview(empty: true, index: -2)
  br.previews[1] = Preview(empty: true, index: -1)
  for i in 0..2:
    if i >= len(br.fileList):
      br.previews[i] = Preview(empty: true, index: i)
      continue
    let img18 = readTGA(br.fileList[i]).img18
    if img18.w == 32 and img18.h == 32:
      br.previews[i+2] = Preview(empty: false, index: i, path: br.fileList[i], img: zoom(img18))
    elif img18.w == 64 and img18.h == 64:
      br.previews[i+2] = Preview(empty: false, index: i, path: br.fileList[i], img: img18)
    else:
      raise newException(ValueError, br.fileList[i] & ": unsupported image size")
  br.updatePalette()

proc initBrowser*(): Browser =
  result.fileList = toSeq(listStorageDir("images"))
  result.initPreviews()
  frameSprite.show()
  blackFrame.show()

proc handleInput*(br: var Browser, pressed: set[ButtonInput], instant: set[InstantInput]): bool =
  var newPressed = pressed
  newPressed.excl(br.lastPressed)
  br.lastPressed = pressed
  let oldIndex = br.index
  if E_Left in newPressed or E_ScrollDown in instant:
    br.index = max(br.index-1, 0)
  elif E_Right in newPressed or E_ScrollUp in instant:
    br.index = min(br.index+1, len(br.fileList)-1)
  elif E_A in pressed:
    leftMask.hide()
    rightMask.hide()
    frameSprite.hide()
    blackFrame.hide()
    return true
  br.shiftPreviews(br.index - oldIndex)
  return false

proc draw*(br: Browser, buffer: var framebuffer18) =
  leftMask.hide()
  rightMask.hide()
  let left = br.previews[1]
  let main = br.previews[2]
  let right = br.previews[3]
  const lOffsetX = -46
  const lOffsetY = 26
  const offsetX = 32
  const offsetY = 32
  const rOffsetX = 109
  const rOffsetY = 26
  for y in 0..63:
    for x in 0..63:
      let ssx1 = lOffsetX + x
      let ssy1 = lOffsetY + y
      let ssx2 = offsetX + x
      let ssy2 = offsetY + y
      let ssx3 = rOffsetX + x
      let ssy3 = rOffsetY + y
      
      let iLeft = (ssy1 * SCREEN_WIDTH) + ssx1
      let iMain = (ssy2 * SCREEN_WIDTH) + ssx2
      let iRight = (ssy3 * SCREEN_WIDTH) + ssx3

      if not (ssx1 < 0 or ssx1 >= SCREEN_WIDTH or ssy1 < 0 or ssy1 >= SCREEN_HEIGHT):
        if left.empty:
          leftMask.show()
          buffer[iLeft] = main.img.palette[2]
        else:
          buffer[iLeft] = left.img.palette[left.img.contents[(y * 64) + x]]

      if main.empty:
        buffer[iMain] = rgb(0,0,0)
      else:
        buffer[iMain] = main.img.palette[main.img.contents[(y * 64) + x]]

      if not (ssx3 < 0 or ssx3 >= SCREEN_WIDTH or ssy3 < 0 or ssy3 >= SCREEN_HEIGHT):
        if right.empty:
          rightMask.show()
          buffer[iRight] = main.img.palette[2]
        else:
          buffer[iRight] = right.img.palette[right.img.contents[(y * 64) + x]]

