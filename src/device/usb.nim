import device/tinyusb
import nesper

proc initUSB*() = 
  var config: tinyusb_config_t # zeroed config should use defaults specified in menuconfig

  check tinyusb_driver_install(addr config)
