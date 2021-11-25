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


  SSD1351_CMD_SETCOLUMN = 0x15
  SSD1351_CMD_SETROW = 0x75
  SSD1351_CMD_WRITERAM = 0x5C
  SSD1351_CMD_READRAM = 0x5D
  SSD1351_CMD_SETREMAP = 0xA0
  SSD1351_CMD_STARTLINE = 0xA1
  SSD1351_CMD_DISPLAYOFFSET = 0xA2
  SSD1351_CMD_DISPLAYALLOFF = 0xA4
  SSD1351_CMD_DISPLAYALLON = 0xA5
  SSD1351_CMD_NORMALDISPLAY = 0xA6
  SSD1351_CMD_INVERTDISPLAY = 0xA7
  SSD1351_CMD_FUNCTIONSELECT = 0xAB
  SSD1351_CMD_DISPLAYOFF = 0xAE
  SSD1351_CMD_DISPLAYON = 0xAF
  SSD1351_CMD_PRECHARGE = 0xB1
  SSD1351_CMD_DISPLAYENHANCE = 0xB2
  SSD1351_CMD_CLOCKDIV = 0xB3
  SSD1351_CMD_SETVSL = 0xB4
  SSD1351_CMD_SETGPIO = 0xB5
  SSD1351_CMD_PRECHARGE2 = 0xB6
  SSD1351_CMD_SETGRAY = 0xB8
  SSD1351_CMD_USELUT = 0xB9
  SSD1351_CMD_PRECHARGELEVEL = 0xBB
  SSD1351_CMD_VCOMH = 0xBE
  SSD1351_CMD_CONTRASTABC = 0xC1
  SSD1351_CMD_CONTRASTMASTER = 0xC7
  SSD1351_CMD_MUXRATIO = 0xCA
  SSD1351_CMD_COMMANDLOCK = 0xFD
  SSD1351_CMD_HORIZSCROLL = 0x96
  SSD1351_CMD_STOPSCROLL = 0x9E
  SSD1351_CMD_STARTSCROLL = 0x9F


proc init1351Spi*(bus: SpiBus): SpiDev =
  return bus.addDevice(commandlen = bits(0),
                       addresslen = bits(0),
                       mode=SPI_MODE, cs_io=PIN_CS_SSD1351,
                       clock_speed_hz = SPI_MASTER_FREQ_8M, 
                       queue_size = 1,
                       flags={HALFDUPLEX})

proc setContrast*(dev: SpiDev, r, g, b: uint8) =
  for c in @[
    uint8(SSD1351_CMD_CONTRASTABC),
    r,
    g,
    b
  ]:
    dev.sendCommand(c)

proc initScreen*(dev: SpiDev) = withSpiBus(dev):
  gpio_pad_select_gpio(PIN_CS_SSD1351_NUM)
  check gpio_set_direction(PIN_CS_SSD1351, GPIO_MODE_OUTPUT)
  check gpio_set_level(PIN_CS_SSD1351, 0)

  dev.sendCommand(uint8(SSD1351_CMD_DISPLAYON))
  delayMillis(300)


  logi(TAG, "Initializing display")
  # TODO: check against datasheet. this was just copy pasta from adafruit.
  for cmd in @[
      uint8(SSD1351_CMD_COMMANDLOCK),
      # Set command lock, 1 arg
      0x12,
      SSD1351_CMD_COMMANDLOCK,
      # Set command lock, 1 arg
      0xB1,
      SSD1351_CMD_DISPLAYOFF,
      # Display off, no args
      SSD1351_CMD_CLOCKDIV,
      0xF1, # 7:4 = Oscillator Freq, 3:0 = CLK Div Ratio (A[3:0]+1 = 1..16)
      SSD1351_CMD_MUXRATIO,
      127,
      SSD1351_CMD_DISPLAYOFFSET,
      0x0,
      SSD1351_CMD_SETGPIO,
      0x00,
      SSD1351_CMD_FUNCTIONSELECT,
      0x01, # internal (diode drop)
      SSD1351_CMD_PRECHARGE,
      0x32,
      SSD1351_CMD_VCOMH,
      0x05,
      SSD1351_CMD_NORMALDISPLAY,
      SSD1351_CMD_CONTRASTABC,
      0xC8,
      0x80,
      0xC8,
      SSD1351_CMD_CONTRASTMASTER,
      0x0F,
      SSD1351_CMD_SETVSL,
      0xA0,
      0xB5,
      0x55,
      SSD1351_CMD_PRECHARGE2,
      0x01,
      SSD1351_CMD_SETREMAP,
      0b0010001,
      SSD1351_CMD_SETROW,
      0,
      127,
      SSD1351_CMD_SETCOLUMN,
      0,
      127,
      SSD1351_CMD_DISPLAYOFFSET,
      0,
      SSD1351_CMD_STARTLINE,
      127,
      SSD1351_CMD_DISPLAYON,
    ]: dev.sendCommand(cmd)
  logi(TAG, "Display enabled")

# note: esp32 is little endian so if we copy any multi-byte words we get fucky colors
proc sendBuffer*(dev: SpiDev, length: uint, data: pointer) =
  dev.sendCommand(uint8(SSD1351_CMD_WRITERAM))
  dev.sendData(length, data)
