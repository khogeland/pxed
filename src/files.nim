import os
import posix

const storagePrefixEsp* = "/data"
const resourcePrefixEsp* = "/resources"

const storagePrefix =
  when defined(macosx) or defined(linux):
    getHomeDir() & "/.pxed/data/"
  else:
    storagePrefixEsp & "/"
const resourcePrefix =
  when defined(macosx) or defined(linux):
    "resources"
  else:
    resourcePrefixEsp

# copypasta to remove lstat usage which is not implemented in esp-idf's newlib
iterator walkDir*(dir: string; relative = false):
  tuple[kind: PathComponent, path: string] {.tags: [ReadDirEffect].} =
    var d = opendir(dir)
    if d == nil:
      discard
      #raiseOSError(osLastError(), dir)
    else:
      defer: discard closedir(d)
      while true:
        var x = readdir(d)
        if x == nil: break
        var y = $cstring(addr x.d_name)
        if y != "." and y != "..":
          var s: Stat
          let path = dir / y
          if not relative:
            y = path
          var k = pcFile

          if stat(path, s) < 0'i32: continue  # don't yield
          elif S_ISDIR(s.st_mode):
            k = pcDir

          yield (k, y)

#proc maybeOpenFileStream(path: string, st: var FileStream, mode: FileMode = fmRead, bufSize: int = -1): bool =
  #if not fileExists(path):
    #return false
  #else:
    #st = openFileStream(path, mode, bufSize)
    #return true

#proc openResourceStream*(path: string, st: var FileStream, bufSize: int = -1): bool =
  #return maybeOpenFileStream(resourcePrefix & path, st, fmRead, bufSize)

#proc openResourceStream*(path: string, bufSize: int = -1): FileStream =
  #return openFileStream(resourcePrefix & path, fmRead, bufSize)

#proc openStorageStream*(path: string, st: var FileStream, mode: FileMode = fmRead, bufSize: int = -1): bool =
  #return maybeOpenFileStream(storagePrefix & path, st, mode, bufSize)

#proc openStorageStream*(path: string, mode: FileMode = fmRead, bufSize: int = -1): FileStream =
  #return openFileStream(storagePrefix & path, mode, bufSize)

proc resolveStoragePath*(path: string): string =
  return storagePrefix & path

proc resolveResourcePath*(path: string): string =
  return resourcePrefix & path

iterator listStorageDir*(path: string, relative = false): string =
  let realPath = storagePrefix & path
  discard existsOrCreateDir(realPath)
  #var omitNext = true
  #for i in 1.. realPath.len-1:
    #if realPath[i] in {DirSep, AltSep}:
      #if omitNext:
        #omitNext = false
      #else:
        #discard existsOrCreateDir(substr(realPath, 0, i-1))
  for f in walkDir(realPath, relative):
    yield f[1]
