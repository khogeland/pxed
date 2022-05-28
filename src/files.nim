import os
import streams
export streams

const storagePrefix =
  when defined(macosx) or defined(linux):
    getHomeDir() & "/.pxed/data/"
  else:
    "/data/"
const resourcePrefix =
  when defined(macosx) or defined(linux):
    "resources/"
  else:
    "/resources/"


proc openFileStream(path: string, mode: FileMode = fmRead, bufSize: int = -1): FileStream =
  createDir(parentDir(path))
  return newFileStream(path, mode, bufSize)

proc maybeOpenFileStream(path: string, st: var FileStream, mode: FileMode = fmRead, bufSize: int = -1): bool =
  if not fileExists(path):
    return false
  else:
    st = newFileStream(path, mode, bufSize)
    return true

proc openResourceStream*(path: string, st: var FileStream, bufSize: int = -1): bool =
  return maybeOpenFileStream(resourcePrefix & path, st, fmRead, bufSize)

proc openResourceStream*(path: string, bufSize: int = -1): FileStream =
  return openFileStream(resourcePrefix & path, fmRead, bufSize)

proc openStorageStream*(path: string, st: var FileStream, mode: FileMode = fmRead, bufSize: int = -1): bool =
  return maybeOpenFileStream(storagePrefix & path, st, mode, bufSize)

proc openStorageStream*(path: string, mode: FileMode = fmRead, bufSize: int = -1): FileStream =
  return openFileStream(storagePrefix & path, mode, bufSize)

proc resolveStoragePath*(path: string): string =
  return storagePrefix & path

iterator listStorageDir*(path: string): string =
  let realPath = storagePrefix & path
  createDir(realPath)
  for f in walkFiles(realPath & "/*"):
    yield f
