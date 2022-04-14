{.experimental: "dotOperators".}

const
  SCREEN_HEIGHT* = 128
  SCREEN_WIDTH* = 128
  #SCREEN_HEIGHT_2* = 64
  #SCREEN_WIDTH_2* = 96
  BUFFER_ITEM_WIDTH* = 2
  BUFFER_LENGTH* = SCREEN_HEIGHT * SCREEN_WIDTH * BUFFER_ITEM_WIDTH

#TODO give this a home and/or remove leaky abstraction
type framebuffer* = array[BUFFER_LENGTH, uint8]

proc `.=`*(buffer: var framebuffer, i: int, color: uint16): void =
  let c1 = uint8(color shr 8)
  let c2 = uint8(color)
  buffer[i] = c1
  buffer[i+1] = c2

proc `[]=`*(buffer: var framebuffer, x, y: int, color: uint16): void =
  let i = (SCREEN_WIDTH * y * BUFFER_ITEM_WIDTH) + (x * BUFFER_ITEM_WIDTH)
  buffer.i = color

type direction* = enum
  UP, DOWN, LEFT, RIGHT

