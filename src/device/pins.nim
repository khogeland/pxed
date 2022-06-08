import nesper/gpios
const
  PIN_BATTERY_V* = gpio_num_t(9)
  
  PIN_X_0* = gpio_num_t(11)
  PIN_X_1* = gpio_num_t(12)
  PIN_X_2* = gpio_num_t(13)
  PIN_Y_0* = gpio_num_t(14)
  PIN_Y_1* = gpio_num_t(15)
  PIN_Y_2* = gpio_num_t(16)

  PIN_OFF* = gpio_num_t(38)
  PIN_OFF_INT* = gpio_num_t(10)

  PIN_SCROLL_A* = gpio_num_t(2)
  PIN_SCROLL_B* = gpio_num_t(3)

  PIN_CS_SSD1351_NUM* = 7
  PIN_CS_SSD1351*   = gpio_num_t(PIN_CS_SSD1351_NUM)

  PIN_MISO* = gpio_num_t(-1)
  PIN_MOSI* = gpio_num_t(5)
  PIN_SCLK* = gpio_num_t(6)
  PIN_DC_NUM* = 8
  PIN_DC*   = gpio_num_t(PIN_DC_NUM)

