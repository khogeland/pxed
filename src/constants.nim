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
  let c2 = uint8(color and 0xFF)
  buffer[i] = c1
  buffer[i+1] = c2

proc `.`*(buffer: framebuffer, i: int): uint16 =
  let c1 = buffer[i]
  let c2 = buffer[i+1]
  return (uint16(c1) shl 8) or uint16(c2)

proc `[]=`*(buffer: var framebuffer, x, y: int, color: uint16): void =
  let i = (SCREEN_WIDTH * y * BUFFER_ITEM_WIDTH) + (x * BUFFER_ITEM_WIDTH)
  buffer.i = color

proc `[]`*(buffer: framebuffer, x, y: int): uint16 =
  let i = (SCREEN_WIDTH * y * BUFFER_ITEM_WIDTH) + (x * BUFFER_ITEM_WIDTH)
  return buffer.i

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

