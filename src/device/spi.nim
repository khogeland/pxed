import constants
import nesper
import nesper/spis
import nesper/esp/driver/gpio_driver
import nesper/esp/gpio
import device/pins
#

const
  # (CPOL, CPHA) = (0, 0)
  SPI_MODE* = 0

  TAG: cstring = "spi"

proc initSpi*(): SpiBus =
  gpio_pad_select_gpio(PIN_DC_NUM)
  check gpio_set_direction(PIN_DC, GPIO_MODE_OUTPUT)
  check gpio_set_level(PIN_DC, 0)

  return HSPI.newSpiBus(
      miso=PIN_MISO,
      mosi=PIN_MOSI,
      sclk=PIN_SCLK,
      max_transfer_sz = SCREEN_HEIGHT * SCREEN_WIDTH * 8,
      dma_channel=1, flags={MASTER})

proc writeSpiBytes*(dev: SpiDev, data: openArray[uint8]) =
  if len(data) == 0:
    return
  var trans = new(SpiTrans)
  trans.dev = dev
  #trans.tx_data = data.toSeq()
  trans.trn.length = 8 * uint32(len(data))
  trans.trn.tx_buffer = unsafeAddr data[0]
  transmit(trans)

proc writeSpi*(dev: SpiDev, length: uint, data: pointer) =
  var trans = new(SpiTrans)
  trans.dev = dev
  #trans.tx_data = data.toSeq()
  trans.trn.length = length
  trans.trn.tx_buffer = data
  transmit(trans)

proc sendCommand*(dev: SpiDev, cmd: uint8) =
  check gpio_set_level(PIN_DC, 0)
  writeSpiBytes(dev, @[cmd])

#proc sendCommand*(dev: SpiDev, cmd: openArray[uint8]) =
  #check gpio_set_level(PIN_DC, 0)
  #writeSpiBytes(dev, cmd[0..1])
  #check gpio_set_level(PIN_DC, 1)
  #writeSpiBytes(dev, cmd[1..^1])

#proc sendData*(dev: SpiDev, data: openArray[uint8]) =
  #check gpio_set_level(PIN_DC, 1)
  #writeSpiBytes(dev, data)

proc sendData*(dev: SpiDev, length: uint, data: pointer) =
  check gpio_set_level(PIN_DC, 1)
  writeSpi(dev, length, data)
