import files
import constants
import color
import framebuffer
import sequtils
import gfx/image
import gfx/sprites

type Browser* = object
  index: int
  previews: seq[RGB18Image]

var frameSprite = loadImage(0, 0, 2, "frames.tga")

proc showBrowserSprites*() =
  frameSprite.show()

proc hideBrowserSprites*() =
  frameSprite.hide()

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

proc updatePreviews(br: var Browser, index: int) =
  let images = toSeq(listStorageDir("images"))
  let numPreviews = min(len(images), 5)
  br.previews = newSeq[RGB18Image](numPreviews)
  for i in 0..numPreviews-1:
    let st = openFileStream(images[i])
    let img18 = readTGA(st).img18
    if img18.w == 32 and img18.h == 32:
      br.previews[i] = zoom(img18)
    elif img18.w == 64 and img18.h == 64:
      br.previews[i] = img18
    else:
      raise newException(ValueError, images[i] & ": unsupported image size")

  let palette = br.previews[br.index].palette
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

proc initBrowser*(): Browser =
  result.updatePreviews(0)

proc handleInput*(br: var Browser, pressed: set[ButtonInput], instant: set[InstantInput]) =
  discard

proc draw*(br: Browser, buffer: var framebuffer18) =
  let img = br.previews[br.index]
  const offsetX = 32
  const offsetY = 32
  for y in 0..63:
    for x in 0..63:
      let ssx = offsetX + x
      let ssy = offsetY + y
      buffer[(ssy * SCREEN_WIDTH) + ssx] = img.palette[img.contents[(y * 64) + x]]
