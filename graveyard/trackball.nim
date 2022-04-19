var trackballTicks = {
  TB_Up: TickType_t(0),
  TB_Down: TickType_t(0),
  TB_Left: TickType_t(0),
  TB_Right: TickType_t(0),
}.toTable

var lastTrackballTick: TickType_t
var lastButtonTick: TickType_t

const BUTTON_MAP = {
  TB_Center: E_A,
}.toTable

const TRACKBALL_MAP = {
  TB_Up: E_ScrollUp,
  TB_Down: E_ScrollDown,
  TB_Left: E_ScrollLeft,
  TB_Right: E_ScrollRight,
}.toTable

import nesper/timers
import nesper/esp/driver/gpio_driver
import nesper/gpios
import nesper/consts
import nesper/queues
import nesper
import tables
import options
import device/pins
#

const
  TAG*: cstring = "input"

type TBDirection* = enum
  TB_Up
  TB_Down
  TB_Left
  TB_Right

type Button* = enum
  TB_Center = PIN_TB_BUTTON

type ButtonEventType* = enum
  ButtonPressed
  ButtonReleased

type InputEventType* = enum
  TrackballEvent
  ButtonEvent

type InputEvent* = object
  case eventType*: InputEventType
    of TrackballEvent:
      direction*: TBDirection
    of ButtonEvent:
      buttonEventType*: ButtonEventType
      button*: Button

var inputQueue: QueueHandle_t

var trackballTicks = {
  TB_Up: TickType_t(0),
  TB_Down: TickType_t(0),
  TB_Left: TickType_t(0),
  TB_Right: TickType_t(0),
}.toTable

var lastTrackballTick: TickType_t
var lastButtonTick: TickType_t

proc handleTrackballInterrupt(dptr: pointer) {.cdecl.} =
  let direction = cast[TBDirection](dptr)
  let ticks = xTaskGetTickCountFromISR()
  if ticks > trackballTicks[direction] + 1 and lastTrackballTick <= trackballTicks[direction]:
    if ticks > lastButtonTick + 20:
      let event = InputEvent(
        eventType: TrackballEvent,
        direction: direction
      )
      discard xQueueSend(inputQueue, unsafeAddr event, 0)
  trackballTicks[direction] = ticks
  lastTrackballTick = ticks

proc handleButtonInterrupt(bptr: pointer) {.cdecl.} =
  let button = cast[Button](bptr)
  if button == TB_Center:
    lastButtonTick = xTaskGetTickCountFromISR()
  let event = InputEvent(
    eventType: ButtonEvent,
    buttonEventType: if getLevel(cast[gpio_num_t](button)): ButtonReleased else: ButtonPressed,
    button: button,
  )
  discard xQueueSend(inputQueue, unsafeAddr event, 0)


proc initInput*() = 
  configure(
    {PIN_TB_UP, PIN_TB_DOWN, PIN_TB_LEFT, PIN_TB_RIGHT},
    mode = MODE_INPUT,
    pull_up = false,
    pull_down = false,
    interrupt = INTR_ANYEDGE,
  )
  configure(
    {PIN_TB_BUTTON},
    mode = MODE_INPUT,
    pull_up = true,
    pull_down = false,
    interrupt = INTR_ANYEDGE,
  )
  inputQueue = xQueueCreate(30, sizeof(InputEvent))

  check gpio_install_isr_service(esp_intr_flags(0))
  check gpio_isr_handler_add(PIN_TB_UP, handleTrackBallInterrupt, cast[pointer](TB_Up))
  check gpio_isr_handler_add(PIN_TB_DOWN, handleTrackBallInterrupt, cast[pointer](TB_Down))
  check gpio_isr_handler_add(PIN_TB_LEFT, handleTrackBallInterrupt, cast[pointer](TB_Left))
  check gpio_isr_handler_add(PIN_TB_RIGHT, handleTrackBallInterrupt, cast[pointer](TB_Right))
  check gpio_isr_handler_add(PIN_TB_BUTTON, handleButtonInterrupt, cast[pointer](TB_Center))

proc getNextInputEvent*(): Option[InputEvent] =
  var event: InputEvent
  if xQueueReceive(inputQueue, addr event, 0) != 0:
    return some(event)
