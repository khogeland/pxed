import constants
import device/extra
import device/storage
import nesper
import options
import nesper/net_utils
import nesper/timers
import input
import editor/editor
import gfx/gfx
import thread
import tables
import streams
import msgpack4nim
#


#when defined(ESP32_ETHERNET):
  #import setup_eth
#else:
  #import setup_wifi

# const CONFIG_EXAMPLE_WIFI_SSID = getEnv("WIFI_SSID")
# const CONFIG_EXAMPLE_WIFI_PASSWORD = getEnv("WIFI_PASSWORD")

type DeviceSettings = object
  brightness: uint8
  contrastR: uint8
  contrastG: uint8
  contrastB: uint8

const
  TAG*: cstring = "main"
  filePrefix = "/data"
  editorFile = "/data/ed_state"
  settingsFile = "/data/settings"
  defaultSettings = DeviceSettings(
    brightness: 8,
    contrastR: 200,
    contrastG: 100,
    contrastB: 200,
  )

proc adjust*(a: var uint8, by: int): void = a = uint8(max(0, min(255, int(a) + by)))

app_main():
  logi(TAG, "hello!")
  delayMillis(200) # calm down
  initStorage(filePrefix)
  initInput()
  # I think this size is in words?
  createThreadWithStack[void](3000 + BUFFER_LENGTH, renderLoop)
  delayMillis(200) # calm down
  logi(TAG, "we didn't die!")
  var ed: Editor[32, 32]
  var settings: DeviceSettings
  let buttons = pollButtons()
  if E_X in buttons and E_Y in buttons and E_B in buttons:
    ed = initEditor[32,32]()
  else:
    var file: File
    if file.open(editorFile, fmRead):
      var buf = file.readAll()
      unpack(buf, ed)
    else:
      ed = initEditor[32,32]()
    file.close()
  if E_X in buttons and E_Y in buttons and E_Left in buttons:
      settings = defaultSettings
  else:
    var file: File
    if file.open(settingsFile, fmRead):
      var buf = file.readAll()
      unpack(buf, settings)
    else:
      settings = defaultSettings
    file.close()
  ed[0, 0] = 1
  ed[31, 31] = 5
  ed[0, 31] = 3
  setBrightness(settings.brightness)
  setContrast(settings.contrastR, settings.contrastG, settings.contrastB)

  #var currentlyPressed: set[ButtonInput]
  while true:
    # TODO this is bad, framerate locked
    delayMillis(10)
    let buttons = pollButtons()
    var instant: set[InstantInput]
    let scrolls = getScrolls()
    for s in scrolls:
      if s == ScrollUp:
        instant.incl(E_ScrollUp)
      else:
        instant.incl(E_ScrollDown)
    #while true:
      #let o = getNextInputEvent()
      #if o.isNone: break
      #let inputEvent = o.get()
    if E_X in buttons and E_Y in buttons: # device control
      var oldSettings = settings
      if E_A in buttons:
        var buf = pack(ed)
        writeFile(editorFile, buf)
        buf = pack(settings)
        writeFile(settingsFile, buf)
        echo "shutting down screen"
        shutdownScreen()
        echo "sleeping"
        enterDeepSleep()
      elif E_Left in buttons:
        if E_ScrollUp in instant:
          settings.contrastR.adjust(+5)
        elif E_ScrollDown in instant:
          settings.contrastR.adjust(-5)
      elif E_Up in buttons:
        if E_ScrollUp in instant:
          settings.contrastG.adjust(+5)
        elif E_ScrollDown in instant:
          settings.contrastG.adjust(-5)
      elif E_Right in buttons:
        if E_ScrollUp in instant:
          settings.contrastB.adjust(+5)
        elif E_ScrollDown in instant:
          settings.contrastB.adjust(-5)
      elif E_ScrollUp in instant:
        settings.brightness = uint8(max(0, min(16, int(settings.brightness+1))))
      elif E_ScrollDown in instant:
        settings.brightness = uint8(max(0, min(16, int(settings.brightness-1))))
      if settings != oldSettings:
        echo(settings)
        setBrightness(settings.brightness)
        setContrast(settings.contrastR, settings.contrastG, settings.contrastB)
      continue
      
      #case inputEvent.eventType:
        #of ButtonEvent:
          #let eButton = BUTTON_MAP[inputEvent.button]
          #case inputEvent.buttonEventType:
            #of ButtonPressed: currentlyPressed.incl(eButton)
            #of ButtonReleased: currentlyPressed.excl(eButton)
        #of TrackballEvent:
          #instant.incl(TRACKBALL_MAP[inputEvent.direction])
    #if len(buttons) > 0:
      #echo(buttons)
    #if len(instant) > 0:
      #echo(instant)
    ed.handleInput(buttons, instant)
    withBuffer:
      ed.draw(buffer)
