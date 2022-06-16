import constants
import device/storage
import device/spi
import device/ssd1351
import device/extra
#import device/usb
import nesper
import nesper/net_utils
import nesper/timers
import input
import ui/picker
import ui/boss
import msgpack4nim
import framebuffer

type DeviceSettings = object
  brightness: uint8
  contrastR: uint8
  contrastG: uint8
  contrastB: uint8

const
  TAG*: cstring = "main"
  settingsFile = "/data/settings"
  defaultSettings = DeviceSettings(
    brightness: 8,
    contrastR: 235,
    contrastG: 165,
    contrastB: 175,
  )

var buffer: framebuffer18

proc adjust*(a: var uint8, by: int): void = a = uint8(max(0, min(255, int(a) + by)))

app_main():
    try:
      logi(TAG, "hello!")
      delayMillis(200) # calm down
      let bus = initSpi()
      let bigscreen = init1351Spi(bus)
      bigscreen.initScreen()
      initInput()
      initStorage()
      initSystemStuff()
      #initUSB()
      loadSprites()
      loadBatterySprite()
      initUI()
      logi(TAG, "we didn't die!")
      var settings: DeviceSettings
      let buttons = pollButtons()
      if E_X in buttons and E_Y in buttons and E_Left in buttons:
          settings = defaultSettings
      else:
        var file: File
        try:
          if file.open(settingsFile, fmRead):
            var buf = file.readAll()
            unpack(buf, settings)
          else:
            settings = defaultSettings
        except:
          echo getCurrentException().msg
          settings = defaultSettings
        finally:
          file.close()
      bigscreen.setBrightness(settings.brightness)
      bigscreen.setContrast(settings.contrastR, settings.contrastG, settings.contrastB)

      var powerSave = false
      var lastLoop: TickType_t
      while true:
        if getBatteryLevel() < 0.0:
          bigscreen.shutdown()
          hibernate()
        #echo "loop: " & $(xTaskGetTickCount() - lastLoop)
        lastLoop = xTaskGetTickCount()
        delayMillis(1)
        maybeSaveImage()
        var states = getInputStates()
        states.add(InputState(pressed: pollButtons()))
        hideBattery()
        var scrollSpeed = 1
        for s in states:
          if E_B in s.pressed and E_Y in s.pressed: # device control
            #echo getBatteryLevel()
            showBattery()
            var oldSettings = settings
            if E_Left in s.pressed:
              if E_ScrollUp in s.instant:
                settings.contrastR.adjust(+5)
              elif E_ScrollDown in s.instant:
                settings.contrastR.adjust(-5)
            elif E_Up in s.pressed:
              if E_ScrollUp in s.instant:
                settings.contrastG.adjust(+5)
              elif E_ScrollDown in s.instant:
                settings.contrastG.adjust(-5)
            elif E_Right in s.pressed:
              if E_ScrollUp in s.instant:
                settings.contrastB.adjust(+5)
              elif E_ScrollDown in s.instant:
                settings.contrastB.adjust(-5)
            elif E_Down in s.pressed:
              if E_ScrollUp in s.instant:
                powerSave = true
              elif E_ScrollDown in s.instant:
                powerSave = false
              echo powerSave
            elif E_ScrollUp in s.instant:
              settings.brightness = uint8(max(0, min(15, int(settings.brightness)+1)))
            elif E_ScrollDown in s.instant:
              settings.brightness = uint8(max(0, min(15, int(settings.brightness)-1)))
            if settings != oldSettings:
              echo(settings)
              bigscreen.setBrightness(settings.brightness)
              bigscreen.setContrast(settings.contrastR, settings.contrastG, settings.contrastB)
              var file: File
              if file.open(settingsFile, fmWrite):
                let buf = pack(settings)
                file.write(buf)
              file.close()
            continue
          #if len(buttons) > 0:
            #echo buttons
          #if len(instant) > 0:
            #echo instant
          handleInput(s.pressed, s.instant)
          if E_ScrollUp in s.instant or E_ScrollDown in s.instant:
            scrollSpeed += 1
        var time = xTaskGetTickCount()
        drawUI(buffer)
        #echo "draw: " & $(xTaskGetTickCount() - time)
        time = xTaskGetTickCount()
        # the screen SPI clock makes this very slow, but the esp32s2 is single-core :(
        # eliminating this delay would double the framerate but would require a second core
        # i.e. esp32s3 or a second mcu
        # TODO possible optimization: might be possible to update only a region of display ram
        bigscreen.sendBuffer(SCREEN_HEIGHT * SCREEN_WIDTH * 24, addr buffer)
        #echo "sendBuffer: " & $(xTaskGetTickCount() - time)
        #echo "rendered"
    except:
      let e = getCurrentException()
      echo e.msg
      echo e.getStackTrace()
