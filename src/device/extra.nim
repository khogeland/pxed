import nesper
import color
import nesper/esp/driver/gpio_driver
import nesper/esp/driver/adc
import nesper/gpios
import pins
import gfx/sprites
import device/esp_adc_cal
import device/esp_sleep

var adcChars: esp_adc_cal_characteristics_t
var batterySprite: Sprite

proc initSystemStuff*(): void =
  configure(
    {PIN_BATTERY_V},
    mode = MODE_INPUT,
    pull_up = false,
    pull_down = false,
  )
  check adc1_config_width(ADC_WIDTH_BIT_13)
  check adc1_config_channel_atten(ADC1_CHANNEL_8, ADC_ATTEN_DB_11)
  discard esp_adc_cal_characterize(ADC_UNIT_1, ADC_ATTEN_DB_11, ADC_WIDTH_BIT_13, 0, addr adcChars)

# (100/570)*4200mV
const minVoltage = 578.94738
const maxVoltage = 736.84212 - minVoltage
# (100/570)*3300mV
proc getBatteryLevel*(): float =
  return (esp_adc_cal_raw_to_voltage(adc1_get_raw(ADC1_CHANNEL_8).uint32, addr adcChars).float-minVoltage)/maxVoltage

proc loadBatterySprite*() =
  # TODO this sprite sucks
  batterySprite = loadImage(80, 104, 2, "battery.tga")

proc showBattery*() =
  let level = min(99.99, getBatteryLevel())
  let width = int(12 * level)
  let angle = level * 160.0
  var color = hsvToRgb(hsv(angle, 1.0, 0.5))
  var palette: array[256, RGB18Color]
  palette[1] = rgb(0, 0, 0)
  for i in 2..width+1:
    palette[i] = color
  updatePalette(batterySprite.palette, palette)
  batterySprite.show()

proc hideBattery*() =
  batterySprite.hide()

proc hibernate*() =
  check esp_deep_sleep_start()
