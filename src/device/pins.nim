import nesper/gpios
const
  # note these are reversed 180 degrees for ergonimics :o)
  PIN_TB_RIGHT* = gpio_num_t(33)
  PIN_TB_LEFT* = gpio_num_t(32)
  PIN_TB_DOWN* = gpio_num_t(39)
  PIN_TB_UP* = gpio_num_t(34)
  PIN_TB_BUTTON* = gpio_num_t(14)

  PIN_CS_SSD1351_NUM* = 13
  PIN_CS_SSD1351*   = gpio_num_t(PIN_CS_SSD1351_NUM)

  #PIN_CS_SSD1331_NUM* = 12
  #PIN_CS_SSD1331*   = gpio_num_t(PIN_CS_SSD1331_NUM)

  PIN_MISO* = gpio_num_t(19)
  PIN_MOSI* = gpio_num_t(18)
  PIN_SCLK* = gpio_num_t(5)
  PIN_DC_NUM* = 27
  PIN_DC*   = gpio_num_t(PIN_DC_NUM)

