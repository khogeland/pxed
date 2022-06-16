import browser
import os
import files
import strutils
import constants
import gfx/sprites
import framebuffer
import editor
import msgpack4nim

type
  ViewType = enum
    EditorView,
    BrowserView
  View = object
    case kind: ViewType
      of EditorView:
        browserIndex: int
        editor: Editor
      of BrowserView:
        browser: Browser
  ViewSaveState = object
    browserIndex: int
    case kind: ViewType
      of EditorView:
        path: string
      of BrowserView: discard

var file: File
var view: View
const savePath = resolveStoragePath("view")

proc initUI*() =
  try:
    if file.open(savePath, fmRead):
      var saveState: ViewSaveState
      var buf = file.readAll()
      unpack(buf, saveState)
      case saveState.kind
      of EditorView:
        view = View(
          kind: EditorView,
          browserIndex: saveState.browserIndex,
          editor: initEditor(saveState.path)
        )
      of BrowserView:
        view = View(
          kind: BrowserView,
          browser: initBrowser(saveState.browserIndex)
        )
    else:
      view = View(
        kind: BrowserView,
        browser: initBrowser(),
      )
  except:
    let e = getCurrentException()
    echo e.msg
    echo e.getStackTrace()
    view = View(
      kind: BrowserView,
      browser: initBrowser(),
    )
  finally:
    file.close()
    discard tryRemoveFile(savePath)

proc loadSprites*() =
  loadBrowserSprites()
  loadEditorSprites()

proc saveUI*() =
  var saveState: ViewSaveState
  case view.kind
  of EditorView:
    view.editor.saveImage()
    if fileExists(view.editor.path): #in case this is a new file we didn't edit
      saveState = ViewSaveState(
        kind: EditorView,
        path: view.editor.path,
        browserIndex: view.browserIndex,
      )
    else:
      saveState = ViewSaveState(
        kind: BrowserView,
        browserIndex: view.browserIndex,
      )
  of BrowserView:
    saveState = ViewSaveState(
      kind: BrowserView,
      browserIndex: view.browser.index,
    )
  var buf = pack(saveState)
  try:
    echo savePath
    echo file.open(savePath, fmWrite)
    file.write(buf)
  finally:
    file.close()

proc maybeSaveImage*() =
  if view.kind == EditorView:
    view.editor.maybeSave()

var previousViewPressed: set[ButtonInput]

proc handleInput*(pressed: set[ButtonInput], instant: set[InstantInput], scrollSpeed = 1) =
  var newPressed = pressed
  newPressed.excl(previousViewPressed)
  var released = previousViewPressed
  released.excl(pressed)
  previousViewPressed.excl(released)
  case view.kind
    of EditorView:
      if view.editor.handleInput(newPressed, instant, scrollSpeed):
        previousViewPressed = pressed
        view.editor.saveImage()
        view = View(
          kind: BrowserView,
          browser: initBrowser(view.browserIndex),
        )
        saveUI()
    of BrowserView:
      if view.browser.handleInput(newPressed, instant, scrollSpeed):
        previousViewPressed = pressed
        let preview = view.browser.getSelection()
        var path = preview.path
        var newFile = false
        var newFileSize = 32
        # this is a little ugly..... whatever........
        if path.endsWith("newfile32.tga"):
          newFile = true
        elif path.endsWith("newfile64.tga"):
          newFile = true
          newFileSize = 64
        elif path.endsWith("newfile128.tga"):
          newFile = true
          newFileSize = 128
        if newFile:
          var images = newSeq[string]()
          for s in listStorageDir("images", true):
            images.add(s.toLowerAscii)
          for i in 0..10000:
            let name = $i & ".tga"
            if not(name in images):
              path = resolveStoragePath("images/" & name)
              break
          view = View(
            kind: EditorView,
            browserIndex: view.browser.index,
            editor: initEditorNewFile(path, newFileSize, newFileSize)
          )
        else:
          view = View(
            kind: EditorView,
            browserIndex: view.browser.index,
            editor: initEditor(path),
          )
        saveUI()

proc drawUI*(buffer: var framebuffer18) =
  case view.kind
    of EditorView:
      view.editor.draw(buffer)
    of BrowserView:
      view.browser.draw(buffer)
  drawSprites(buffer)

