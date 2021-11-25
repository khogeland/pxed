import constants
import nesper
import options
import nesper/net_utils
import nesper/timers
import input
import editor/editor
import gfx/gfx
import thread
import tables
#


#when defined(ESP32_ETHERNET):
  #import setup_eth
#else:
  #import setup_wifi

# const CONFIG_EXAMPLE_WIFI_SSID = getEnv("WIFI_SSID")
# const CONFIG_EXAMPLE_WIFI_PASSWORD = getEnv("WIFI_PASSWORD")

const TAG*: cstring = "main"

const BUTTON_MAP = {
  TB_Center: E_A,
}.toTable

const TRACKBALL_MAP = {
  TB_Up: E_ScrollUp,
  TB_Down: E_ScrollDown,
  TB_Left: E_ScrollLeft,
  TB_Right: E_ScrollRight,
}.toTable

app_main():
  logi(TAG, "hello!")
  delayMillis(200) # calm down
  initInput()
  # I think this size is in words?
  createThreadWithStack[void](3000 + BUFFER_LENGTH, renderLoop)
  logi(TAG, "we didn't die!")
  var ed = initEditor[32, 32]()
  ed[0, 0] = 1
  ed[31, 31] = 5
  ed[0, 31] = 3

  var currentlyPressed: set[ButtonInput]
  while true:
    delayMillis(10)
    while true:
      let o = getNextInputEvent()
      if o.isNone: break
      let inputEvent = o.get()
      var momentary: set[MomentaryInput]
      case inputEvent.eventType:
        of ButtonEvent:
          let eButton = BUTTON_MAP[inputEvent.button]
          case inputEvent.buttonEventType:
            of ButtonPressed: currentlyPressed.incl(eButton)
            of ButtonReleased: currentlyPressed.excl(eButton)
        of TrackballEvent:
          momentary.incl(TRACKBALL_MAP[inputEvent.direction])
      ed.handleInput(currentlyPressed, momentary)
    withBuffer:
      ed.draw(buffer)
