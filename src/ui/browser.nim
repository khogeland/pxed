import files
import os
import sequtils
import algorithm
import strutils
import constants
import color
import framebuffer
import gfx/image
import gfx/sprites

#TODO file deletion

type
  Preview* = object
    index: int
    case empty*: bool
      of false:
        path*: string
        img*: RGB18Image
      of true:
        discard
  Browser* = object
    index*: int
    fileList: seq[string]
    previews: seq[Preview]
    lastPressed: set[ButtonInput]

var
  blackFrame, frameSprite, leftMask, rightMask: Sprite

proc loadBrowserSprites*() =
  blackFrame = loadImage(0, 0, 2, "blackframe.tga")
  frameSprite = loadImage(0, 0, 2, "frames.tga")
  #TODO these don't need to be screen sized
  leftMask = loadImage(0, 0, 2, "leftbrowsermask.tga")
  rightMask = loadImage(0, 0, 2, "rightbrowsermask.tga")

proc getSelection*(br: Browser): Preview = br.previews[2]

proc zoom(img18: RGB18Image): RGB18Image =
  result.w = img18.w*2
  result.h = img18.h*2
  result.palette = img18.palette
  result.contents = newSeq[uint8](result.w * result.h)
  for y in 0..img18.h-1:
    let ry = y*2
    for x in 0..img18.w-1:
      let rx = x*2
      let i = (y * img18.w) + x
      let i2 = (ry*result.w) + rx
      result.contents[i2] = img18.contents[i]
      result.contents[i2+1] = img18.contents[i]
    let yi1 = ry * result.w
    let yi2 = yi1 + result.w
    for rx in 0..result.w-1:
      result.contents[yi2 + rx] = result.contents[yi1 + rx]

proc sample(img18: RGB18Image): RGB18Image =
  result.w = img18.w div 2
  result.h = img18.h div 2
  result.palette = img18.palette
  result.contents = newSeq[uint8](result.w * result.h)
  for y in countup(0, img18.h-1, 2):
    let ry = y div 2
    for x in countup(0, img18.w-1, 2):
      let rx = x div 2
      let i = (y * img18.w) + x
      let i2 = (ry*result.w) + rx
      result.contents[i2] = img18.contents[i]

proc loadPreview(path: string): Preview =
  try:
    result.empty = false
    result.path = path
    let img18 = readTGA(path).img18
    if img18.w == 32 and img18.h == 32:
      result.img = zoom(img18)
    elif img18.w == 64 and img18.h == 64:
      result.img = img18
    elif img18.w == 128 and img18.h == 128:
      result.img = sample(img18)
    else:
      raise newException(ValueError, path & ": unsupported image size: " & $img18.w & " * " & $img18.h)
  except:
    echo getCurrentException().msg
    # TODO
    return Preview(empty: true)

proc updatePalette(br: var Browser) =
  let p = br.getSelection()
  if p.empty: return
  let palette = p.img.palette
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
    var name = "empty"
    try:
      if i >= len(br.fileList):
        br.previews[i+2] = Preview(empty: true, index: i)
        continue
      name = br.fileList[i]
      let img18 = readTGA(br.fileList[i]).img18
      if img18.w == 32 and img18.h == 32:
        br.previews[i+2] = Preview(empty: false, index: i, path: br.fileList[i], img: zoom(img18))
      elif img18.w == 64 and img18.h == 64:
        br.previews[i+2] = Preview(empty: false, index: i, path: br.fileList[i], img: img18)
      elif img18.w == 128 and img18.h == 128:
        br.previews[i+2] = Preview(empty: false, index: i, path: br.fileList[i], img: sample(img18))
      else:
        # TODO: gracefully fail, prefilter the file list or show an error icon or something
        raise newException(ValueError, br.fileList[i] & ": unsupported image size: " & $img18.w & " * " & $img18.h)
    except:
      br.previews[i+2] = Preview(empty: true, index: 0)
      let e = getCurrentException()
      echo name & ": " & e.msg

  br.updatePalette()

proc initBrowser*(index: int = -1): Browser =
  result.fileList = newSeq[string]()
  for f in sorted(toSeq(listStorageDir("images"))):
    if f.toLowerAscii.endsWith(".tga"):
      result.fileList.add(f)
  result.fileList.add(resolveResourcePath("/images/newfile32.tga"))
  result.fileList.add(resolveResourcePath("/images/newfile64.tga"))
  result.fileList.add(resolveResourcePath("/images/newfile128.tga"))
  result.initPreviews()
  blackFrame.show()
  frameSprite.show()
  if index >= 0:
    let i = min(len(result.fileList)-1, index)
    result.index = i
    result.shiftPreviews(i)

proc handleInput*(br: var Browser, pressed: set[ButtonInput], instant: set[InstantInput], scrollSpeed = 1): bool =
  var newPressed = pressed
  newPressed.excl(br.lastPressed)
  br.lastPressed = pressed
  let oldIndex = br.index
  if E_Left in newPressed or E_ScrollDown in instant:
    br.index = max(br.index-scrollSpeed, 0)
  elif E_Right in newPressed or E_ScrollUp in instant:
    br.index = min(br.index+scrollSpeed, len(br.fileList)-1)
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
  let leftP = br.previews[1]
  let mainP = br.previews[2]
  let rightP  = br.previews[3]
  const lOffsetX = -46
  const lOffsetY = 26
  const offsetX = 32
  const offsetY = 32
  const rOffsetX = 109
  const rOffsetY = 26
  if leftP.empty:
    leftMask.show()
  if rightP.empty:
    rightMask.show()
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

      if not leftP.empty and not (ssx1 < 0 or ssx1 >= SCREEN_WIDTH or ssy1 < 0 or ssy1 >= SCREEN_HEIGHT):
        buffer[iLeft] = leftP.img.palette[leftP.img.contents[(y * 64) + x]]

      if mainP.empty:
        buffer[iMain] = rgb(0,0,0)
      else:
        buffer[iMain] = mainP.img.palette[mainP.img.contents[(y * 64) + x]]

      if not rightP.empty and not (ssx3 < 0 or ssx3 >= SCREEN_WIDTH or ssy3 < 0 or ssy3 >= SCREEN_HEIGHT):
        buffer[iRight] = rightP.img.palette[rightP.img.contents[(y * 64) + x]]

