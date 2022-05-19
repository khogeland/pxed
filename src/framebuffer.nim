import color
import constants

const
  BUFFER_LENGTH* = SCREEN_HEIGHT * SCREEN_WIDTH

type framebuffer18* = array[SCREEN_HEIGHT * SCREEN_WIDTH, RGB18Color]

proc `[]=`*(fb: var framebuffer18, x, y: int, b: RGB18Color): void =
  let offset = ((y * SCREEN_WIDTH) + x)
  fb[offset] = b

proc `[]`*(fb: framebuffer18, x, y: int): RGB18Color =
  let offset = ((y * SCREEN_WIDTH) + x)
  return fb[offset]
