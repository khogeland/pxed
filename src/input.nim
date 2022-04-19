import nesper/timers
import nesper/esp/driver/gpio_driver
import nesper/gpios
import nesper/consts
import nesper/queues
import nesper
import tables
import options
import device/pins
import constants
#

const
  TAG*: cstring = "input"

type ScrollDirection* = enum
  ScrollUp, ScrollDown

type ButtonEventType* = enum
  ButtonPressed
  ButtonReleased

type InputEventType* = enum
  ScrollEvent
  ButtonEvent

var scrollQueue: QueueHandle_t
#var debugQueue: QueueHandle_t

var lastTicks: TickType_t

proc handleScrollAInterrupt(unused: pointer) {.cdecl.} =
  let ticks = xTaskGetTickCountFromISR()
  if ticks > lastTicks+1:
    delayMillis(1)
    let scrollA = gpio_get_level(PIN_SCROLL_A)
    let scrollB = gpio_get_level(PIN_SCROLL_B)
    #let dbg = (scrollA shl 1) or scrollB
    #discard xQueueSend(debugQueue, unsafeAddr ticks, 0)
    let scroll = if scrollA == scrollB:
      ScrollUp
    else:
      ScrollDown
    discard xQueueSend(scrollQueue, unsafeAddr scroll, 0)
    lastTicks = ticks

proc initInput*() = 
  configure(
    {PIN_X_0, PIN_X_1, PIN_X_2},
    mode = MODE_OUTPUT,
    pull_up = true,
    pull_down = false,
  )
  configure(
    {PIN_Y_0, PIN_Y_1, PIN_Y_2, PIN_SCROLL_B},
    mode = MODE_INPUT,
    pull_up = true,
    pull_down = false,
  )
  configure(
    {PIN_SCROLL_A},
    mode = MODE_INPUT,
    pull_up = true,
    pull_down = false,
    interrupt = INTR_ANYEDGE,
  )
  #debugQueue = xQueueCreate(30, sizeof(TickType_t))
  scrollQueue = xQueueCreate(30, sizeof(ScrollDirection))
  check gpio_install_isr_service(esp_intr_flags(0))
  check gpio_isr_handler_add(PIN_SCROLL_A, handleScrollAInterrupt, nil)

proc getScrolls*(): set[ScrollDirection] =
  var scroll: ScrollDirection
  var tick: TickType_t
  #while xQueueReceive(debugQueue, addr tick, 0) != 0:
    #echo(tick)
  while xQueueReceive(scrollQueue, addr scroll, 0) != 0:
    result.incl(scroll)

proc pollButtons*(): set[ButtonInput] =
  check gpio_set_level(PIN_X_0, 0)
  let x0y0 = gpio_get_level(PIN_Y_0)
  let x0y1 = gpio_get_level(PIN_Y_1)
  let x0y2 = gpio_get_level(PIN_Y_2)
  check gpio_set_level(PIN_X_0, 1)
  check gpio_set_level(PIN_X_1, 0)
  let x1y0 = gpio_get_level(PIN_Y_0)
  let x1y1 = gpio_get_level(PIN_Y_1)
  let x1y2 = gpio_get_level(PIN_Y_2)
  check gpio_set_level(PIN_X_1, 1)
  check gpio_set_level(PIN_X_2, 0)
  let x2y0 = gpio_get_level(PIN_Y_0)
  let x2y1 = gpio_get_level(PIN_Y_1)
  check gpio_set_level(PIN_X_2, 1)
  #echo $x0y0 & " " & $x1y0 & " " & $x2y0
  #echo $x0y1 & " " & $x1y1 & " " & $x2y1
  #echo $x0y2 & " " & $x1y2
  if x0y0 == 0:
    result.incl(E_X)
  if x0y1 == 0:
    result.incl(E_Y)
  if x0y2 == 0:
    result.incl(E_A)
  if x1y0 == 0:
    result.incl(E_Left)
  if x1y1 == 0:
    result.incl(E_Up)
  if x1y2 == 0:
    result.incl(E_B)
  if x2y0 == 0:
    result.incl(E_Down)
  if x2y1 == 0:
    result.incl(E_Right)
