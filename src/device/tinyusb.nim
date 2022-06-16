##  Copyright 2020 Espressif Systems (Shanghai) PTE LTD
##
##  Licensed under the Apache License, Version 2.0 (the "License");
##  you may not use this file except in compliance with the License.
##  You may obtain a copy of the License at
##
##      http://www.apache.org/licenses/LICENSE-2.0
##
##  Unless required by applicable law or agreed to in writing, software
##  distributed under the License is distributed on an "AS IS" BASIS,
##  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
##  See the License for the specific language governing permissions and
##  limitations under the License.

import nesper

##  tinyusb uses buffers with type of uint8_t[] but in our driver we are reading them as a 32-bit word

#type tusb_desc_device_t* {.importc: "tusb_desc_device_t", header: "tusb_types.h".} = object 
#type tusb_desc_device_t* {.importc: "tusb_desc_device_t".} = object 
type tusb_desc_device_t* {.bycopy.} = object 
  bLength*: uint8
  bDescriptorType*: uint8
  bcdUSB*: uint16
  bDeviceClass*: uint8
  bDeviceSubClass*: uint8
  bDeviceProtocol*: uint8
  bMaxPacketSize0: uint8
  idVendor*: uint16
  idProduct*: uint16
  bcdDevice*: uint16
  iManufacturer*: uint8
  bNumConfigurations*: uint8

type
  tinyusb_config_t* {.bycopy.} = object
    descriptor*: ptr tusb_desc_device_t ## !< Pointer to a device descriptor
    string_descriptor*: cstringArray ## !< Pointer to an array of string descriptors
    external_phy*: bool        ## !< Should USB use an external PHY


## *
##  @brief This is an all-in-one helper function, including:
##  1. USB device driver initialization
##  2. Descriptors preparation
##  3. TinyUSB stack initialization
##  4. Creates and start a task to handle usb events
##
##  @note Don't change Custom descriptor, but if it has to be done,
##        Suggest to define as follows in order to match the Interface Association Descriptor (IAD):
##        bDeviceClass = TUSB_CLASS_MISC,
##        bDeviceSubClass = MISC_SUBCLASS_COMMON,
##
##  @param config tinyusb stack specific configuration
##  @retval ESP_ERR_INVALID_ARG Install driver and tinyusb stack failed because of invalid argument
##  @retval ESP_FAIL Install driver and tinyusb stack failed because of internal error
##  @retval ESP_OK Install driver and tinyusb stack successfully
##

proc tinyusb_driver_install*(config: ptr tinyusb_config_t): esp_err_t {.
    importc: "tinyusb_driver_install".}
##  TODO esp_err_t tinyusb_driver_uninstall(void); (IDF-1474)
