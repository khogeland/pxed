import nesper
import nesper/esp/driver/gpio_driver
import nesper/gpios
import pins
import constants

proc initSystemStuff*(): void =
  configure(
    {PIN_BATTERY_V},
    mode = MODE_INPUT,
    pull_up = false,
    pull_down = false,
  )

#TODO
proc getBatteryLevel(): float =
  return 0

proc esp_deep_sleep_start(): void {.importc: "esp_deep_sleep_start", header: "esp_sleep.h".} =
  discard


type esp_vfs_spiffs_conf_t {.importc: "esp_vfs_spiffs_conf_t", header: "esp_spiffs.h".} = object

proc esp_vfs_spiffs_register(e: esp_vfs_spiffs_conf_t) {.importc: "esp_vfs_spiffs_register", header: "esp_spiffs.h".} = discard

proc enterDeepSleep*(): void =
  esp_deep_sleep_start()
