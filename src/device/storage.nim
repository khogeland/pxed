import nesper
import nesper/esp/esp_vfs_fat
import nesper/esp/fatfs/ff

proc initStorage*(prefix: string): void =
  var config: esp_vfs_fat_mount_config_t
  var wlHandle: wl_handle_t
  config.max_files = 4
  config.format_if_mount_failed = true
  check esp_vfs_fat_spiflash_mount(prefix, "pxed", addr config, addr wlHandle)
