import nesper
import nesper/spis
import nesper/esp/driver/gpio_driver
import nesper/esp/gpio
import nesper/timers
import spi
#

const
  TAG: cstring = "ssd1331"

  PIN_CS_SSD1331_NUM = 12
  PIN_CS_SSD1331   = gpio_num_t(PIN_CS_NUM)

  # SSD1331 Commands
  SSD1331_CMD_DRAWLINE = 0x21      #!< Draw line
  SSD1331_CMD_DRAWRECT = 0x22      #!< Draw rectangle
  SSD1331_CMD_FILL = 0x26          #!< Fill enable/disable
  SSD1331_CMD_SETCOLUMN = 0x15     #!< Set column address
  SSD1331_CMD_SETROW = 0x75        #!< Set row adress
  SSD1331_CMD_CONTRASTA = 0x81     #!< Set contrast for color A
  SSD1331_CMD_CONTRASTB = 0x82     #!< Set contrast for color B
  SSD1331_CMD_CONTRASTC = 0x83     #!< Set contrast for color C
  SSD1331_CMD_MASTERCURRENT = 0x87 #!< Master current control
  SSD1331_CMD_SETREMAP = 0xA0      #!< Set re-map & data format
  SSD1331_CMD_STARTLINE = 0xA1     #!< Set display start line
  SSD1331_CMD_DISPLAYOFFSET = 0xA2 #!< Set display offset
  SSD1331_CMD_NORMALDISPLAY = 0xA4 #!< Set display to normal mode
  SSD1331_CMD_DISPLAYALLON = 0xA5  #!< Set entire display ON
  SSD1331_CMD_DISPLAYALLOFF = 0xA6 #!< Set entire display OFF
  SSD1331_CMD_INVERTDISPLAY = 0xA7 #!< Invert display
  SSD1331_CMD_SETMULTIPLEX = 0xA8  #!< Set multiplex ratio
  SSD1331_CMD_SETMASTER = 0xAD     #!< Set master configuration
  SSD1331_CMD_DISPLAYOFF = 0xAE    #!< Display OFF (sleep mode)
  SSD1331_CMD_DISPLAYON = 0xAF     #!< Normal Brightness Display ON
  SSD1331_CMD_POWERMODE = 0xB0     #!< Power save mode
  SSD1331_CMD_PRECHARGE = 0xB1     #!< Phase 1 and 2 period adjustment
  SSD1331_CMD_CLOCKDIV  = 0xB3     #!< Set display clock divide ratio/oscillator frequency
  SSD1331_CMD_PRECHARGEA = 0x8A    #!< Set second pre-charge speed for color A
  SSD1331_CMD_PRECHARGEB = 0x8B    #!< Set second pre-charge speed for color B
  SSD1331_CMD_PRECHARGEC = 0x8C    #!< Set second pre-charge speed for color C
  SSD1331_CMD_PRECHARGELEVEL = 0xBB #!< Set pre-charge voltage
  SSD1331_CMD_VCOMH = 0xBE          #!< Set Vcomh voltge

proc init1331Spi*(bus: SpiBus): SpiDev =
  return bus.addDevice(commandlen = bits(0),
                       addresslen = bits(0),
                       mode=SPI_MODE, cs_io=PIN_CS_SSD1331,
                       clock_speed_hz = SPI_MASTER_FREQ_13M, 
                       queue_size = 10,
                       flags={HALFDUPLEX})

proc setContrast*(dev: SpiDev, r, g, b: uint8) =
  for c in @[
    uint8(SSD1331_CMD_CONTRASTA),
    r,
    SSD1331_CMD_CONTRASTB,
    g,
    SSD1331_CMD_CONTRASTC,
    b
  ]:
    dev.sendCommand(c)

proc initScreen*(dev: SpiDev) = withSpiBus(dev):
  gpio_pad_select_gpio(PIN_CS_SSD1331_NUM)
  check gpio_set_direction(PIN_CS_SSD1331, GPIO_MODE_OUTPUT)
  check gpio_set_level(PIN_CS_SSD1331, 0)

  logi(TAG, "Initializing display")
  for cmd in @[
      uint8(SSD1331_CMD_DISPLAYOFF),
      SSD1331_CMD_SETREMAP,
      0b01110010, # RGB, line-by-line, horizontal first, starting top left
      SSD1331_CMD_SETMASTER,
      0b10001110, # select external power supply
      SSD1331_CMD_POWERMODE,
      0x0B, # disable power save mode
      SSD1331_CMD_CLOCKDIV,
      #1111 0000 = 15/0
      #I don't really understand this, but this is what Adafruit uses.
      0b11110000,
      SSD1331_CMD_MASTERCURRENT,
      0x06, # "Set master current attenuation factor" (to... 7/16 I think? not sure what this does)
      SSD1331_CMD_DISPLAYON,
    ]: dev.sendCommand(cmd)
  logi(TAG, "Display enabled")
