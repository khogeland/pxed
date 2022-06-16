##
##  SPDX-FileCopyrightText: 2015-2021 Espressif Systems (Shanghai) CO LTD
##
##  SPDX-License-Identifier: Apache-2.0
##

import nesper
import nesper/gpios

## *
##  @brief Logic function used for EXT1 wakeup mode.
##

type
  esp_sleep_ext1_wakeup_mode_t* = enum
    ESP_EXT1_WAKEUP_ALL_LOW = 0, ## !< Wake the chip when all selected GPIOs go low
    ESP_EXT1_WAKEUP_ANY_HIGH = 1


type
  esp_sleep_pd_domain_t* = enum
    ESP_PD_DOMAIN_RTC_PERIPH, ## !< RTC IO, sensors and ULP co-processor
    ESP_PD_DOMAIN_RTC_SLOW_MEM, ## !< RTC slow memory
    ESP_PD_DOMAIN_RTC_FAST_MEM, ## !< RTC fast memory
    ESP_PD_DOMAIN_XTAL,       ## !< XTAL oscillator
    ESP_PD_DOMAIN_RTC8M,      ## !< Internal 8M oscillator
    ESP_PD_DOMAIN_VDDSDIO,    ## !< VDD_SDIO
    ESP_PD_DOMAIN_MAX         ## !< Number of domains


## *
##  @brief Power down options
##

type
  esp_sleep_pd_option_t* = enum
    ESP_PD_OPTION_OFF,        ## !< Power down the power domain in sleep mode
    ESP_PD_OPTION_ON,         ## !< Keep power domain enabled during sleep mode
    ESP_PD_OPTION_AUTO        ## !< Keep power domain enabled in sleep mode, if it is needed by one of the wakeup options. Otherwise power it down.


## *
##  @brief Sleep wakeup cause
##

type
  esp_sleep_source_t* = enum
    ESP_SLEEP_WAKEUP_UNDEFINED, ## !< In case of deep sleep, reset was not caused by exit from deep sleep
    ESP_SLEEP_WAKEUP_ALL,     ## !< Not a wakeup cause, used to disable all wakeup sources with esp_sleep_disable_wakeup_source
    ESP_SLEEP_WAKEUP_EXT0,    ## !< Wakeup caused by external signal using RTC_IO
    ESP_SLEEP_WAKEUP_EXT1,    ## !< Wakeup caused by external signal using RTC_CNTL
    ESP_SLEEP_WAKEUP_TIMER,   ## !< Wakeup caused by timer
    ESP_SLEEP_WAKEUP_TOUCHPAD, ## !< Wakeup caused by touchpad
    ESP_SLEEP_WAKEUP_ULP,     ## !< Wakeup caused by ULP program
    ESP_SLEEP_WAKEUP_GPIO,    ## !< Wakeup caused by GPIO (light sleep only)
    ESP_SLEEP_WAKEUP_UART,    ## !< Wakeup caused by UART (light sleep only)
    ESP_SLEEP_WAKEUP_WIFI,    ## !< Wakeup caused by WIFI (light sleep only)
    ESP_SLEEP_WAKEUP_COCPU,   ## !< Wakeup caused by COCPU int
    ESP_SLEEP_WAKEUP_COCPU_TRAP_TRIG, ## !< Wakeup caused by COCPU crash
    ESP_SLEEP_WAKEUP_BT       ## !< Wakeup caused by BT (light sleep only)


##  Leave this type define for compatibility

type
  esp_sleep_wakeup_cause_t* = esp_sleep_source_t

## *
##  @brief Disable wakeup source
##
##  This function is used to deactivate wake up trigger for source
##  defined as parameter of the function.
##
##  @note This function does not modify wake up configuration in RTC.
##        It will be performed in esp_sleep_start function.
##
##  See docs/sleep-modes.rst for details.
##
##  @param source - number of source to disable of type esp_sleep_source_t
##  @return
##       - ESP_OK on success
##       - ESP_ERR_INVALID_STATE if trigger was not active
##

proc esp_sleep_disable_wakeup_source*(source: esp_sleep_source_t): esp_err_t {.
    importc: "esp_sleep_disable_wakeup_source".}
## *
##  @brief Enable wakeup by timer
##  @param time_in_us  time before wakeup, in microseconds
##  @return
##       - ESP_OK on success
##       - ESP_ERR_INVALID_ARG if value is out of range (TBD)
##

proc esp_sleep_enable_timer_wakeup*(time_in_us: uint64): esp_err_t {.
    importc: "esp_sleep_enable_timer_wakeup".}
## *
##  @brief Returns true if a GPIO number is valid for use as wakeup source.
##
##  @note For SoCs with RTC IO capability, this can be any valid RTC IO input pin.
##
##  @param gpio_num Number of the GPIO to test for wakeup source capability
##
##  @return True if this GPIO number will be accepted as a sleep wakeup source.
##

proc esp_sleep_is_valid_wakeup_gpio*(gpio_num: gpio_num_t): bool {.
    importc: "esp_sleep_is_valid_wakeup_gpio".}
## *
##  @brief Enable wakeup from light sleep using GPIOs
##
##  Each GPIO supports wakeup function, which can be triggered on either low level
##  or high level. Unlike EXT0 and EXT1 wakeup sources, this method can be used
##  both for all IOs: RTC IOs and digital IOs. It can only be used to wakeup from
##  light sleep though.
##
##  To enable wakeup, first call gpio_wakeup_enable, specifying gpio number and
##  wakeup level, for each GPIO which is used for wakeup.
##  Then call this function to enable wakeup feature.
##
##  @note In revisions 0 and 1 of the ESP32, GPIO wakeup source
##        can not be used together with touch or ULP wakeup sources.
##
##  @return
##       - ESP_OK on success
##       - ESP_ERR_INVALID_STATE if wakeup triggers conflict
##

proc esp_sleep_enable_gpio_wakeup*(): esp_err_t {.
    importc: "esp_sleep_enable_gpio_wakeup".}
## *
##  @brief Enable wakeup from light sleep using UART
##
##  Use uart_set_wakeup_threshold function to configure UART wakeup threshold.
##
##  Wakeup from light sleep takes some time, so not every character sent
##  to the UART can be received by the application.
##
##  @note ESP32 does not support wakeup from UART2.
##
##  @param uart_num  UART port to wake up from
##  @return
##       - ESP_OK on success
##       - ESP_ERR_INVALID_ARG if wakeup from given UART is not supported
##

proc esp_sleep_enable_uart_wakeup*(uart_num: cint): esp_err_t {.
    importc: "esp_sleep_enable_uart_wakeup".}
## *
##  @brief Enable wakeup by WiFi MAC
##  @return
##       - ESP_OK on success
##

proc esp_sleep_enable_wifi_wakeup*(): esp_err_t {.
    importc: "esp_sleep_enable_wifi_wakeup".}
## *
##  @brief Disable wakeup by WiFi MAC
##  @return
##       - ESP_OK on success
##

proc esp_sleep_disable_wifi_wakeup*(): esp_err_t {.
    importc: "esp_sleep_disable_wifi_wakeup".}
## *
##  @brief Get the bit mask of GPIOs which caused wakeup (ext1)
##
##  If wakeup was caused by another source, this function will return 0.
##
##  @return bit mask, if GPIOn caused wakeup, BIT(n) will be set
##

## *
##  @brief Set power down mode for an RTC power domain in sleep mode
##
##  If not set set using this API, all power domains default to ESP_PD_OPTION_AUTO.
##
##  @param domain  power domain to configure
##  @param option  power down option (ESP_PD_OPTION_OFF, ESP_PD_OPTION_ON, or ESP_PD_OPTION_AUTO)
##  @return
##       - ESP_OK on success
##       - ESP_ERR_INVALID_ARG if either of the arguments is out of range
##

proc esp_sleep_pd_config*(domain: esp_sleep_pd_domain_t;
                         option: esp_sleep_pd_option_t): esp_err_t {.
    importc: "esp_sleep_pd_config".}
## *
##  @brief Enter deep sleep with the configured wakeup options
##
##  This function does not return.
##

## !!!Ignored construct:  void esp_deep_sleep_start ( void ) __attribute__ ( ( noreturn ) ) ;
## Error: expected ';'!!!

## *
##  @brief Enter light sleep with the configured wakeup options
##
##  @return
##   - ESP_OK on success (returned after wakeup)
##   - ESP_ERR_INVALID_STATE if WiFi or BT is not stopped
##

proc esp_light_sleep_start*(): esp_err_t {.importc: "esp_light_sleep_start".}
## *
##  @brief Enter deep-sleep mode
##
##  The device will automatically wake up after the deep-sleep time
##  Upon waking up, the device calls deep sleep wake stub, and then proceeds
##  to load application.
##
##  Call to this function is equivalent to a call to esp_deep_sleep_enable_timer_wakeup
##  followed by a call to esp_deep_sleep_start.
##
##  esp_deep_sleep does not shut down WiFi, BT, and higher level protocol
##  connections gracefully.
##  Make sure relevant WiFi and BT stack functions are called to close any
##  connections and deinitialize the peripherals. These include:
##      - esp_bluedroid_disable
##      - esp_bt_controller_disable
##      - esp_wifi_stop
##
##  This function does not return.
##
##  @note The device will wake up immediately if the deep-sleep time is set to 0
##
##  @param time_in_us  deep-sleep time, unit: microsecond
##

## !!!Ignored construct:  void esp_deep_sleep ( uint64_t time_in_us ) __attribute__ ( ( noreturn ) ) ;
## Error: expected ';'!!!

## *
##  @brief Get the wakeup source which caused wakeup from sleep
##
##  @return cause of wake up from last sleep (deep sleep or light sleep)
##

proc esp_sleep_get_wakeup_cause*(): esp_sleep_wakeup_cause_t {.
    importc: "esp_sleep_get_wakeup_cause".}
## *
##  @brief Default stub to run on wake from deep sleep.
##
##  Allows for executing code immediately on wake from sleep, before
##  the software bootloader or ESP-IDF app has started up.
##
##  This function is weak-linked, so you can implement your own version
##  to run code immediately when the chip wakes from
##  sleep.
##
##  See docs/deep-sleep-stub.rst for details.
##

proc esp_wake_deep_sleep*() {.importc: "esp_wake_deep_sleep".}
## *
##  @brief Function type for stub to run on wake from sleep.
##
##

type
  esp_deep_sleep_wake_stub_fn_t* = proc ()

## *
##  @brief Install a new stub at runtime to run on wake from deep sleep
##
##  If implementing esp_wake_deep_sleep() then it is not necessary to
##  call this function.
##
##  However, it is possible to call this function to substitute a
##  different deep sleep stub. Any function used as a deep sleep stub
##  must be marked RTC_IRAM_ATTR, and must obey the same rules given
##  for esp_wake_deep_sleep().
##

proc esp_set_deep_sleep_wake_stub*(new_stub: esp_deep_sleep_wake_stub_fn_t) {.
    importc: "esp_set_deep_sleep_wake_stub".}
## *
##  @brief Get current wake from deep sleep stub
##  @return Return current wake from deep sleep stub, or NULL if
##          no stub is installed.
##

proc esp_get_deep_sleep_wake_stub*(): esp_deep_sleep_wake_stub_fn_t {.
    importc: "esp_get_deep_sleep_wake_stub".}
## *
##   @brief The default esp-idf-provided esp_wake_deep_sleep() stub.
##
##   See docs/deep-sleep-stub.rst for details.
##

proc esp_default_wake_deep_sleep*() {.importc: "esp_default_wake_deep_sleep".}
## *
##  @brief Disable logging from the ROM code after deep sleep.
##
##  Using LSB of RTC_STORE4.
##

proc esp_deep_sleep_disable_rom_logging*() {.
    importc: "esp_deep_sleep_disable_rom_logging".}
