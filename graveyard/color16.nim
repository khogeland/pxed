
  var color1: uint8
  var color2: uint8
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

