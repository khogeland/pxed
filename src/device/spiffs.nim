##  Copyright 2015-2017 Espressif Systems (Shanghai) PTE LTD
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

import
  nesper/consts

## *
##  @brief Configuration structure for esp_vfs_spiffs_register
##

type
  esp_vfs_spiffs_conf_t* {.bycopy.} = object
    base_path*: cstring        ## !< File path prefix associated with the filesystem.
    partition_label*: cstring  ## !< Optional, label of SPIFFS partition to use. If set to NULL, first partition with subtype=spiffs will be used.
    max_files*: csize_t        ## !< Maximum files that could be open at the same time.
    format_if_mount_failed*: bool ## !< If true, it will format the file system if it fails to mount.


## *
##  Register and mount SPIFFS to VFS with given path prefix.
##
##  @param   conf                      Pointer to esp_vfs_spiffs_conf_t configuration structure
##
##  @return
##           - ESP_OK                  if success
##           - ESP_ERR_NO_MEM          if objects could not be allocated
##           - ESP_ERR_INVALID_STATE   if already mounted or partition is encrypted
##           - ESP_ERR_NOT_FOUND       if partition for SPIFFS was not found
##           - ESP_FAIL                if mount or format fails
##

proc esp_vfs_spiffs_register*(conf: ptr esp_vfs_spiffs_conf_t): esp_err_t {.
    importc: "esp_vfs_spiffs_register".}
## *
##  Unregister and unmount SPIFFS from VFS
##
##  @param partition_label  Same label as passed to esp_vfs_spiffs_register.
##
##  @return
##           - ESP_OK if successful
##           - ESP_ERR_INVALID_STATE already unregistered
##

proc esp_vfs_spiffs_unregister*(partition_label: cstring): esp_err_t {.
    importc: "esp_vfs_spiffs_unregister".}
## *
##  Check if SPIFFS is mounted
##
##  @param partition_label  Optional, label of the partition to check.
##                          If not specified, first partition with subtype=spiffs is used.
##
##  @return
##           - true    if mounted
##           - false   if not mounted
##

proc esp_spiffs_mounted*(partition_label: cstring): bool {.
    importc: "esp_spiffs_mounted".}
## *
##  Format the SPIFFS partition
##
##  @param partition_label  Same label as passed to esp_vfs_spiffs_register.
##  @return
##           - ESP_OK      if successful
##           - ESP_FAIL    on error
##

proc esp_spiffs_format*(partition_label: cstring): esp_err_t {.
    importc: "esp_spiffs_format".}
## *
##  Get information for SPIFFS
##
##  @param partition_label           Same label as passed to esp_vfs_spiffs_register
##  @param[out] total_bytes          Size of the file system
##  @param[out] used_bytes           Current used bytes in the file system
##
##  @return
##           - ESP_OK                  if success
##           - ESP_ERR_INVALID_STATE   if not mounted
##

proc esp_spiffs_info*(partition_label: cstring; total_bytes: ptr csize_t;
                     used_bytes: ptr csize_t): esp_err_t {.
    importc: "esp_spiffs_info".}
