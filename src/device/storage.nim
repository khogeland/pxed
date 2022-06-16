import nesper
import spiffs
import littlefs
import files

proc initStorage*(): void =
  try:
    var config: esp_vfs_littlefs_conf_t
    config.base_path = storagePrefixEsp
    config.format_if_mount_failed = 1
    config.partition_label = "userdata"
    check esp_vfs_littlefs_register(addr config)
    var sconfig: esp_vfs_spiffs_conf_t
    sconfig.base_path = resourcePrefixEsp
    sconfig.format_if_mount_failed = false
    sconfig.partition_label = "res"
    sconfig.max_files = 1
    check esp_vfs_spiffs_register(addr sconfig)
  except:
    let e = getCurrentException()
    echo e.msg
    echo e.getStackTrace()
    raise e

