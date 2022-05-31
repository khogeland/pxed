import color
import streams

# TODO run-length encoding
type
  TGAPalette = object
    case alpha: bool
    of true:
      palette32: array[256, BGRA32Color]
    of false:
      palette24: array[256, BGR24Color]
  TGA* = object
    palette*: TGAPalette
    data*: seq[uint8]
    w*, h*: uint16
    topOrigin: bool
    rle: bool
  TGAHeader {.packed.} = object
    idLen: uint8
    colorMapType: uint8
    imageType: uint8
    mapIdx: uint16
    mapLen: uint16
    mapEntryBits: uint8
    xOrigin: uint16
    yOrigin: uint16
    w: uint16
    h: uint16
    bpp: uint8
    descriptor: uint8
  RGB18Image* = object
    w*, h*: int
    contents*: seq[uint8]
    palette*: array[256, RGB18Color]

func valErr*(msg: string): void =
  raise newException(ValueError, msg)

const bgrBlack = rgb(0,0,0).bgr
const bgraBlack = BGRA32Color(r: 0, g: 0, b: 0, a: 0)

proc compress(tga: TGA): TGA =
  if tga.rle: return tga
  if unlikely(tga.topOrigin):
    valErr("wrong scanline order")
  var firstBlack = 0'u8
  if unlikely(tga.palette.alpha):
    for i in 0'u8..len(tga.palette.palette32)-1:
      if tga.palette.palette32[i] == bgraBlack:
        firstBlack = i
        break
  else:
    for i in 0'u8..len(tga.palette.palette24)-1:
      if tga.palette.palette24[i] == bgrBlack:
        firstBlack = i
        break
  result = tga
  result.rle = true
  result.data = newSeq[uint8]()
  var offset = 0'u16
  for y in 0'u16..tga.h-1:
    var prev = tga.data[y*tga.w]
    # this is *technically* lossy (to your palette), but it allows me to safely save several hundred bytes
    # by truncating unused palette slots, so... whatever!
    if tga.palette.alpha:
      if tga.palette.palette32[prev] == bgraBlack:
        prev = firstBlack
    elif tga.palette.palette24[prev] == bgrBlack:
      prev = firstBlack
    var running = false
    result.data.add(0)
    offset = len(result.data).uint16-1
    result.data.add(prev)
    for x in 1'u64..tga.w-1:
      var current = tga.data[(y * tga.w) + x]
      if tga.palette.alpha:
        if tga.palette.palette32[current] == bgraBlack:
          current = firstBlack
      elif tga.palette.palette24[current] == bgrBlack:
        current = firstBlack
      if not running:
        if current == prev: # oops, we are running
          running = true
          if result.data[offset] == 0: # raw packet is only 1 pixel, replace
            result.data[offset] = 129
            result.data[^1] = current
          else: # raw packet contains other pixels, reduce and add new rle packet
            result.data[offset] -= 1
            result.data[^1] = 129 #replace previous pixel value with the rle packet
            offset = len(result.data).uint16-1
            result.data.add(current)
        else:
          result.data[offset] += 1
          result.data.add(current)
      else:
        if current == prev:
          result.data[offset] += 1
        else:
          running = false
          result.data.add(0)
          offset = len(result.data).uint16-1
          result.data.add(current)
      prev = current

proc decompress(tga: TGA): TGA =
  if not tga.rle: return tga
  result = tga
  result.rle = false
  result.data = newSeq[uint8]()
  var i = 0
  while i < len(tga.data)-1:
    let b = tga.data[i]
    let length = (b and 127)
    if tga.data[i] >= 128: # rle
      i += 1
      let v = tga.data[i]
      for _ in 0'u8..length:
        result.data.add(v)
    else:
      for _ in 0'u8..length:
        i += 1
        result.data.add(tga.data[i])
    i += 1

# ensures all images originate from bottom left
iterator iterDataIdx*(tga: TGA): (int, int) =
  if tga.topOrigin:
    for i in 0..len(tga.data)-1:
      let tx = i mod tga.w.int
      let ty = (i - tx) div tga.w.int
      let sy = (tga.h.int-1)-ty
      yield (i, (sy * tga.w.int) + tx)
  else:
    for i in 0..len(tga.data)-1:
      yield (i, i)

proc tga*(img18: RGB18Image): TGA =
  result.w = img18.w.uint16
  result.h = img18.h.uint16
  result.palette.alpha = false
  #result.palette.palette24 = newSeq[BGR24Color](256)
  result.data = newSeq[uint8](img18.w * img18.h)
  for i in 0..len(img18.palette)-1:
    result.palette.palette24[i] = img18.palette[i].bgr
  for i in 0..(img18.w * img18.h)-1:
    result.data[i] = img18.contents[i]

proc img18*(tga: TGA): RGB18Image =
  result.w = tga.w.int
  result.h = tga.h.int
  result.contents = newSeq[uint8](result.w * result.h)
  if tga.palette.alpha:
    for i in 0..len(tga.palette.palette32)-1:
      result.palette[i] = tga.palette.palette32[i].rgb
  else:
    for i in 0..len(tga.palette.palette24)-1:
      result.palette[i] = tga.palette.palette24[i].rgb
  for i1, i2 in tga.iterDataIdx():
    result.contents[i1] = tga.data[i2]

const black = rgb(0,0,0).bgr

proc writeTGA*(st: FileStream, tga: TGA): void =
  let tga = compress(tga)
  var mapTrailingZero = 0'u16
  var palette: seq[BGR24Color]
  if tga.palette.alpha:
    for color in tga.palette.palette32:
      let color24 = color.bgr
      if color24 == black:
        mapTrailingZero += 1
      else:
        mapTrailingZero = 0
      palette.add(color24)
  else:
    for color in tga.palette.palette24:
      if color == black:
        mapTrailingZero += 1
      else:
        mapTrailingZero = 0
      palette.add(color)
  let header = TGAHeader(
    idLen: 0,
    colorMapType: 1,
    imageType: 9,
    mapIdx: 0,
    mapLen: 256-mapTrailingZero,
    mapEntryBits: 24,
    xOrigin: 0,
    yOrigin: 0,
    w: tga.w,
    h: tga.h,
    bpp: 8,
    descriptor: 0, # always write with bottom origin
  )
  st.write(header)
  for i in 0..header.mapLen.uint64-1:
    st.write(palette[i])
  if tga.topOrigin: # we gotta flip it!!!!
    for i in 0..len(tga.data)-1:
      let tx = i mod tga.w.int
      let ty = (i - tx) div tga.w.int
      let sy = (tga.h.int-1)-ty
      st.write(tga.data[(sy * tga.w.int) + tx])
  else:
    for pixel in tga.data:
      st.write(pixel)

proc writeTGA*(path: string, tga: TGA): void =
  let st = newFileStream(path, fmWrite)
  defer:
    st.close()
  writeTGA(st, tga)

proc readTGA*(st: FileStream): TGA =
  var header: TGAHeader
  st.read(header)
  if unlikely(header.colorMapType != 1):
    valErr("incorrect color map type: " & $header.colorMapType)
  if unlikely(header.imageType != 1 and header.imageType != 9):
    valErr("image should be indexed")
  if unlikely(header.mapEntryBits != 32 and header.mapEntryBits != 24):
    valErr("unsupported color format")
  if unlikely(header.mapLen > 256):
    valErr("color map too large")
  if unlikely(header.bpp != 8):
    valErr("expected 8 bits per pixel")
  # rest of the fields i'm just going to ignore....
  result.w = header.w
  result.h = header.h
  result.rle = header.imageType == 9
  result.topOrigin = (header.descriptor and 0b00100000) != 0
  if header.idLen != 0:
    for _ in 1'u8..header.idLen:
      discard st.readUint8()
  if header.mapEntryBits == 32:
    result.palette = TGAPalette(alpha: true)
    for i in 0'u16..header.mapLen-1:
      var c: BGRA32Color
      st.read(c)
      result.palette.palette32[i] = c
  else:
    result.palette = TGAPalette(alpha: false)
    for i in 0'u16..header.mapLen-1:
      var c: BGR24Color
      st.read(c)
      result.palette.palette24[i] = c
  let size = header.w * header.h
  if result.rle:
    while true:
      try:
        result.data.add(st.readUint8())
      except IOError:
        break
    result = decompress(result)
  else:
    for _ in 1'u16..size:
      result.data.add(st.readUint8())

proc readTGA*(path: string): TGA =
  let st = newFileStream(path)
  defer:
    st.close()
  return readTGA(st)

