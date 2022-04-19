import nesper/gpios
const
  #PIN_TB_RIGHT* = gpio_num_t(33)
  #PIN_TB_LEFT* = gpio_num_t(32)
  #PIN_TB_DOWN* = gpio_num_t(39)
  #PIN_TB_UP* = gpio_num_t(34)
  #PIN_TB_BUTTON* = gpio_num_t(14)

  PIN_BATTERY_V* = gpio_num_t(35)
  
  PIN_X_0* = gpio_num_t(22)
  PIN_X_1* = gpio_num_t(26)
  PIN_X_2* = gpio_num_t(25)
  PIN_Y_0* = gpio_num_t(21)
  PIN_Y_1* = gpio_num_t(33)
  PIN_Y_2* = gpio_num_t(32)
  # huzzah32 pins
  #PIN_X_0* = gpio_num_t(33)
  #PIN_X_1* = gpio_num_t(12)
  #PIN_X_2* = gpio_num_t(14)
  #PIN_Y_0* = gpio_num_t(34)
  #PIN_Y_1* = gpio_num_t(39)
  #PIN_Y_2* = gpio_num_t(32)

  PIN_SCROLL_A* = gpio_num_t(27)
  PIN_SCROLL_B* = gpio_num_t(15)

  PIN_CS_SSD1351_NUM* = 14
  PIN_CS_SSD1351*   = gpio_num_t(PIN_CS_SSD1351_NUM)

  PIN_MISO* = gpio_num_t(19)
  PIN_MOSI* = gpio_num_t(23)
  PIN_SCLK* = gpio_num_t(18)
  PIN_DC_NUM* = 4
  PIN_DC*   = gpio_num_t(PIN_DC_NUM)

