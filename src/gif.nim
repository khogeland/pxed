{.compile: "../vendor/gifenc/gifenc.c".}

type
  ge_GIF* {.bycopy.} = object
    w*: uint16
    h*: uint16
    depth*: cint
    bgindex*: cint
    fd*: cint
    offset*: cint
    nframes*: cint
    frame*: ptr uint8
    back*: ptr uint8
    partial*: uint32
    buffer*: array[0xFF, uint8]


proc ge_new_gif(fname: cstring; width: uint16; height: uint16;
                palette: ptr uint8; depth: cint; bgindex: cint; loop: cint): ptr ge_GIF {.
    importc: "ge_new_gif" .}
proc ge_add_frame(gif: ptr ge_GIF; delay: uint16) {.importc: "ge_add_frame".}
proc ge_close_gif(gif: ptr ge_GIF) {.importc: "ge_close_gif".}

proc writeGif*(w, h: uint16, contents: openArray[uint8], palette: openArray[uint16], filename: string) =
  var pLen = len(palette)
  var depth: cint = 0
  while pLen > 0:
    pLen = pLen shr 1
    depth += 1
  var palette24 = newSeq[uint8](len(palette)*3)
  for i in 0..len(palette)-1:
    let rgb16Color = palette[i]
    let red: uint8 = uint8(rgb16Color shr 11) shl 3
    let green: uint8 = uint8(rgb16Color shr 5) shl 2
    let blue: uint8 = uint8(rgb16Color) shl 3
    let p=i*3
    palette24[p] = red
    palette24[p+1] = green
    palette24[p+2] = blue
  var gif = ge_new_gif(filename, w, h, unsafeAddr palette24[0], depth, -1, -1)
  copyMem(gif.frame, unsafeAddr contents, w*h)
  ge_add_frame(gif, 0)
  ge_close_gif(gif)
