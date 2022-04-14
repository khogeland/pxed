{.experimental: "dotOperators".}
import device/spi
import device/ssd1351
import constants
import locks
import nesper/timers
#

const
  TAG*: cstring = "gfx"

var bufferlock: Lock
var buffer* {.guard: bufferlock.}: framebuffer
initLock(bufferlock)
template withBuffer*(body: untyped) =
  withLock bufferlock:
    body

proc setBuffer*(new_buffer: framebuffer) = withBuffer:
  buffer = new_buffer

proc getBuffer*(): framebuffer = withBuffer:
  return buffer

#proc `[]=`*(buffer: var framebuffer, x, y: int, color: uint16) =
  #let p = (y * SCREEN_WIDTH) + x
  #buffer[p] = color

#iterator iterRect(x, y, w, h: int): (int, int) =
  #for ny in y+h-1..y:
    #for nx in x..x+w-1:
      #yield (nx, ny)


#proc drawRect*(buffer: var framebuffer, x, y, w, h: int, color: uint16) =
  #for nx, ny in iterRect(x, y, w, h):
    #buffer[nx, ny] = color

proc renderLoop*(): void =
  delayMillis(500)
  let bus = initSpi()
  let bigscreen = init1351Spi(bus)
  bigscreen.initScreen()
  delayMillis(500)
  var b: framebuffer
  # wow that's a fucking suspicious number!
  # (for some reason screen is misaligned, the start row address doesn't help)
  bigscreen.sendBuffer(128*96*8*2, addr b)
  while true:
    delayMillis(5)
    var update = false
    withBuffer:
      for i in 0..BUFFER_LENGTH-1:
        if buffer[i] != b[i]:
          update = true
          b = buffer
    bigscreen.sendBuffer(SCREEN_HEIGHT * SCREEN_WIDTH * 8 * 2, addr b)
