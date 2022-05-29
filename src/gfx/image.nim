import color
import streams

# TODO run-length encoding
type
  TGAPalette = object
    case alpha: bool
    of true:
      palette32: seq[BGRA32Color]
    of false:
      palette24: seq[BGR24Color]
  TGA* = object
    palette*: TGAPalette
    data*: seq[uint8]
    w*, h*: uint16
    topOrigin: bool
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
  result.palette.palette24 = newSeq[BGR24Color](256)
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

func tgaErr(msg: string): void =
  raise newException(ValueError, msg)

proc writeTGA*(st: FileStream, tga: TGA): void =
  let header = TGAHeader(
    idLen: 0,
    colorMapType: 1,
    imageType: 1,
    mapIdx: 0,
    mapLen: 256,
    mapEntryBits: if tga.palette.alpha: 32 else: 24,
    xOrigin: 0,
    yOrigin: 0,
    w: tga.w,
    h: tga.h,
    bpp: 8,
    descriptor: 0, # always write with bottom origin
  )
  st.write(header)
  if tga.palette.alpha:
    for color in tga.palette.palette32:
      st.write(color)
  else:
    for color in tga.palette.palette24:
      st.write(color)
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
    tgaErr("incorrect color map type: " & $header.colorMapType)
  if unlikely(header.imageType != 1):
    tgaErr("image should be uncompressed and indexed")
  if unlikely(header.mapEntryBits != 32 and header.mapEntryBits != 24):
    tgaErr("unsupported color format")
  if unlikely(header.mapLen > 256):
    tgaErr("color map too large")
  if unlikely(header.bpp != 8):
    tgaErr("expected 8 bits per pixel")
  # rest of the fields i'm just going to ignore....
  result.w = header.w
  result.h = header.h
  result.topOrigin = (header.descriptor and 0b00100000) != 0
  if header.idLen != 0:
    for _ in 1'u8..header.idLen:
      discard st.readUint8()
  if header.mapEntryBits == 32:
    result.palette = TGAPalette(alpha: true)
    for _ in 1'u16..header.mapLen:
      var c: BGRA32Color
      st.read(c)
      result.palette.palette32.add(c)
  else:
    result.palette = TGAPalette(alpha: false)
    for _ in 1'u16..header.mapLen:
      var c: BGR24Color
      st.read(c)
      result.palette.palette24.add(c)
  let size = header.w * header.h
  for _ in 1'u16..size:
    result.data.add(st.readUint8())

proc readTGA*(path: string): TGA =
  let st = newFileStream(path)
  defer:
    st.close()
  return readTGA(st)

