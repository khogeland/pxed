import nesper
import nesper/esp/esp_vfs_fat
import spiffs
import files

proc initStorage*(): void =
  try:
    var config: esp_vfs_fat_mount_config_t
    var wlHandle: wl_handle_t
    config.max_files = 4
    config.format_if_mount_failed = true
    check esp_vfs_fat_spiflash_mount(storagePrefixEsp, "pxed", addr config, addr wlHandle)
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

