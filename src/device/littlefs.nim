import nesper

## *
##  @brief Last Modified Time
##
##  Use 't' for LITTLEFS_ATTR_MTIME to match example:
##      https://github.com/ARMmbed/littlefs/issues/23#issuecomment-482293539
##  And to match other external tools such as:
##      https://github.com/earlephilhower/mklittlefs
##

#const
  #LITTLEFS_ATTR_MTIME* = (cast[uint8_t]('t'))

## *
## Configuration structure for esp_vfs_littlefs_register.
##

type
  esp_vfs_littlefs_conf_t* {.bycopy.} = object
    base_path*: cstring        ## *< Mounting point.
    partition_label*: cstring  ## *< Label of partition to use.
    format_if_mount_failed* {.bitsize: 1.}: uint8 ## *< Format the file system if it fails to mount.
    dont_mount* {.bitsize: 1.}: uint8 ## *< Don't attempt to mount or format. Overrides format_if_mount_failed


## *
##  Register and mount littlefs to VFS with given path prefix.
##
##  @param   conf                      Pointer to esp_vfs_littlefs_conf_t configuration structure
##
##  @return
##           - ESP_OK                  if success
##           - ESP_ERR_NO_MEM          if objects could not be allocated
##           - ESP_ERR_INVALID_STATE   if already mounted or partition is encrypted
##           - ESP_ERR_NOT_FOUND       if partition for littlefs was not found
##           - ESP_FAIL                if mount or format fails
##

proc esp_vfs_littlefs_register*(conf: ptr esp_vfs_littlefs_conf_t): esp_err_t {.
    importc: "esp_vfs_littlefs_register".}
## *
##  Unregister and unmount littlefs from VFS
##
##  @param partition_label  Label of the partition to unregister.
##
##  @return
##           - ESP_OK if successful
##           - ESP_ERR_INVALID_STATE already unregistered
##

proc esp_vfs_littlefs_unregister*(partition_label: cstring): esp_err_t {.
    importc: "esp_vfs_littlefs_unregister".}
## *
##  Check if littlefs is mounted
##
##  @param partition_label  Label of the partition to check.
##
##  @return
##           - true    if mounted
##           - false   if not mounted
##

proc esp_littlefs_mounted*(partition_label: cstring): bool {.
    importc: "esp_littlefs_mounted".}
## *
##  Format the littlefs partition
##
##  @param partition_label  Label of the partition to format.
##  @return
##           - ESP_OK      if successful
##           - ESP_FAIL    on error
##

proc esp_littlefs_format*(partition_label: cstring): esp_err_t {.
    importc: "esp_littlefs_format".}
## *
##  Get information for littlefs
##
##  @param partition_label           Optional, label of the partition to get info for.
##  @param[out] total_bytes          Size of the file system
##  @param[out] used_bytes           Current used bytes in the file system
##
##  @return
##           - ESP_OK                  if success
##           - ESP_ERR_INVALID_STATE   if not mounted
##

proc esp_littlefs_info*(partition_label: cstring; total_bytes: ptr csize_t;
                       used_bytes: ptr csize_t): esp_err_t {.
    importc: "esp_littlefs_info".}

