import nesper/timers
import nesper/esp/driver/gpio_driver
import nesper/gpios
import nesper/consts
import nesper/queues
import nesper
import device/pins
import constants
import strutils

const
  TAG*: cstring = "input"

type ButtonMask = distinct uint8
type InstantMask = distinct uint8

type InputState* = object
  pressed*: set[ButtonInput]
  instant*: set[InstantInput]

type InputStateMasked* = object
  pressed: ButtonMask
  instant: InstantMask

type ButtonEventType* = enum
  ButtonPressed
  ButtonReleased

type InputEventType* = enum
  ScrollEvent
  ButtonEvent

var debugQueue: QueueHandle_t
var inputQueue: QueueHandle_t

var bintp: proc(_: pointer): void {.cdecl.}

proc disableButtonInterrupts() = 
  check gpio_isr_handler_remove(PIN_Y_0)
  check gpio_isr_handler_remove(PIN_Y_1)
  check gpio_isr_handler_remove(PIN_Y_2)

proc enableButtonInterrupts() =
  check gpio_isr_handler_add(PIN_Y_0, bintp, nil)
  check gpio_isr_handler_add(PIN_Y_1, bintp, nil)
  check gpio_isr_handler_add(PIN_Y_2, bintp, nil)

proc pollButtons*(): set[ButtonInput] =
  disableButtonInterrupts()
  check gpio_set_level(PIN_X_0, 1)
  check gpio_set_level(PIN_X_1, 0)
  check gpio_set_level(PIN_X_2, 0)
  let x0y0 = gpio_get_level(PIN_Y_0)
  let x0y1 = gpio_get_level(PIN_Y_1)
  let x0y2 = gpio_get_level(PIN_Y_2)
  check gpio_set_level(PIN_X_0, 0)
  check gpio_set_level(PIN_X_1, 1)
  let x1y0 = gpio_get_level(PIN_Y_0)
  let x1y1 = gpio_get_level(PIN_Y_1)
  let x1y2 = gpio_get_level(PIN_Y_2)
  check gpio_set_level(PIN_X_1, 0)
  check gpio_set_level(PIN_X_2, 1)
  let x2y0 = gpio_get_level(PIN_Y_0)
  let x2y1 = gpio_get_level(PIN_Y_1)
  check gpio_set_level(PIN_X_0, 1)
  check gpio_set_level(PIN_X_1, 1)
  check gpio_set_level(PIN_X_2, 1)
  enableButtonInterrupts()
  #echo $x0y0 & " " & $x1y0 & " " & $x2y0
  #echo $x0y1 & " " & $x1y1 & " " & $x2y1
  #echo $x0y2 & " " & $x1y2
  if x0y0 == 1:
    result.incl(E_Y)
  if x0y1 == 1:
    result.incl(E_X)
  if x0y2 == 1:
    result.incl(E_B)
  if x1y0 == 1:
    result.incl(E_A)
  if x1y1 == 1:
    result.incl(E_Down)
  if x1y2 == 1:
    result.incl(E_Left)
  if x2y0 == 1:
    result.incl(E_Up)
  if x2y1 == 1:
    result.incl(E_Right)

proc packButtons(b: set[ButtonInput]): ButtonMask =
  return 
    ((if E_X in b: 1 else: 0) or
    ((if E_Y in b: 1 else: 0) shl 1) or
    ((if E_A in b: 1 else: 0) shl 2) or
    ((if E_B in b: 1 else: 0) shl 3) or
    ((if E_Up in b: 1 else: 0) shl 4) or
    ((if E_Down in b: 1 else: 0) shl 5) or
    ((if E_Left in b: 1 else: 0) shl 6) or
    ((if E_Right in b: 1 else: 0) shl 7)).ButtonMask

proc unpackButtons(b: ButtonMask): set[ButtonInput] =
  if (b.uint8 and 1) != 0: result.incl(E_X)
  if ((b.uint8 shr 1) and 1) != 0: result.incl(E_Y)
  if ((b.uint8 shr 2) and 1) != 0: result.incl(E_A)
  if ((b.uint8 shr 3) and 1) != 0: result.incl(E_B)
  if ((b.uint8 shr 4) and 1) != 0: result.incl(E_Up)
  if ((b.uint8 shr 5) and 1) != 0: result.incl(E_Down)
  if ((b.uint8 shr 6) and 1) != 0: result.incl(E_Left)
  if ((b.uint8 shr 7) and 1) != 0: result.incl(E_Right)

proc packInstant(i: set[InstantInput]): InstantMask =
  return
    (((if E_ScrollUp in i: 1 else: 0) shl 0) or 
    ((if E_ScrollDown in i: 1 else: 0) shl 1) or 
    ((if E_ScrollLeft in i: 1 else: 0) shl 2) or 
    ((if E_ScrollRight in i: 1 else: 0) shl 3)).InstantMask

proc unpackInstant(i: InstantMask): set[InstantInput] =
  if (i.uint8 and 1) != 0: result.incl(E_ScrollUp)
  if ((i.uint8 shr 1) and 1) != 0: result.incl(E_ScrollDown)
  if ((i.uint8 shr 2) and 1) != 0: result.incl(E_ScrollLeft)
  if ((i.uint8 shr 3) and 1) != 0: result.incl(E_ScrollRight)

#TODO fix shutdown switch
proc handleShutdown(unused: pointer) {.cdecl.} = 
  discard
  #delayMillis(1000)
  #check gpio_set_level(PIN_OFF, 0)

var scrollState: uint8 = 0
proc handleScrollInterrupt(unused: pointer) {.cdecl.} =
  var scrollA = uint8(gpio_get_level(PIN_SCROLL_A))
  var scrollB = uint8(gpio_get_level(PIN_SCROLL_B))
  let S0: uint8 = scrollState and 0b11
  let S1: uint8 = (scrollState shr 2) and 0b11
  let C: uint8 = (scrollA shl 1) or scrollB
  # if we're at a detent or midway, any movement is valid:
  if S0 mod 0b11 == 0:
    scrollState = (scrollState shl 2) or C
  # if we're between a detent and a midway point, we must complete the motion in the same direction:
  elif C != S1 and C mod 0b11 == 0: 
    scrollState = (scrollState shl 2) or C
  else:
    return
  # finally, check if we're in the detent position and what direction we were going:
  if (scrollState and 0b1111) == 0b1011:
    var state = InputStateMasked(
      pressed: packButtons(pollButtons()),
      instant: packInstant({E_ScrollDown}),
    )
    discard xQueueSend(inputQueue, addr state, 0)
  elif (scrollState and 0b1111) == 0b0111:
    var state = InputStateMasked(
      pressed: packButtons(pollButtons()),
      instant: packInstant({E_ScrollUp}),
    )
    discard xQueueSend(inputQueue, addr state, 0)

proc handleButtonInterrupt(unused: pointer) {.cdecl.} =
  var state = InputStateMasked(
    pressed: packButtons(pollButtons()),
    instant: 0.InstantMask
  )
  #var i = 0
  #discard xQueueSend(debugQueue, addr i, 0)
  discard xQueueSend(inputQueue, addr state, 0)

bintp = handleButtonInterrupt

proc installScrollInterrupt*() =
  check gpio_isr_handler_add(PIN_SCROLL_A, handleScrollInterrupt, nil)
  check gpio_isr_handler_add(PIN_SCROLL_B, handleScrollInterrupt, nil)

proc initInput*() = 
  configure(
    {PIN_X_0, PIN_X_1, PIN_X_2},
    mode = MODE_OUTPUT,
    pull_up = true,
    pull_down = false,
  )
  configure(
    {PIN_OFF},
    mode = MODE_OUTPUT,
    pull_up = true,
    pull_down = false,
  )
  configure(
    {PIN_Y_0, PIN_Y_1, PIN_Y_2},
    mode = MODE_INPUT,
    pull_up = false,
    pull_down = true,
    interrupt = INTR_ANYEDGE,
  )
  configure(
    {PIN_OFF_INT},
    mode = MODE_INPUT,
    pull_up = false,
    pull_down = false,
    interrupt = INTR_ANYEDGE,
  )
  configure(
    {PIN_SCROLL_A},
    mode = MODE_INPUT,
    pull_up = true,
    pull_down = false,
    interrupt = INTR_ANYEDGE,
  )
  configure(
    {PIN_SCROLL_B},
    mode = MODE_INPUT,
    pull_up = true,
    pull_down = false,
    interrupt = INTR_ANYEDGE,
  )
  check gpio_set_level(PIN_OFF, 1)
  check gpio_set_level(PIN_X_0, 1)
  check gpio_set_level(PIN_X_1, 1)
  check gpio_set_level(PIN_X_2, 1)
  debugQueue = xQueueCreate(30, sizeof(int))
  inputQueue = xQueueCreate(30, sizeof(InputStateMasked))
  check gpio_install_isr_service(esp_intr_flags(0))
  installScrollInterrupt()
  check gpio_isr_handler_add(PIN_OFF_INT, handleShutdown, nil)
  enableButtonInterrupts()

proc getInputStates*(): seq[InputState] =
  var m: InputStateMasked
  while xQueueReceive(inputQueue, addr m, 0) != 0:
    result.add(InputState( 
      pressed: unpackButtons(m.pressed),
      instant: unpackInstant(m.instant),
    ))
  #var i: int
  #while xQueueReceive(debugQueue, addr i, 0) != 0:
    #echo i.toBin(8)
