import nesper
import nesper/spis
import nesper/esp/driver/gpio_driver
import nesper/esp/gpio
import nesper/timers
import device/pins
import spi
#

const
  TAG: cstring = "ssd1351"


  CMD_SETCOLUMN = 0x15'u8
  CMD_SETROW = 0x75'u8
  CMD_WRITERAM = 0x5C'u8
  CMD_READRAM = 0x5D'u8
  CMD_SETREMAP = 0xA0'u8
  CMD_STARTLINE = 0xA1'u8
  CMD_DISPLAYOFFSET = 0xA2'u8
  CMD_DISPLAYALLOFF = 0xA4'u8
  CMD_DISPLAYALLON = 0xA5'u8
  CMD_NORMALDISPLAY = 0xA6'u8
  CMD_INVERTDISPLAY = 0xA7'u8
  CMD_FUNCTIONSELECT = 0xAB'u8
  CMD_DISPLAYOFF = 0xAE'u8
  CMD_DISPLAYON = 0xAF'u8
  CMD_PRECHARGE = 0xB1'u8
  CMD_DISPLAYENHANCE = 0xB2'u8
  CMD_CLOCKDIV = 0xB3'u8
  CMD_SETVSL = 0xB4'u8
  CMD_SETGPIO = 0xB5'u8
  CMD_PRECHARGE2 = 0xB6'u8
  CMD_SETGRAY = 0xB8'u8
  CMD_USELUT = 0xB9'u8
  CMD_PRECHARGELEVEL = 0xBB'u8
  CMD_VCOMH = 0xBE'u8
  CMD_CONTRASTABC = 0xC1'u8
  CMD_CONTRASTMASTER = 0xC7'u8
  CMD_MUXRATIO = 0xCA'u8
  CMD_COMMANDLOCK = 0xFD'u8
  CMD_HORIZSCROLL = 0x96'u8
  CMD_STOPSCROLL = 0x9E'u8
  CMD_STARTSCROLL = 0x9F'u8

var brightness = 0xFF

proc init1351Spi*(bus: SpiBus): SpiDev =
  return bus.addDevice(commandlen = bits(0),
                       addresslen = bits(0),
                       mode=SPI_MODE, cs_io=PIN_CS_SSD1351,
                       clock_speed_hz = SPI_MASTER_FREQ_8M, 
                       queue_size = 1,
                       flags={HALFDUPLEX})

proc setContrast*(dev: SpiDev, r, g, b: uint8) =
  dev.sendCommand(CMD_CONTRASTABC)
  var arg = r
  dev.sendData(8, addr arg)
  arg = g
  dev.sendData(8, addr arg)
  arg = b
  dev.sendData(8, addr arg)

proc initScreen*(dev: SpiDev) = withSpiBus(dev):
  gpio_pad_select_gpio(PIN_CS_SSD1351_NUM)
  check gpio_set_direction(PIN_CS_SSD1351, GPIO_MODE_OUTPUT)
  check gpio_set_level(PIN_CS_SSD1351, 0)

  dev.sendCommand(uint8(CMD_DISPLAYON))
  delayMillis(500)


  logi(TAG, "Initializing display")
  dev.sendCommand(CMD_SETREMAP)
  #TODO asrtarstidnied why my spi functions no work
  var args: uint8 = 0b10110110
  dev.sendData(8, addr args)

  dev.sendCommand(CMD_STARTLINE)
  args = 32
  dev.sendData(8, addr args)

  dev.sendCommand(CMD_COMMANDLOCK)
  args = 0xB1
  dev.sendData(8, addr args)

  dev.sendCommand(CMD_CLOCKDIV)
  args = 0b10110001
  dev.sendData(8, addr args)

  logi(TAG, "Display enabled")

proc setBrightness*(dev: SpiDev, brightness: uint8): void =
  var b = brightness
  dev.sendCommand(CMD_CONTRASTMASTER)
  dev.sendData(8, addr b)

# note: esp32 is little endian so if we copy any multi-byte words we get fucky colors
proc sendBuffer*(dev: SpiDev, length: uint, data: pointer) =
  dev.sendCommand(uint8(CMD_WRITERAM))
  dev.sendData(length, data)

proc shutdown*(dev: SpiDev): void =
  dev.sendCommand(CMD_DISPLAYOFF)
  dev.sendCommand(CMD_FUNCTIONSELECT)
  var args: uint8 = 0
  dev.sendData(8, addr args)
